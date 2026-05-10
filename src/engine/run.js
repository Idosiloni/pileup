/**
 * Pileup engine — run state.
 *
 * A "run" is one full single-player game: shop → battle → shop → battle…
 * until one side reaches 0 HP.
 *
 * All functions return new state (immutable pattern) — no in-place mutation.
 *
 * Two currencies:
 *   Gold  — refills to STARTING_GOLD each turn. Use-it-or-lose-it.
 *   Mana  — accumulates across the run. Earned from battles, spent on upgrades.
 */

var STARTING_HP    = 25;
var STARTING_GOLD  = 10;
var CARD_COST      = 3;
var SELL_VALUE     = 1;
var SELL_MANA      = 1;   // mana refund when selling a card
var MAX_PILE_SIZE  = 10;
var UPGRADE_COST   = 3;   // mana cost to +1 a card's value
var MANA_WIN       = 2;   // mana earned for winning a battle
var MANA_LOSS      = 1;   // mana earned for losing a battle
var MANA_TIE       = 1;   // mana earned for a tied battle

var _cardsRun = null;
function getCardsRun() {
  if (_cardsRun) return _cardsRun;
  _cardsRun = (typeof module !== 'undefined' && module.exports)
    ? require('./cards.js') : window.PileupCards;
  return _cardsRun;
}

var _jokersRun = null;
function getJokersRun() {
  if (_jokersRun) return _jokersRun;
  _jokersRun = (typeof module !== 'undefined' && module.exports)
    ? require('./jokers.js') : window.PileupJokers;
  return _jokersRun;
}

/**
 * Create the initial run state. Player starts with the canonical starter pile.
 */
function makeRun() {
  return {
    round:      1,
    playerHP:   STARTING_HP,
    aiHP:       STARTING_HP,
    gold:       STARTING_GOLD,
    mana:       0,
    joker:      null,   // active Joker id, or null
    playerPile: getCardsRun().makeStarterPile('player'),
    phase:      'shop'
  };
}

/**
 * Add a card to the player's pile. Returns unchanged run if pile is full or
 * player cannot afford the card.
 */
function buyCard(run, card) {
  if (run.gold < CARD_COST) return run;
  if (run.playerPile.cards.length >= MAX_PILE_SIZE) return run;
  return Object.assign({}, run, {
    gold: run.gold - CARD_COST,
    playerPile: {
      cards:   run.playerPile.cards.concat([card]),
      ownerId: run.playerPile.ownerId
    }
  });
}

/**
 * Remove a card from the player's pile by ID.
 * Refunds SELL_VALUE gold + SELL_MANA mana. Cannot sell the last card.
 */
function sellCard(run, cardId) {
  var remaining = run.playerPile.cards.filter(function(c) { return c.id !== cardId; });
  if (remaining.length === run.playerPile.cards.length) return run;
  if (remaining.length === 0) return run;
  return Object.assign({}, run, {
    gold: run.gold + SELL_VALUE,
    mana: run.mana + SELL_MANA,
    playerPile: { cards: remaining, ownerId: run.playerPile.ownerId }
  });
}

/**
 * Permanently upgrade a card's value by 1, costing UPGRADE_COST mana.
 * Returns unchanged run if card not found or insufficient mana.
 */
function upgradeCard(run, cardId) {
  if (run.mana < UPGRADE_COST) return run;
  var found = false;
  var newCards = run.playerPile.cards.map(function(c) {
    if (c.id === cardId) { found = true; return getCardsRun().upgradeCardValue(c); }
    return c;
  });
  if (!found) return run;
  return Object.assign({}, run, {
    mana: run.mana - UPGRADE_COST,
    playerPile: { cards: newCards, ownerId: run.playerPile.ownerId }
  });
}

function effectivePileCap(run) {
  var jokerCap = getJokersRun().jokerPileCap(run.joker);
  return jokerCap !== null ? jokerCap : MAX_PILE_SIZE;
}

function canBuy(run)            { return run.gold >= CARD_COST && run.playerPile.cards.length < effectivePileCap(run); }
function canSell(run, cardId)   { return run.playerPile.cards.length > 1 && run.playerPile.cards.some(function(c){ return c.id === cardId; }); }
function canUpgrade(run)        { return run.mana >= UPGRADE_COST; }

/**
 * Buy a Joker. Player may hold only 1 Joker at a time.
 * Returns unchanged run if can't afford or already has a Joker.
 */
function buyJoker(run, jokerId) {
  var jk = getJokersRun();
  if (!jk.JOKERS[jokerId]) return run;
  var cost = jk.JOKERS[jokerId].cost;
  if (run.gold < cost) return run;
  return Object.assign({}, run, { gold: run.gold - cost, joker: jokerId });
}

function canBuyJoker(run, jokerId) {
  var jk = getJokersRun();
  if (!jk.JOKERS[jokerId]) return false;
  return run.gold >= jk.JOKERS[jokerId].cost && run.joker === null;
}

/**
 * Apply the result of a battle to the run.
 * battleResult: { winner: 'player'|'ai'|'tie', margin: number, goldBonus?: number }
 * goldBonus — extra gold from card abilities (e.g. Comeback) earned by the player this battle.
 * Damage is capped at 3 HP. Winner earns MANA_WIN, loser MANA_LOSS.
 * Advances round, refills gold. Phase → 'over' if HP hits 0.
 */
function applyBattleResult(run, battleResult) {
  var damage     = Math.min(3, battleResult.margin);
  var newPlayerHP = run.playerHP;
  var newAiHP     = run.aiHP;
  if (battleResult.winner === 'ai')     newPlayerHP = Math.max(0, run.playerHP - damage);
  if (battleResult.winner === 'player') newAiHP     = Math.max(0, run.aiHP - damage);
  var phase = (newPlayerHP <= 0 || newAiHP <= 0) ? 'over' : 'shop';

  var manaEarned = (battleResult.winner === 'player' ? MANA_WIN
                  : battleResult.winner === 'ai'    ? MANA_LOSS
                  : MANA_TIE) + (battleResult.jokerManaBonus || 0);

  return Object.assign({}, run, {
    round:    run.round + 1,
    gold:     STARTING_GOLD + (battleResult.goldBonus || 0),
    mana:     run.mana + manaEarned,
    playerHP: newPlayerHP,
    aiHP:     newAiHP,
    phase:    phase
  });
}

if (typeof module !== 'undefined' && module.exports) {
  module.exports = {
    STARTING_HP, STARTING_GOLD, CARD_COST, SELL_VALUE, SELL_MANA,
    MAX_PILE_SIZE, UPGRADE_COST, MANA_WIN, MANA_LOSS, MANA_TIE,
    makeRun, buyCard, sellCard, upgradeCard, buyJoker,
    canBuy, canSell, canUpgrade, canBuyJoker, effectivePileCap,
    applyBattleResult
  };
}
if (typeof window !== 'undefined') {
  window.PileupRun = {
    STARTING_HP, STARTING_GOLD, CARD_COST, SELL_VALUE, SELL_MANA,
    MAX_PILE_SIZE, UPGRADE_COST, MANA_WIN, MANA_LOSS, MANA_TIE,
    makeRun, buyCard, sellCard, upgradeCard, buyJoker,
    canBuy, canSell, canUpgrade, canBuyJoker, effectivePileCap,
    applyBattleResult
  };
}
