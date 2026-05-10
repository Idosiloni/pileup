/**
 * Pileup engine tests.
 *
 * Plain-Node tests, no framework. Run with:  node tests/engine.test.js
 *
 * Add tests as engine grows. These document expected behavior and
 * guard against regressions when refactoring.
 */

const { makeCard, makeRandomPile, makeStarterPile, upgradeCardValue } = require('../src/engine/cards.js');
const {
  FLIP_COUNT, BASE_WEIGHT, MIN_WEIGHT,
  effectiveWeight, weightedSample, shuffle,
  selectFlipped, flipProbabilities
} = require('../src/engine/selection.js');
const { ABILITIES, onRevealBonus, postFlipDeltas } = require('../src/engine/abilities.js');
const { resolveFlip, simulateBattle } = require('../src/engine/battle.js');

let passed = 0;
let failed = 0;
const failures = [];

function assert(condition, message) {
  if (condition) {
    passed += 1;
  } else {
    failed += 1;
    failures.push(message);
  }
}

function approxEqual(actual, expected, tolerance, message) {
  const diff = Math.abs(actual - expected);
  assert(diff <= tolerance, message + ' (got ' + actual + ', expected ~' + expected + ' ±' + tolerance + ')');
}

// ------------------------------------------------------------------
// cards.js
// ------------------------------------------------------------------

(function testCards() {
  const c = makeCard(7);
  assert(c.value === 7, 'makeCard sets value');
  assert(c.weight === 0, 'makeCard defaults weight to 0');
  assert(typeof c.id === 'string', 'makeCard assigns string id');

  const pile = makeRandomPile('test');
  assert(pile.cards.length === 10, 'makeRandomPile returns 10 cards');
  assert(pile.ownerId === 'test', 'makeRandomPile sets ownerId');
  assert(pile.cards.every(c => c.value >= 1 && c.value <= 10), 'random values are 1-10');

  const starter = makeStarterPile('s');
  assert(starter.cards.length === 10, 'starter pile has 10 cards');
  const values = starter.cards.map(c => c.value).sort((a, b) => a - b);
  assert(JSON.stringify(values) === JSON.stringify([1,2,3,4,5,6,7,8,9,10]), 'starter pile is values 1-10');

  const ids = pile.cards.map(c => c.id);
  const unique = new Set(ids);
  assert(unique.size === ids.length, 'card ids are unique within a pile');
})();

// ------------------------------------------------------------------
// selection.js
// ------------------------------------------------------------------

(function testSelection() {
  assert(FLIP_COUNT === 5, 'FLIP_COUNT is 5');

  const neutral = makeCard(5);
  assert(effectiveWeight(neutral) === BASE_WEIGHT, 'neutral card has BASE_WEIGHT');
  const buffed = makeCard(5, { weight: 50 });
  assert(effectiveWeight(buffed) === BASE_WEIGHT + 50, 'positive weight adds');
  const debuffed = makeCard(5, { weight: -200 });
  assert(effectiveWeight(debuffed) === MIN_WEIGHT, 'weight floors at MIN_WEIGHT');

  const pile = makeRandomPile('t');
  const flipped = selectFlipped(pile);
  assert(flipped.length === FLIP_COUNT, 'selectFlipped returns exactly FLIP_COUNT cards');

  const flippedIds = new Set(flipped.map(c => c.id));
  assert(flippedIds.size === FLIP_COUNT, 'selected cards are unique (no duplicates)');

  // Positional traits
  const positionedPile = {
    cards: [
      makeCard(1, { position: 'first' }),
      makeCard(2),
      makeCard(3),
      makeCard(4),
      makeCard(5),
      makeCard(6),
      makeCard(7),
      makeCard(8),
      makeCard(9),
      makeCard(10, { position: 'last' })
    ],
    ownerId: 't'
  };
  let firstAlwaysFirst = true;
  let lastAlwaysLast = true;
  for (let i = 0; i < 50; i++) {
    const f = selectFlipped(positionedPile);
    if (f.length === FLIP_COUNT) {
      // The 'first' card may not be drawn at all (it has neutral weight),
      // but if it IS drawn, it must be at index 0.
      const firstIdx = f.findIndex(c => c.position === 'first');
      const lastIdx = f.findIndex(c => c.position === 'last');
      if (firstIdx !== -1 && firstIdx !== 0) firstAlwaysFirst = false;
      if (lastIdx !== -1 && lastIdx !== f.length - 1) lastAlwaysLast = false;
    }
  }
  assert(firstAlwaysFirst, 'position:first card always appears at index 0 when drawn');
  assert(lastAlwaysLast, 'position:last card always appears at last index when drawn');

  // Probability sanity check: high-weight cards flip more often
  const weightedPile = {
    cards: [
      makeCard(1, { weight: 200 }),  // heavy favorite
      makeCard(2),
      makeCard(3),
      makeCard(4),
      makeCard(5),
      makeCard(6),
      makeCard(7),
      makeCard(8),
      makeCard(9),
      makeCard(10, { weight: -50 })  // long shot
    ],
    ownerId: 't'
  };
  const heavyId = weightedPile.cards[0].id;
  const longShotId = weightedPile.cards[9].id;
  let heavyAppearances = 0;
  let longShotAppearances = 0;
  const trials = 2000;
  for (let i = 0; i < trials; i++) {
    const f = selectFlipped(weightedPile);
    const ids = new Set(f.map(c => c.id));
    if (ids.has(heavyId)) heavyAppearances += 1;
    if (ids.has(longShotId)) longShotAppearances += 1;
  }
  assert(heavyAppearances > longShotAppearances, 'heavy-weight card flips more often than long-shot');

  // Probability display sanity
  const probs = flipProbabilities(weightedPile);
  assert(probs.length === 10, 'flipProbabilities returns one per card');
  assert(probs[0] > probs[9], 'heavier weight has higher flip probability');
  assert(probs.every(p => p >= 0 && p <= 100), 'probabilities are in [0, 100]');

  // Neutral pile: all cards must show the same flip probability
  const neutralPile = makeStarterPile('n');
  const neutralProbs = flipProbabilities(neutralPile);
  assert(neutralProbs.every(p => p === neutralProbs[0]), 'neutral pile has equal flip probabilities for all cards');
})();

// ------------------------------------------------------------------
// battle.js
// ------------------------------------------------------------------

(function testBattle() {
  const high = makeCard(10);
  const low = makeCard(1);
  assert(resolveFlip(high, low).winner === 'left', 'higher value wins');
  assert(resolveFlip(low, high).winner === 'right', 'higher value wins (right)');
  assert(resolveFlip(high, high).winner === 'tie', 'equal values tie');
  assert(resolveFlip(high, low).delta === 9, 'delta is value difference');

  // Battle structure
  const left = makeRandomPile('p1');
  const right = makeRandomPile('p2');
  const result = simulateBattle(left, right, selectFlipped);
  assert(result.flips.length === FLIP_COUNT, 'battle has FLIP_COUNT flips');
  assert(result.leftFlipped.length === FLIP_COUNT, 'left flipped count is FLIP_COUNT');
  assert(result.rightFlipped.length === FLIP_COUNT, 'right flipped count is FLIP_COUNT');
  assert(result.leftUnflipped.length === 5, 'left unflipped count is 5');
  assert(result.rightUnflipped.length === 5, 'right unflipped count is 5');
  assert(['left', 'right', 'tie'].indexOf(result.winner) !== -1, 'winner is left/right/tie');

  // Score consistency
  const computedLeft = result.flips.filter(f => f.winner === 'left').length;
  const computedRight = result.flips.filter(f => f.winner === 'right').length;
  assert(result.leftScore === computedLeft, 'leftScore matches flip count');
  assert(result.rightScore === computedRight, 'rightScore matches flip count');

  // Deterministic outcome: stacked deck
  const allTens = { cards: Array.from({length: 10}, () => makeCard(10)), ownerId: 'a' };
  const allOnes = { cards: Array.from({length: 10}, () => makeCard(1)), ownerId: 'b' };
  const blowout = simulateBattle(allTens, allOnes, selectFlipped);
  assert(blowout.winner === 'left', 'all-10s beats all-1s');
  assert(blowout.leftScore === FLIP_COUNT, 'all-10s sweeps every flip');

  // Engine is dependency-injected: simulateBattle requires selectionFn
  let threw = false;
  try { simulateBattle(left, right); } catch (e) { threw = true; }
  assert(threw, 'simulateBattle throws if selectionFn missing');
})();

// ------------------------------------------------------------------
// abilities.js
// ------------------------------------------------------------------

(function testAbilities() {
  // ABILITIES metadata
  assert(typeof ABILITIES.valor === 'object', 'ABILITIES has valor');
  assert(typeof ABILITIES.spite === 'object', 'ABILITIES has spite');
  assert(typeof ABILITIES.blaze === 'object', 'ABILITIES has blaze');
  assert(ABILITIES.valor.trigger === 'on_win', 'valor trigger is on_win');
  assert(ABILITIES.spite.trigger === 'on_loss', 'spite trigger is on_loss');
  assert(ABILITIES.blaze.trigger === 'on_reveal', 'blaze trigger is on_reveal');

  // onRevealBonus
  assert(onRevealBonus('blaze') === 2, 'blaze gives +2 on reveal');
  assert(onRevealBonus('valor') === 0, 'valor gives 0 on reveal');
  assert(onRevealBonus(undefined) === 0, 'no ability gives 0 on reveal');

  // postFlipDeltas
  const vWin = postFlipDeltas('left', 'valor', undefined);
  assert(vWin.leftDelta === 1, 'valor on win: left next +1');
  assert(vWin.rightDelta === 0, 'valor on win: right unaffected');

  const sLoss = postFlipDeltas('left', undefined, 'spite');
  assert(sLoss.leftDelta === -1, 'spite on loss (right card): left next -1');

  const sLossLeft = postFlipDeltas('right', 'spite', undefined);
  assert(sLossLeft.rightDelta === -1, 'spite on loss (left card): right next -1');

  assert(postFlipDeltas('tie', 'valor', 'spite').leftDelta === 0, 'no triggers on tie');
  assert(postFlipDeltas('tie', 'valor', 'spite').rightDelta === 0, 'no triggers on tie (right)');
})();

// ------------------------------------------------------------------
// ability integration in simulateBattle
// ------------------------------------------------------------------

(function testAbilityIntegration() {
  // Fixed selectionFn returns first 5 cards in order — deterministic battles.
  const fixedSelect = pile => pile.cards.slice(0, 5);

  // Valor: left card wins flip 0, next left card (flip 1) gets +1.
  // Setup: left[0]=10(valor) vs right[0]=1 → left wins → leftPending=+1
  //        left[1]=4 vs right[1]=4 → 4+1=5 vs 4 → left wins (would tie without valor)
  const valorLeft = [
    makeCard(10, { ability: 'valor' }),
    makeCard(4), makeCard(5), makeCard(5), makeCard(5)
  ];
  const valorRight = [
    makeCard(1),
    makeCard(4), makeCard(4), makeCard(4), makeCard(4)
  ];
  const vResult = simulateBattle(
    { cards: valorLeft, ownerId: 'l' },
    { cards: valorRight, ownerId: 'r' },
    fixedSelect
  );
  assert(vResult.flips[0].winner === 'left', 'valor flip 0: left wins');
  assert(vResult.flips[1].leftEffective === 5, 'valor: next card left effective = 4+1 = 5');
  assert(vResult.flips[1].winner === 'left', 'valor: next flip wins due to +1 bonus');

  // Spite: right card loses flip 0, left's next card (flip 1) gets -1.
  // Setup: left[0]=10 vs right[0]=1(spite) → left wins, spite triggers → leftPending=-1
  //        left[1]=4 vs right[1]=3 → 4-1=3 vs 3 → tie (would be left win without spite)
  const spiteLeft = [
    makeCard(10),
    makeCard(4), makeCard(5), makeCard(5), makeCard(5)
  ];
  const spiteRight = [
    makeCard(1, { ability: 'spite' }),
    makeCard(3), makeCard(3), makeCard(3), makeCard(3)
  ];
  const sResult = simulateBattle(
    { cards: spiteLeft, ownerId: 'l' },
    { cards: spiteRight, ownerId: 'r' },
    fixedSelect
  );
  assert(sResult.flips[0].winner === 'left', 'spite flip 0: left wins normally');
  assert(sResult.flips[1].leftEffective === 3, 'spite: left next effective = 4-1 = 3');
  assert(sResult.flips[1].winner === 'tie', 'spite: next flip is now a tie');

  // Blaze: left card with blaze gets +2 on reveal, flips at value+2.
  // Setup: left[0]=3(blaze) vs right[0]=4 → 3+2=5 vs 4 → left wins (would lose without blaze)
  const blazeLeft = [
    makeCard(3, { ability: 'blaze' }),
    makeCard(5), makeCard(5), makeCard(5), makeCard(5)
  ];
  const blazeRight = [
    makeCard(4),
    makeCard(4), makeCard(4), makeCard(4), makeCard(4)
  ];
  const bResult = simulateBattle(
    { cards: blazeLeft, ownerId: 'l' },
    { cards: blazeRight, ownerId: 'r' },
    fixedSelect
  );
  assert(bResult.flips[0].leftEffective === 5, 'blaze: effective = 3+2 = 5');
  assert(bResult.flips[0].winner === 'left', 'blaze: wins flip that would otherwise lose');

  // Effective values are recorded on every flip even with no abilities.
  const plain = simulateBattle(makeStarterPile('l'), makeStarterPile('r'), fixedSelect);
  assert(plain.flips.every(f => f.leftEffective === f.left.value), 'no ability: leftEffective equals raw value');
  assert(plain.flips.every(f => f.rightEffective === f.right.value), 'no ability: rightEffective equals raw value');
})();

// ------------------------------------------------------------------
// run.js
// ------------------------------------------------------------------

(function testRun() {
  const {
    makeRun, buyCard, sellCard, upgradeCard, canBuy, canSell, canUpgrade,
    applyBattleResult,
    STARTING_HP, STARTING_GOLD, CARD_COST, SELL_VALUE, SELL_MANA,
    MAX_PILE_SIZE, UPGRADE_COST, MANA_WIN, MANA_LOSS, MANA_TIE
  } = require('../src/engine/run.js');

  const run = makeRun();
  assert(run.round === 1, 'makeRun: round starts at 1');
  assert(run.playerHP === STARTING_HP, 'makeRun: playerHP is STARTING_HP');
  assert(run.aiHP === STARTING_HP, 'makeRun: aiHP is STARTING_HP');
  assert(run.gold === STARTING_GOLD, 'makeRun: gold is STARTING_GOLD');
  assert(run.mana === 0, 'makeRun: mana starts at 0');
  assert(run.phase === 'shop', 'makeRun: phase is shop');
  assert(run.playerPile.cards.length === 10, 'makeRun: player starts with 10 cards');

  // starter pile has MAX_PILE_SIZE cards — can't buy until we sell one
  assert(!canBuy(run), 'canBuy: false when pile is full (starter pile = MAX_PILE_SIZE)');

  // sell one to open a slot, then buy works
  const card = makeCard(7);
  const firstId = run.playerPile.cards[0].id;
  const runWithSlot = sellCard(run, firstId);
  assert(canBuy(runWithSlot), 'canBuy: true when gold >= CARD_COST and pile not full');
  const afterBuy = buyCard(runWithSlot, card);
  assert(afterBuy.gold === runWithSlot.gold - CARD_COST, 'buyCard: deducts CARD_COST');
  assert(afterBuy.playerPile.cards.length === runWithSlot.playerPile.cards.length + 1,
    'buyCard: adds card to pile');
  assert(afterBuy !== runWithSlot, 'buyCard: returns new state (immutable)');

  // can't buy if not enough gold
  const broke = Object.assign({}, runWithSlot, { gold: CARD_COST - 1 });
  assert(buyCard(broke, card) === broke, 'buyCard: no-op when insufficient gold');
  assert(!canBuy(broke), 'canBuy: false when insufficient gold');

  // can't buy when pile is full
  const fullPile = { cards: Array.from({ length: MAX_PILE_SIZE }, () => makeCard(1)), ownerId: 'p' };
  const fullRun = Object.assign({}, run, { playerPile: fullPile });
  assert(buyCard(fullRun, card) === fullRun, 'buyCard: no-op when pile is full');
  assert(!canBuy(fullRun), 'canBuy: false when pile is full');

  // canSell / sellCard
  const sellId = run.playerPile.cards[0].id;
  assert(canSell(run, sellId), 'canSell: true for a valid card id with >1 cards');
  const afterSell = sellCard(run, sellId);
  assert(afterSell.gold === STARTING_GOLD + SELL_VALUE, 'sellCard: adds SELL_VALUE to gold');
  assert(afterSell.mana === SELL_MANA, 'sellCard: refunds SELL_MANA mana');
  assert(afterSell.playerPile.cards.length === 9, 'sellCard: removes card from pile');

  // can't sell unknown card
  assert(sellCard(runWithSlot, 'nonexistent') === runWithSlot, 'sellCard: no-op for unknown card id');

  // can't sell last card
  const oneCard = { cards: [makeCard(5)], ownerId: 'p' };
  const singleRun = Object.assign({}, run, { playerPile: oneCard });
  const lastId = oneCard.cards[0].id;
  assert(sellCard(singleRun, lastId) === singleRun, 'sellCard: no-op when selling last card');
  assert(!canSell(singleRun, lastId), 'canSell: false when only one card left');

  // applyBattleResult — player wins
  const afterWin = applyBattleResult(run, { winner: 'player', margin: 2 });
  assert(afterWin.aiHP === STARTING_HP - 2, 'applyBattleResult: player win damages aiHP by margin');
  assert(afterWin.playerHP === STARTING_HP, 'applyBattleResult: player win leaves playerHP intact');
  assert(afterWin.round === 2, 'applyBattleResult: advances round');
  assert(afterWin.gold === STARTING_GOLD, 'applyBattleResult: refills gold');
  assert(afterWin.mana === MANA_WIN, 'applyBattleResult: player win earns MANA_WIN');
  assert(afterWin.phase === 'shop', 'applyBattleResult: phase back to shop when no one dies');

  // applyBattleResult — ai wins
  const afterLoss = applyBattleResult(run, { winner: 'ai', margin: 3 });
  assert(afterLoss.playerHP === STARTING_HP - 3, 'applyBattleResult: ai win damages playerHP');
  assert(afterLoss.aiHP === STARTING_HP, 'applyBattleResult: ai win leaves aiHP intact');
  assert(afterLoss.mana === MANA_LOSS, 'applyBattleResult: loss earns MANA_LOSS');

  // damage caps at 3
  const bigMargin = applyBattleResult(run, { winner: 'ai', margin: 10 });
  assert(bigMargin.playerHP === STARTING_HP - 3, 'applyBattleResult: damage capped at 3');

  // phase = 'over' when HP reaches 0
  const nearDead = Object.assign({}, run, { playerHP: 1 });
  const killed = applyBattleResult(nearDead, { winner: 'ai', margin: 3 });
  assert(killed.playerHP === 0, 'applyBattleResult: HP floored at 0');
  assert(killed.phase === 'over', 'applyBattleResult: phase is over when playerHP hits 0');

  // tie — no damage, earns MANA_TIE
  const afterTie = applyBattleResult(run, { winner: 'tie', margin: 0 });
  assert(afterTie.playerHP === STARTING_HP, 'applyBattleResult: tie does no damage to player');
  assert(afterTie.aiHP === STARTING_HP, 'applyBattleResult: tie does no damage to ai');
  assert(afterTie.mana === MANA_TIE, 'applyBattleResult: tie earns MANA_TIE');

  // upgradeCardValue (cards.js)
  const plain5 = makeCard(5);
  const up5 = upgradeCardValue(plain5);
  assert(up5.value === 6, 'upgradeCardValue: increments value by 1');
  assert(up5.id === plain5.id, 'upgradeCardValue: preserves card id');
  assert(up5 !== plain5, 'upgradeCardValue: returns new object');

  // upgradeCard (run.js)
  assert(!canUpgrade(run), 'canUpgrade: false when mana < UPGRADE_COST (run starts at 0)');
  const richRun = Object.assign({}, run, { mana: UPGRADE_COST + 2 });
  assert(canUpgrade(richRun), 'canUpgrade: true when mana >= UPGRADE_COST');
  const targetId = richRun.playerPile.cards[2].id;
  const targetVal = richRun.playerPile.cards[2].value;
  const afterUpgrade = upgradeCard(richRun, targetId);
  assert(afterUpgrade.mana === richRun.mana - UPGRADE_COST, 'upgradeCard: deducts UPGRADE_COST mana');
  const upgraded = afterUpgrade.playerPile.cards.find(c => c.id === targetId);
  assert(upgraded.value === targetVal + 1, 'upgradeCard: card value incremented by 1');
  assert(upgradeCard(run, targetId) === run, 'upgradeCard: no-op when mana < UPGRADE_COST');
  assert(upgradeCard(richRun, 'bad-id') === richRun, 'upgradeCard: no-op for unknown card id');
})();

// ------------------------------------------------------------------
// jokers.js
// ------------------------------------------------------------------

(function testJokers() {
  const {
    JOKERS, JOKER_POOL, JOKER_COST,
    applyJokerPreFlip, applyJokerTie,
    jokerManaBonusOnWin, jokerPileCap, jokerFlipCount, sniperAnchorId
  } = require('../src/engine/jokers.js');
  const { simulateBattle } = require('../src/engine/battle.js');
  const { makeRun, buyJoker, canBuyJoker, effectivePileCap } = require('../src/engine/run.js');

  assert(typeof JOKERS.tiebreaker === 'object', 'JOKERS has tiebreaker');
  assert(typeof JOKERS.sniper     === 'object', 'JOKERS has sniper');
  assert(typeof JOKERS.hoarder    === 'object', 'JOKERS has hoarder');
  assert(JOKER_POOL.length >= 6, 'JOKER_POOL has at least 6 Jokers');

  // Tiebreaker: tie → left win
  const tieFlip = { winner: 'tie', delta: 0 };
  assert(applyJokerTie('tiebreaker', tieFlip).winner === 'left', 'tiebreaker converts tie to left win');
  assert(applyJokerTie(null, tieFlip).winner === 'tie', 'no joker: tie stays tie');
  const winFlip = { winner: 'left', delta: 1 };
  assert(applyJokerTie('tiebreaker', winFlip).winner === 'left', 'tiebreaker does not affect non-tie');

  // Underdog: left card lower value → +2
  const lc = makeCard(3), rc = makeCard(7);
  const ud = applyJokerPreFlip('underdog', lc, rc, lc.value, rc.value, 0);
  assert(ud.leftEff === 5, 'underdog: low left card gets +2');
  const ud2 = applyJokerPreFlip('underdog', makeCard(8), makeCard(3), 8, 3, 0);
  assert(ud2.leftEff === 8, 'underdog: no bonus when left >= right');

  // Streak: streakCount added to leftEff
  const sk = applyJokerPreFlip('streak', makeCard(5), makeCard(5), 5, 5, 3);
  assert(sk.leftEff === 8, 'streak: +3 from streak count of 3');

  // Hoarder: pile cap = 12
  assert(jokerPileCap('hoarder') === 12, 'hoarder: pile cap 12');
  assert(jokerPileCap(null) === null, 'no joker: pile cap null');

  // Gambler: 4 flips
  assert(jokerFlipCount('gambler') === 4, 'gambler: flip count 4');
  assert(jokerFlipCount(null) === null, 'no joker: flip count null');

  // Gambler: mana bonus on win
  assert(jokerManaBonusOnWin('gambler') === 2, 'gambler: +2 mana on win');
  assert(jokerManaBonusOnWin(null) === 0, 'no joker: 0 mana bonus');

  // Sniper: anchor id = highest value card
  const sniperPile = { cards: [makeCard(3), makeCard(9), makeCard(5)], ownerId: 't' };
  const anchorId = sniperAnchorId(sniperPile);
  assert(anchorId === sniperPile.cards[1].id, 'sniper: anchors the highest card');

  // buyJoker / canBuyJoker
  const run = makeRun();
  assert(canBuyJoker(run, 'tiebreaker'), 'canBuyJoker: true when can afford and no joker');
  const afterJoker = buyJoker(run, 'tiebreaker');
  assert(afterJoker.joker === 'tiebreaker', 'buyJoker: sets joker id');
  assert(afterJoker.gold === run.gold - JOKER_COST, 'buyJoker: deducts JOKER_COST');
  assert(!canBuyJoker(afterJoker, 'sniper'), 'canBuyJoker: false when already have joker');
  const brokeRun = Object.assign({}, run, { gold: JOKER_COST - 1 });
  assert(!canBuyJoker(brokeRun, 'tiebreaker'), 'canBuyJoker: false when insufficient gold');

  // effectivePileCap: hoarder raises to 12
  const hoarderRun = buyJoker(run, 'hoarder');
  assert(effectivePileCap(hoarderRun) === 12, 'hoarder run: effectivePileCap is 12');
  assert(effectivePileCap(run) === 10, 'default run: effectivePileCap is 10');

  // Joker integration in simulateBattle — tiebreaker
  const fixAll5 = pile => pile.cards.slice(0, 5);
  const allFives = { cards: Array.from({length:5}, () => makeCard(5)), ownerId: 't' };
  const withJoker = simulateBattle(allFives, allFives, fixAll5, 'tiebreaker');
  assert(withJoker.flips.every(f => f.winner === 'left'), 'tiebreaker: all ties become left wins');
  assert(withJoker.winner === 'left', 'tiebreaker: left wins the battle (all ties resolved for left)');

  // Gambler: only 4 flips
  const pile5 = { cards: Array.from({length:5}, () => makeCard(5)), ownerId: 't' };
  const gamblerResult = simulateBattle(pile5, pile5, fixAll5, 'gambler');
  assert(gamblerResult.flips.length === 4, 'gambler: battle has 4 flips');
})();

// ------------------------------------------------------------------
// abilities.js (v0.6 additions)
// ------------------------------------------------------------------

(function testAbilitiesV6() {
  const { ABILITIES, onRevealBonus, postFlipGoldBonus } = require('../src/engine/abilities.js');

  assert(typeof ABILITIES.pierce   === 'object', 'ABILITIES has pierce');
  assert(typeof ABILITIES.echo     === 'object', 'ABILITIES has echo');
  assert(typeof ABILITIES.comeback === 'object', 'ABILITIES has comeback');
  assert(typeof ABILITIES.anchor   === 'object', 'ABILITIES has anchor');

  assert(ABILITIES.pierce.trigger   === 'on_tie',    'pierce trigger is on_tie');
  assert(ABILITIES.echo.trigger     === 'on_reveal', 'echo trigger is on_reveal');
  assert(ABILITIES.comeback.trigger === 'on_loss',   'comeback trigger is on_loss');
  assert(ABILITIES.anchor.trigger   === 'passive',   'anchor trigger is passive');

  assert(onRevealBonus('echo')  === 3, 'echo gives +3 on reveal');
  assert(onRevealBonus('blaze') === 2, 'blaze still gives +2 on reveal');

  // Comeback: player (left) lost by ≥3, gets +2 gold
  const cb1 = postFlipGoldBonus('right', 'comeback', undefined, 5);
  assert(cb1.leftGold  === 2, 'comeback: left earns 2 gold when losing by ≥3');
  assert(cb1.rightGold === 0, 'comeback: right earns nothing here');

  // Comeback: margin <3, no bonus
  const cb2 = postFlipGoldBonus('right', 'comeback', undefined, 2);
  assert(cb2.leftGold  === 0, 'comeback: no bonus when margin < 3');

  // Comeback on right side
  const cb3 = postFlipGoldBonus('left', undefined, 'comeback', 4);
  assert(cb3.rightGold === 2, 'comeback: right earns 2 gold when losing by ≥3');
})();

// ------------------------------------------------------------------
// battle.js — pierce and comeback integration
// ------------------------------------------------------------------

(function testBattleV6() {
  const { simulateBattle } = require('../src/engine/battle.js');
  const fix = pile => pile.cards.slice(0, 5);

  // Pierce: left card ties but has pierce → counts as left win
  const pierceLeft = [
    makeCard(5, { ability: 'pierce' }),
    makeCard(5), makeCard(5), makeCard(5), makeCard(5)
  ];
  const pierceRight = [
    makeCard(5),
    makeCard(5), makeCard(5), makeCard(5), makeCard(5)
  ];
  const pResult = simulateBattle({ cards: pierceLeft, ownerId: 'l' }, { cards: pierceRight, ownerId: 'r' }, fix);
  assert(pResult.flips[0].winner === 'left', 'pierce: tied flip counted as left win');

  // Without pierce, tie stays tie
  const noAbility = { cards: Array.from({length:5}, () => makeCard(5)), ownerId: 'x' };
  const tResult   = simulateBattle(noAbility, noAbility, fix);
  assert(tResult.flips[0].winner === 'tie', 'no pierce: equal values stay tied');

  // Comeback: player (left) loses by margin ≥3, earns leftGoldBonus
  const comebackLeft  = [makeCard(1, { ability: 'comeback' }), makeCard(5), makeCard(5), makeCard(5), makeCard(5)];
  const comebackRight = [makeCard(8),                          makeCard(1), makeCard(1), makeCard(1), makeCard(1)];
  const cResult = simulateBattle(
    { cards: comebackLeft,  ownerId: 'l' },
    { cards: comebackRight, ownerId: 'r' },
    fix
  );
  assert(cResult.flips[0].winner === 'right', 'comeback: left lost flip 0');
  assert(cResult.flips[0].delta >= 3, 'comeback: margin ≥ 3');
  assert(cResult.leftGoldBonus === 2, 'comeback: leftGoldBonus is 2 after one qualifying loss');

  // Echo: +3 on reveal (similar to blaze test)
  const echoLeft  = [makeCard(3, { ability: 'echo' }), makeCard(5), makeCard(5), makeCard(5), makeCard(5)];
  const echoRight = [makeCard(5),                      makeCard(5), makeCard(5), makeCard(5), makeCard(5)];
  const eResult   = simulateBattle({ cards: echoLeft, ownerId: 'l' }, { cards: echoRight, ownerId: 'r' }, fix);
  assert(eResult.flips[0].leftEffective === 6, 'echo: effective = 3+3 = 6');
  assert(eResult.flips[0].winner === 'left', 'echo: 3+3=6 beats 5');
})();

// ------------------------------------------------------------------
// selection.js — anchor always flips
// ------------------------------------------------------------------

(function testSelectionAnchor() {
  const { selectFlipped, flipProbabilities, FLIP_COUNT } = require('../src/engine/selection.js');

  // Anchor card must always appear in selected 5
  const anchorCard = makeCard(1, { ability: 'anchor' });
  const pile = {
    cards: [anchorCard].concat(Array.from({length:9}, () => makeCard(5))),
    ownerId: 't'
  };
  let anchorAlwaysShows = true;
  for (let i = 0; i < 50; i++) {
    const flipped = selectFlipped(pile);
    if (!flipped.find(c => c.id === anchorCard.id)) { anchorAlwaysShows = false; break; }
  }
  assert(anchorAlwaysShows, 'anchor card always appears in flipped 5');

  // Anchor shows 100% in flipProbabilities
  const probs = flipProbabilities(pile);
  assert(probs[0] === 100, 'anchor card shows 100% flip probability');

  // Multiple anchors all flip (up to FLIP_COUNT)
  const twoAnchorPile = {
    cards: [
      makeCard(1, { ability: 'anchor' }),
      makeCard(2, { ability: 'anchor' }),
    ].concat(Array.from({length:8}, () => makeCard(5))),
    ownerId: 't'
  };
  const flipped2 = selectFlipped(twoAnchorPile);
  assert(flipped2.length === FLIP_COUNT, 'anchor: still flips FLIP_COUNT cards total');
  const anchorIds = new Set(twoAnchorPile.cards.slice(0,2).map(c => c.id));
  assert(flipped2.filter(c => anchorIds.has(c.id)).length === 2, 'both anchor cards always flip');
})();

// ------------------------------------------------------------------
// shop.js

(function testShop() {
  const { generateShop, SHOP_SIZE, REROLL_COST, SHOP_ABILITY_POOL, shopMaxValue } = require('../src/engine/shop.js');

  assert(REROLL_COST === 1, 'REROLL_COST is 1');
  assert(SHOP_SIZE === 4, 'SHOP_SIZE is 4');

  // Tier curve
  assert(shopMaxValue(1) === 3,  'tier: round 1 max value 3');
  assert(shopMaxValue(2) === 3,  'tier: round 2 max value 3');
  assert(shopMaxValue(3) === 5,  'tier: round 3 max value 5');
  assert(shopMaxValue(4) === 5,  'tier: round 4 max value 5');
  assert(shopMaxValue(5) === 7,  'tier: round 5 max value 7');
  assert(shopMaxValue(7) === 9,  'tier: round 7 max value 9');
  assert(shopMaxValue(9) === 10, 'tier: round 9 max value 10');
  assert(shopMaxValue(99) === 10,'tier: round 99 max value 10');

  // Round-1 shop: all values ≤ 3
  const earlyShop = generateShop(1);
  assert(earlyShop.cards.length === SHOP_SIZE, 'generateShop(1) returns SHOP_SIZE cards');
  assert(earlyShop.cards.every(c => c.value >= 1 && c.value <= 3), 'generateShop(1) values capped at 3');

  // Round-9 shop: values can reach 10
  // Run enough times to confirm max value > 3 (probability of all ≤3 in 200 rounds is astronomically low)
  let seenHigh = false;
  for (let t = 0; t < 200; t++) {
    const s = generateShop(9);
    if (s.cards.some(c => c.value > 3)) { seenHigh = true; break; }
  }
  assert(seenHigh, 'generateShop(9) eventually produces cards with value > 3');

  const shop = generateShop(1);

  // deterministic rng — card 0 uses 3 calls (r, ability-pick, value); others use 2 (r, value)
  // card 0: r=0.10 → ability; pick=0.50 → SHOP_ABILITY_POOL[1]='spite'; value=0.30 → 4
  // card 1: r=0.25 → weight+50; value=0.70 → 8
  // card 2: r=0.40 → weight-50; value=0.50 → 6
  // card 3: r=0.60 → neutral;   value=0.10 → 2
  let callCount = 0;
  const seqRng = () => {
    const vals = [0.10, 0.50, 0.30, 0.25, 0.70, 0.40, 0.50, 0.60, 0.10];
    return vals[callCount++] !== undefined ? vals[callCount - 1] : 0.5;
  };
  const ds = generateShop(seqRng);
  assert(ds.cards.length === SHOP_SIZE, 'deterministic shop has SHOP_SIZE cards');
  assert(SHOP_ABILITY_POOL.indexOf(ds.cards[0].ability) !== -1,
    'shop ability is from SHOP_ABILITY_POOL when generated');
  assert(ds.cards[1].weight === 50, 'deterministic: card 1 has weight 50');
  assert(ds.cards[2].weight === -50, 'deterministic: card 2 has weight -50');
  assert(ds.cards[3].weight === 0 && !ds.cards[3].ability, 'deterministic: card 3 is neutral');
})();

// ------------------------------------------------------------------
// Report
// ------------------------------------------------------------------

console.log('');
console.log('Pileup engine tests');
console.log('-------------------');
console.log('Passed: ' + passed);
console.log('Failed: ' + failed);
if (failed > 0) {
  console.log('');
  console.log('Failures:');
  failures.forEach(f => console.log('  - ' + f));
  process.exit(1);
}
