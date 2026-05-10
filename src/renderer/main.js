/**
 * Pileup renderer — main.
 *
 * Throwaway layer. Replace entirely when porting to Godot/Unity.
 *
 * Battle animation flow:
 *   1. Render pile grids + pile stacks (count visible)
 *   2. Draw phase: 5 cards drawn one-by-one from each pile to staging rows
 *   3. The Hush: 5 face-down cards per side, pause
 *   4. Flip phase: staged cards reveal value one-by-one, big display shows matchup
 *   5. Reveal Window: unflipped cards shown in pile grid
 */

(function () {
  'use strict';

  const { makeRandomPile } = window.PileupCards;
  const { selectFlipped, flipProbabilities, FLIP_COUNT } = window.PileupSelection;
  const { ABILITIES } = window.PileupAbilities;
  const { simulateBattle } = window.PileupBattle;

  const TIMING = {
    DRAW_INTERVAL: 320,    // delay between each card drawn from pile
    DRAW_OFFSET: 110,      // extra gap between left draw and right draw per round
    HUSH: 1400,            // The Hush — pause after all cards staged
    FLIP_INTERVAL: 1100,   // time between flips
    REVEAL_DELAY: 600,     // pause before Reveal Window
    FLIP_RESULT_DELAY: 80  // delay before win/lose styling appears
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
        const g1 = document.createElement('div');
        g1.className = 'stack-ghost g1';
        art.appendChild(g1);
      }
      if (count > 1) {
        const g2 = document.createElement('div');
        g2.className = 'stack-ghost g2';
        art.appendChild(g2);
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
  // Staged card helpers
  // ------------------------------------------------------------------

  function addStagedCard(containerId) {
    const container = $(containerId);
    const card = document.createElement('div');
    card.className = 'card-staged';
    container.appendChild(card);
    // Double rAF to trigger CSS transition after paint
    requestAnimationFrame(() => requestAnimationFrame(() => card.classList.add('visible')));
  }

  function revealStagedCard(containerId, index, displayText) {
    const cards = $(containerId).querySelectorAll('.card-staged');
    if (!cards[index]) return;
    const card = cards[index];
    card.classList.add('face-up', 'active');
    card.textContent = displayText;
  }

  function finishStagedCard(containerId, index, outcome) {
    const cards = $(containerId).querySelectorAll('.card-staged');
    if (!cards[index]) return;
    cards[index].classList.remove('active');
    cards[index].classList.add(outcome);
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
  // Arena helpers
  // ------------------------------------------------------------------

  function cardLabel(card, effective) {
    return (effective !== undefined && effective !== card.value)
      ? card.value + '→' + effective
      : String(card.value);
  }

  function showFlipPair(flip) {
    const display = $('flipDisplay');
    display.innerHTML = '';
    const lc = document.createElement('div');
    lc.className = 'card-big';
    lc.textContent = cardLabel(flip.left, flip.leftEffective);
    const vs = document.createElement('div');
    vs.className = 'vs';
    vs.textContent = 'vs';
    const rc = document.createElement('div');
    rc.className = 'card-big';
    rc.textContent = cardLabel(flip.right, flip.rightEffective);
    display.appendChild(lc);
    display.appendChild(vs);
    display.appendChild(rc);
    setTimeout(() => {
      if (flip.winner === 'left')       { lc.classList.add('win');  rc.classList.add('lose'); }
      else if (flip.winner === 'right') { rc.classList.add('win');  lc.classList.add('lose'); }
      else                              { lc.classList.add('tie');  rc.classList.add('tie'); }
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
    $('leftStaging').innerHTML = '';
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

    const leftPile = makeRandomPile('p1');
    const rightPile = makeRandomPile('p2');

    logLine('P1: [' + leftPile.cards.map(c => c.value).join(', ') + ']');
    logLine('P2: [' + rightPile.cards.map(c => c.value).join(', ') + ']');

    renderPile('leftCards', leftPile, null, false);
    renderPile('rightCards', rightPile, null, false);
    renderPileStack('leftStack', 10);
    renderPileStack('rightStack', 10);
    $('leftScore').textContent = 'Score: 0';
    $('rightScore').textContent = 'Score: 0';

    // Run engine now; animation is a replay of the result.
    const result = simulateBattle(leftPile, rightPile, selectFlipped);

    // Draw phase: one card at a time from each pile into staging rows.
    setStatus('Selecting 5 cards from each pile…');
    for (let i = 0; i < FLIP_COUNT; i++) {
      await sleep(TIMING.DRAW_INTERVAL);
      renderPileStack('leftStack', 10 - i - 1);
      addStagedCard('leftStaging');
      await sleep(TIMING.DRAW_OFFSET);
      renderPileStack('rightStack', 10 - i - 1);
      addStagedCard('rightStaging');
    }

    // The Hush — 5 face-down cards per side, deliberate pause.
    setStatus('The Hush — five chosen, none revealed.');
    await sleep(TIMING.HUSH);

    // Flip phase.
    let leftScore = 0, rightScore = 0;
    for (let i = 0; i < result.flips.length; i++) {
      const flip = result.flips[i];
      setStatus('Flip ' + (i + 1) + ' of ' + result.flips.length);

      // Reveal staged card values.
      revealStagedCard('leftStaging',  i, cardLabel(flip.left,  flip.leftEffective));
      revealStagedCard('rightStaging', i, cardLabel(flip.right, flip.rightEffective));

      showFlipPair(flip);

      if (flip.winner === 'left')       leftScore += 1;
      else if (flip.winner === 'right') rightScore += 1;
      $('leftScore').textContent  = 'Score: ' + leftScore;
      $('rightScore').textContent = 'Score: ' + rightScore;

      // Log this flip.
      const lVal = cardLabel(flip.left,  flip.leftEffective);
      const rVal = cardLabel(flip.right, flip.rightEffective);
      const winnerText = flip.winner === 'tie'
        ? 'tie'
        : 'P' + (flip.winner === 'left' ? '1' : '2') + ' wins by ' + flip.delta;
      logLine('Flip ' + (i + 1) + ': P1 ' + lVal + ' vs P2 ' + rVal + ' — ' + winnerText);
      flip.events.forEach(ev => {
        if (ev.trigger && ev.ability) {
          const who  = ev.side === 'left' ? 'P1' : 'P2';
          const sign = ev.delta > 0 ? '+' : '';
          const next = ev.next ? ' (next card)' : '';
          logLine('  ' + who + ' ' + ev.ability + ' [' + ev.trigger + ']: ' + sign + ev.delta + next);
        }
      });

      await sleep(TIMING.FLIP_RESULT_DELAY);
      const lOutcome = flip.winner === 'left'  ? 'win' : flip.winner === 'tie' ? 'tie' : 'lose';
      const rOutcome = flip.winner === 'right' ? 'win' : flip.winner === 'tie' ? 'tie' : 'lose';
      finishStagedCard('leftStaging',  i, lOutcome);
      finishStagedCard('rightStaging', i, rOutcome);

      await sleep(TIMING.FLIP_INTERVAL - TIMING.FLIP_RESULT_DELAY);
    }

    // Reveal Window — unflipped cards briefly shown in pile grid.
    await sleep(TIMING.REVEAL_DELAY);
    setStatus('Reveal Window — unflipped cards shown.');
    const leftFlippedIds  = new Set(result.leftFlipped.map(c => c.id));
    const rightFlippedIds = new Set(result.rightFlipped.map(c => c.id));
    renderPile('leftCards',  leftPile,  leftFlippedIds,  true);
    renderPile('rightCards', rightPile, rightFlippedIds, true);

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
