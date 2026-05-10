/**
 * Pileup renderer — main.
 *
 * Throwaway layer. Replace entirely when porting to Godot/Unity.
 *
 * Battle flow:
 *   For each of 5 flips:
 *     1. Draw one card from each pile (stack count decreases)
 *     2. Place both face-down in the center briefly
 *     3. Flip to reveal values
 *     4. Show win/lose/tie styling
 *     5. Add result card to running history row
 *   Then Reveal Window shows unflipped cards in pile grid.
 */

(function () {
  'use strict';

  const { makeRandomPile } = window.PileupCards;
  const { selectFlipped, flipProbabilities, FLIP_COUNT } = window.PileupSelection;
  const { ABILITIES } = window.PileupAbilities;
  const { simulateBattle } = window.PileupBattle;

  const TIMING = {
    FACE_DOWN_DURATION: 380, // ms cards sit face-down before revealing
    FLIP_RESULT_DELAY:  100, // ms after reveal before win/lose styling
    FLIP_INTERVAL:     1300, // total ms per flip (face-down + reveal + viewing)
    REVEAL_DELAY:       700, // ms before Reveal Window
  };

  const $ = id => document.getElementById(id);
  let battleInProgress = false;

  // ------------------------------------------------------------------
  // Pile stack visual
  // ------------------------------------------------------------------

  function renderPileStack(id, count) {
    const wrap = $(id);
    wrap.innerHTML = '';
    const art = document.createElement('div');
    art.className = 'pile-stack-art';

    if (count <= 0) {
      const top = document.createElement('div');
      top.className = 'stack-top';
      top.style.opacity = '0.3';
      top.style.fontSize = '11px';
      top.textContent = 'empty';
      art.appendChild(top);
    } else {
      if (count > 2) {
        const g1 = document.createElement('div'); g1.className = 'stack-ghost g1'; art.appendChild(g1);
      }
      if (count > 1) {
        const g2 = document.createElement('div'); g2.className = 'stack-ghost g2'; art.appendChild(g2);
      }
      const top = document.createElement('div');
      top.className = 'stack-top';
      const countEl = document.createElement('span');
      countEl.className = 'stack-count';
      countEl.textContent = count;
      const labelEl = document.createElement('span');
      labelEl.className = 'stack-label';
      labelEl.textContent = count === 1 ? 'card' : 'cards';
      top.appendChild(countEl);
      top.appendChild(labelEl);
      art.appendChild(top);
    }
    wrap.appendChild(art);
  }

  // ------------------------------------------------------------------
  // Flip display — face-down then reveal
  // ------------------------------------------------------------------

  function showFaceDownPair() {
    const display = $('flipDisplay');
    display.innerHTML = '';
    const lc = document.createElement('div');
    lc.className = 'card-big card-face-down';
    const vs = document.createElement('div');
    vs.className = 'vs';
    vs.textContent = 'vs';
    const rc = document.createElement('div');
    rc.className = 'card-big card-face-down';
    display.appendChild(lc);
    display.appendChild(vs);
    display.appendChild(rc);
  }

  function revealFlipPair(flip) {
    const cards = $('flipDisplay').querySelectorAll('.card-big');
    if (cards.length < 2) return;
    const lc = cards[0], rc = cards[1];
    lc.classList.remove('card-face-down');
    rc.classList.remove('card-face-down');
    lc.textContent = cardLabel(flip.left,  flip.leftEffective);
    rc.textContent = cardLabel(flip.right, flip.rightEffective);
    setTimeout(() => {
      if (flip.winner === 'left')       { lc.classList.add('win');  rc.classList.add('lose'); }
      else if (flip.winner === 'right') { rc.classList.add('win');  lc.classList.add('lose'); }
      else                              { lc.classList.add('tie');  rc.classList.add('tie');  }
    }, TIMING.FLIP_RESULT_DELAY);
  }

  // ------------------------------------------------------------------
  // Running history row (fills up one card per flip)
  // ------------------------------------------------------------------

  function addHistoryCard(containerId, label, outcome) {
    const container = $(containerId);
    const card = document.createElement('div');
    card.className = 'card-staged face-up ' + outcome;
    card.textContent = label;
    container.appendChild(card);
    requestAnimationFrame(() => requestAnimationFrame(() => card.classList.add('visible')));
  }

  // ------------------------------------------------------------------
  // Pile grid render
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
      div.style.opacity = '0.4';
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

  // ------------------------------------------------------------------
  // Misc helpers
  // ------------------------------------------------------------------

  function cardLabel(card, effective) {
    return (effective !== undefined && effective !== card.value)
      ? card.value + '→' + effective
      : String(card.value);
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
    $('flipDisplay').innerHTML  = '';
    $('resultDisplay').innerHTML = '';
    $('leftStaging').innerHTML  = '';
    $('rightStaging').innerHTML = '';
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

    const leftPile  = makeRandomPile('p1');
    const rightPile = makeRandomPile('p2');

    logLine('P1: [' + leftPile.cards.map(c => c.value).join(', ') + ']');
    logLine('P2: [' + rightPile.cards.map(c => c.value).join(', ') + ']');

    renderPile('leftCards',  leftPile,  null, false);
    renderPile('rightCards', rightPile, null, false);
    renderPileStack('leftStack',  10);
    renderPileStack('rightStack', 10);
    $('leftScore').textContent  = 'Score: 0';
    $('rightScore').textContent = 'Score: 0';

    // Engine runs the full battle deterministically; animation is a replay.
    const result = simulateBattle(leftPile, rightPile, selectFlipped);

    let leftScore = 0, rightScore = 0;
    const leftFlippedSet  = new Set();
    const rightFlippedSet = new Set();

    for (let i = 0; i < result.flips.length; i++) {
      const flip = result.flips[i];

      // Both players draw one card from their pile.
      renderPileStack('leftStack',  10 - i - 1);
      renderPileStack('rightStack', 10 - i - 1);
      setStatus('Flip ' + (i + 1) + ' of ' + FLIP_COUNT);

      // Cards placed face-down on the table.
      showFaceDownPair();
      await sleep(TIMING.FACE_DOWN_DURATION);

      // Flip — reveal values and outcome.
      revealFlipPair(flip);

      // Brief pause before updating scores and history.
      await sleep(TIMING.FLIP_RESULT_DELAY + 120);

      if (flip.winner === 'left')       leftScore++;
      else if (flip.winner === 'right') rightScore++;
      $('leftScore').textContent  = 'Score: ' + leftScore;
      $('rightScore').textContent = 'Score: ' + rightScore;

      // Running history rows.
      const lOutcome = flip.winner === 'left'  ? 'win' : flip.winner === 'tie' ? 'tie' : 'lose';
      const rOutcome = flip.winner === 'right' ? 'win' : flip.winner === 'tie' ? 'tie' : 'lose';
      addHistoryCard('leftStaging',  cardLabel(flip.left,  flip.leftEffective),  lOutcome);
      addHistoryCard('rightStaging', cardLabel(flip.right, flip.rightEffective), rOutcome);

      // Highlight drawn card in pile grid live.
      leftFlippedSet.add(flip.left.id);
      rightFlippedSet.add(flip.right.id);
      renderPile('leftCards',  leftPile,  leftFlippedSet,  false);
      renderPile('rightCards', rightPile, rightFlippedSet, false);

      // Log.
      const winnerText = flip.winner === 'tie'
        ? 'tie'
        : 'P' + (flip.winner === 'left' ? '1' : '2') + ' wins by ' + flip.delta;
      logLine('Flip ' + (i + 1) + ': P1 ' + cardLabel(flip.left, flip.leftEffective)
        + ' vs P2 ' + cardLabel(flip.right, flip.rightEffective) + ' — ' + winnerText);
      flip.events.forEach(ev => {
        if (ev.trigger && ev.ability) {
          const who  = ev.side === 'left' ? 'P1' : 'P2';
          const sign = ev.delta > 0 ? '+' : '';
          const next = ev.next ? ' (next card)' : '';
          logLine('  ' + who + ' ' + ev.ability + ' [' + ev.trigger + ']: ' + sign + ev.delta + next);
        }
      });

      // Wait the remaining time before the next flip starts.
      const elapsed = TIMING.FACE_DOWN_DURATION + TIMING.FLIP_RESULT_DELAY + 120;
      await sleep(TIMING.FLIP_INTERVAL - elapsed);
    }

    // Reveal Window — the 5 cards that stayed home briefly shown.
    await sleep(TIMING.REVEAL_DELAY);
    setStatus('Reveal Window — unflipped cards shown.');
    renderPile('leftCards',  leftPile,  leftFlippedSet,  true);
    renderPile('rightCards', rightPile, rightFlippedSet, true);

    const winText = result.winner === 'tie'
      ? 'Battle tied ' + leftScore + '–' + rightScore
      : 'P' + (result.winner === 'left' ? '1' : '2') + ' wins '
        + Math.max(leftScore, rightScore) + '–' + Math.min(leftScore, rightScore);
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
    renderPileStack('leftStack',  10);
    renderPileStack('rightStack', 10);
    renderPlaceholderPile('leftCards');
    renderPlaceholderPile('rightCards');
  }

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', boot);
  } else {
    boot();
  }
})();
