/**
 * Pileup engine — weighted random selection.
 *
 * The single most important function in Pileup: given a 10-card pile,
 * pick which 5 will flip in battle. Each card's `weight` value tilts
 * its flip probability without ever guaranteeing it.
 *
 * Design parameters (locked, see GAME_DESIGN.md Section 11):
 *   - Medium bend (~30-40% max influence via weights)
 *   - No preview (player does not know which 5 until they flip)
 *   - Random order with positional modifiers
 *   - Anchor ability: rare guarantee that a card always flips
 *
 * Algorithm: weighted reservoir sampling with positional override.
 *   1. Anchor cards are always included (pre-selected before the draw).
 *   2. Remaining slots filled by weighted random draw (no replacement).
 *   3. Order: position='first' cards lead, position='last' cards close,
 *      others (including anchors) shuffle in between.
 */

const FLIP_COUNT  = 5;
const BASE_WEIGHT = 100;
const MIN_WEIGHT  = 10;

function effectiveWeight(card) {
  return Math.max(MIN_WEIGHT, BASE_WEIGHT + (card.weight || 0));
}

/**
 * Weighted random sample without replacement.
 */
function weightedSample(pool, count, rng) {
  rng = rng || Math.random;
  const remaining = pool.slice();
  const picked = [];
  for (let i = 0; i < count && remaining.length > 0; i++) {
    let totalWeight = 0;
    for (let j = 0; j < remaining.length; j++) totalWeight += effectiveWeight(remaining[j]);
    let roll = rng() * totalWeight;
    let pickIndex = 0;
    for (let j = 0; j < remaining.length; j++) {
      roll -= effectiveWeight(remaining[j]);
      if (roll <= 0) { pickIndex = j; break; }
    }
    picked.push(remaining[pickIndex]);
    remaining.splice(pickIndex, 1);
  }
  return picked;
}

function shuffle(arr, rng) {
  rng = rng || Math.random;
  const a = arr.slice();
  for (let i = a.length - 1; i > 0; i--) {
    const j = Math.floor(rng() * (i + 1));
    const tmp = a[i]; a[i] = a[j]; a[j] = tmp;
  }
  return a;
}

/**
 * Select FLIP_COUNT cards from a pile, honoring weights, positional traits, and anchors.
 *
 * Anchor cards (ability === 'anchor') are always included, using up slots before
 * the weighted draw. If anchors exceed FLIP_COUNT, only the first FLIP_COUNT are used.
 * Anchored cards shuffle into the middle (no positional bias for anchors themselves).
 *
 * Returns cards in flip order (first → middle → last).
 */
function selectFlipped(pile, rng) {
  rng = rng || Math.random;
  const cards = pile.cards;
  if (cards.length <= FLIP_COUNT) return shuffle(cards, rng);

  const anchorCards  = cards.filter(c => c.ability === 'anchor');
  const normalCards  = cards.filter(c => c.ability !== 'anchor');

  const anchored     = anchorCards.slice(0, FLIP_COUNT);
  const slotsLeft    = FLIP_COUNT - anchored.length;

  const firstCards   = normalCards.filter(c => c.position === 'first');
  const lastCards    = normalCards.filter(c => c.position === 'last');
  const neutralCards = normalCards.filter(c => !c.position);

  const resFirst = weightedSample(firstCards, Math.min(firstCards.length, slotsLeft), rng);
  const rem1     = slotsLeft - resFirst.length;
  const resLast  = weightedSample(lastCards,  Math.min(lastCards.length,  rem1), rng);
  const rem2     = rem1 - resLast.length;
  const middle   = weightedSample(neutralCards, rem2, rng);

  // Anchors shuffle into the middle group so they have no positional preference.
  const shuffledMiddle = shuffle(middle.concat(anchored), rng);
  return resFirst.concat(shuffledMiddle).concat(resLast);
}

/**
 * Compute each card's flip probability as a percentage.
 * Anchor cards always show 100%.
 * Others use normalized weight approximation.
 */
function flipProbabilities(pile) {
  const cards = pile.cards;
  if (cards.length <= FLIP_COUNT) return cards.map(() => 100);

  // Count how many anchor slots are used
  const anchorCount  = cards.filter(c => c.ability === 'anchor').length;
  const anchorSlots  = Math.min(anchorCount, FLIP_COUNT);
  const normalSlots  = FLIP_COUNT - anchorSlots;
  const normalCards  = cards.filter(c => c.ability !== 'anchor');

  let totalWeight = 0;
  for (let i = 0; i < normalCards.length; i++) totalWeight += effectiveWeight(normalCards[i]);

  return cards.map(c => {
    if (c.ability === 'anchor') return 100;
    const w = effectiveWeight(c);
    const prob = 1 - Math.pow(1 - (w / totalWeight), normalSlots);
    return Math.round(prob * 100);
  });
}

if (typeof module !== 'undefined' && module.exports) {
  module.exports = {
    FLIP_COUNT, BASE_WEIGHT, MIN_WEIGHT,
    effectiveWeight, weightedSample, shuffle,
    selectFlipped, flipProbabilities
  };
}
if (typeof window !== 'undefined') {
  window.PileupSelection = {
    FLIP_COUNT, BASE_WEIGHT, MIN_WEIGHT,
    effectiveWeight, weightedSample, shuffle,
    selectFlipped, flipProbabilities
  };
}
