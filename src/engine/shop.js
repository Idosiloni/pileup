/**
 * Pileup engine — shop generation.
 *
 * Generates a set of cards available to buy each round.
 * Card variety mirrors makeRandomPile: some weighted, some with abilities.
 */

var SHOP_SIZE    = 4;
var REROLL_COST  = 1;
var SHOP_ABILITY_POOL = ['valor', 'spite', 'blaze'];

var _cardsShop = null;
function getCardsShop() {
  if (_cardsShop) return _cardsShop;
  _cardsShop = (typeof module !== 'undefined' && module.exports)
    ? require('./cards.js') : window.PileupCards;
  return _cardsShop;
}

/**
 * Generate a new shop — SHOP_SIZE cards ready to buy.
 * rng is injectable for deterministic tests.
 */
function generateShop(rng) {
  rng = rng || Math.random;
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
    var value = Math.floor(rng() * 10) + 1;
    cards.push(makeCard(value, { weight: weight || 0, ability: ability }));
  }
  return { cards: cards };
}

if (typeof module !== 'undefined' && module.exports) {
  module.exports = { SHOP_SIZE, REROLL_COST, SHOP_ABILITY_POOL, generateShop };
}
if (typeof window !== 'undefined') {
  window.PileupShop = { SHOP_SIZE, REROLL_COST, SHOP_ABILITY_POOL, generateShop };
}
