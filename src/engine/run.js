/**
 * Pileup engine — run state.
 *
 * A "run" is one full single-player game: shop → battle → shop → battle…
 * until one side reaches 0 HP.
 *
 * All functions return new state (immutable pattern) — no in-place mutation.
 */

var STARTING_HP   = 25;
var STARTING_GOLD = 10;
var CARD_COST     = 3;
var SELL_VALUE    = 1;
var MAX_PILE_SIZE = 10;

var _cardsRun = null;
function getCardsRun() {
  if (_cardsRun) return _cardsRun;
  _cardsRun = (typeof module !== 'undefined' && module.exports)
    ? require('./cards.js') : window.PileupCards;
  return _cardsRun;
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
 * Remove a card from the player's pile by ID, refunding SELL_VALUE gold.
 * Cannot sell the last card in the pile.
 */
function sellCard(run, cardId) {
  var remaining = run.playerPile.cards.filter(function(c) { return c.id !== cardId; });
  if (remaining.length === run.playerPile.cards.length) return run; // card not found
  if (remaining.length === 0) return run;                            // can't sell last card
  return Object.assign({}, run, {
    gold: run.gold + SELL_VALUE,
    playerPile: { cards: remaining, ownerId: run.playerPile.ownerId }
  });
}

function canBuy(run)         { return run.gold >= CARD_COST && run.playerPile.cards.length < MAX_PILE_SIZE; }
function canSell(run, cardId){ return run.playerPile.cards.length > 1 && run.playerPile.cards.some(function(c){ return c.id === cardId; }); }

/**
 * Apply the result of a battle to the run.
 * battleResult: { winner: 'player'|'ai'|'tie', margin: number }
 * Damage is capped at 3 HP per loss (design doc: "1–3 HP").
 * Advances the round and refills gold. Sets phase to 'over' if HP reaches 0.
 */
function applyBattleResult(run, battleResult) {
  var damage     = Math.min(3, battleResult.margin);
  var newPlayerHP = run.playerHP;
  var newAiHP     = run.aiHP;
  if (battleResult.winner === 'ai')     newPlayerHP = Math.max(0, run.playerHP - damage);
  if (battleResult.winner === 'player') newAiHP     = Math.max(0, run.aiHP - damage);
  var phase = (newPlayerHP <= 0 || newAiHP <= 0) ? 'over' : 'shop';
  return Object.assign({}, run, {
    round:     run.round + 1,
    gold:      STARTING_GOLD,
    playerHP:  newPlayerHP,
    aiHP:      newAiHP,
    phase:     phase
  });
}

if (typeof module !== 'undefined' && module.exports) {
  module.exports = {
    STARTING_HP, STARTING_GOLD, CARD_COST, SELL_VALUE, MAX_PILE_SIZE,
    makeRun, buyCard, sellCard, canBuy, canSell, applyBattleResult
  };
}
if (typeof window !== 'undefined') {
  window.PileupRun = {
    STARTING_HP, STARTING_GOLD, CARD_COST, SELL_VALUE, MAX_PILE_SIZE,
    makeRun, buyCard, sellCard, canBuy, canSell, applyBattleResult
  };
}
