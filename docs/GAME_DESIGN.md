# Pileup — Game Design Document

*(Working title — subject to change)*

> An 8-player online auto-battler card game. War's simplicity meets Super Auto Pets' shop loop, Hearthstone Battlegrounds' lobby format, and Balatro's run-defining modifiers.

---

## 1. Core Pitch

A competitive online auto-battler where 8 players each build a 10-card pile of numbered cards (values 1–10, like the card game War). Each round, players are matched against each other and their piles auto-fight: 5 random cards from each pile flip in sequence, higher value wins the skirmish, most skirmishes won wins the battle. The loser takes HP damage. Last player with HP standing wins the run.

The game lives in the tension between three things:
- **Skill** — building a synergistic 10-card pile and choosing the right upgrades and Jokers.
- **Luck** — only 5 of your 10 cards flip per battle, randomly. Which 5 flip is part of the drama.
- **Run variance** — Balatro-style global perks (Jokers) reshape the rules each run, making no two runs feel the same.

---

## 2. Genre & References

**Direct inspirations:**
- **Super Auto Pets** — async/lobby auto-battler structure, shop-then-battle loop, HP elimination
- **Hearthstone Battlegrounds** — 8-player lobby format, last-pile-standing
- **Balatro** — run-defining Joker modifiers that warp the base ruleset
- **War (the card game)** — instantly readable "higher number wins" base mechanic

**Genre:** Competitive auto-battler / deckbuilder hybrid.

---

## 3. The Match Loop (One Round)

Every round in a lobby follows this structure:

1. **Shop phase** (~60–90 seconds)
   - Player has a budget of gold (refills each turn) and accumulated mana (persistent).
   - Player can buy cards, sell cards, reroll the shop, freeze shop slots, buy Jokers, and spend mana on permanent buffs.
   - Pile must end the shop phase at no more than 10 cards (cap; archetypes may push for fewer).

2. **Matchmaking** — players paired with another live player (or a ghost pile in async mode).

3. **Battle phase** (~30 seconds, auto-resolves)
   - Both players' piles are shuffled.
   - **5 cards from each pile** are randomly selected to flip (out of 10).
   - The 5 cards flip one at a time, in order, head-to-head.
   - Each flip: higher value wins → 1 point. Ties handled per current rules / Joker effects.
   - Card abilities trigger on flip events (see Section 6).
   - Most points across the 5 flips wins the battle.

4. **Resolution**
   - Loser takes HP damage proportional to the point margin (e.g. 1–3 HP).
   - Winner gets bonus mana (e.g. +2 mana on win, +1 on loss).
   - Eliminated players (0 HP) watch the rest of the run.
   - Run ends when one player remains.

**Target run length:** ~25–30 minutes for an 8-player lobby.

---

## 4. The 8-Player Lobby Structure

- 8 players start with full HP (e.g. 25 HP — tunable).
- Each round, players pair off → 4 simultaneous battles.
- Damage scales with margin of defeat.
- Eliminated players are removed; remaining players continue pairing.
- When only one player has HP > 0, that player wins the lobby.

**Async mode (v1 priority):** if 8 live players aren't available, fill seats with "ghost piles" — saved piles from prior players' runs at similar progression. SAP-style.

**Live PvP (v2):** real matchmaking with concurrent shop timers and live opponents.

---

## 5. The Pile (Deck)

- **Size:** 10 cards (cap; pile can be smaller, archetypes may exploit this).
- **Card values:** 1–10. Higher value wins skirmishes.
- **Starter pile:** All 8 players begin every run with the **same** starter pile (TBD — see open questions).
- **Selection on battle:** 5 of 10 cards selected at random per battle. Most cards have no control over whether they're picked. A small subset of card abilities and Jokers can influence selection (anchor effects, swaps, scrying).
- **Pile thickness as strategy:** A 10-card pile dilutes your best cards but gives more variety; a 6-card pile (sold down) means key cards always show up. Both should be viable archetypes.

---

## 6. Card Abilities & Perks

Abilities split into two clear tiers: **card-specific** (attached to one card in your pile) and **global / Joker** (affect the whole run, all your cards, or the rules of battle itself).

### Card-specific abilities (the four categories)

**1. Number shifts** — the foundation. Simple stat mods.
  - "+1 to this card's value"
  - "-2 to opponent's card when this flips"
  - "+1 to all your 7s for this battle"
  - Easy to understand, easy to combine, the bread and butter of the upgrade economy.

**2. Pair synergies** — payoffs when both players play matching values.
  - "If you and your opponent both flip a 4: gain +2 to all your 4s for the rest of the battle."
  - Triggers rarely (because exact matches are uncommon) so the payoff can be juicy.
  - Rewards deckbuilding around specific values to fish for the synergy.

**3. Comeback mechanics** — payoffs for losing badly.
  - "If you lose this skirmish by 8 or more: gain 3 gold."
  - "When this card loses to a card 5+ higher: gain 2 mana."
  - Makes blowout losses *interesting* instead of just sad. Players actually root for chaos.
  - Pairs naturally with low-value cards becoming "engine" pieces.

**4. Probability weighting** — control which cards are more likely to appear in the 5-of-10 draw.
  - "Your 10s are 15% more likely to flip in battle."
  - "Your 1s are 50% less likely to flip."
  - Doesn't *guarantee* outcomes — loads the dice. Preserves luck while granting agency.
  - Creates real archetypal tension: weight up high cards, or weight down low cards?

### Global / Joker abilities

These affect the entire run or all your cards. They're the **Balatro layer** — they *warp the rules*, forcing players to build around them rather than just stacking generic power.

Examples:
- "If both players flip odd cards: both cards get +1."
- "If both players flip even cards: yours triggers its ability twice."
- "Ties count as wins for you."
- "Your highest card is always among the 5 that flip."
- "Battles last 3 flips instead of 5."

When you buy a Joker, your *entire build pivots* around it. That's the engine of run-to-run variance.

### Trigger vocabulary

Card abilities use a small set of trigger events so the language stays consistent:

- **On Reveal** — when this card flips
- **On Win** — this card won its skirmish
- **On Loss** — this card lost its skirmish
- **On Tie** — exact-value match
- **Passive** — always active while in pile
- **On Buy / On Sell** — shop-phase triggers
- **On Battle Start** — fires once per battle, before flips

**Design principle:** Numbers stay readable (1–10). The depth comes from ability layering and Joker interactions — not from inflated values.

---

## 7. Currency System

Two currencies, each with a clear and separate role:

### Gold (turn currency)
- **Refills** to a base amount (e.g. 10) every shop turn.
- **Doesn't carry over** — use it or lose it.
- **Spent on:** buying cards, rerolling shop, selling cards (some refund), freezing shop slots, buying Jokers.
- **Role:** tactical roster management.

### Mana (run currency)
- **Earned by:** winning battles (+2), losing battles (+1), specific card abilities, Joker effects.
- **Persists** across turns within a run.
- **Spent on:** permanent buffs to individual cards (the primary upgrade path).
- **Role:** strategic power growth.

**Why two currencies:** The split prevents the shop from feeling one-note. Gold answers "what's in my pile?"; mana answers "what gets stronger?" They don't compete for the same budget, so each shop turn presents two distinct decision spaces.

---

## 8. The Shop Phase

Each shop turn, the player can:

- **Buy a card** (e.g. 3 gold) — adds to pile, capped at 10.
- **Sell a card** (refunds 1 gold + 1 mana) — frees a slot, recovers value.
- **Reroll the shop** (1 gold) — refresh offered cards.
- **Freeze a shop slot** (free) — keep a specific card available next turn.
- **Buy a Joker** (premium gold cost or mana cost — TBD) — global run-modifier.
- **Spend mana on permanent buffs** (see below).
- **Level up the shop tier** (gold cost, optional) — unlocks higher-tier cards earlier.

**Shop tier curve** (recommended starting point):

| Round | Max card tier | Card values seen |
|-------|---------------|------------------|
| 1–2   | 1             | 1, 2, 3          |
| 3–4   | 2             | up to 5          |
| 5–6   | 3             | up to 7          |
| 7–8   | 4             | up to 9          |
| 9+    | 5             | up to 10 + legendaries |

This gates raw power so players can't rush 10s on round 1. It mirrors SAP's tier system and Battlegrounds' tavern tiers.

---

## 9. Permanent Buffs (Primary Upgrade Path)

The main way players strengthen their pile mid-run. Spent with mana. Scales with impact:

- **+1 value** (e.g. 3 mana): A 5 becomes a 6.
- **+1 ability magnitude** (e.g. 2 mana): "gain 2 gold" becomes "gain 3 gold."
- **Add a keyword** (e.g. 5 mana): Give a card "Pierce" (wins ties), "Echo" (triggers ability twice), "Anchor" (always among the 5 flipped), etc.
- **Evolve** (e.g. 8 mana): Transform a card into a souped-up version with new art, stronger ability, +1–2 value.

**Target pacing:** A run should let a player make ~4–6 meaningful upgrades total. Enough to feel built, not enough to max everything.

---

## 10. Jokers (Global Run Modifiers — Balatro Layer)

Jokers are run-defining items that warp the rules of the entire game for that player. They're the primary source of run-to-run variance and the "every run feels different" magic.

**Slot count:** TBD (open question — see Section 13). Likely 1–3.

**Where they come from:** Earned in shop (premium cost), as battle rewards, or in a separate Joker shop track.

**Example Jokers:**

| Name           | Effect                                                              |
|----------------|---------------------------------------------------------------------|
| Tiebreaker     | Draws count as wins for you                                         |
| Underdog       | When your card has lower value, it gains +X                         |
| Streak         | Each consecutive win this battle adds +1 to next flip               |
| Coin Flip      | At battle start, flip a coin — doubled gold on win, half on loss    |
| Sniper         | Your highest card is always among the 5 that flip                   |
| Gambler        | Battles last 4 flips instead of 5; ties give double mana            |
| Echo Chamber   | Every 5th flip in a battle triggers its ability twice               |
| Curator        | Removing cards from your pile is free                               |
| Hoarder        | Pile cap raised to 12                                               |
| Speed Run      | Battles end after 3 flips instead of 5                              |
| Pyromancer     | All 1s deal 1 damage on loss instead of triggering normal effect    |
| Doubles Down   | Pairs of identical values in your flipped 5 give +2 to both         |

**Design principle:** Jokers should *change how you build*, not just give numbers. A Tiebreaker player builds a different pile than a Sniper player.

---

## 11. The 5-of-10 Selection (Core Tension)

The single most distinctive mechanic in this game. Half your pile doesn't flip in any given battle. This is not a flaw to engineer around — it is **the experience.**

**Pileup's identity in one sentence:** *Build a 10-card pile knowing only 5 will flip, tilt the odds with weighted probability, and watch your bet resolve.*

The closest emotional analog isn't another auto-battler — it's the moment in poker where you've committed your chips pre-flop and you're watching the river hit. You did your math. You committed. Now the universe decides. Pileup is *that feeling, on loop, for 25 minutes*. The shop is the calm; the battle is the reveal.

### Locked design parameters

These three answers, taken together, define the soul of Pileup. They are non-negotiable; everything else flows from them.

**1. Probability bend: Medium (~30–40%).**
Players can shift flip-chance weights freely (e.g. ±15–20% per card via abilities and Jokers). **Anchor** effects — *guaranteeing* a card flips — exist but are rare, expensive, and build-around. Most of a player's skill expression lives in soft odds-tilting, not hard guarantees. A typical run might see one or two Anchors.

**2. No preview.**
Players do not see which 5 of their 10 cards will flip until they flip. The reveal is the experience. Previewing would convert the game into a known-outcome execution puzzle — instead, every flip is a moment of discovery.

**3. Random order with positional modifiers.**
Flip order within a battle is random, except where specific cards have positional traits (e.g. *First Light* — always flips first if drawn; *Grand Finale* — always flips last). Most cards are pure random order; positional cards are a deliberate, build-around archetype.

### Tools players have

- **Probability weighting** — abilities and Jokers that shift flip chances (the primary skill axis).
- **Anchor** — rare and expensive guarantees that a card flips.
- **Cull** — remove a card from your pile for this battle only.
- **Pile sizing** — selling cards down to <10 increases flip odds for remaining cards.
- **Positional traits** — *First Light*, *Grand Finale*, etc. that influence order.

Note: **Scry / preview is explicitly NOT a tool.** Earlier drafts considered it; it has been ruled out as it would weaken the no-preview design parameter above.

### Feel goal

Every battle should feel like *committed chaos*. The player did their math during the calm of the shop. The 30-second battle is them watching their committed bet pay off — or not. Skill is not in real-time decisions; it's in pre-bet preparation. This rhythm is what makes Pileup mechanically distinct from every other auto-battler in the genre.

---

## 11.5. Original Mechanics (Pileup-only)

These mechanics exist nowhere else in the auto-battler genre. They are direct consequences of the *committed chaos* identity and would be pointless in any other game. They are what give Pileup its voice.

### The Hush

A signature pre-battle animation. Both players' piles are face-down on screen. The 5 selected cards rise out of the pile and float forward — *still face-down*. There is a deliberate **2-second pause** — the **Hush** — during which players see *that 5 cards are about to flip* but do not yet know which ones. Then the flipping begins, one card at a time.

The Hush is the poker pre-flop moment turned into UX. It is the visual signature of Pileup. Every battle has one. Players will associate the sound design and visuals of the Hush with the game itself.

### Visible probability

Every card in a player's pile displays a small **percentage** in its corner — its current flip chance after all weighted modifiers from cards, Jokers, and effects. The default is 50% (5 of 10). A heavily anchored 10 might show 90%+. A heavily de-weighted 1 might show 10–15%.

These numbers update in real time as the player makes shop decisions. Adding a *Spotlight* card raises that card's percentage live. Selling a *Hide & Seek* card recalculates the rest.

This makes strategy concrete instead of abstract. Players are not guessing how much their weights matter. They are *staring at the math*, which makes the shop feel like a probabilistic puzzle rather than a vibes check.

### The Reveal Window

After flips resolve and damage is calculated, but before the next shop, there is a **3-second Reveal Window** in which the 5 *unflipped* cards turn face-up briefly. The player sees which cards stayed home.

This serves two purposes:
1. **Emotional closure** — players find out whether they were unlucky (their best cards stayed home) or whether the unflipped half wouldn't have helped anyway. Every battle ends with information, not just an outcome.
2. **Strategic feedback** — over time, players learn whether their weights are working. If their 10 keeps not showing up, they need more weight on it.

A small set of Joker effects can interact with the Reveal Window: *"At Reveal: gain 1 mana per unflipped card of value 8+."* This rewards correct *building* even when the dice betrayed you on a given battle.

### Public weights in shop

Every card in the shop displays its weight modifier prominently as part of its core stats — alongside value and ability text. A *Spotlight* card's "+20% flip chance" is not fine print; it is a headline.

This signals that probability manipulation is a first-class mechanic, not a hidden subsystem. Players evaluate cards on three axes: value, ability, weight.

### Bait archetype (build-to-lose)

In every other auto-battler, losses are pure damage. In Pileup — because only 5 of 10 cards flip — players can deliberately compose a pile of *cards that want to lose*.

Specific Jokers and abilities exist that invert the goal: *"Each value-1-to-3 card that loses a flip: gain 4 mana."* Now the player wants their 1s to flip, *and* wants them to lose. They weight their bait cards UP and their power cards DOWN. They celebrate losing skirmishes.

This creates a strategic space — *"I built a deck that wants to lose"* — that no other auto-battler can support, because all other auto-battlers are full-deployment. Losses always hurt. Pileup, with its partial deployment and probability weighting, can engineer *who* shows up to lose.

### Pile composition feedback

The shop UI shows live, computed stats about the pile:
- **Average value** (e.g. 5.4)
- **Parity ratio** (e.g. 6 odd / 4 even)
- **Total weight points spent** (sum of all weight modifiers in pile)
- **Expected battle value** (a math estimate of average outcome — sum of value × flip-chance for the top 5)

This is theorycrafting *in the game itself*. Players see their pile's *shape*, not just its contents. It surfaces the math that the committed-chaos design depends on.

### Why these six together

The Hush makes the moment of revelation visceral. Visible probability makes the strategy concrete. The Reveal Window provides closure. Public weights signal that probability is the first-class mechanic. Bait archetypes give players a uniquely Pileup strategic space. Pile composition feedback turns the shop into a probabilistic puzzle.

Together, they make Pileup feel like a poker-meets-deckbuilder where the player composes a probabilistic engine, commits to it, and watches it resolve. That experience is not Balatro. It is not SAP. It is not Bazaar. It is Pileup.

---

## 12. Meta Progression

**Cosmetic only.** No power progression between runs.

- Card skin sets (themed art for the 1–10, e.g. medieval, cyberpunk, animals).
- Earned via end-of-run rewards, battle pass, seasonal events.
- All players sit down on equal footing — a brand new player can win a lobby on day one.

This locks in a fairness-first philosophy aligned with SAP, Balatro, and Slay the Spire.

---

## 13. Open Questions / TBD

These are unresolved and should be decided early in implementation:

1. **Joker slot count** — 1, 2, 3, or variable? (Affects synergy depth and balance burden.)
2. **Starter pile composition** — what 10 cards does everyone begin with? Should all be value 1–3 with simple abilities, or include some value variance?
3. **Tiebreak rules** — what happens when both flipped cards are the same value? Default options:
   - No points awarded
   - Both players get a point
   - Resolved by ability priority
   - Triggers any On Tie effects, then no points
4. **Damage formula** — exact HP loss per battle (margin-based, fixed, or hybrid).
5. **Starting HP** — 20? 25? 30?
6. **Gold per turn** — 10 baseline? Scaling?
7. **Live PvP timing** — concurrent shop timers, or async-first only for v1?

---

## 14. Suggested Build Order (For Implementation)

1. **Battle resolver** — given two 10-card piles, simulate a 5-flip battle with abilities. Pure logic, no UI.
2. **Shop logic** — gold/mana economy, buying/selling, tier system.
3. **Single-player vs bot** — full one-run loop against AI piles. Validates economy and ability design.
4. **Card and Joker content** — author 30+ cards and 20+ Jokers to fill the design space.
5. **8-player async lobby** — ghost piles, matchmaking, HP elimination.
6. **Cosmetic skin system** — card art swapping, unlocks.
7. **Live PvP** — concurrent shop timers, real opponents.
8. **Polish, balance passes, content expansion.**

---

## 15. Design Principles (Keep These In Mind)

- **Readability first.** Numbers 1–10 are universal. Don't break this.
- **Originality over genre-borrowing.** Pileup's voice is *committed chaos via partial deployment with loaded dice*. Mechanics exist nowhere else (the Hush, visible probability, Reveal Window, bait archetype). Resist the temptation to import features from SAP, Bazaar, Oaken Tower, Battlegrounds, etc. unless they directly serve Pileup's identity. Genre defaults are the path to a remix album, not an original record.
- **Depth over brute force.** The base game is dead simple — higher card wins. Without depth in upgrades, it collapses to "buy bigger numbers." Every upgrade path must offer *meaningful tradeoffs*, not just stat boosts. If "boost everything" is the optimal strategy, the design has failed.
- **Multiple viable paths.** A run should support wildly different strategies — high-card power, comeback engines, pair-synergy specialists, bait builds, probability-weighting specialists, Joker-warped weirdness. Bad paths must exist and get punished; weird paths must get rewarded.
- **Luck is a feature, never a bug.** The 5-of-10 randomness is the point. Players have tools to *tilt* odds, never *eliminate* them. Anchor effects exist but are rare and expensive. No-preview is non-negotiable: previewing the 5 would convert Pileup into a known-outcome execution puzzle and destroy the committed-chaos identity.
- **Skill expresses through building, not playing.** The battle auto-resolves with no real-time decisions. All skill lives in the shop — composing a probabilistic engine and committing to it.
- **Every run should feel different.** Jokers are the engine of this. Author broadly.
- **Fairness over grind.** Cosmetic-only meta progression. New players never disadvantaged.
- **Watchability.** The game should be fun to spectate (streams, replays). Auto-resolution and the Hush moment make every battle a small drama.
