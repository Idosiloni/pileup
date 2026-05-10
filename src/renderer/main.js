/**
 * Pileup renderer — main.
 *
 * This file is the THROWAWAY layer. Everything here is HTML/DOM-specific.
 * When porting to Godot/Unity, replace this entirely; the engine modules
 * (src/engine/*.js) translate cleanly.
 *
 * Responsibilities:
 *   - Generate two piles (currently random)
 *   - Run a battle through the engine
 *   - Animate the result: pile render -> Hush -> flips -> Reveal Window
 *   - Maintain a battle log
 *
 * Animation timing constants are tuned for "feel" — adjust freely.
 */

(function () {
  'use strict';

  const { makeRandomPile } = window.PileupCards;
  const { selectFlipped, flipProbabilities } = window.PileupSelection;
  const { ABILITIES } = window.PileupAbilities;
  const { simulateBattle } = window.PileupBattle;

  // Timing constants (ms). Tweak to taste.
  const TIMING = {
    HUSH: 1400,           // The Hush — pause before first flip
    FLIP_INTERVAL: 1100,  // Time between flips
    REVEAL_DELAY: 600,    // Pause before Reveal Window
    FLIP_RESULT_DELAY: 80 // Tiny delay before win/lose styling appears
  };

  const $ = id => document.getElementById(id);
  let battleInProgress = false;

  // ------------------------------------------------------------------
  // Render helpers
  // ------------------------------------------------------------------

  function renderPile(containerId, pile, flippedIdSet, showUnflipped) {
    const container = $(containerId);
    container.innerHTML = '';
    const probs = flipProbabilities(pile);
    pile.cards.forEach((card, i) => {
      const div = document.createElement('div');
      div.className = 'card-mini';
      const isFlipped = flippedIdSet && flippedIdSet.has(card.id);
      if (isFlipped) div.classList.add('flipped');
      if (showUnflipped && !isFlipped) div.classList.add('unflipped-reveal');
      const valueEl = document.createElement('span');
      valueEl.textContent = card.value;
      const probEl = document.createElement('span');
      probEl.className = 'card-prob';
      probEl.textContent = probs[i] + '%';
      div.appendChild(valueEl);
      div.appendChild(probEl);
      if (card.ability && ABILITIES[card.ability]) {
        const abilEl = document.createElement('span');
        abilEl.className = 'card-ability';
        abilEl.textContent = ABILITIES[card.ability].label;
        div.appendChild(abilEl);
      }
      container.appendChild(div);
    });
  }

  function renderPlaceholderPile(containerId) {
    const container = $(containerId);
    container.innerHTML = '';
    for (let i = 0; i < 10; i++) {
      const div = document.createElement('div');
      div.className = 'card-mini';
      div.style.opacity = '0.5';
      const valueEl = document.createElement('span');
      valueEl.textContent = '?';
      const probEl = document.createElement('span');
      probEl.className = 'card-prob';
      probEl.textContent = '–';
      div.appendChild(valueEl);
      div.appendChild(probEl);
      container.appendChild(div);
    }
  }

  function cardBigLabel(card, effective) {
    if (effective !== undefined && effective !== card.value) {
      return card.value + '→' + effective;
    }
    return String(card.value);
  }

  function showFlipPair(flip) {
    const display = $('flipDisplay');
    display.innerHTML = '';
    const lc = document.createElement('div');
    lc.className = 'card-big';
    lc.textContent = cardBigLabel(flip.left, flip.leftEffective);
    const vs = document.createElement('div');
    vs.className = 'vs';
    vs.textContent = 'vs';
    const rc = document.createElement('div');
    rc.className = 'card-big';
    rc.textContent = cardBigLabel(flip.right, flip.rightEffective);
    display.appendChild(lc);
    display.appendChild(vs);
    display.appendChild(rc);
    setTimeout(() => {
      if (flip.winner === 'left') { lc.classList.add('win'); rc.classList.add('lose'); }
      else if (flip.winner === 'right') { rc.classList.add('win'); lc.classList.add('lose'); }
      else { lc.classList.add('tie'); rc.classList.add('tie'); }
    }, TIMING.FLIP_RESULT_DELAY);
  }

  function setStatus(text) { $('arenaStatus').textContent = text; }

  function logLine(msg) {
    const el = $('log');
    const line = document.createElement('div');
    line.textContent = msg;
    el.appendChild(line);
    el.scrollTop = el.scrollHeight;
  }

  function clearArena() {
    $('flipDisplay').innerHTML = '';
    $('resultDisplay').innerHTML = '';
  }

  function sleep(ms) { return new Promise(r => setTimeout(r, ms)); }

  // ------------------------------------------------------------------
  // Battle orchestration
  // ------------------------------------------------------------------

  async function runBattle() {
    if (battleInProgress) return;
    battleInProgress = true;
    $('newBattleBtn').disabled = true;

    $('log').innerHTML = '';
    clearArena();

    const leftPile = makeRandomPile('p1');
    const rightPile = makeRandomPile('p2');

    logLine('P1 pile: [' + leftPile.cards.map(c => c.value).join(', ') + ']');
    logLine('P2 pile: [' + rightPile.cards.map(c => c.value).join(', ') + ']');

    renderPile('leftCards', leftPile, null, false);
    renderPile('rightCards', rightPile, null, false);
    $('leftScore').textContent = 'Score: 0';
    $('rightScore').textContent = 'Score: 0';

    // Run the entire battle through the engine first; render is replay.
    const result = simulateBattle(leftPile, rightPile, selectFlipped);

    // The Hush — 5 are chosen, none yet shown.
    setStatus('The Hush — five chosen, none revealed.');
    await sleep(TIMING.HUSH);

    // Highlight which cards flipped (still face-up since values are visible
    // by default in the prototype; later we may add face-down rendering).
    const leftFlippedIds = new Set(result.leftFlipped.map(c => c.id));
    const rightFlippedIds = new Set(result.rightFlipped.map(c => c.id));
    renderPile('leftCards', leftPile, leftFlippedIds, false);
    renderPile('rightCards', rightPile, rightFlippedIds, false);

    let leftScore = 0, rightScore = 0;
    for (let i = 0; i < result.flips.length; i++) {
      const flip = result.flips[i];
      setStatus('Flip ' + (i + 1) + ' of ' + result.flips.length);
      showFlipPair(flip);
      if (flip.winner === 'left') leftScore += 1;
      else if (flip.winner === 'right') rightScore += 1;
      $('leftScore').textContent = 'Score: ' + leftScore;
      $('rightScore').textContent = 'Score: ' + rightScore;
      const winnerText = flip.winner === 'tie'
        ? 'tie'
        : 'P' + (flip.winner === 'left' ? '1' : '2') + ' wins by ' + flip.delta;
      const lVal = flip.leftEffective !== flip.left.value ? flip.left.value + '→' + flip.leftEffective : flip.left.value;
      const rVal = flip.rightEffective !== flip.right.value ? flip.right.value + '→' + flip.rightEffective : flip.right.value;
      logLine('Flip ' + (i + 1) + ': P1 ' + lVal + ' vs P2 ' + rVal + ' — ' + winnerText);
      flip.events.forEach(ev => {
        if (ev.trigger && ev.ability) {
          const who = ev.side === 'left' ? 'P1' : 'P2';
          const sign = ev.delta > 0 ? '+' : '';
          const nextNote = ev.next ? ' (next card)' : '';
          logLine('  ' + who + ' ' + ev.ability + ' [' + ev.trigger + ']: ' + sign + ev.delta + nextNote);
        }
      });
      await sleep(TIMING.FLIP_INTERVAL);
    }

    // Reveal Window
    await sleep(TIMING.REVEAL_DELAY);
    setStatus('Reveal Window — unflipped cards shown.');
    renderPile('leftCards', leftPile, leftFlippedIds, true);
    renderPile('rightCards', rightPile, rightFlippedIds, true);

    const winText = result.winner === 'tie'
      ? 'Battle tied ' + leftScore + '-' + rightScore
      : 'P' + (result.winner === 'left' ? '1' : '2') + ' wins ' + Math.max(leftScore, rightScore) + '-' + Math.min(leftScore, rightScore);
    $('resultDisplay').textContent = winText;
    logLine('=== ' + winText + ' ===');

    battleInProgress = false;
    $('newBattleBtn').disabled = false;
  }

  // ------------------------------------------------------------------
  // Boot
  // ------------------------------------------------------------------

  function boot() {
    $('newBattleBtn').addEventListener('click', runBattle);
    renderPlaceholderPile('leftCards');
    renderPlaceholderPile('rightCards');
  }

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', boot);
  } else {
    boot();
  }
})();
