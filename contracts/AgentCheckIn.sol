// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title StreakGate — Daily check-in for Agent ID holders
/// @notice Holders of an Agent ID (SPACE ID Agent ID, ERC-721) check in once per
///         UTC day to build an on-chain streak, earn milestone recognition at
///         7 / 14 / 30-day streaks, and climb a public leaderboard.
///
///         Season 1 ("Genesis Season") is framed on the Agent ID Hackathon
///         submission window: check-ins inside the season window are tallied
///         separately so the season leaderboard stays meaningful. Check-ins
///         remain open after the season ends — streaks are forever.
///
///         Design constraints (deliberate):
///         - NO token, NO deposits, NO transfers: this contract never holds or
///           moves user assets. `checkIn()` is not payable and there is no
///           withdraw function. Milestones are pure data (a tier counter +
///           an event) — non-transferable, non-tradable, worth nothing except
///           bragging rights. Nothing here promises any return of any kind.
///         - NO owner, NO admin: there is no owner address and no privileged
///           function of any kind. After deployment nobody — including the
///           deployer — can change any parameter, pause the contract, edit
///           counters, or touch user records. All configuration is immutable.
///         - The ONLY external call is a read-only `balanceOf` staticcall to
///           the Agent ID contract, used to gate check-ins.
///         - Agent ID is used solely as a self-gate (is the *caller* a
///           holder?). The contract never resolves names to wallets.
///
/// @dev Agent ID contract (BNB Chain mainnet):
///      0x60B9262456dE011F7d15a54CdD8c48bAaa8B022F

/// @dev Minimal read-only interface for the Agent ID ERC-721 contract.
interface IAgentId {
    function balanceOf(address owner) external view returns (uint256);
}

contract AgentCheckIn {
    // ---------------------------------------------------------------------
    // Immutable configuration (set once at deployment, never changeable)
    // ---------------------------------------------------------------------

    /// @notice The Agent ID contract whose holders may check in.
    IAgentId public immutable agentId;

    /// @notice Season 1 start (unix timestamp, inclusive).
    uint256 public immutable seasonStart;

    /// @notice Season 1 end (unix timestamp, inclusive).
    uint256 public immutable seasonEnd;

    /// @notice Streak lengths that earn a milestone tier, ascending.
    ///         Tier 1 = 7 days, Tier 2 = 14 days, Tier 3 = 30 days.
    uint256 public constant MILESTONE_1 = 7;
    uint256 public constant MILESTONE_2 = 14;
    uint256 public constant MILESTONE_3 = 30;

    // ---------------------------------------------------------------------
    // Global counters
    // ---------------------------------------------------------------------

    /// @notice Total successful check-ins, all users, all time.
    uint256 public totalCheckIns;

    /// @notice Distinct addresses that have ever checked in.
    uint256 public uniqueCheckers;

    /// @notice Check-ins that landed inside the Season 1 window.
    uint256 public seasonCheckIns;

    // ---------------------------------------------------------------------
    // Per-user state
    // ---------------------------------------------------------------------

    struct UserStats {
        uint256 totalCheckIns;   // lifetime check-ins
        uint256 currentStreak;   // consecutive UTC days counting the latest check-in day
        uint256 longestStreak;   // best streak ever
        uint256 lastCheckInDay;  // UTC day index of last check-in (0 = never*)
        uint256 seasonCheckIns;  // check-ins inside the Season 1 window
        uint8   milestoneTier;   // highest milestone tier reached: 0 none, 1 = 7d, 2 = 14d, 3 = 30d
        uint256 milestonesEarned;// total milestone events earned (re-earnable after a streak reset)
        bool    counted;         // true once added to uniqueCheckers / _checkers
    }
    // * Day index 0 is 1970-01-01; a real check-in can never have day index 0.

    mapping(address => UserStats) private _users;

    /// @dev Every address that has ever checked in, in first-check-in order.
    ///      This is the leaderboard data layer: frontends page through it with
    ///      `getLeaderboardPage`, sort client-side, and render. (Sorting
    ///      on-chain would be gas-prohibitive and is deliberately not done.)
    address[] private _checkers;

    // ---------------------------------------------------------------------
    // Events
    // ---------------------------------------------------------------------

    /// @notice Emitted on every successful check-in.
    event CheckedIn(address indexed user, uint256 day, uint256 streak);

    /// @notice Emitted when a check-in lands exactly on a milestone streak.
    /// @param user          The holder reaching the milestone.
    /// @param milestoneDays The streak length reached (7, 14, or 30).
    /// @param tier          Milestone tier: 1, 2, or 3.
    event MilestoneReached(address indexed user, uint256 milestoneDays, uint8 tier);

    // ---------------------------------------------------------------------
    // Errors
    // ---------------------------------------------------------------------

    error NotAgentIdHolder();
    error AlreadyCheckedIn();
    error ZeroAddress();
    error BadSeasonWindow();
    error PageTooLarge();

    // ---------------------------------------------------------------------
    // Constructor
    // ---------------------------------------------------------------------

    /// @param agentIdAddress Agent ID contract on BNB Chain
    ///        (0x60B9262456dE011F7d15a54CdD8c48bAaa8B022F).
    /// @param seasonStartTs  Season 1 start, unix timestamp.
    ///        For the hackathon window: 1794988800 (2026-11-18 08:00 UTC).
    /// @param seasonEndTs    Season 1 end, unix timestamp.
    ///        For the hackathon window: 1796803200 (2026-12-09 08:00 UTC).
    constructor(address agentIdAddress, uint256 seasonStartTs, uint256 seasonEndTs) {
        if (agentIdAddress == address(0)) revert ZeroAddress();
        if (seasonEndTs <= seasonStartTs) revert BadSeasonWindow();
        agentId = IAgentId(agentIdAddress);
        seasonStart = seasonStartTs;
        seasonEnd = seasonEndTs;
    }

    // ---------------------------------------------------------------------
    // Core action
    // ---------------------------------------------------------------------

    /// @notice Check in for today. Caller must hold an Agent ID.
    /// @dev One check-in per address per UTC day. Streak rules:
    ///      - checked in yesterday -> streak + 1
    ///      - gap of 2+ days (or first ever) -> streak resets to 1
    ///      Landing exactly on a 7/14/30 streak emits MilestoneReached and
    ///      raises the user's milestone tier. Moves no assets; takes no value.
    function checkIn() external {
        // Gate: caller must hold at least one Agent ID (read-only staticcall).
        if (agentId.balanceOf(msg.sender) == 0) revert NotAgentIdHolder();

        uint256 today = block.timestamp / 1 days;

        UserStats storage u = _users[msg.sender];
        if (u.lastCheckInDay == today) revert AlreadyCheckedIn();

        // Streak logic.
        if (u.lastCheckInDay == today - 1) {
            u.currentStreak += 1;
        } else {
            u.currentStreak = 1;
        }
        if (u.currentStreak > u.longestStreak) {
            u.longestStreak = u.currentStreak;
        }

        // Milestone recognition (pure data — no asset, no transfer).
        uint8 tier = _tierForStreak(u.currentStreak);
        if (tier > 0) {
            u.milestonesEarned += 1;
            if (tier > u.milestoneTier) u.milestoneTier = tier;
            emit MilestoneReached(msg.sender, u.currentStreak, tier);
        }

        // Bookkeeping.
        u.lastCheckInDay = today;
        u.totalCheckIns += 1;
        if (!u.counted) {
            u.counted = true;
            uniqueCheckers += 1;
            _checkers.push(msg.sender);
        }
        totalCheckIns += 1;
        if (block.timestamp >= seasonStart && block.timestamp <= seasonEnd) {
            seasonCheckIns += 1;
            u.seasonCheckIns += 1;
        }

        emit CheckedIn(msg.sender, today, u.currentStreak);
    }

    /// @dev Returns the milestone tier for an exact streak length, or 0.
    function _tierForStreak(uint256 streak) internal pure returns (uint8) {
        if (streak == MILESTONE_3) return 3;
        if (streak == MILESTONE_2) return 2;
        if (streak == MILESTONE_1) return 1;
        return 0;
    }

    // ---------------------------------------------------------------------
    // View helpers — user stats & milestones
    // ---------------------------------------------------------------------

    /// @notice Current UTC day index used by the contract.
    function currentDay() public view returns (uint256) {
        return block.timestamp / 1 days;
    }

    /// @notice True if `user` holds at least one Agent ID.
    function isHolder(address user) external view returns (bool) {
        return agentId.balanceOf(user) > 0;
    }

    /// @notice True if `user` has already checked in today (UTC).
    function hasCheckedInToday(address user) external view returns (bool) {
        return _users[user].counted && _users[user].lastCheckInDay == currentDay();
    }

    /// @notice Full stats for one address.
    /// @return total           lifetime check-ins
    /// @return streak          stored current streak (see `liveStreak` for the
    ///                         effective value if a day was missed)
    /// @return longest         longest streak ever
    /// @return lastDay         UTC day index of last check-in (0 = never)
    /// @return seasonCount     check-ins inside the Season 1 window
    /// @return milestoneTier   highest milestone tier reached (0–3)
    /// @return milestonesEarned total milestone events earned
    function getUserStats(address user)
        external
        view
        returns (
            uint256 total,
            uint256 streak,
            uint256 longest,
            uint256 lastDay,
            uint256 seasonCount,
            uint8 milestoneTier,
            uint256 milestonesEarned
        )
    {
        UserStats storage u = _users[user];
        return (
            u.totalCheckIns,
            u.currentStreak,
            u.longestStreak,
            u.lastCheckInDay,
            u.seasonCheckIns,
            u.milestoneTier,
            u.milestonesEarned
        );
    }

    /// @notice The streak as it effectively stands right now: the stored streak
    ///         if the user checked in today or yesterday, otherwise 0 (broken).
    function liveStreak(address user) external view returns (uint256) {
        return _liveStreak(user);
    }

    function _liveStreak(address user) internal view returns (uint256) {
        UserStats storage u = _users[user];
        uint256 today = currentDay();
        if (u.lastCheckInDay == today || u.lastCheckInDay == today - 1) {
            return u.currentStreak;
        }
        return 0;
    }

    /// @notice Milestone progress for the frontend progress bar.
    /// @return tier         highest tier reached so far (0–3)
    /// @return nextDays     streak length of the next milestone above the
    ///                      user's *live* streak (0 = all milestones passed
    ///                      on the current run / at max tier for this run)
    /// @return daysToGo     check-ins remaining to reach `nextDays`
    function getMilestoneProgress(address user)
        external
        view
        returns (uint8 tier, uint256 nextDays, uint256 daysToGo)
    {
        uint256 s = _liveStreak(user);
        tier = _users[user].milestoneTier;
        if (s < MILESTONE_1) {
            nextDays = MILESTONE_1;
        } else if (s < MILESTONE_2) {
            nextDays = MILESTONE_2;
        } else if (s < MILESTONE_3) {
            nextDays = MILESTONE_3;
        } else {
            nextDays = 0; // current run already passed the top milestone
        }
        daysToGo = nextDays == 0 ? 0 : nextDays - s;
    }

    // ---------------------------------------------------------------------
    // View helpers — globals & season
    // ---------------------------------------------------------------------

    /// @notice Global counters in one call, for dashboards.
    function getGlobalStats()
        external
        view
        returns (uint256 total, uint256 unique, uint256 today)
    {
        return (totalCheckIns, uniqueCheckers, currentDay());
    }

    /// @notice Season 1 framing in one call.
    /// @return start  season start timestamp
    /// @return end    season end timestamp
    /// @return active whether the season window is open right now
    /// @return count  check-ins counted inside the season so far
    function getSeasonStats()
        external
        view
        returns (uint256 start, uint256 end, bool active, uint256 count)
    {
        bool isActive = block.timestamp >= seasonStart && block.timestamp <= seasonEnd;
        return (seasonStart, seasonEnd, isActive, seasonCheckIns);
    }

    // ---------------------------------------------------------------------
    // View helpers — leaderboard data layer
    // ---------------------------------------------------------------------

    /// @notice Number of addresses that have ever checked in.
    function checkersCount() external view returns (uint256) {
        return _checkers.length;
    }

    /// @notice One page of the leaderboard's raw data, in first-check-in order.
    ///         The frontend sorts by liveStreak / totalCheckIns client-side.
    /// @param offset index into the checkers list to start from
    /// @param limit  page size (max 100, to bound response size)
    /// @return addrs          the page's addresses
    /// @return totals         lifetime check-ins per address
    /// @return streaks        *live* streak per address
    /// @return tiers          milestone tier per address
    function getLeaderboardPage(uint256 offset, uint256 limit)
        external
        view
        returns (
            address[] memory addrs,
            uint256[] memory totals,
            uint256[] memory streaks,
            uint8[] memory tiers
        )
    {
        if (limit > 100) revert PageTooLarge();
        uint256 n = _checkers.length;
        if (offset >= n) {
            return (addrs, totals, streaks, tiers); // empty page
        }
        uint256 size = limit;
        if (offset + size > n) size = n - offset;

        addrs = new address[](size);
        totals = new uint256[](size);
        streaks = new uint256[](size);
        tiers = new uint8[](size);
        for (uint256 i = 0; i < size; i++) {
            address a = _checkers[offset + i];
            addrs[i] = a;
            totals[i] = _users[a].totalCheckIns;
            streaks[i] = _liveStreak(a);
            tiers[i] = _users[a].milestoneTier;
        }
        return (addrs, totals, streaks, tiers);
    }
}
