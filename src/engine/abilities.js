/**
 * Pileup engine — card ability definitions and resolution helpers.
 *
 * Trigger types:
 *   on_reveal  — card gets a value bonus when it flips (before comparison)
 *   on_win     — card's win buffs your next card's effective value
 *   on_loss    — card's loss debuffs the opponent's next card
 *   on_tie     — card converts a tie into a win
 *   passive    — always-active effect (handled by other engine layers)
 *   comeback   — On Loss by margin ≥ 3: +2 gold next shop
 *
 * All functions are pure data transformations. No DOM, no side effects.
 */

const ABILITIES = {
  valor: {
    id: 'valor', label: 'Valor',
    description: 'On Win: next +1',
    trigger: 'on_win'
  },
  spite: {
    id: 'spite', label: 'Spite',
    description: 'On Loss: foe next −1',
    trigger: 'on_loss'
  },
  blaze: {
    id: 'blaze', label: 'Blaze',
    description: 'On Reveal: +2',
    trigger: 'on_reveal'
  },
  pierce: {
    id: 'pierce', label: 'Pierce',
    description: 'On Tie: count as win',
    trigger: 'on_tie'
  },
  echo: {
    id: 'echo', label: 'Echo',
    description: 'On Reveal: +3',
    trigger: 'on_reveal'
  },
  comeback: {
    id: 'comeback', label: 'Comeback',
    description: 'On Loss by 3+: +2g next shop',
    trigger: 'on_loss'
  },
  anchor: {
    id: 'anchor', label: 'Anchor',
    description: 'Passive: always flips',
    trigger: 'passive'
  }
};

/**
 * Returns the bonus to add to a card's effective value when it flips (On Reveal).
 */
function onRevealBonus(abilityId) {
  if (abilityId === 'blaze') return 2;
  if (abilityId === 'echo')  return 3;
  return 0;
}

/**
 * Returns pending value deltas to carry into the NEXT flip after this one resolves.
 * leftDelta  — added to left's next card effective value
 * rightDelta — added to right's next card effective value
 */
function postFlipDeltas(winner, leftAbility, rightAbility) {
  var ld = 0, rd = 0;
  if (winner === 'left') {
    if (leftAbility  === 'valor') ld += 1;
    if (rightAbility === 'spite') ld -= 1;
  } else if (winner === 'right') {
    if (rightAbility === 'valor') rd += 1;
    if (leftAbility  === 'spite') rd -= 1;
  }
  return { leftDelta: ld, rightDelta: rd };
}

/**
 * Returns the gold bonus the PLAYER earns from a single flip (for comeback).
 * Called after the flip is resolved (including pierce adjustments).
 * leftGold: gold the player (left side) earns from this flip.
 */
function postFlipGoldBonus(winner, leftAbility, rightAbility, margin) {
  var leftGold = 0, rightGold = 0;
  if (winner === 'right' && leftAbility === 'comeback' && margin >= 3) {
    leftGold += 2;
  }
  if (winner === 'left' && rightAbility === 'comeback' && margin >= 3) {
    rightGold += 2;
  }
  return { leftGold: leftGold, rightGold: rightGold };
}

if (typeof module !== 'undefined' && module.exports) {
  module.exports = { ABILITIES, onRevealBonus, postFlipDeltas, postFlipGoldBonus };
}
if (typeof window !== 'undefined') {
  window.PileupAbilities = { ABILITIES, onRevealBonus, postFlipDeltas, postFlipGoldBonus };
}
