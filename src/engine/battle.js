/**
 * Pileup engine — battle resolution.
 *
 * Given two piles, simulate one full battle: select 5 cards from each,
 * flip them head-to-head, return a structured result.
 *
 * Returns enough data to fully replay or render the battle.
 */

/**
 * Resolve a single flip between two cards.
 * Higher value wins. Equal values = tie (no points to either side).
 */
function resolveFlip(leftCard, rightCard) {
  if (leftCard.value > rightCard.value) {
    return { winner: 'left', delta: leftCard.value - rightCard.value };
  }
  if (rightCard.value > leftCard.value) {
    return { winner: 'right', delta: rightCard.value - leftCard.value };
  }
  return { winner: 'tie', delta: 0 };
}

/**
 * Simulate a battle between two piles.
 * Returns full battle data including which cards flipped, which didn't,
 * each flip's outcome, and the final score and winner.
 */
function simulateBattle(leftPile, rightPile, selectionFn) {
  if (!selectionFn) {
    throw new Error('simulateBattle: selectionFn required (inject selectFlipped from selection.js)');
  }
  const leftFlipped = selectionFn(leftPile);
  const rightFlipped = selectionFn(rightPile);

  const leftFlippedIds = new Set(leftFlipped.map(c => c.id));
  const rightFlippedIds = new Set(rightFlipped.map(c => c.id));
  const leftUnflipped = leftPile.cards.filter(c => !leftFlippedIds.has(c.id));
  const rightUnflipped = rightPile.cards.filter(c => !rightFlippedIds.has(c.id));

  const flips = [];
  let leftScore = 0;
  let rightScore = 0;
  const flipCount = Math.min(leftFlipped.length, rightFlipped.length);

  for (let i = 0; i < flipCount; i++) {
    const flip = resolveFlip(leftFlipped[i], rightFlipped[i]);
    if (flip.winner === 'left') leftScore += 1;
    else if (flip.winner === 'right') rightScore += 1;
    flips.push({
      index: i,
      left: leftFlipped[i],
      right: rightFlipped[i],
      winner: flip.winner,
      delta: flip.delta
    });
  }

  let winner = 'tie';
  if (leftScore > rightScore) winner = 'left';
  else if (rightScore > leftScore) winner = 'right';

  return {
    leftPile: leftPile,
    rightPile: rightPile,
    leftFlipped: leftFlipped,
    rightFlipped: rightFlipped,
    leftUnflipped: leftUnflipped,
    rightUnflipped: rightUnflipped,
    flips: flips,
    leftScore: leftScore,
    rightScore: rightScore,
    winner: winner,
    margin: Math.abs(leftScore - rightScore)
  };
}

if (typeof module !== 'undefined' && module.exports) {
  module.exports = { resolveFlip, simulateBattle };
}
if (typeof window !== 'undefined') {
  window.PileupBattle = { resolveFlip, simulateBattle };
}
