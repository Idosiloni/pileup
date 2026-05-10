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

var _jk = null;
function getJk() {
  if (_jk) return _jk;
  _jk = (typeof module !== 'undefined' && module.exports)
    ? require('./jokers.js') : window.PileupJokers;
  return _jk;
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
 * @param {object} leftPile
 * @param {object} rightPile
 * @param {function} selectionFn  — selectFlipped from selection.js
 * @param {string|null} [jokerId] — active Joker id, or null
 *
 * result.flips[i] shape:
 *   index, left, right           — raw cards
 *   leftEffective, rightEffective — values used to resolve (after On Reveal + Joker)
 *   winner, delta                — outcome
 *   events                       — ability + joker trigger log entries
 *
 * result includes leftGoldBonus/rightGoldBonus (comeback) and jokerManaBonus (gambler).
 */
function simulateBattle(leftPile, rightPile, selectionFn, jokerId) {
  if (!selectionFn) {
    throw new Error('simulateBattle: selectionFn required (inject selectFlipped from selection.js)');
  }
  var ab = getAb();
  var jk = getJk();
  jokerId = jokerId || null;

  // Sniper: guarantee highest-value left card flips
  var leftPileForSelection = leftPile;
  if (jokerId === 'sniper') {
    var anchorId = jk.sniperAnchorId(leftPile);
    if (anchorId) {
      // Temporarily mark the sniper target as anchor ability so selectFlipped picks it
      var sniperCards = leftPile.cards.map(function(c) {
        return c.id === anchorId ? Object.assign({}, c, { _sniperAnchor: true, ability: c.ability || 'anchor' }) : c;
      });
      leftPileForSelection = { cards: sniperCards, ownerId: leftPile.ownerId };
    }
  }

  var leftFlipped  = selectionFn(leftPileForSelection);
  // Strip _sniperAnchor markers and restore original ability on flipped cards
  if (jokerId === 'sniper') {
    leftFlipped = leftFlipped.map(function(c) {
      if (!c._sniperAnchor) return c;
      var orig = leftPile.cards.find(function(o) { return o.id === c.id; });
      return orig || c;
    });
  }
  var rightFlipped = selectionFn(rightPile);

  // Gambler: only 4 flips
  var flipCount = jk.jokerFlipCount(jokerId) || Math.min(leftFlipped.length, rightFlipped.length);
  flipCount = Math.min(flipCount, leftFlipped.length, rightFlipped.length);

  var flips       = [];
  var leftScore   = 0;
  var rightScore  = 0;
  var leftPending  = 0;
  var rightPending = 0;
  var leftGoldBonus  = 0;
  var rightGoldBonus = 0;
  var streakCount = 0;   // consecutive left wins (Streak Joker)

  var leftFlippedIds  = new Set(leftFlipped.map(function(c) { return c.id; }));
  var rightFlippedIds = new Set(rightFlipped.map(function(c) { return c.id; }));
  var leftUnflipped   = leftPile.cards.filter(function(c)  { return !leftFlippedIds.has(c.id); });
  var rightUnflipped  = rightPile.cards.filter(function(c) { return !rightFlippedIds.has(c.id); });

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

    // Joker pre-flip: may modify effective values (Underdog, Streak, Doubler, Pyromancer).
    var jokerEff = jk.applyJokerPreFlip(jokerId, leftCard, rightCard, leftEff, rightEff, streakCount);
    if (jokerEff.leftEff !== leftEff || jokerEff.rightEff !== rightEff) {
      events.push({ source: 'joker', jokerId: jokerId, leftEff: jokerEff.leftEff, rightEff: jokerEff.rightEff });
    }
    leftEff  = jokerEff.leftEff;
    rightEff = jokerEff.rightEff;

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

    // Joker tie override (Tiebreaker: tie → left win).
    var jokerFlip = jk.applyJokerTie(jokerId, flip);
    if (jokerFlip !== flip) {
      events.push({ source: 'joker', jokerId: jokerId, note: jokerFlip.jokerNote });
      flip = jokerFlip;
    }

    if (flip.winner === 'left')  { leftScore  += 1; streakCount += 1; }
    else                        { streakCount  = 0; }
    if (flip.winner === 'right') rightScore += 1;

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

  var jokerManaBonus = (winner === 'left') ? jk.jokerManaBonusOnWin(jokerId) : 0;

  return {
    leftPile:        leftPile,
    rightPile:       rightPile,
    leftFlipped:     leftFlipped,
    rightFlipped:    rightFlipped,
    leftUnflipped:   leftUnflipped,
    rightUnflipped:  rightUnflipped,
    flips:           flips,
    leftScore:       leftScore,
    rightScore:      rightScore,
    winner:          winner,
    margin:          Math.abs(leftScore - rightScore),
    leftGoldBonus:   leftGoldBonus,
    rightGoldBonus:  rightGoldBonus,
    jokerManaBonus:  jokerManaBonus
  };
}

if (typeof module !== 'undefined' && module.exports) {
  module.exports = { resolveFlip, simulateBattle };
}
if (typeof window !== 'undefined') {
  window.PileupBattle = { resolveFlip, simulateBattle };
}
