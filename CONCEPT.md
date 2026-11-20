# StreakGate — Daily Check-In for Agent ID Holders

> **DRAFT — not deployed, not submitted.** Prepared for the Binance Wallet × BNB Chain
> Agent ID Hackathon (submission period 2026-11-18 → 2026-12-09 08:00 UTC).

## Pitch (one paragraph)

StreakGate is a daily ritual built exclusively for Agent ID holders. Once per UTC
day, a holder checks in with one small transaction; the contract builds their
**streak**, celebrates **milestones at 7, 14, and 30 days** with permanent on-chain
recognition, and ranks every holder on a **public leaderboard** — all inside
**Season 1, the Genesis Season**, framed on the hackathon window itself. Agent ID
is not a decorative badge here: it is the admission rule. The contract refuses
every check-in from an address that does not hold an Agent ID, so the entire user
base, leaderboard, and activity history are Agent ID holders by construction.
StreakGate turns a one-time identity claim into a daily on-chain habit — and gives
the ecosystem a live, public answer to the question every identity system faces:
*how many of these identities are actually alive?*

## The experience (why holders come back daily)

- **The streak flame.** Your streak is the product. Miss a day and it resets —
  that small daily tension is what makes check-ins a habit instead of a one-off.
- **Milestones with on-chain recognition.** Reaching a **7-day (Tier 1 · Spark)**,
  **14-day (Tier 2 · Blaze)**, or **30-day (Tier 3 · Inferno)** streak emits a
  `MilestoneReached` event and permanently raises your milestone tier in your
  on-chain stats. Milestones are pure data — non-transferable, non-tradable, no
  payout, no promised return — recognition and bragging rights only, which keeps
  them fully inside the campaign's red lines while still feeling like an achievement.
- **A leaderboard worth climbing.** Every checker address is stored on-chain and
  served through paginated view functions, so the leaderboard (top live streaks,
  top totals, tier badges) is rendered from contract data — not from a private
  database anyone could fudge. Because the gate is on-chain, every name on the
  board is a *verified* Agent ID holder.
- **Season 1 — Genesis Season.** Check-ins inside the season window are tallied
  separately (`seasonCheckIns`, per-user season counts), so Season 1 has its own
  race: who builds the longest streak before the season closes on 9 Dec? Genesis
  participants are the founding cohort — their stats are the first entries the
  contract will ever hold. Streaks and milestones continue after the season;
  only the season tally closes.

## How Agent ID is used at the core

- **The gate:** `checkIn()` calls `balanceOf(msg.sender)` on the Agent ID contract
  (`0x60B9262456dE011F7d15a54CdD8c48bAaa8B022F`, SPACE ID Agent ID, ERC-721,
  non-transferable). Balance `0` → revert. No signatures, no off-chain allowlist,
  no server — the on-chain NFT balance *is* the login.
- **Why this is "active use", not a wrapper:** every state-changing interaction is
  conditioned on holding an Agent ID. Remove Agent ID and the product has no
  users, no streaks, no leaderboard, no data. The global counters double as a
  live census of *active* Agent ID holders.
- **Composability:** streaks and milestone tiers are exposed via public view
  functions (`liveStreak`, `getUserStats`, `getMilestoneProgress`), so any other
  Agent ID dApp can build on them — e.g. gate a feature on "holder with a 7-day
  streak" instead of just "holder". StreakGate aims to be the reputation layer
  other entrants plug into.
- **What it deliberately does NOT do:** never resolves names to wallets, never
  looks up other people's identities, never moves user assets.

## How it maps to the two award tracks

### Growth Award (ranked by interacting Agent ID addresses + tx volume/count)

| Metric | How StreakGate drives it |
|---|---|
| Unique interacting Agent ID addresses | Every check-in must come from a distinct holder address; `uniqueCheckers` counts them on-chain |
| Transaction count | One check-in = one transaction, repeatable daily per holder; milestones and leaderboard rivalry give holders reasons to not skip days — the mechanic is structurally a daily tx generator |
| Transaction volume | Honestly: near zero. Check-ins carry no value by design (no deposits). We compete on address count and tx count, not volume |

### Innovation Award — criterion by criterion

| Criterion (weight) | Our case, feature by feature |
|---|---|
| **Agent ID application depth (30%)** | Agent ID is simultaneously (1) the access credential for the only action, (2) the subject of every metric (streaks, milestones, season tally), and (3) the guarantee behind the leaderboard's integrity — every ranked address is a holder, enforced by the contract, not by a moderator. Few integrations make the identity load-bearing in three independent ways. |
| **Practicality & feasibility (25%)** | The ecosystem's real gap: thousands of claimed Agent IDs, almost no public signal of which are active. StreakGate is that signal — cheap (one tiny tx/day), legible (public counters + views any project can read), and immediately reusable as a liveness/reputation primitive by other dApps. The build is deliberately small enough to be finished, audited by eye, and live well inside the window. |
| **Product completion (25%)** | The full loop works end-to-end with no backend: connect → on-chain holder check → check in → flame counter, milestone progress bar, tier cards, season countdown, live leaderboard — all read from the contract. Zero admin surface means nothing can break operationally after launch; there is no server to go down during judging. |
| **Innovation (20%)** | Reframes identity from a static NFT into a **streak-based reputation primitive**: milestones and live streaks give the ecosystem graduated trust levels (holder → 7-day → 14-day → 30-day) that other projects can compose on. The Season framing adds a recurring campaign rhythm — a reason for the community to return each season, not just once. |

Eligibility note: the Innovation track requires a **live product with ≥ 30 Agent ID
addresses interacting during the submission period**. That is a distribution
problem, not a code problem — see below.

## The ≥30 Agent ID addresses problem — stated honestly

The contract can be perfect and still score zero if fewer than 30 distinct Agent ID
holders ever call it. We do not control 30 Agent ID wallets, and manufacturing them
(fake registrations / wash interaction) would violate the campaign's
anti-manipulation rules and risk disqualification. The interactions must come from
real, independent holders. Concrete outreach plan:

1. **Agent ID community channels:** post the live dApp in the Binance Wallet /
   Agentic Wallet community spaces and BNB Chain developer groups where Agent ID
   holders already gather. Message: "Prove your Agent ID is alive — start your
   Season 1 streak", zero cost beyond a fraction of a cent of gas.
2. **Cross-promotion with other hackathon entrants:** other Agent ID projects need
   the same 30+ holders. A mutual "holder circuit" — each project links the
   others' holder-only features — pools the same audience instead of fragmenting
   it. The hackathon's own Community Promotion Campaign (X posts about
   participating projects) is a ready-made channel for this.
3. **Milestone moments are the marketing:** the frontend is built so a 7/14/30-day
   milestone is a shareable event ("Day 14 — Blaze tier on StreakGate") formatted
   for X with the campaign hashtags (#BinanceWalletHackathon, #AgenticWallet).
   The leaderboard gives holders a second reason to post: rank. Daily cadence
   means daily impressions, and every post recruits from the exact target
   audience — other holders.
4. **Existing Agent-ID-adjacent networks:** announce in communities of projects
   that already integrate Agentic Wallet / Agent ID (earlier Agent ID campaign
   circles, Ptah holder communities), offering the streak/milestone views as a
   free integration for their own holder perks — their holders become our
   checkers, our checkers become their "verified active" segment.

Realistic expectation: reaching 30 genuine holders is plausible with 2–3 weeks of
daily posting; it is not guaranteed. If we fall short, the Growth track still
counts whatever real interactions occur, and the submission itself costs nothing
but gas.

## Timeline to the 9 Dec 2026 08:00 UTC deadline

| When (UTC) | Step |
|---|---|
| 21–22 Nov | Finalize contract + frontend; local tests (Hardhat/Foundry) incl. fork test against the real Agent ID contract (milestone + streak-reset cases covered) |
| 22–23 Nov | Deploy to BSC mainnet with Season 1 window args; verify source on BscScan; publish repo (MIT) |
| 23 Nov | Smoke-test with our own Agent ID wallet (chz.ai) — first real check-in, Season 1 opens for us |
| 23 Nov – 8 Dec | Outreach window: daily posts, cross-promo, milestone shares; monitor `uniqueCheckers` against the 30-address threshold and `seasonCheckIns` |
| ≤ 5 Dec | Prepare submission materials (name, website, contract address, Agent ID usage description — checklist in README) |
| ≤ 7 Dec | Submit — **two full days before the deadline**, never at the wire |
| 9 Dec 08:00 UTC | Submission period + Season 1 close |

## Name check (red-line compliance)

"StreakGate" is an original name. It contains no "Binance" or "BNB", does not
impersonate any brand, and the product copy makes no return promises of any kind.
Milestone tiers (Spark / Blaze / Inferno) are original names for streak lengths —
they describe the holder's own consistency, nothing financial.
