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
 *
 * Algorithm: weighted reservoir sampling with positional override.
 *   1. Cards with position='first' or position='last' get reserved slots.
 *   2. Remaining slots are filled by weighted random draw without replacement.
 *   3. Order: 'first' cards lead, 'last' cards close, others shuffled in middle.
 */

const FLIP_COUNT = 5;
const BASE_WEIGHT = 100;
const MIN_WEIGHT = 10;

function effectiveWeight(card) {
  return Math.max(MIN_WEIGHT, BASE_WEIGHT + (card.weight || 0));
}

/**
 * Weighted random sample without replacement.
 * Returns `count` cards from `pool` based on each card's effective weight.
 */
function weightedSample(pool, count, rng) {
  rng = rng || Math.random;
  const remaining = pool.slice();
  const picked = [];
  for (let i = 0; i < count && remaining.length > 0; i++) {
    let totalWeight = 0;
    for (let j = 0; j < remaining.length; j++) {
      totalWeight += effectiveWeight(remaining[j]);
    }
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
 * Select FLIP_COUNT cards from a pile honoring weights and positional traits.
 * Returns cards in flip order (first to last).
 */
function selectFlipped(pile, rng) {
  rng = rng || Math.random;
  const cards = pile.cards;
  if (cards.length <= FLIP_COUNT) {
    return shuffle(cards, rng);
  }

  const firstCards = cards.filter(c => c.position === 'first');
  const lastCards = cards.filter(c => c.position === 'last');
  const neutralCards = cards.filter(c => !c.position);

  const reservedFirst = weightedSample(firstCards, Math.min(firstCards.length, FLIP_COUNT), rng);
  const reservedLast = weightedSample(lastCards, Math.min(lastCards.length, FLIP_COUNT - reservedFirst.length), rng);
  const slotsLeft = FLIP_COUNT - reservedFirst.length - reservedLast.length;
  const middle = weightedSample(neutralCards, slotsLeft, rng);

  return reservedFirst.concat(shuffle(middle, rng)).concat(reservedLast);
}

/**
 * Compute each card's flip probability as a percentage.
 * Used for the visible-probability UI (see GAME_DESIGN.md Section 11.5).
 *
 * Note: this is an approximation. True per-card probability under weighted
 * sampling without replacement is a complex calculation; a Monte Carlo
 * simulation gives the ground truth. For UI display, the simple normalized
 * weight is close enough and intuitive.
 */
function flipProbabilities(pile) {
  const cards = pile.cards;
  if (cards.length <= FLIP_COUNT) {
    return cards.map(() => 100);
  }
  let totalWeight = 0;
  for (let i = 0; i < cards.length; i++) {
    totalWeight += effectiveWeight(cards[i]);
  }
  const avgPickPerSlot = totalWeight / cards.length;
  return cards.map(c => {
    const w = effectiveWeight(c);
    const probabilityPerSlot = w / totalWeight;
    const inclusionProbability = 1 - Math.pow(1 - probabilityPerSlot, FLIP_COUNT);
    return Math.round(inclusionProbability * 100);
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
