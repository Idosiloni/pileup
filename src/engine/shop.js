/**
 * Pileup engine — shop generation.
 *
 * Generates a set of cards available to buy each round.
 * Card values are gated by the shop tier (round number) per the design doc:
 *
 *   Rounds 1-2  → max value 3
 *   Rounds 3-4  → max value 5
 *   Rounds 5-6  → max value 7
 *   Rounds 7-8  → max value 9
 *   Round  9+   → max value 10
 */

var SHOP_SIZE    = 4;
var REROLL_COST  = 1;
var SHOP_ABILITY_POOL = ['valor', 'spite', 'blaze', 'pierce', 'echo', 'comeback', 'anchor'];

var SHOP_TIERS = [
  { upToRound: 2, maxValue: 3 },
  { upToRound: 4, maxValue: 5 },
  { upToRound: 6, maxValue: 7 },
  { upToRound: 8, maxValue: 9 },
  { upToRound: Infinity, maxValue: 10 }
];

function shopMaxValue(round) {
  for (var i = 0; i < SHOP_TIERS.length; i++) {
    if (round <= SHOP_TIERS[i].upToRound) return SHOP_TIERS[i].maxValue;
  }
  return 10;
}

var _cardsShop = null;
function getCardsShop() {
  if (_cardsShop) return _cardsShop;
  _cardsShop = (typeof module !== 'undefined' && module.exports)
    ? require('./cards.js') : window.PileupCards;
  return _cardsShop;
}

/**
 * Generate a new shop — SHOP_SIZE cards ready to buy.
 * @param {number} [round=1]  Current round (controls card value ceiling).
 * @param {function} [rng]    Injectable RNG for deterministic tests.
 */
function generateShop(round, rng) {
  if (typeof round === 'function') { rng = round; round = 1; } // back-compat: generateShop(rng)
  round = round || 1;
  rng   = rng   || Math.random;
  var maxVal  = shopMaxValue(round);
  var makeCard = getCardsShop().makeCard;
  var cards = [];
  for (var i = 0; i < SHOP_SIZE; i++) {
    var r = rng();
    var ability = undefined, weight;
    if (r < 0.20) {
      ability = SHOP_ABILITY_POOL[Math.floor(rng() * SHOP_ABILITY_POOL.length)];
      weight  = 0;
    } else if (r < 0.35) {
      weight = 50;
    } else if (r < 0.50) {
      weight = -50;
    } else {
      weight = 0;
    }
    var value = Math.floor(rng() * maxVal) + 1;
    cards.push(makeCard(value, { weight: weight || 0, ability: ability }));
  }
  return { cards: cards };
}

if (typeof module !== 'undefined' && module.exports) {
  module.exports = { SHOP_SIZE, REROLL_COST, SHOP_ABILITY_POOL, SHOP_TIERS, shopMaxValue, generateShop };
}
if (typeof window !== 'undefined') {
  window.PileupShop = { SHOP_SIZE, REROLL_COST, SHOP_ABILITY_POOL, SHOP_TIERS, shopMaxValue, generateShop };
}
