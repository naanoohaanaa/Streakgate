# Agent ID Hackathon — Draft Submission Package

**Status: DRAFT ONLY.** Nothing in this folder has been deployed, verified, or submitted.
Everything marked _unverified_ has not been checked against a live chain or the final
submission form yet.

## Contents

| File | Purpose |
|---|---|
| `CONCEPT.md` | Project pitch, Agent ID integration, judging-criteria mapping, distribution plan, timeline |
| `contracts/AgentCheckIn.sol` | The dApp contract (BSC mainnet target, not deployed) — streaks, 7/14/30-day milestones, leaderboard data layer, Season 1 tally |
| `README.md` | Compile / deploy / verify steps, owner-permissions disclosure, submission checklist |
| `frontend/index.html` | Polished static frontend: flame streak counter, milestone progress + tier cards, season countdown, leaderboard table (wallet connect via `window.ethereum`, no QR/pairing login) |

**Attractiveness upgrade applied (user direction, 20 Nov):** streak milestones
(7/14/30 days → Tier 1 Spark / Tier 2 Blaze / Tier 3 Inferno, on-chain event +
tier counter — asset-free, non-transferable, no payout), a public leaderboard fed
by on-chain view functions, and "Season 1 — Genesis Season" framing on the
hackathon window. Contract compiles clean with solc 0.8.26 (0 errors, 3,994 bytes
bytecode) — local check only; not deployed.

## Key facts baked into this draft (from the official announcement)

- Submission period: **2026-11-18 08:00 UTC → 2026-12-09 08:00 UTC**
- Agent ID contract (BNB Chain): `0x60B9262456dE011F7d15a54CdD8c48bAaa8B022F`
  (SPACE ID Agent ID, ERC-721, non-transferable; holder check = `balanceOf(address) > 0`)
- Innovation Award eligibility: live product + **≥ 30 distinct Agent ID addresses**
  interacting with the submitted contract(s) during the submission period
- Growth Award ranking: interacting Agent ID addresses, transaction volume / count
  (only submitted contract addresses count; only Agent ID holder addresses count)

## Deliberate design constraints (safety red lines)

- No token, no deposits, no transfers — the contract moves **no user assets, ever**
- No QR-code / pairing-code web login; frontend uses plain injected-wallet connect
- No approval requests of any kind (the contract never calls `approve`/`transferFrom`)
- No return promises anywhere in copy ("passive income", yield, etc. — none)
- Agent ID is used only as a **self-gate** (is the caller a holder?), never as a
  name→wallet lookup tool for other people
- Contract has **no owner and no admin functions at all** after deployment
  (see README "Owner permissions disclosure")
