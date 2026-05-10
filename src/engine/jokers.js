/**
 * Pileup engine — Joker definitions and resolution.
 *
 * Jokers are global run-modifiers that warp battle rules for the whole run.
 * Each run the player may hold 1 Joker (slot expands in later versions).
 * A Joker changes HOW battles work, not just how much damage a card does.
 *
 * Joker effects plug into the battle pipeline as pre/post hooks:
 *   applyJokerPreFlip(joker, leftCard, rightCard, leftEff, rightEff)
 *     → { leftEff, rightEff }    (modify effective values before comparison)
 *
 *   applyJokerPostFlip(joker, flip, leftScore, rightScore)
 *     → { scoreDelta }           (add to winner's score)
 *
 *   applyJokerBattleStart(joker, leftFlipped, rightFlipped)
 *     → { leftFlipped, rightFlipped }  (modify the selected 5 before any flip)
 *
 * All functions are pure. No DOM, no side effects.
 */

var JOKER_COST = 6;  // gold cost to buy a Joker

var JOKERS = {
  tiebreaker: {
    id: 'tiebreaker', name: 'Tiebreaker',
    description: 'Ties count as wins for you.',
    cost: JOKER_COST
  },
  underdog: {
    id: 'underdog', name: 'Underdog',
    description: 'When your card has lower value: it gains +2.',
    cost: JOKER_COST
  },
  streak: {
    id: 'streak', name: 'Streak',
    description: 'Each consecutive flip you win adds +1 to the next.',
    cost: JOKER_COST
  },
  sniper: {
    id: 'sniper', name: 'Sniper',
    description: 'Your highest card is always among the 5 that flip.',
    cost: JOKER_COST
  },
  doubler: {
    id: 'doubler', name: 'Doubler',
    description: 'If both flipped cards have the same value: +1 to yours.',
    cost: JOKER_COST
  },
  gambler: {
    id: 'gambler', name: 'Gambler',
    description: 'You flip only 4 cards, but winning earns +2 mana.',
    cost: JOKER_COST
  },
  pyromancer: {
    id: 'pyromancer', name: 'Pyromancer',
    description: 'All your 1s get +3 on reveal.',
    cost: JOKER_COST
  },
  hoarder: {
    id: 'hoarder', name: 'Hoarder',
    description: 'Pile cap raised to 12.',
    cost: JOKER_COST
  }
};

var JOKER_POOL = Object.keys(JOKERS);

/**
 * Apply a Joker's pre-flip effect: modify effective values before comparison.
 * Returns { leftEff, rightEff }.
 */
function applyJokerPreFlip(jokerId, leftCard, rightCard, leftEff, rightEff, streakCount) {
  if (!jokerId) return { leftEff: leftEff, rightEff: rightEff };

  if (jokerId === 'underdog') {
    // Left card (player) is lower → gets +2
    if (leftCard.value < rightCard.value) leftEff += 2;
  }
  if (jokerId === 'streak') {
    // streakCount = consecutive wins before this flip
    leftEff += (streakCount || 0);
  }
  if (jokerId === 'doubler') {
    // Both cards same raw value → player's effective gets +1
    if (leftCard.value === rightCard.value) leftEff += 1;
  }
  if (jokerId === 'pyromancer') {
    // Player's 1s get +3 on reveal (on top of their own abilities)
    if (leftCard.value === 1) leftEff += 3;
  }
  return { leftEff: leftEff, rightEff: rightEff };
}

/**
 * Apply a Joker's post-flip tie-override.
 * Returns the (potentially modified) flip result { winner, delta }.
 * Called after resolveFlip and pierce checks.
 */
function applyJokerTie(jokerId, flip) {
  if (!jokerId || flip.winner !== 'tie') return flip;
  if (jokerId === 'tiebreaker') {
    return { winner: 'left', delta: 0, jokerNote: 'tiebreaker' };
  }
  return flip;
}

/**
 * Returns the Joker's mana bonus per battle win (stacks on top of normal mana).
 */
function jokerManaBonusOnWin(jokerId) {
  if (jokerId === 'gambler') return 2;
  return 0;
}

/**
 * Returns the pile cap override for the active Joker (or null if unchanged).
 */
function jokerPileCap(jokerId) {
  if (jokerId === 'hoarder') return 12;
  return null;
}

/**
 * Returns the flip count override for the active Joker (or null if unchanged).
 */
function jokerFlipCount(jokerId) {
  if (jokerId === 'gambler') return 4;
  return null;
}

/**
 * For Sniper: return the id of the card that should be guaranteed to flip.
 * Returns the id of the highest-value card in the pile (first if ties).
 */
function sniperAnchorId(pile) {
  var best = pile.cards.reduce(function(a, b) { return b.value > a.value ? b : a; }, pile.cards[0]);
  return best ? best.id : null;
}

if (typeof module !== 'undefined' && module.exports) {
  module.exports = {
    JOKERS, JOKER_POOL, JOKER_COST,
    applyJokerPreFlip, applyJokerTie,
    jokerManaBonusOnWin, jokerPileCap, jokerFlipCount, sniperAnchorId
  };
}
if (typeof window !== 'undefined') {
  window.PileupJokers = {
    JOKERS, JOKER_POOL, JOKER_COST,
    applyJokerPreFlip, applyJokerTie,
    jokerManaBonusOnWin, jokerPileCap, jokerFlipCount, sniperAnchorId
  };
}
