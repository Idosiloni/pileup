# Pileup — Archetype Design Doc

> A surgical fix-list for the 10 archetypes that currently exist in the game. This is not a brainstorm. It is a prescription for what's missing in each lane and what to add (and weaken) to make each archetype *deliverable*, *legible*, and *fun to commit to*.

---

## How to read this doc

For each archetype:
- **Name** — what players will call it
- **Identity** — one sentence describing the feel of playing it
- **Current kit** — what's already in the game (cards & jokers, by their existing names)
- **The gap** — the specific reason it doesn't work yet (from the diagnosis)
- **The fix** — new cards/jokers to add that *only* fill this gap
- **Generic cards to weaken** — content that currently outshines this archetype and should be tuned down

Design philosophy locked from this pass:

1. **Cards teach themselves.** No archetype tags, no class picker, no unlock gates. A player reads "*Coin Pair*: when both players flip same parity, gain 2 gold" and understands the lane. The text is the signal.
2. **Every archetype's fix is the *minimum* needed.** 2–4 additions per archetype. Not a content dump.
3. **Weaken generics, don't delete them.** Generic power is the floor. But it shouldn't outshine commitment.
4. **No new mechanical systems unless absolutely required.** If an archetype's fix requires a new trigger type or shop behavior, it's called out under *Cross-archetype changes* at the bottom of the doc.

---

## 1. The Anchor (Raw Power / Guarantee-the-Top)

**Identity:** *Stack the highest values, then load the dice so they always show up. Your 10s are inevitable.*

**Current kit:**
- Cards: `eclipse`, `titan`, `godslayer`, `stage_hog`, `phantom`, `anchor`, `colossus`
- Jokers: `sniper`, `weighted_dice`, `heavyweight`

**The gap:** None critical. This is the most-supported archetype in the game and works as intended. The diagnosis explicitly says: *"Nothing critical."*

**The fix:** No new content. The Anchor is the *control* archetype against which others are balanced. Resist the temptation to add more. If anything, this is the lane that should *lose* a card or two when we weaken generics (see end of doc).

**Generic cards to weaken:**
- `eclipse` and `titan` — flat value buffs. Reduce by 1 point each so they're competitive with archetype-committed cards, not strictly better.
- `heavyweight` joker — likely overtuned given how much support exists. Reduce its bonus by ~20%.

---

## 2. The Spike & The Spread (Flip-Count Manipulation)

**Identity:** *Bend the contract of the battle itself. Either concentrate everything into 3 deadly flips, or spread your power across 7 reliable ones.*

**Current kit:**
- Jokers: `speed_demon` (3 flips), `long_haul` (7 flips), `gambler` (4 flips), `time_warp` (6 flips)

**The gap:** Selling support. A `speed_demon` player wants a *small, concentrated* pile of 3–5 elite cards. A `long_haul` player wants a *deep, consistent* pile of 12+. Current shop allows 1 sell per turn at a gold cost. The archetype is advertised but not deliverable on the pace of a run.

**The fix:**

- **Liquidator (Joker, Rare)** — *"Sell prices doubled. You may sell up to 3 cards per shop turn."* Unlocks the Spike build by making pile thinning fast and rewarding.
- **Hoarder (Joker, Rare)** — *"Pile cap raised to 14. Gain +1 value to all cards in pile if pile size is 12 or more."* Unlocks the Spread build by making deep piles actively valuable, not just legal.
- **Cleaver (Card ability, Uncommon)** — *"On Buy: destroy a random card in your pile. Your remaining cards gain +1 value."* A one-shot thin-and-grow tool. Helps the Spike player commit early.
- **Echo Pile (Card ability, Uncommon)** — *"At battle start: if your pile has 11+ cards, gain +20% flip chance on all cards."* Makes Spread piles *more*, not just *bigger*.

**Generic cards to weaken:**
- None specific. These archetypes are already mechanically distinct from generic power; they just need pacing tools.

---

## 3. The Spectrum (Parity / Odd & Even Specialization)

**Identity:** *Commit to one color of the spectrum. All odd or all even. Your pile shape becomes a key.*

**Current kit:**
- Jokers: `odd_job`, `even_steven`, `symmetry`, `asymmetry`, `coin_pair`

**The gap:** Two compounding problems from the diagnosis:
1. You can't *buy* specific-value cards (only power-ups for existing ones).
2. You can only sell 1 card per shop turn.

So the player sees `odd_job` (*"+1 to all odd cards"*), buys it… and has 5 odd cards in their pile that they can't easily increase. The archetype is impossible to commit to.

**The fix:** This archetype requires a small shop-loop change — the ability to *recruit* cards into the pile, not just buff existing ones. See *Cross-archetype changes* at the bottom of the doc. The content additions assume that change is in place.

- **Recruit: Odd (Shop item, Uncommon)** — *"Add a value-1, 3, 5, 7, or 9 card to your pile. You choose. 4 gold."* Available in shop as a special slot — not a power-up, but a *roster move*.
- **Recruit: Even (Shop item, Uncommon)** — *"Add a value-2, 4, 6, 8, or 10 card to your pile. You choose. 4 gold."*
- **Coin Flip (Joker, Common)** — *"When your card flips against a card of opposite parity: +1 value to your card."* A small encouragement to commit to a single parity early, when payoffs from `odd_job` are still small.
- **Parity Bomb (Card ability, Rare)** — *"On Reveal: if your pile is 80%+ one parity, gain +4 value and trigger ability twice."* The committed-payoff card. The reward for going *all-in* on parity.

**Generic cards to weaken:**
- `coin_pair` (when both players flip same parity → +2g) — currently a joker but functions as a passive sub-econ. Either move its identity into the Gold archetype or tune down the payoff to 1g.

---

## 4. The Cascade (Win Amplification Chain)

**Identity:** *Win flip 1, then flip 2 is easier, then flip 3 is automatic. You build a wave that crashes harder each step.*

**Current kit:**
- Cards: `valor` (+1 next ally on win), `storm` (-3 foe next on win), `shield` (-2 foe next on win), `warlord` (+3 next ally on win)
- Cards: `fortress`, `annihilator` (higher-tier versions)
- Joker: `streak` (each consecutive win → +1 next)

**The gap:** This is currently the strongest build in the game, and *it's invisible*. The diagnosis explicitly says: *"It works by accident of trigger overlap."* Players who discover it dominate; players who don't never realize the build exists. This is a discoverability problem, not a power problem.

**The fix:** **Do NOT add more cascade content — it's already overtuned.** Instead, add *signposts* — cards whose text makes the cascade *legible*.

- **Tidewalker (Card ability, Uncommon)** — *"This card gains +1 value for each previous flip you won this battle."* The card *explains* the cascade strategy through its text. A player who reads it understands "oh, winning earlier flips matters."
- **Momentum (Joker, Common)** — *"At battle start: if you won the previous battle, your first flipped card gains +2 value."* Reinforces the cascade *between* battles too. Makes the archetype's signal louder.

**Generic cards to weaken:**
- `warlord` (+3 next ally on win) — the strongest cascade trigger. Reduce to +2. The Cascade is *already* the strongest archetype; we shouldn't widen the gap by giving it the biggest numbers too.
- `annihilator` — likely also overtuned. Audit its numbers; should be a *peak* of a committed cascade build, not a generic top-tier pick.

---

## 5. The Sequence (Positional Order Control)

**Identity:** *You don't just stack power — you choreograph it. First card sets up. Last card closes.*

**Current kit:**
- Cards: `first_light` (flips first), `grand_finale` (flips last), `spotlight_effect` (+3 first flip), `last_stand` (+3 final flip), `bookend` (+2 first+last)

**The gap:** From the diagnosis: *"Limited but coherent as a secondary build axis."* Too few positional traits to make positional control its own primary build. Currently it pairs with Cascade as a secondary axis.

**The fix:**

- **Center Stage (Card ability, Uncommon)** — *"position: middle. This card always flips third if drawn."* Adds a third positional slot. Now the player has *three* positional control points instead of two.
- **Opening Act (Card ability, Common)** — *"On Reveal at flip 1 or 2: +3 value."* Doesn't lock position, but pays out if you happen to flip early. Pairs with `first_light` for double commitment.
- **Curtain Call (Card ability, Common)** — *"On Reveal at flip 4 or 5: +3 value."* Same idea, late game.
- **Choreographer (Joker, Rare)** — *"You may choose the flip order of any two cards in your battle hand (after the 5 are selected)."* Mid-tier control. Doesn't break the no-preview rule (you still don't know *which* 5 will flip), but once they're chosen, you tune their order.

**Generic cards to weaken:**
- `bookend` (+2 first+last) — currently a top-tier general buff because both slots are commonly buffed. Reduce to +1, or make it require *both* slots to be your positional cards (`first_light` + `grand_finale`).

---

## 6. The Drought (Slim Pile / Reliability)

**Identity:** *Sell down to 6 cards. Now every card you own flips almost every battle. The pile is small and devastating.*

**Current kit:**
- Joker: `slim_pile` (cap 8, all cards +2)
- Cards: `anchor`, `sniper`, `ironclad` — all pair well with thinned piles

**The gap:** From the diagnosis: *"No joker that rewards a small pile (except `slim_pile`)... the sell-down archetype needs a positive pull, not just the passive flip-probability improvement."*

The current implementation rewards a small pile *passively* (cards flip more often). But there's no *active* reward for committing to slimness. A 6-card pile feels punishing because you've spent gold selling cards rather than buying upgrades.

**The fix:**

- **Famine (Joker, Rare)** — *"For each empty slot in your pile (under cap 10), all your cards gain +1 value."* The positive pull. Selling becomes *growth*, not just thinning.
- **Distilled (Card ability, Uncommon)** — *"On Reveal: if your pile has 7 or fewer cards, +3 value."* A card that *only* works in a slim pile. The committed payoff.
- **Curator (Joker, Common)** — *"You may sell up to 2 cards per shop turn. Selling refunds full cost."* Pacing tool. Pairs with `Liquidator` (from archetype 2) but gentler.

**Generic cards to weaken:**
- None. Slim Pile suffers from absence, not competition.

---

## 7. The Crush (Value Compression)

**Identity:** *Cap and floor the values until everyone is fighting at 4–7. Now raw value barely matters — abilities decide who wins.*

**Current kit:**
- Cards/Jokers: `truncate` (all cards max 7), `boost` (all cards min 4)

**The gap:** From the diagnosis: *"No secondary support for this world — no ability that says 'in a world of equal values, this card always wins ties' or 'gains extra weight when all values are similar.'"*

You can compress the field, but there's nothing that *exploits* a compressed field. The archetype has the setup but no payoff.

**The fix:**

- **Equalizer (Card ability, Uncommon)** — *"On Reveal: if both this card and the opponent's flipped card are between value 4 and 7, win ties."* The payoff card. Wins ties *only* in the compressed range — a hyper-specific tool that's worthless outside of Crush, devastating inside it.
- **Field Marshal (Joker, Rare)** — *"While in a compressed field (truncate or boost active): your cards gain +20% flip chance."* Weight manipulation tied to the compressed state. Makes Crush a real probability-bender, not just a value-bender.
- **Common Ground (Joker, Rare)** — *"While truncate AND boost are both active: all your card abilities trigger twice."* The double-commit jackpot. Stack both, get exponential payoff. Reward for going full Crush.

**Generic cards to weaken:**
- None specific. Crush is currently *under*-supported.

---

## 8. The Mint (Gold Engine)

**Identity:** *You don't fight battles — you fund them. Gold buys what your pile can't muscle through.*

**Current kit:**
- Cards/Jokers: `fortune`, `golden_touch`, `rampage`, `coin_press`, `bounty`, `comeback`, `coin_pair`, `mud_pit`, `momentum`, `scrapper`

**The gap:** From the diagnosis: *"No 'convert gold into something other than what everyone else buys' path... gold engine in Pileup needs a sink that's exclusive to high-gold players."*

A gold-engine player generates 50g per shop, then spends it on the same upgrades as everyone else. No *exclusive* benefit from being rich.

**The fix:**

- **Black Market (Shop slot, mechanic)** — A special shop slot that appears every 3 rounds. Contains 1 Rare card at *3x normal price*. Inaccessible without gold engine commitment.
- **Goldbond (Card ability, Rare)** — *"On Reveal: gain value equal to (your current gold / 5), rounded down."* Direct gold-to-value conversion. A card whose entire power scales with your gold reserves.
- **Banker (Joker, Rare)** — *"You may carry up to 30 gold between shop turns. Above 20 gold, all your cards gain +1 value."* Creates an active reason to *hoard* gold, not spend it. The wealthier you stay, the stronger your pile becomes.
- **Liquidate (Joker, Uncommon)** — *"At battle start: spend all your gold. For every 4 gold spent: +1 value to a random flipped card."* The opposite play — go *broke* for a single battle's power spike.

**Generic cards to weaken:**
- `fortune` and `golden_touch` — likely overtuned given the volume of gold abilities. Audit and reduce.

---

## 9. The Stalemate (Tie Archetype)

**Identity:** *You don't want to win flips — you want to *tie* them. Your cards meet the opponent's exactly, and that's when the engine fires.*

**Current kit:**
- Cards/Jokers: `tiebreaker` (ties → win), `doomsday` (ties → 1 HP), `doubler` (+1 on matched values), `resilience` (tie → next ally +3), `pierce`, `balance`, `scrapper`

**The gap:** From the diagnosis: *"No way to actively engineer ties... you'd need something like: 'your cards adopt the opponent's value for this flip' or 'reduce your card's value by 2 before comparison.'"*

The archetype only fires when ties *happen to occur*. Players need tools to *fish* for ties.

**The fix:**

- **Chameleon (Card ability, Rare)** — *"On Reveal: this card's value becomes the opponent's card value (this flip only)."* The signature tie-fisher. Forces a tie *every time it flips*.
- **Adapter (Card ability, Uncommon)** — *"On Reveal: this card's value becomes the average of all flipped values this battle so far (rounded)."* Soft tie-fishing. Trends toward the middle of the battle's value range.
- **Equilibrium (Joker, Rare)** — *"Each card in your pile gains the trait: 'On Reveal: 25% chance this card's value -1 or +1.'"* A subtle value-jitter that lands on ties more often than it would otherwise.
- **Mirror Match (Joker, Legendary)** — *"At battle start: copy one random opponent card's value to one random card in your pile."* Almost-guaranteed tie if positioned right. Hugely build-around.

**Generic cards to weaken:**
- `pierce` (tie → win, simpler version of `tiebreaker`) — currently duplicates `tiebreaker`'s function. Either remove or differentiate (e.g. `pierce` ties → win only for value-5-and-under cards).

---

## 10. The Tribute (Embrace-the-Loss / Bait)

**Identity:** *Some of your cards are meant to die. They flip, they lose, and their sacrifice fuels everything else.*

**Current kit:**
- Cards: `martyr` (on loss → next ally +2), `nemesis` (on loss → next ally +4), `avenger` (previous flip lost → +3), `rage_build` (+1 per prior loss this battle), `bitter_end` (lose by 8+ → foe next -4)
- Jokers: `mud_pit` (lose battle → +5g), `pyromancer`, `lowball`

**The gap:** From the diagnosis: *"Losing individual flips gives tiny advantages... there's no joker that says 'Each of your 1–3 value cards that loses a flip: +2g' — a flip-level loss payoff that makes flipping your bait cards into an active plan."*

The kit *exists* but the loop doesn't close. Losing a flip should feel *rewarding* to a Tribute player. Currently it just feels like setup for the next flip.

**The fix:**

- **Tithe (Joker, Uncommon)** — *"Each of your value-1-to-3 cards that loses a flip: gain 3 gold and 1 mana-equivalent."* Wait — mana removed. Reword: *"Each of your value-1-to-3 cards that loses a flip: gain 3 gold AND your next flipped card gains +2 value."* The flip-level payoff the diagnosis demanded.
- **Sacrifice (Card ability, Rare)** — *"On Loss: permanently +1 value to a random other card in your pile (carries between battles)."* A card whose *losses* grow your pile permanently. Run-scaling through death.
- **Funeral Procession (Joker, Rare)** — *"For each flip you lost this battle: gain +1 flip chance to all your value-8+ cards next battle."* The bait pile *teaches* opponents to expect losses, then your power cards arrive next round more reliably.
- **Cannon Fodder (Card ability, Common)** — *"value: 1. weight: +50. On Loss: gain 2 gold."* The signature bait card. Cheap, almost guaranteed to flip, almost guaranteed to lose, pays out every time.

**Generic cards to weaken:**
- `rage_build` — overpowered when stacked because there's no theoretical ceiling. Cap at +4 max stacks. Otherwise the archetype runaways into degenerate snowball.

---

## Cross-archetype changes

These changes apply across multiple archetypes and are needed for several of the fixes above to work. They're listed here so they're not duplicated.

### 1. Recruitment slot in shop

The Parity archetype (Section 3) and others (Spectrum, Slim Pile) need a way to add specific cards to the pile, not just buff existing ones. Currently the shop only sells power-ups.

**Add:** A *Recruitment* slot that appears 1–2 times per run, offering a card of specified value (e.g. "Add a value-7 card for 4g"). This is rare enough not to break the existing economy but available enough to make build commitment possible.

### 2. Selling cap raised conditionally

The Spike (Spread/Speed Demon) archetype and Slim Pile archetype both need faster pile thinning. The base game stays at 1 sell/turn for cost reasons, but the Jokers `Liquidator` (Section 2) and `Curator` (Section 6) raise this conditionally. Other archetypes don't need it.

### 3. Generic-power weakening summary

Pulled together from each archetype's section above. Tune these down so committed archetype cards don't get outshone by generic ones:

| Card / Joker | Current behavior | Change |
|---|---|---|
| `eclipse` | +X flat value | Reduce by 1 |
| `titan` | +X flat value | Reduce by 1 |
| `heavyweight` | guarantee top card | Reduce bonus ~20% |
| `warlord` | +3 next ally on win | Reduce to +2 |
| `annihilator` | (audit) | Tune down to fit cascade ceiling |
| `bookend` | +2 first+last | Reduce to +1, or require both positional cards |
| `coin_pair` | +2g on same parity | Reduce to +1g |
| `fortune` / `golden_touch` | audit | Reduce gold yields |
| `pierce` | duplicates tiebreaker | Differentiate or remove |
| `rage_build` | unbounded stacks | Cap at +4 |
| `survivor` | reactive HP-based buff | Either delete or rework as Tribute card |

### 4. Cards that should be flagged as *removable*

The diagnosis identified `survivor` as having no archetype home. It's a panic-button consolation mechanic that doesn't pair with anything. Recommend: either delete it, or rework it as part of the Tribute archetype with text like *"On Reveal: gain +1 value per HP you have lost this run."*

---

## What this doc does NOT do

To stay focused, this doc deliberately does *not*:

- Brainstorm new archetypes (Pileup has enough — 10 is plenty; depth > breadth)
- Add new mechanical systems (no tags, no class picker, no unlock gates)
- Add cosmetic content (skins, music — that's for v2.0+)
- Address graphics or animation (separate concern — see graphics-prototype track)
- Address single-player vs. lobby tuning (orthogonal to archetype design)

The single goal: **make all 10 currently-existing archetypes deliverable, legible, and fun to commit to**, with minimum new content.

---

## Implementation order suggestion

If you can't ship all of this at once, here's the priority order based on diagnosis severity:

1. **The Tribute** (bait) — the doc's "most original mechanic" with the worst current implementation. Adding `Tithe` and `Cannon Fodder` alone would dramatically change the game.
2. **The Spectrum** (parity) — currently advertised but undeliverable. Adding the Recruitment slot unblocks this *and* helps two other archetypes.
3. **The Cascade** (signposting) — fastest fix. Just adding `Tidewalker` and `Momentum` makes the strongest unannounced build legible.
4. **The Mint** (gold sink) — adds depth without much new mechanical complexity.
5. **The Stalemate** (tie-fishing) — `Chameleon` alone transforms this archetype.
6. **The Drought** (slim pile) — `Famine` is the entire unlock.
7. **The Crush** (value compression) — currently weakest commitment; adding the payoff layer makes it real.
8. **The Sequence** (positional) — quality-of-life, but the archetype works without it.
9. **The Spike & The Spread** (flip-count) — works fine but `Liquidator` makes it sing.
10. **The Anchor** — already solid, just needs the generic-power weakening to not dominate.
