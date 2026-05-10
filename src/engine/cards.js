/**
 * Pileup engine — pure logic for piles and cards.
 *
 * Zero DOM, zero rendering. Every function is a pure data transformation.
 * This file ports cleanly to Godot/GDScript, Unity/C#, or any backend.
 *
 * Type definitions (JSDoc — no TypeScript dependency yet):
 *
 * @typedef {Object} Card
 * @property {number} value         - Card value 1-10
 * @property {number} weight        - Flip probability weight modifier (0 = neutral, +20 = 20% more likely, -50 = 50% less likely)
 * @property {string} [ability]     - Ability identifier (future use)
 * @property {string} [position]    - 'first' | 'last' | undefined (positional traits)
 * @property {string} id            - Unique id for tracking across shuffles
 *
 * @typedef {Object} Pile
 * @property {Card[]} cards         - Array of 10 cards (or fewer if pile is thinned)
 * @property {string} ownerId       - Player identifier
 */

let _cardIdCounter = 0;
function nextCardId() {
  _cardIdCounter += 1;
  return 'c' + _cardIdCounter;
}

/**
 * Create a card with optional overrides.
 */
function makeCard(value, opts) {
  opts = opts || {};
  return {
    id: nextCardId(),
    value: value,
    weight: opts.weight || 0,
    ability: opts.ability,
    position: opts.position
  };
}

/**
 * Generate a random pile of 10 cards with values 1-10.
 * Used for prototyping and AI opponents.
 */
var ABILITY_POOL = ['valor', 'spite', 'blaze'];

function makeRandomPile(ownerId) {
  const cards = [];
  for (let i = 0; i < 10; i++) {
    const r = Math.random();
    let ability, weight;
    if (r < 0.20) {
      ability = ABILITY_POOL[Math.floor(Math.random() * ABILITY_POOL.length)];
      weight = 0;
    } else if (r < 0.35) {
      ability = undefined;
      weight = 50;
    } else if (r < 0.50) {
      ability = undefined;
      weight = -50;
    } else {
      ability = undefined;
      weight = 0;
    }
    cards.push(makeCard(Math.floor(Math.random() * 10) + 1, { weight, ability }));
  }
  return { cards: cards, ownerId: ownerId || 'anon' };
}

/**
 * Generate the canonical starter pile that every player begins with.
 * Currently: values 1-10, no abilities, no weights.
 * This is a design TBD — see GAME_DESIGN.md Section 13.
 */
function makeStarterPile(ownerId) {
  const cards = [];
  for (let v = 1; v <= 10; v++) {
    cards.push(makeCard(v));
  }
  return { cards: cards, ownerId: ownerId || 'anon' };
}

if (typeof module !== 'undefined' && module.exports) {
  module.exports = { makeCard, makeRandomPile, makeStarterPile };
}
if (typeof window !== 'undefined') {
  window.PileupCards = { makeCard, makeRandomPile, makeStarterPile };
}
