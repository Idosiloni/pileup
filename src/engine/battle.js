/**
 * Pileup engine — battle resolution.
 *
 * Given two piles, simulate one full battle: select 5 cards from each,
 * flip them head-to-head, return a structured result.
 *
 * Returns enough data to fully replay or render the battle.
 * Ability triggers handled in order: On Reveal → resolve → Pierce → On Win/Loss/Comeback.
 */

var _ab = null;
function getAb() {
  if (_ab) return _ab;
  _ab = (typeof module !== 'undefined' && module.exports)
    ? require('./abilities.js') : window.PileupAbilities;
  return _ab;
}

/**
 * Resolve a single flip between two cards.
 * Uses effective values (ability-adjusted). Returns winner + delta.
 */
function resolveFlip(leftCard, rightCard, effectiveLeft, effectiveRight) {
  var lv = (effectiveLeft  !== undefined) ? effectiveLeft  : leftCard.value;
  var rv = (effectiveRight !== undefined) ? effectiveRight : rightCard.value;
  if (lv > rv) return { winner: 'left',  delta: lv - rv };
  if (rv > lv) return { winner: 'right', delta: rv - lv };
  return { winner: 'tie', delta: 0 };
}

/**
 * Simulate a battle between two piles.
 *
 * result.flips[i] shape:
 *   index, left, right           — raw cards
 *   leftEffective, rightEffective — values used to resolve (after On Reveal)
 *   winner, delta                — outcome
 *   events                       — ability trigger log entries
 *
 * result also includes leftGoldBonus / rightGoldBonus (from comeback etc.)
 * for applyBattleResult to pick up.
 */
function simulateBattle(leftPile, rightPile, selectionFn) {
  if (!selectionFn) {
    throw new Error('simulateBattle: selectionFn required (inject selectFlipped from selection.js)');
  }
  var ab = getAb();
  var leftFlipped  = selectionFn(leftPile);
  var rightFlipped = selectionFn(rightPile);

  var leftFlippedIds  = new Set(leftFlipped.map(function(c) { return c.id; }));
  var rightFlippedIds = new Set(rightFlipped.map(function(c) { return c.id; }));
  var leftUnflipped   = leftPile.cards.filter(function(c)  { return !leftFlippedIds.has(c.id); });
  var rightUnflipped  = rightPile.cards.filter(function(c) { return !rightFlippedIds.has(c.id); });

  var flips       = [];
  var leftScore   = 0;
  var rightScore  = 0;
  var flipCount   = Math.min(leftFlipped.length, rightFlipped.length);
  var leftPending  = 0;
  var rightPending = 0;
  var leftGoldBonus  = 0;
  var rightGoldBonus = 0;

  for (var i = 0; i < flipCount; i++) {
    var leftCard  = leftFlipped[i];
    var rightCard = rightFlipped[i];
    var events = [];

    // Consume pending bonuses from previous flip's On Win / On Loss triggers.
    var leftEff  = leftCard.value  + leftPending;
    var rightEff = rightCard.value + rightPending;
    if (leftPending  !== 0) events.push({ side: 'left',  source: 'pending', delta: leftPending });
    if (rightPending !== 0) events.push({ side: 'right', source: 'pending', delta: rightPending });
    leftPending  = 0;
    rightPending = 0;

    // On Reveal bonuses (Blaze +2, Echo +3).
    var lReveal = ab.onRevealBonus(leftCard.ability);
    var rReveal = ab.onRevealBonus(rightCard.ability);
    if (lReveal !== 0) {
      leftEff += lReveal;
      events.push({ side: 'left',  ability: leftCard.ability,  trigger: 'on_reveal', delta: lReveal });
    }
    if (rReveal !== 0) {
      rightEff += rReveal;
      events.push({ side: 'right', ability: rightCard.ability, trigger: 'on_reveal', delta: rReveal });
    }

    var flip = resolveFlip(leftCard, rightCard, leftEff, rightEff);

    // Pierce: tie → win for the piercing side.
    if (flip.winner === 'tie') {
      if (leftCard.ability === 'pierce') {
        flip = { winner: 'left', delta: 0 };
        events.push({ side: 'left', ability: 'pierce', trigger: 'on_tie', delta: 0, note: 'tie→win' });
      } else if (rightCard.ability === 'pierce') {
        flip = { winner: 'right', delta: 0 };
        events.push({ side: 'right', ability: 'pierce', trigger: 'on_tie', delta: 0, note: 'tie→win' });
      }
    }

    if (flip.winner === 'left')  leftScore  += 1;
    else if (flip.winner === 'right') rightScore += 1;

    // On Win / On Loss triggers (Valor, Spite — affect next flip's pending).
    var deltas = ab.postFlipDeltas(flip.winner, leftCard.ability, rightCard.ability);
    leftPending  += deltas.leftDelta;
    rightPending += deltas.rightDelta;
    if (deltas.leftDelta !== 0) {
      events.push({ side: 'left',  ability: leftCard.ability || rightCard.ability,
        trigger: flip.winner === 'left' ? 'on_win' : 'on_loss', delta: deltas.leftDelta, next: true });
    }
    if (deltas.rightDelta !== 0) {
      events.push({ side: 'right', ability: rightCard.ability || leftCard.ability,
        trigger: flip.winner === 'right' ? 'on_win' : 'on_loss', delta: deltas.rightDelta, next: true });
    }

    // Comeback: On Loss by margin ≥ 3 → +2g next shop.
    var goldBonuses = ab.postFlipGoldBonus(flip.winner, leftCard.ability, rightCard.ability, flip.delta);
    if (goldBonuses.leftGold !== 0) {
      leftGoldBonus += goldBonuses.leftGold;
      events.push({ side: 'left',  ability: 'comeback', trigger: 'on_loss', delta: goldBonuses.leftGold, currency: 'gold' });
    }
    if (goldBonuses.rightGold !== 0) {
      rightGoldBonus += goldBonuses.rightGold;
      events.push({ side: 'right', ability: 'comeback', trigger: 'on_loss', delta: goldBonuses.rightGold, currency: 'gold' });
    }

    flips.push({
      index: i,
      left:  leftCard,
      right: rightCard,
      leftEffective:  leftEff,
      rightEffective: rightEff,
      winner: flip.winner,
      delta:  flip.delta,
      events: events
    });
  }

  var winner = 'tie';
  if (leftScore > rightScore)  winner = 'left';
  else if (rightScore > leftScore) winner = 'right';

  return {
    leftPile:      leftPile,
    rightPile:     rightPile,
    leftFlipped:   leftFlipped,
    rightFlipped:  rightFlipped,
    leftUnflipped:  leftUnflipped,
    rightUnflipped: rightUnflipped,
    flips:          flips,
    leftScore:      leftScore,
    rightScore:     rightScore,
    winner:         winner,
    margin:         Math.abs(leftScore - rightScore),
    leftGoldBonus:  leftGoldBonus,
    rightGoldBonus: rightGoldBonus
  };
}

if (typeof module !== 'undefined' && module.exports) {
  module.exports = { resolveFlip, simulateBattle };
}
if (typeof window !== 'undefined') {
  window.PileupBattle = { resolveFlip, simulateBattle };
}
