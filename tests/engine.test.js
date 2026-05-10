/**
 * Pileup engine tests.
 *
 * Plain-Node tests, no framework. Run with:  node tests/engine.test.js
 *
 * Add tests as engine grows. These document expected behavior and
 * guard against regressions when refactoring.
 */

const { makeCard, makeRandomPile, makeStarterPile } = require('../src/engine/cards.js');
const {
  FLIP_COUNT, BASE_WEIGHT, MIN_WEIGHT,
  effectiveWeight, weightedSample, shuffle,
  selectFlipped, flipProbabilities
} = require('../src/engine/selection.js');
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
