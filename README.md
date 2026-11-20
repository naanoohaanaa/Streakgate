# StreakGate — Daily Check-In for Agent ID Holders

> **Status: DEPLOYED + LIVE on BNB Chain (2026-11-20).** Contract:
> `0x97ec62795ce9884597a79950eafcae03a8402b78` (CREATE2 via the Arachnid
> deterministic deployment proxy, deployer = the deployer's Agentic Wallet).
> Source verified with an **exact match on Sourcify** (creation + runtime);
> the same verification was forwarded to BscScan by Sourcify. Submission
> package for the Binance Wallet × BNB Chain **Agent ID Hackathon**
> (submission period 2026-11-18 08:00 UTC → 2026-12-09 08:00 UTC).

## What it is

StreakGate is a daily check-in dApp exclusively for **Agent ID** holders. Once per
UTC day, a holder sends one small transaction to check in. The contract tracks:

- per-user **current streak**, **longest streak**, and **lifetime check-ins**
- **milestone recognition** at 7 / 14 / 30-day streaks (Tier 1 "Spark",
  Tier 2 "Blaze", Tier 3 "Inferno") — pure on-chain data (a tier counter plus a
  `MilestoneReached` event): non-transferable, non-tradable, no payout of any kind
- a **leaderboard data layer**: every checker address is stored on-chain and
  exposed via paginated view functions, so any frontend can render top streaks /
  top totals (sorting is done client-side — on-chain sorting is gas-prohibitive)
- **Season 1 ("Genesis Season")** framing aligned to the hackathon window:
  check-ins inside the season are tallied separately; streaks continue after it
- global counters: total check-ins, unique checkers

**The gate is Agent ID itself.** `checkIn()` reverts unless
`balanceOf(msg.sender) > 0` on the Agent ID contract
(`0x60B9262456dE011F7d15a54CdD8c48bAaa8B022F`, SPACE ID Agent ID, ERC-721,
non-transferable). No allowlist, no server, no signatures — the NFT balance is
the admission rule, so every user and every leaderboard entry is a holder by
construction.

There is **no token, no deposit, and no transfer of any asset anywhere** in the
system. Check-ins cost only network gas.

## Contract

`contracts/AgentCheckIn.sol` — Solidity `^0.8.20`, single file, no imports beyond
a minimal read-only `IAgentId` interface.

### Functions

| Function | Type | Purpose |
|---|---|---|
| `checkIn()` | external, non-payable | Daily check-in; Agent-ID-gated; updates streak/milestones/counters; emits `CheckedIn` and (on 7/14/30) `MilestoneReached` |
| `isHolder(address)` | view | `balanceOf > 0` on the Agent ID contract |
| `hasCheckedInToday(address)` | view | Whether the address already checked in this UTC day |
| `getUserStats(address)` | view | total, streak, longest, lastDay, seasonCount, milestoneTier, milestonesEarned |
| `liveStreak(address)` | view | Effective streak now (0 if a day was missed) |
| `getMilestoneProgress(address)` | view | tier, next milestone days, days to go (frontend progress bar) |
| `getGlobalStats()` | view | totalCheckIns, uniqueCheckers, current UTC day |
| `getSeasonStats()` | view | season start/end, active flag, season check-in count |
| `checkersCount()` | view | Number of addresses that have ever checked in |
| `getLeaderboardPage(offset, limit)` | view | Page (≤100) of addresses + totals + live streaks + tiers for client-side leaderboard rendering |
| `currentDay()` | view | Current UTC day index |

Events: `CheckedIn(address indexed user, uint256 day, uint256 streak)`,
`MilestoneReached(address indexed user, uint256 milestoneDays, uint8 tier)`.

### Constructor arguments

| Arg | Value |
|---|---|
| `agentIdAddress` | `0x60B9262456dE011F7d15a54CdD8c48bAaa8B022F` |
| `seasonStartTs` | `1794988800` (2026-11-18 08:00 UTC — submission window open) |
| `seasonEndTs` | `1796803200` (2026-12-09 08:00 UTC — submission window close) |

## Owner permissions disclosure (red-line requirement)

**This contract has no owner and no privileged functions — none.**

- No `owner` variable, no `Ownable`, no admin role, no proxy, no upgrade path.
- Nobody — including the deployer — can, after deployment:
  - change the Agent ID contract address or the season window (both `immutable`)
  - pause or stop check-ins
  - edit, reset, or delete any user's streak, milestones, or counters
  - add or remove leaderboard entries
  - withdraw anything (the contract holds no assets and has no withdraw function;
    it is not payable and accepts no value by design)
- The only external call in the contract is a read-only `balanceOf` staticcall
  to the Agent ID contract.
- There are no token approvals, no `transferFrom`, no delegation, no signature
  verification, and no collection of any credential (seed phrase, private key,
  pairing code) anywhere in the contract or the frontend.
- The frontend connects via the user's own injected wallet (`window.ethereum`)
  only. **No QR-code login, no pairing code, no third-party sign-in.**
- Milestones are counters and events only. They are not tokens, cannot be
  transferred or redeemed, and the project **promises no returns** of any kind.

## Compile / deploy / verify (reference)

Compiled with solc 0.8.26, optimizer 200 runs. The live deployment was a
CREATE2 deployment of this exact creation bytecode through the Arachnid
deterministic deployment proxy (`0x4e59b44847b379578588920cA78FbF26c0B4956C`)
with salt `keccak256("StreakGate-Season1-chz.ai")`, producing
`0x97ec62795ce9884597a79950eafcae03a8402b78`. Equivalent direct-deploy routes:

### Foundry

```bash
forge build
forge create contracts/AgentCheckIn.sol:AgentCheckIn \
  --rpc-url https://bsc-dataseed.binance.org \
  --private-key $DEPLOYER_KEY \
  --constructor-args 0x60B9262456dE011F7d15a54CdD8c48bAaa8B022F 1794988800 1796803200

# Verify on BscScan
forge verify-contract <DEPLOYED_ADDRESS> contracts/AgentCheckIn.sol:AgentCheckIn \
  --chain-id 56 --etherscan-api-key $BSCSCAN_API_KEY \
  --constructor-args $(cast abi-encode "constructor(address,uint256,uint256)" \
    0x60B9262456dE011F7d15a54CdD8c48bAaa8B022F 1794988800 1796803200)
```

### Hardhat (alternative)

```bash
npx hardhat compile
npx hardhat run scripts/deploy.js --network bsc   # passes the same 3 constructor args
npx hardhat verify --network bsc <DEPLOYED_ADDRESS> \
  0x60B9262456dE011F7d15a54CdD8c48bAaa8B022F 1794988800 1796803200
```

After deployment: confirm the source shows as verified/open-source on BscScan,
publish this repo under an OSI-approved license (MIT, see contract header),
and set `CONTRACT_ADDRESS` in `frontend/index.html`.

## Frontend

`frontend/index.html` — a single static page (ethers v6 via CDN): connect wallet,
on-chain holder badge, flame streak counter, milestone progress bar + tier cards,
global/season stat cards, and a leaderboard table fed by `getLeaderboardPage`.
Serve it from any static host; no backend exists or is needed.

## Submission materials checklist (per the official announcement)

To submit during the submission period we must provide:

- [x] **Project name** — StreakGate
- [ ] **Website** — live URL of `frontend/index.html` (static host) — GitHub Pages
      for this repo (`/frontend/` path); enable Pages in repo Settings if the
      URL is not yet live
- [x] **Contract address(es)** — `0x97ec62795ce9884597a79950eafcae03a8402b78`
      (AgentCheckIn, BNB Chain mainnet)
- [ ] **Agent ID usage description** — "StreakGate gates its only action — the daily
      check-in — on holding an Agent ID: `checkIn()` reverts unless the caller's
      `balanceOf` on the Agent ID contract (0x60B9…022F) is greater than zero.
      Streaks, milestones, the leaderboard, and all counters therefore exist
      exclusively for Agent ID holders, turning the identity into a daily
      on-chain activity and reputation signal."
- [x] Contract source **verified and open-source** — exact match on Sourcify
      (2026-11-20); Sourcify forwarded the verification to BscScan (Etherscan
      backend). Source is also public in this repo under MIT.
- [ ] Product **live**, with interaction data generated during the submission
      period (Innovation eligibility additionally needs **≥ 30 distinct Agent ID
      addresses** interacting — see `CONCEPT.md` for the outreach plan)
- [ ] No registration is required beforehand, per the announcement

## Repository layout

```
CONCEPT.md               pitch, judging-criteria mapping, distribution plan, timeline
LICENSE                  MIT
PACKAGE.md               package overview + red-line design constraints
README.md                this file
contracts/AgentCheckIn.sol
frontend/index.html
```
