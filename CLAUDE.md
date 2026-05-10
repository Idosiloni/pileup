# Notes for Claude Code

This file is for AI assistants working in this codebase. Read it before suggesting code changes.

## Read the design docs first

Before any non-trivial change, read:
1. `docs/GAME_DESIGN.md` — the canonical design. Section 11 and 11.5 are *load-bearing*: they define the game's identity. Do not violate the locked design parameters (medium probability bend, no preview, random order with positional modifiers).
2. `docs/BRAINSTORM.md` — content brainstorm. *Reference, not prescription.* Most of the ideas in there are genre-borrowed from Oaken Tower, SAP, Bazaar, etc. Pileup deliberately rejects most of them. Use this doc to spark ideas, not as a checklist.

## Architecture rules (don't break)

**Engine vs renderer split.** The single most important architectural rule:

- `src/engine/*` is pure JavaScript. **Never** add DOM access, browser globals (window, document), animation, or timing-based code to engine files. Every function must be a pure data transformation.
- `src/renderer/*` is throwaway. It exists to make the engine visible. When the project ports to Godot/Unity, the renderer is replaced and the engine ports as data transformations.
- The renderer imports the engine via `window.PileupCards`, `window.PileupSelection`, `window.PileupBattle` (browser) or `require()` (Node). The engine does not import from the renderer.

**Why this matters:** if the engine stays pure, porting to a real game engine is a translation job. If it doesn't, porting becomes a rewrite.

## Code style

- **Plain JavaScript, no TypeScript yet.** Use JSDoc type annotations for clarity.
- **No build step, no bundler.** The prototype loads via plain `<script>` tags. Keep it that way until there's a concrete reason not to.
- **No external dependencies in the engine.** The engine must run in Node with zero installs.
- **Renderer dependencies should be minimal too.** If you reach for a framework, stop and check with the human first.

## When adding features

1. **Engine first, renderer second.** Implement the rule in `src/engine/`, write tests, then make it visible in `src/renderer/`.
2. **Add tests.** `tests/engine.test.js` is plain-Node, no framework. Append new test functions. The bar for the engine is high — every public function should have at least one test.
3. **Update the design doc** if the change touches a design decision. Do *not* let code drift away from `docs/GAME_DESIGN.md`. If you find yourself implementing something the doc doesn't describe, pause and update the doc first.

## Identity guardrails

These should never be quietly changed without explicit user approval:

- **5 of 10 partial deployment.** This is the core mechanic. Don't change FLIP_COUNT or pile size casually.
- **No preview before the battle.** Players never see which 5 will flip ahead of time. Don't add preview UIs even "just for debugging."
- **Probability bend is medium (~30-40%).** Anchor effects (full guarantees) exist but should be rare and expensive. Don't make hard guarantees easy to access.
- **Originality > genre features.** If a feature ideas comes from "X game has this," push back. Pileup's voice is the *committed chaos* feel, not a remix of genre conventions.
- **Cosmetic-only meta progression.** No power upgrades persist between runs. Ever.

## Common pitfalls

- **Don't import positional UI logic into the engine.** The engine doesn't know what "first" or "last" looks like on screen — it just knows positional sort order.
- **Don't optimize prematurely.** The game has 10 cards and 5 flips. There is no perf concern.
- **Don't add features that exist in other auto-battlers** without asking why Pileup needs them. Tags, multicast, captains, fusion — these are genre defaults, and adopting them dilutes the game's identity.

## Running and testing

```bash
node tests/engine.test.js   # run engine tests (currently 36 passing)
open index.html             # run prototype in browser (macOS); use xdg-open on Linux
```

No build step. No watch process. Edit, refresh, see changes.
