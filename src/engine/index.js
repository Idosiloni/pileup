/**
 * Pileup engine — public API.
 *
 * Pulls the pure-logic modules together for the renderer to consume.
 * Both Node (tests) and browser (renderer) load through this file.
 */

if (typeof module !== 'undefined' && module.exports) {
  // Node / tests
  const cards = require('./cards.js');
  const selection = require('./selection.js');
  const abilities = require('./abilities.js');
  const battle = require('./battle.js');
  module.exports = Object.assign({}, cards, selection, abilities, battle);
}
