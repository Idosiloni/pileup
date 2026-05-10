/**
 * Pileup engine — card ability definitions and resolution helpers.
 *
 * Three trigger types are implemented here:
 *   On Reveal  — card gets a value bonus for its own flip
 *   On Win     — card's win buffs your next card
 *   On Loss    — card's loss debuffs the opponent's next card
 *
 * All functions are pure data transformations. No DOM, no side effects.
 */

const ABILITIES = {
  valor: {
    id: 'valor',
    label: 'Valor',
    description: 'On Win: next +1',
    trigger: 'on_win'
  },
  spite: {
    id: 'spite',
    label: 'Spite',
    description: 'On Loss: foe next −1',
    trigger: 'on_loss'
  },
  blaze: {
    id: 'blaze',
    label: 'Blaze',
    description: 'On Reveal: +2',
    trigger: 'on_reveal'
  }
};

/**
 * Returns the bonus to add to a card's effective value when it flips.
 * Called before resolving the flip (On Reveal phase).
 */
function onRevealBonus(abilityId) {
  if (abilityId === 'blaze') return 2;
  return 0;
}

/**
 * Returns pending value deltas to carry into the next flip after this one resolves.
 * leftDelta  — added to left's next card effective value
 * rightDelta — added to right's next card effective value
 *
 * Valor on winner: your next card gets +1
 * Spite on loser:  opponent's next card gets −1
 */
function postFlipDeltas(winner, leftAbility, rightAbility) {
  var ld = 0, rd = 0;
  if (winner === 'left') {
    if (leftAbility === 'valor') ld += 1;
    if (rightAbility === 'spite') ld -= 1;
  } else if (winner === 'right') {
    if (rightAbility === 'valor') rd += 1;
    if (leftAbility === 'spite') rd -= 1;
  }
  return { leftDelta: ld, rightDelta: rd };
}

if (typeof module !== 'undefined' && module.exports) {
  module.exports = { ABILITIES, onRevealBonus, postFlipDeltas };
}
if (typeof window !== 'undefined') {
  window.PileupAbilities = { ABILITIES, onRevealBonus, postFlipDeltas };
}
