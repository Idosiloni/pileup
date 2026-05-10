/**
 * Pileup renderer — main.
 *
 * Throwaway layer. Replace entirely when porting to Godot/Unity.
 *
 * Run flow:
 *   New Run → shop phase → Battle → shop phase → … → game over
 *
 * Battle flow (manual, button-driven):
 *   For each of 5 flips: [Flip Card] → face-down → reveal → result
 *   [Continue →] → back to shop (or game over)
 */

(function () {
  'use strict';

  // Engine imports
  const { makeRandomPile, upgradeCardValue } = window.PileupCards;
  const { selectFlipped, flipProbabilities, pileStats, FLIP_COUNT } = window.PileupSelection;
  const { ABILITIES } = window.PileupAbilities;
  const { JOKERS, JOKER_POOL } = window.PileupJokers;
  const { simulateBattle } = window.PileupBattle;
  const { makeRun, buyCard, sellCard, upgradeCard, buyJoker, canBuy, canSell,
          canUpgrade, canBuyJoker, effectivePileCap,
          applyBattleResult, CARD_COST, SELL_COST, MIN_PILE_SIZE, STARTING_HP, UPGRADE_COST } = window.PileupRun;
  const { generateShop, REROLL_COST } = window.PileupShop;

  const TIMING = {
    FACE_DOWN: 360,   // ms face-down before revealing
    RESULT:    100,   // ms after reveal before win/lose color
    INTERVAL: 1200,   // total ms per flip (FACE_DOWN + RESULT + viewing)
    REVEAL:    700,   // ms before Reveal Window
  };

  const $ = id => document.getElementById(id);

  let run            = null;
  let currentShop    = null;
  let frozenIndices  = new Set();  // shop card indices that survive a reroll
  let battleActive   = false;
  let flipResolve    = null;  // resolves when player presses Flip / Continue

  // ------------------------------------------------------------------
  // Flip / Continue button
  // ------------------------------------------------------------------

  function waitForButton(label) {
    const btn = $('flipBtn');
    btn.textContent = label;
    btn.disabled    = false;
    return new Promise(resolve => { flipResolve = resolve; });
  }

  // ------------------------------------------------------------------
  // Run status bar
  // ------------------------------------------------------------------

  function updateRunStatus() {
    $('playerHP').textContent     = run.playerHP;
    $('aiHP').textContent         = run.aiHP;
    $('goldLabel').textContent    = run.gold + 'g';
    $('manaLabel').textContent    = run.mana + 'm';
    $('roundLabel').textContent   = 'Round ' + run.round;
    $('playerHPFill').style.width = Math.max(0, run.playerHP / STARTING_HP * 100) + '%';
    $('aiHPFill').style.width     = Math.max(0, run.aiHP     / STARTING_HP * 100) + '%';
    $('jokerLabel').textContent   = run.joker ? JOKERS[run.joker].name : '';
  }

  // ------------------------------------------------------------------
  // Shop phase
  // ------------------------------------------------------------------

  function showShopPhase() {
    $('shopSection').hidden    = false;
    $('battleSection').hidden  = true;
    // Keep frozen cards, regenerate unfrozen slots
    const prevCards  = currentShop ? currentShop.cards : [];
    const newShop    = generateShop(run.round);
    const mergedCards = [];
    for (let i = 0; i < 4; i++) {
      mergedCards.push(frozenIndices.has(i) && prevCards[i] ? prevCards[i] : newShop.cards[i]);
    }
    currentShop = { cards: mergedCards };
    frozenIndices = new Set();  // freeze expires when entering shop (cards are now "this turn's" shop)
    renderShop();
    renderJokerShop();
    renderShopPile();
    updateRunStatus();
  }

  function renderJokerShop() {
    const slot = $('jokerShopSlot');
    slot.innerHTML = '';
    const hint = $('jokerShopHint');

    if (run.joker) {
      // Show active Joker
      const active = document.createElement('div');
      active.className = 'joker-card joker-card-active';
      const nameEl = document.createElement('span');
      nameEl.className = 'joker-name';
      nameEl.textContent = JOKERS[run.joker].name;
      const descEl = document.createElement('span');
      descEl.className = 'joker-desc';
      descEl.textContent = JOKERS[run.joker].description;
      active.appendChild(nameEl);
      active.appendChild(descEl);
      slot.appendChild(active);
      hint.textContent = 'Active Joker';
      return;
    }

    hint.textContent = 'One Joker per run';
    // Offer 3 random Jokers to buy
    const offered = [];
    const pool = JOKER_POOL.slice();
    for (let i = 0; i < 3 && pool.length > 0; i++) {
      const idx = Math.floor(Math.random() * pool.length);
      offered.push(pool.splice(idx, 1)[0]);
    }
    offered.forEach(jokerId => {
      const j = JOKERS[jokerId];
      const card = document.createElement('div');
      card.className = 'joker-card';
      const nameEl = document.createElement('span');
      nameEl.className = 'joker-name';
      nameEl.textContent = j.name;
      const descEl = document.createElement('span');
      descEl.className = 'joker-desc';
      descEl.textContent = j.description;
      const buyBtn = document.createElement('button');
      buyBtn.className = 'btn-buy';
      buyBtn.textContent = j.cost + 'g — Buy';
      buyBtn.disabled = !canBuyJoker(run, jokerId);
      buyBtn.addEventListener('click', () => {
        run = buyJoker(run, jokerId);
        updateRunStatus();
        renderJokerShop();
        renderShopPile();
      });
      card.appendChild(nameEl);
      card.appendChild(descEl);
      card.appendChild(buyBtn);
      slot.appendChild(card);
    });
  }

  function renderShop() {
    const container = $('shopCards');
    container.innerHTML = '';
    currentShop.cards.forEach((card, idx) => {
      const wrap = document.createElement('div');
      wrap.className = 'shop-card' + (frozenIndices.has(idx) ? ' shop-card-frozen' : '');

      // --- card preview ---
      const preview = document.createElement('div');
      preview.className = 'shop-card-preview';

      const valEl = document.createElement('span');
      valEl.className   = 'shop-card-value';
      valEl.textContent = card.value;
      preview.appendChild(valEl);

      if (card.weight !== 0) {
        const wEl = document.createElement('span');
        wEl.className   = 'shop-card-meta';
        wEl.textContent = (card.weight > 0 ? '+' : '') + card.weight + ' weight';
        preview.appendChild(wEl);
      }

      if (card.ability && ABILITIES[card.ability]) {
        const ablEl = document.createElement('span');
        ablEl.className   = 'shop-card-meta shop-card-ability-text';
        ablEl.textContent = ABILITIES[card.ability].description;
        preview.appendChild(ablEl);
      }

      // --- bottom row: freeze + buy ---
      const bottomRow = document.createElement('div');
      bottomRow.className = 'shop-card-actions';

      const freezeBtn = document.createElement('button');
      freezeBtn.className   = 'btn-freeze';
      freezeBtn.textContent = frozenIndices.has(idx) ? '❄ Frozen' : 'Freeze';
      freezeBtn.addEventListener('click', () => {
        if (frozenIndices.has(idx)) frozenIndices.delete(idx);
        else                         frozenIndices.add(idx);
        renderShop();
      });

      const buyBtn = document.createElement('button');
      buyBtn.className   = 'btn-buy';
      buyBtn.textContent = CARD_COST + 'g — Buy';
      buyBtn.disabled    = !canBuy(run);
      buyBtn.addEventListener('click', () => {
        run = buyCard(run, card);
        frozenIndices.delete(idx);
        updateRunStatus();
        wrap.remove();
        renderShopPile();
        $('shopCards').querySelectorAll('.btn-buy').forEach(b => {
          b.disabled = !canBuy(run);
        });
      });

      bottomRow.appendChild(freezeBtn);
      bottomRow.appendChild(buyBtn);
      wrap.appendChild(preview);
      wrap.appendChild(bottomRow);
      container.appendChild(wrap);
    });
  }

  function renderShopPile() {
    const container = $('shopPlayerPile');
    container.innerHTML = '';
    const cap = effectivePileCap(run);
    $('pileCount').textContent = run.playerPile.cards.length + ' / ' + cap;

    // Pile composition feedback (Section 11.5)
    const stats = pileStats(run.playerPile);
    const statsEl = document.createElement('div');
    statsEl.className = 'pile-stats';
    statsEl.innerHTML =
      '<span>avg <b>' + stats.avgValue + '</b></span>' +
      '<span>' + stats.oddCount + ' odd / ' + stats.evenCount + ' even</span>' +
      '<span>exp <b>' + stats.expectedValue + '</b></span>' +
      (stats.totalWeight !== 0
        ? '<span>weight <b>' + (stats.totalWeight > 0 ? '+' : '') + stats.totalWeight + '</b></span>'
        : '');
    container.appendChild(statsEl);
    const probs = flipProbabilities(run.playerPile);

    run.playerPile.cards.forEach((card, i) => {
      const row = document.createElement('div');
      row.className = 'shop-pile-row';

      // card info
      const info = document.createElement('div');
      info.className = 'shop-pile-info';

      const valEl = document.createElement('span');
      valEl.className   = 'shop-pile-value';
      valEl.textContent = card.value;

      const probEl = document.createElement('span');
      probEl.className   = 'card-prob';
      probEl.textContent = probs[i] + '%';

      info.appendChild(valEl);
      info.appendChild(probEl);

      if (card.weight !== 0) {
        const wEl = document.createElement('span');
        wEl.className   = 'card-prob';
        wEl.textContent = (card.weight > 0 ? '+' : '') + card.weight + 'w';
        info.appendChild(wEl);
      }

      if (card.ability && ABILITIES[card.ability]) {
        const ablEl = document.createElement('span');
        ablEl.className   = 'card-ability';
        ablEl.textContent = ABILITIES[card.ability].label;
        info.appendChild(ablEl);
      }

      // upgrade button
      const upBtn = document.createElement('button');
      upBtn.className   = 'btn-upgrade';
      upBtn.textContent = '+1 (' + UPGRADE_COST + 'm)';
      upBtn.disabled    = !canUpgrade(run);
      upBtn.addEventListener('click', () => {
        run = upgradeCard(run, card.id);
        updateRunStatus();
        renderShopPile();
      });

      // sell button
      const sellBtn = document.createElement('button');
      sellBtn.className   = 'btn-sell';
      sellBtn.textContent = 'Sell -' + SELL_COST + 'g';
      sellBtn.disabled    = !canSell(run, card.id);
      sellBtn.addEventListener('click', () => {
        run = sellCard(run, card.id);
        updateRunStatus();
        renderShopPile();
        $('shopCards').querySelectorAll('.btn-buy').forEach(b => {
          b.disabled = !canBuy(run);
        });
      });

      row.appendChild(info);
      row.appendChild(upBtn);
      row.appendChild(sellBtn);
      container.appendChild(row);
    });
  }

  // ------------------------------------------------------------------
  // Battle phase
  // ------------------------------------------------------------------

  function showBattlePhase() {
    $('shopSection').hidden   = true;
    $('battleSection').hidden = false;
    runBattle();
  }

  async function runBattle() {
    if (battleActive) return;
    battleActive = true;

    $('log').innerHTML = '';
    clearArena();

    const leftPile  = run.playerPile;          // player's built pile
    const rightPile = makeRandomPile('ai');     // AI gets fresh random pile

    logLine('You:  [' + leftPile.cards.map(c => c.value).join(', ') + ']');
    logLine('AI:   [' + rightPile.cards.map(c => c.value).join(', ') + ']');

    renderPile('leftCards',  leftPile,  null, false);
    renderPile('rightCards', rightPile, null, false);
    renderPileStack('leftStack',  leftPile.cards.length);
    renderPileStack('rightStack', rightPile.cards.length);
    $('leftScore').textContent  = 'Score: 0';
    $('rightScore').textContent = 'Score: 0';

    // Engine resolves the whole battle up front; animation is a replay.
    const result = simulateBattle(leftPile, rightPile, selectFlipped, run.joker);

    let leftScore = 0, rightScore = 0;
    const leftFlippedSet  = new Set();
    const rightFlippedSet = new Set();
    const leftTotal  = leftPile.cards.length;
    const rightTotal = rightPile.cards.length;

    for (let i = 0; i < result.flips.length; i++) {
      const flip = result.flips[i];

      // Player presses Flip Card
      setStatus('Press Flip Card — flip ' + (i + 1) + ' of ' + FLIP_COUNT);
      await waitForButton('Flip Card');

      // Both piles lose one card
      renderPileStack('leftStack',  leftTotal  - i - 1);
      renderPileStack('rightStack', rightTotal - i - 1);
      setStatus('Flip ' + (i + 1) + ' of ' + FLIP_COUNT);

      // Cards placed face-down
      showFaceDownPair();
      await sleep(TIMING.FACE_DOWN);

      // Reveal
      revealFlipPair(flip);
      await sleep(TIMING.RESULT + 120);

      // Score
      if (flip.winner === 'left')       leftScore++;
      else if (flip.winner === 'right') rightScore++;
      $('leftScore').textContent  = 'Score: ' + leftScore;
      $('rightScore').textContent = 'Score: ' + rightScore;

      // Running history
      const lOut = flip.winner === 'left'  ? 'win' : flip.winner === 'tie' ? 'tie' : 'lose';
      const rOut = flip.winner === 'right' ? 'win' : flip.winner === 'tie' ? 'tie' : 'lose';
      addHistoryCard('leftStaging',  cardLabel(flip.left,  flip.leftEffective),  lOut);
      addHistoryCard('rightStaging', cardLabel(flip.right, flip.rightEffective), rOut);

      // Highlight drawn card in pile grid
      leftFlippedSet.add(flip.left.id);
      rightFlippedSet.add(flip.right.id);
      renderPile('leftCards',  leftPile,  leftFlippedSet,  false);
      renderPile('rightCards', rightPile, rightFlippedSet, false);

      // Log
      const who     = flip.winner === 'tie' ? 'tie' : (flip.winner === 'left' ? 'You' : 'AI') + ' +' + flip.delta;
      logLine('Flip ' + (i + 1) + ': You ' + cardLabel(flip.left, flip.leftEffective)
        + ' vs AI ' + cardLabel(flip.right, flip.rightEffective) + ' — ' + who);
      flip.events.forEach(ev => {
        if (ev.trigger && ev.ability) {
          const side = ev.side === 'left' ? 'You' : 'AI';
          const sign = ev.delta > 0 ? '+' : '';
          logLine('  ' + side + ' ' + ev.ability + ' [' + ev.trigger + ']: ' + sign + ev.delta + (ev.next ? ' (next)' : ''));
        }
      });
    }

    // Reveal Window
    await sleep(TIMING.REVEAL);
    setStatus('Reveal Window — unflipped cards shown.');
    renderPile('leftCards',  leftPile,  leftFlippedSet,  true);
    renderPile('rightCards', rightPile, rightFlippedSet, true);

    const winText = result.winner === 'tie'
      ? 'Tied ' + leftScore + '–' + rightScore
      : (result.winner === 'left' ? 'You win' : 'AI wins') + ' '
        + Math.max(leftScore, rightScore) + '–' + Math.min(leftScore, rightScore);
    $('resultDisplay').textContent = winText;
    logLine('=== ' + winText + ' ===');

    // Apply to run state
    const battleWinner = result.winner === 'left' ? 'player' : result.winner === 'right' ? 'ai' : 'tie';
    const prevMana = run.mana;
    run = applyBattleResult(run, {
      winner:         battleWinner,
      margin:         result.margin,
      goldBonus:      result.leftGoldBonus,
      jokerManaBonus: result.jokerManaBonus
    });
    const manaGained = run.mana - prevMana;
    logLine('+' + manaGained + 'm earned'
      + (result.leftGoldBonus  > 0 ? ', +' + result.leftGoldBonus  + 'g comeback' : '')
      + (result.jokerManaBonus > 0 ? ', +' + result.jokerManaBonus + 'm (Joker)'  : '')
      + ' (' + run.mana + 'm total)');
    updateRunStatus();

    battleActive = false;

    // Player presses Continue
    if (run.phase === 'over') {
      const runWinner = run.playerHP <= 0 ? 'AI wins the run!' : 'You win the run!';
      setStatus(runWinner + ' Press "New Run" to play again.');
      $('runStatus').hidden = true;
      await waitForButton('New Run');
      startNewRun();
    } else {
      await waitForButton('Continue →');
      showShopPhase();
    }
  }

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
      if (count > 2) { const g = document.createElement('div'); g.className = 'stack-ghost g1'; art.appendChild(g); }
      if (count > 1) { const g = document.createElement('div'); g.className = 'stack-ghost g2'; art.appendChild(g); }
      const top = document.createElement('div');
      top.className = 'stack-top';
      const cEl = document.createElement('span'); cEl.className = 'stack-count'; cEl.textContent = count;
      const lEl = document.createElement('span'); lEl.className = 'stack-label'; lEl.textContent = count === 1 ? 'card' : 'cards';
      top.appendChild(cEl); top.appendChild(lEl);
      art.appendChild(top);
    }
    wrap.appendChild(art);
  }

  // ------------------------------------------------------------------
  // Arena helpers
  // ------------------------------------------------------------------

  function showFaceDownPair() {
    const display = $('flipDisplay');
    display.innerHTML = '';
    const lc = document.createElement('div'); lc.className = 'card-big card-face-down';
    const vs = document.createElement('div'); vs.className = 'vs'; vs.textContent = 'vs';
    const rc = document.createElement('div'); rc.className = 'card-big card-face-down';
    display.appendChild(lc); display.appendChild(vs); display.appendChild(rc);
  }

  function revealFlipPair(flip) {
    const cards = $('flipDisplay').querySelectorAll('.card-big');
    if (cards.length < 2) return;
    const lc = cards[0], rc = cards[1];
    lc.classList.remove('card-face-down'); rc.classList.remove('card-face-down');
    lc.textContent = cardLabel(flip.left,  flip.leftEffective);
    rc.textContent = cardLabel(flip.right, flip.rightEffective);
    setTimeout(() => {
      if (flip.winner === 'left')       { lc.classList.add('win');  rc.classList.add('lose'); }
      else if (flip.winner === 'right') { rc.classList.add('win');  lc.classList.add('lose'); }
      else                              { lc.classList.add('tie');  rc.classList.add('tie');  }
    }, TIMING.RESULT);
  }

  function addHistoryCard(id, label, outcome) {
    const card = document.createElement('div');
    card.className = 'card-staged face-up ' + outcome;
    card.textContent = label;
    $(id).appendChild(card);
    requestAnimationFrame(() => requestAnimationFrame(() => card.classList.add('visible')));
  }

  function setStatus(text)  { $('arenaStatus').textContent = text; }
  function clearArena() {
    $('flipDisplay').innerHTML   = '';
    $('resultDisplay').innerHTML = '';
    $('leftStaging').innerHTML   = '';
    $('rightStaging').innerHTML  = '';
    $('flipBtn').disabled        = true;
    $('flipBtn').textContent     = 'Flip Card';
  }

  // ------------------------------------------------------------------
  // Pile grid
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
      const vEl = document.createElement('span'); vEl.textContent = card.value;
      const pEl = document.createElement('span'); pEl.className = 'card-prob'; pEl.textContent = probs[i] + '%';
      div.appendChild(vEl); div.appendChild(pEl);
      if (card.ability && ABILITIES[card.ability]) {
        const aEl = document.createElement('span'); aEl.className = 'card-ability';
        aEl.textContent = ABILITIES[card.ability].label; div.appendChild(aEl);
      }
      container.appendChild(div);
    });
  }

  function cardLabel(card, eff) {
    return (eff !== undefined && eff !== card.value) ? card.value + '→' + eff : String(card.value);
  }

  function logLine(msg) {
    const el = $('log');
    const line = document.createElement('div'); line.textContent = msg;
    el.appendChild(line); el.scrollTop = el.scrollHeight;
  }

  function sleep(ms) { return new Promise(r => setTimeout(r, ms)); }

  // ------------------------------------------------------------------
  // Boot
  // ------------------------------------------------------------------

  function startNewRun() {
    run = makeRun();
    $('runStatus').hidden = false;
    showShopPhase();
  }

  function boot() {
    // Flip / Continue button — single handler, resolved by waitForButton()
    $('flipBtn').addEventListener('click', () => {
      if (flipResolve) {
        $('flipBtn').disabled = true;
        const resolve = flipResolve;
        flipResolve = null;
        resolve();
      }
    });

    $('newRunBtn').addEventListener('click', startNewRun);

    $('rerollBtn').addEventListener('click', () => {
      if (!run || run.gold < REROLL_COST) return;
      run = Object.assign({}, run, { gold: run.gold - REROLL_COST });
      updateRunStatus();
      const fresh = generateShop(run.round);
      const merged = currentShop.cards.map((c, i) => frozenIndices.has(i) ? c : fresh.cards[i]);
      currentShop = { cards: merged };
      renderShop();
    });

    $('toBattleBtn').addEventListener('click', showBattlePhase);
  }

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', boot);
  } else {
    boot();
  }
})();
