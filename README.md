# Pileup

An 8-player online auto-battler card game. War's simplicity meets Super Auto Pets' shop loop, Hearthstone Battlegrounds' lobby format, and Balatro's run-defining modifiers — but the core mechanic is something none of those games have: **partial deployment with loaded dice.**

You build a 10-card pile knowing only 5 will flip in battle. You can tilt the odds (probability weighting), but you can never fully control them. The shop is the calm, planning phase. The battle is a 30-second adrenaline ride where you have no real-time controls — your committed bet either pays off or it doesn't. Pileup is poker pre-flop turned into a deckbuilder.

## Read these first

Anyone (human or AI) joining this project should read these documents before writing code. They contain the full design philosophy, locked decisions, open questions, and brainstormed content space.

- **[docs/GAME_DESIGN.md](docs/GAME_DESIGN.md)** — the canonical design doc. Section 11 (the 5-of-10 selection) and Section 11.5 (Original Mechanics) are the *soul of the game*. Everything else flows from them.
- **[docs/BRAINSTORM.md](docs/BRAINSTORM.md)** — a research-fueled library of card ideas, perks, Jokers, and lessons from the genre. Treat as a *menu, not a mandate*. Pick what amplifies the core; ignore the rest.

## Project structure

```
pileup/
├── README.md                 ← you are here
├── index.html                ← prototype entry point (open in browser)
├── docs/
│   ├── GAME_DESIGN.md        ← design doc
│   └── BRAINSTORM.md         ← content brainstorm + genre research
├── src/
│   ├── engine/               ← PURE LOGIC, no DOM. Ports cleanly to any engine.
│   │   ├── cards.js          ← card and pile creation
│   │   ├── selection.js      ← weighted random selection (the heart of Pileup)
│   │   ├── battle.js         ← battle resolution
│   │   └── index.js          ← Node entry (combines modules for tests)
│   └── renderer/             ← THROWAWAY. HTML/CSS/animation. Replaced when porting.
│       ├── main.js           ← orchestrates engine output into animated UI
│       └── styles.css
└── tests/
    └── engine.test.js        ← engine tests (run with: node tests/engine.test.js)
```

### Why the engine/renderer split

Pileup will eventually publish on Steam, mobile, or both. The right engine for that is probably **Godot 4** (free, open-source, good 2D, great Steam export — Backpack Battles ships on it) or Unity. But starting in Godot today means slow iteration and you can't easily share progress.

So: **prototype in HTML/JS, but architect for portability.**

- The engine (`src/engine/*`) is pure JavaScript — zero DOM, zero rendering, zero animation. Every function is a pure data transformation. When you port to GDScript, C#, or any backend, these files translate almost line-for-line. *This is the part you keep forever.*
- The renderer (`src/renderer/*`) is HTML, CSS, animation. It exists to make the engine *visible*. When you move to a real game engine, you replace it entirely. *This is the throwaway part.*

The split is enforced by file location and by the dependency-injection pattern in `simulateBattle(left, right, selectionFn)` — engine code never assumes a specific environment.

## Run the prototype

```bash
# Open index.html in a browser. No build step, no dependencies.
# On macOS:
open index.html

# On Linux:
xdg-open index.html

# Or just drag index.html into Chrome/Firefox.
```

## Run the tests

```bash
node tests/engine.test.js
```

Plain Node, no test framework dependency. Currently 36 tests covering pile creation, weighted selection, positional traits, probability calculations, and battle resolution.

## Current status (v0.1)

**What works:**
- Random 10-card pile generation
- Weighted random selection of 5 cards (the core mechanic)
- Positional traits: `position: 'first'` and `position: 'last'`
- Battle resolution: 5 head-to-head flips, score tally, win/loss/tie
- Renderer with the Hush, animated flips, and Reveal Window (locked design from GAME_DESIGN.md Section 11.5)
- Engine tests passing

**What's missing on purpose:**
- No card abilities yet (every card is just a number)
- No visible probability percentages on cards (TODO for v0.2)
- No shop, no economy, no Jokers
- No HP, no run structure, no opponent variety
- No 8-player lobby

## Roadmap

Suggested progression (each step builds on the last):

1. **v0.2 — Visible probabilities.** Display each card's flip % in the pile UI. Add 2-3 probability-modifier cards to the pile generator.
2. **v0.3 — Card abilities.** Implement the trigger vocabulary (On Reveal, On Win, On Loss). Add a small set of starter abilities. Update the battle resolver to fire ability events.
3. **v0.4 — Single-player shop.** Build a pile against a fixed AI pile, with a simple shop turn between battles. Validates the economy.
4. **v0.5 — Full single-player run.** Multiple battles, HP, elimination, end-of-run state. This is the playable proof-of-concept.
5. **v0.6 — First Joker.** Implement one Joker that warps a battle rule. Tests the run-modifier architecture.
6. **v1.0 — port to Godot.** Once the rules feel right, rebuild in Godot for proper publishing. Engine logic translates directly; renderer is rewritten as Godot scenes/scripts.

## Design principles (don't break these)

From `docs/GAME_DESIGN.md` Section 15:

- **Originality over genre-borrowing.** Pileup's voice is committed chaos via partial deployment with loaded dice. Resist importing genre defaults from SAP / Bazaar / Oaken Tower / Battlegrounds unless they directly serve this identity.
- **Readability first.** Numbers 1–10 are universal. Don't break this.
- **Luck is a feature, never a bug.** No-preview is non-negotiable. Anchor effects exist but are rare and expensive. Players tilt odds; they never eliminate them.
- **Skill expresses through building, not playing.** The battle auto-resolves. All decisions live in the shop.
- **Fairness over grind.** Cosmetic-only meta progression. New players never disadvantaged.

## Working title

**Pileup** — chosen because it's both literally the pile of cards and metaphorically the chaos of a 5-of-10 reveal. May change.
