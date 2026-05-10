/**
 * Pileup engine — public API.
 *
 * Pulls the pure-logic modules together for the renderer to consume.
 * Both Node (tests) and browser (renderer) load through this file.
 */

if (typeof module !== 'undefined' && module.exports) {
  const cards     = require('./cards.js');
  const selection = require('./selection.js');
  const abilities = require('./abilities.js');
  const jokers    = require('./jokers.js');
  const battle    = require('./battle.js');
  const run       = require('./run.js');
  const shop      = require('./shop.js');
  module.exports = Object.assign({}, cards, selection, abilities, jokers, battle, run, shop);
}
