import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/community.dart';
import '../models/tree.dart';
import '../services/community_service.dart';
import '../services/locale_service.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';
import 'tree_canvas.dart';

class ChallengesLeaderboardView extends StatefulWidget {
  final StorageService storage;

  const ChallengesLeaderboardView({super.key, required this.storage});

  @override
  State<ChallengesLeaderboardView> createState() => _ChallengesLeaderboardViewState();
}

class _ChallengesLeaderboardViewState extends State<ChallengesLeaderboardView> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final CommunityService _communityService = CommunityService();
  String _selectedFilter = 'today'; // 'today', 'week', 'all'

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _communityService.init(widget.storage);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _communityService,
      builder: (context, _) {
        final me = _communityService.getCurrentUserEntry();

        return Scaffold(
          backgroundColor: OasisColors.background,
          appBar: AppBar(
            backgroundColor: OasisColors.surface,
            elevation: 0,
            title: Row(
              children: [
                const Text('🏆', style: TextStyle(fontSize: 22)),
                const SizedBox(width: 8),
                Text(
                  tr('challenges_title'),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ],
            ),
            actions: [
              // Current User Profile Chip
              InkWell(
                onTap: () => _showEditProfileDialog(context, me),
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: OasisColors.card,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: OasisColors.primary.withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    children: [
                      Text(me.avatar, style: const TextStyle(fontSize: 16)),
                      const SizedBox(width: 6),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 85),
                        child: Text(
                          me.name,
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: OasisColors.textPrimary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.edit_rounded, size: 13, color: OasisColors.textSecondary),
                    ],
                  ),
                ),
              ),
            ],
            bottom: TabBar(
              controller: _tabController,
              indicatorColor: OasisColors.primary,
              indicatorWeight: 3,
              labelColor: OasisColors.primary,
              unselectedLabelColor: OasisColors.textSecondary,
              labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              tabs: [
                Tab(
                  icon: const Icon(Icons.emoji_events_rounded, size: 19),
                  text: tr('tab_leaderboard'),
                ),
                Tab(
                  icon: const Icon(Icons.military_tech_rounded, size: 19),
                  text: tr('tab_challenges'),
                ),
                Tab(
                  icon: const Icon(Icons.fiber_smart_record_rounded, size: 19),
                  text: tr('tab_live_room'),
                ),
              ],
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            children: [
              // 1. Leaderboard Tab
              _buildLeaderboardTab(me),

              // 2. Challenges & Quests Tab
              _buildChallengesTab(),

              // 3. Live Study Room Tab
              _buildLiveRoomTab(me),
            ],
          ),
        );
      },
    );
  }

  // ===========================================================================
  // 1. LEADERBOARD TAB
  // ===========================================================================

  Widget _buildLeaderboardTab(LeaderboardUser me) {
    final users = _communityService.getLeaderboard(_selectedFilter);
    final myRank = _communityService.getCurrentUserRank(_selectedFilter);
    final gapMins = _communityService.getMinutesToRankAhead(_selectedFilter);

    final top3 = users.take(3).toList();
    final remainingUsers = users.skip(3).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Filter Chips (Today / Week / All Time)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _filterChip('today', tr('filter_today')),
              const SizedBox(width: 8),
              _filterChip('week', tr('filter_week')),
              const SizedBox(width: 8),
              _filterChip('all', tr('filter_all_time')),
            ],
          ),
          const SizedBox(height: 20),

          // Top 3 Podium Showcase
          if (top3.length >= 3) _buildPodiumShowcase(top3),
          const SizedBox(height: 20),

          // Current User Status / Progress Card
          _buildMyRankHighlightCard(me, myRank, gapMins),
          const SizedBox(height: 20),

          // Community Ranked List Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                tr('community_rankings'),
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: OasisColors.textPrimary),
              ),
              Text(
                '${users.length} ${tr('participants')}',
                style: const TextStyle(fontSize: 12, color: OasisColors.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // List of Users
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: remainingUsers.length,
            separatorBuilder: (context, index) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final user = remainingUsers[index];
              final rank = index + 4; // Starts from 4th place
              return _buildUserLeaderboardCard(user, rank);
            },
          ),
        ],
      ),
    );
  }

  Widget _filterChip(String id, String label) {
    final isSelected = _selectedFilter == id;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => setState(() => _selectedFilter = id),
      selectedColor: OasisColors.primary,
      backgroundColor: OasisColors.card,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : OasisColors.textSecondary,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        fontSize: 12,
      ),
      side: BorderSide(
        color: isSelected ? OasisColors.primary : OasisColors.cardBorder,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    );
  }

  Widget _buildPodiumShowcase(List<LeaderboardUser> top3) {
    final rank1 = top3[0];
    final rank2 = top3[1];
    final rank3 = top3[2];

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
      decoration: BoxDecoration(
        color: OasisColors.card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: OasisColors.cardBorder),
        boxShadow: [
          BoxShadow(
            color: OasisColors.coinGold.withValues(alpha: 0.08),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // 2nd Place (Silver)
          _podiumPillar(
            user: rank2,
            rank: 2,
            height: 125,
            color: const Color(0xFF94A3B8),
            badgeEmoji: '🥈',
          ),

          // 1st Place (Gold - Tallest & Glowing)
          _podiumPillar(
            user: rank1,
            rank: 1,
            height: 160,
            color: OasisColors.coinGold,
            badgeEmoji: '👑',
            isFirst: true,
          ),

          // 3rd Place (Bronze)
          _podiumPillar(
            user: rank3,
            rank: 3,
            height: 105,
            color: const Color(0xFFD97706),
            badgeEmoji: '🥉',
          ),
        ],
      ),
    );
  }

  Widget _podiumPillar({
    required LeaderboardUser user,
    required int rank,
    required double height,
    required Color color,
    required String badgeEmoji,
    bool isFirst = false,
  }) {
    final mins = user.getMinutesForFilter(_selectedFilter);
    final hours = (mins / 60.0).toStringAsFixed(1);

    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Avatar + Crown
          Stack(
            alignment: Alignment.topCenter,
            clipBehavior: Clip.none,
            children: [
              Container(
                width: isFirst ? 58 : 48,
                height: isFirst ? 58 : 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withValues(alpha: 0.15),
                  border: Border.all(color: color, width: isFirst ? 2.5 : 1.5),
                  boxShadow: isFirst
                      ? [
                          BoxShadow(
                            color: color.withValues(alpha: 0.4),
                            blurRadius: 12,
                            spreadRadius: 2,
                          ),
                        ]
                      : null,
                ),
                child: Center(
                  child: Text(
                    user.avatar,
                    style: TextStyle(fontSize: isFirst ? 28 : 22),
                  ),
                ),
              ),
              Positioned(
                top: -14,
                child: Text(badgeEmoji, style: TextStyle(fontSize: isFirst ? 20 : 16)),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Name
          Text(
            user.name,
            style: TextStyle(
              fontSize: isFirst ? 13 : 11,
              fontWeight: FontWeight.bold,
              color: user.isCurrentUser ? OasisColors.primaryGlow : OasisColors.textPrimary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 2),

          // Hours Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '$hours ${tr('hours_suffix')}',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Pillar pedestal
          Container(
            width: double.infinity,
            height: height,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  color.withValues(alpha: 0.25),
                  color.withValues(alpha: 0.08),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
              border: Border.all(color: color.withValues(alpha: 0.3)),
            ),
            child: Center(
              child: Text(
                '#$rank',
                style: TextStyle(
                  fontSize: isFirst ? 24 : 18,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMyRankHighlightCard(LeaderboardUser me, int myRank, int gapMins) {
    final mins = me.getMinutesForFilter(_selectedFilter);
    final hours = (mins / 60.0).toStringAsFixed(1);

    String motivation;
    if (myRank == 1) {
      motivation = tr('rank_first_motivation');
    } else {
      motivation = tr('rank_gap_motivation', {
        'mins': gapMins,
        'nextRank': myRank - 1,
      });
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            OasisColors.primary.withValues(alpha: 0.2),
            OasisColors.card,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: OasisColors.primary.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
            color: OasisColors.primary.withValues(alpha: 0.15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Rank Badge
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: OasisColors.primary,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: OasisColors.primary.withValues(alpha: 0.4),
                  blurRadius: 8,
                ),
              ],
            ),
            child: Center(
              child: Text(
                '#$myRank',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          ),
          const SizedBox(width: 14),

          // User info and gap
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(me.avatar, style: const TextStyle(fontSize: 16)),
                    const SizedBox(width: 6),
                    Text(
                      '${me.name} (${tr('you_label')})',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: OasisColors.textPrimary),
                    ),
                    const Spacer(),
                    Text(
                      '$hours ${tr('hours_suffix')} ($mins ${tr('mins_suffix')})',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: OasisColors.accentMint),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  motivation,
                  style: const TextStyle(fontSize: 12, color: OasisColors.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserLeaderboardCard(LeaderboardUser user, int rank) {
    final mins = user.getMinutesForFilter(_selectedFilter);
    final hours = (mins / 60.0).toStringAsFixed(1);
    final hasCheered = widget.storage.hasCheeredUser(user.id);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: user.isCurrentUser ? OasisColors.primary.withValues(alpha: 0.12) : OasisColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: user.isCurrentUser ? OasisColors.primary.withValues(alpha: 0.5) : OasisColors.cardBorder,
        ),
      ),
      child: Row(
        children: [
          // Rank
          SizedBox(
            width: 28,
            child: Text(
              '#$rank',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: user.isCurrentUser ? OasisColors.primary : OasisColors.textSecondary,
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Avatar
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: OasisColors.surface,
              shape: BoxShape.circle,
              border: Border.all(color: OasisColors.cardBorder),
            ),
            child: Center(
              child: Text(user.avatar, style: const TextStyle(fontSize: 20)),
            ),
          ),
          const SizedBox(width: 12),

          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        user.name,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: user.isCurrentUser ? OasisColors.primaryGlow : OasisColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                      decoration: BoxDecoration(
                        color: OasisColors.surface,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: OasisColors.cardBorder),
                      ),
                      child: Text(
                        user.studyField,
                        style: const TextStyle(fontSize: 9, color: OasisColors.textSecondary),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  user.statusMessage,
                  style: const TextStyle(fontSize: 11, color: OasisColors.textSecondary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),

          // Hours & Cheer Button
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$hours ${tr('hours_suffix')}',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: OasisColors.textPrimary),
              ),
              const SizedBox(height: 3),
              if (!user.isCurrentUser)
                InkWell(
                  onTap: hasCheered
                      ? null
                      : () async {
                          HapticFeedback.lightImpact();
                          await _communityService.sendCheer(user.id);
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(tr('cheer_sent_snack', {'name': user.name})),
                              duration: const Duration(seconds: 2),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: hasCheered
                          ? OasisColors.primary.withValues(alpha: 0.15)
                          : OasisColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: hasCheered ? OasisColors.primary : OasisColors.cardBorder,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(hasCheered ? '⚡' : '👏', style: const TextStyle(fontSize: 11)),
                        const SizedBox(width: 3),
                        Text(
                          '${user.cheersCount + (hasCheered ? 1 : 0)}',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: hasCheered ? OasisColors.primary : OasisColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('🌟', style: TextStyle(fontSize: 11)),
                    const SizedBox(width: 3),
                    Text('${user.treesPlanted} 🌳', style: const TextStyle(fontSize: 11, color: OasisColors.accentMint)),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // 2. CHALLENGES & QUESTS TAB
  // ===========================================================================

  Widget _buildChallengesTab() {
    final lang = LocaleService.instance.currentLocale;
    final challenges = FocusChallenge.allChallenges;

    final daily = challenges.where((c) => c.category == ChallengeCategory.daily).toList();
    final weekly = challenges.where((c) => c.category == ChallengeCategory.weekly).toList();
    final milestones = challenges.where((c) => c.category == ChallengeCategory.milestone).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Banner
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF065F46), Color(0xFF047857)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                const Text('⚔️', style: TextStyle(fontSize: 32)),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tr('challenges_banner_title'),
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        tr('challenges_banner_sub'),
                        style: const TextStyle(fontSize: 12, color: Colors.white70),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Daily Challenges
          _sectionHeader('⚡', tr('challenge_daily_title')),
          const SizedBox(height: 10),
          ...daily.map((c) => _buildChallengeCard(c, lang)),
          const SizedBox(height: 20),

          // Weekly Challenges
          _sectionHeader('🌟', tr('challenge_weekly_title')),
          const SizedBox(height: 10),
          ...weekly.map((c) => _buildChallengeCard(c, lang)),
          const SizedBox(height: 20),

          // Milestones
          _sectionHeader('👑', tr('challenge_milestone_title')),
          const SizedBox(height: 10),
          ...milestones.map((c) => _buildChallengeCard(c, lang)),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _sectionHeader(String icon, String title) {
    return Row(
      children: [
        Text(icon, style: const TextStyle(fontSize: 16)),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: OasisColors.textPrimary),
        ),
      ],
    );
  }

  Widget _buildChallengeCard(FocusChallenge challenge, String lang) {
    final currentVal = challenge.calculateCurrentValue(widget.storage);
    final target = challenge.target;
    final progress = challenge.getProgress(widget.storage);
    final isDone = challenge.isCompleted(widget.storage);
    final isClaimed = widget.storage.isChallengeClaimed(challenge.id);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: OasisColors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDone && !isClaimed
              ? OasisColors.coinGold
              : OasisColors.cardBorder,
          width: isDone && !isClaimed ? 1.5 : 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: OasisColors.surface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(challenge.icon, style: const TextStyle(fontSize: 22)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      challenge.title(lang),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: OasisColors.textPrimary),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      challenge.description(lang),
                      style: const TextStyle(fontSize: 11, color: OasisColors.textSecondary),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Coins Bounty
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: OasisColors.coinGold.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: OasisColors.coinGold.withValues(alpha: 0.4)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.monetization_on_rounded, size: 14, color: OasisColors.coinGold),
                    const SizedBox(width: 4),
                    Text(
                      '+${challenge.rewardCoins}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: OasisColors.coinGold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Progress Bar and Action Button
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '$currentVal / $target',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: OasisColors.textSecondary),
                        ),
                        Text(
                          '${(progress * 100).toInt()}%',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: isDone ? OasisColors.accentMint : OasisColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 7,
                        backgroundColor: OasisColors.surface,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          isDone ? OasisColors.accentMint : OasisColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),

              // Claim / State Button
              if (isClaimed)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: OasisColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: OasisColors.cardBorder),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle_rounded, size: 14, color: OasisColors.accentMint),
                      const SizedBox(width: 4),
                      Text(
                        tr('claimed'),
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: OasisColors.accentMint),
                      ),
                    ],
                  ),
                )
              else if (isDone)
                ElevatedButton(
                  onPressed: () async {
                    HapticFeedback.mediumImpact();
                    final success = await _communityService.claimChallengeReward(challenge);
                    if (!mounted) return;
                    if (success) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          backgroundColor: const Color(0xFF065F46),
                          content: Row(
                            children: [
                              const Text('🎉', style: TextStyle(fontSize: 20)),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  tr('challenge_reward_claimed_snack', {'coins': challenge.rewardCoins}),
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: OasisColors.coinGold,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 4,
                  ),
                  child: Text(
                    tr('claim_action'),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: OasisColors.surface,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    tr('in_progress_status'),
                    style: const TextStyle(fontSize: 10, color: OasisColors.textSecondary),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // 3. LIVE STUDY ROOM TAB
  // ===========================================================================

  Widget _buildLiveRoomTab(LeaderboardUser me) {
    final liveStudents = _communityService.getLiveStudents();

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Live Activity Banner
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0F766E), Color(0xFF115E59)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: const BoxDecoration(
                    color: Color(0xFF34D399),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tr('live_room_header_title', {'count': liveStudents.length}),
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        tr('live_room_header_sub'),
                        style: const TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Grid of Live Studying Peers
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.88,
            ),
            itemCount: liveStudents.length,
            itemBuilder: (context, index) {
              final student = liveStudents[index];
              return _buildLiveStudentCard(student);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLiveStudentCard(LeaderboardUser student) {
    final species = TreeSpecies.getById(student.currentTreeSpeciesId);
    final hasCheered = widget.storage.hasCheeredUser(student.id);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: OasisColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: student.isCurrentUser ? OasisColors.primary : OasisColors.cardBorder,
          width: student.isCurrentUser ? 1.5 : 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Live indicator + Avatar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF059669).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    CircleAvatar(radius: 3, backgroundColor: Color(0xFF34D399)),
                    SizedBox(width: 4),
                    Text(
                      'Live',
                      style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFF34D399)),
                    ),
                  ],
                ),
              ),
              Text(
                '${student.todayMinutes} ${tr('mins_suffix')}',
                style: const TextStyle(fontSize: 10, color: OasisColors.textSecondary, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Tree Canvas being grown
          SizedBox(
            width: 55,
            height: 55,
            child: TreeCanvas(
              progress: 0.75,
              isFailed: false,
              species: species,
              size: 55,
            ),
          ),
          const SizedBox(height: 6),

          // Name and Avatar
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(student.avatar, style: const TextStyle(fontSize: 14)),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  student.isCurrentUser ? '${student.name} (${tr('you_label')})' : student.name,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: OasisColors.textPrimary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),

          // Task being focused on
          Text(
            student.activeTask ?? student.studyField,
            style: const TextStyle(fontSize: 10, color: OasisColors.textSecondary),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
          const Spacer(),

          // Encouragement Action
          if (!student.isCurrentUser)
            SizedBox(
              width: double.infinity,
              height: 28,
              child: ElevatedButton(
                onPressed: hasCheered
                    ? null
                    : () async {
                        HapticFeedback.lightImpact();
                        await _communityService.sendCheer(student.id);
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(tr('cheer_sent_snack', {'name': student.name})),
                            duration: const Duration(seconds: 2),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: hasCheered ? OasisColors.surface : OasisColors.primary,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: Text(
                  hasCheered ? tr('energy_sent') : tr('send_energy_btn'),
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Text(
                species.name(LocaleService.instance.currentLocale),
                style: const TextStyle(fontSize: 10, color: OasisColors.primary, fontWeight: FontWeight.bold),
              ),
            ),
        ],
      ),
    );
  }

  // ===========================================================================
  // PROFILE EDIT MODAL
  // ===========================================================================

  void _showEditProfileDialog(BuildContext context, LeaderboardUser me) {
    final nameCtrl = TextEditingController(text: me.name);
    final bioCtrl = TextEditingController(text: me.statusMessage);
    final fieldCtrl = TextEditingController(text: me.studyField);
    String selectedAvatar = me.avatar;

    const availableAvatars = [
      '🌿', '🧙‍♂️', '🦉', '🚀', '🦁', '👑', '💻', '📚', '⚡', '🌸', '🦅', '🎯', '🎨', '🩺', '🌌', '🤖'
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: OasisColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          tr('edit_profile_title'),
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: OasisColors.textPrimary),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Avatar picker
                    Text(
                      tr('choose_avatar_label'),
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: OasisColors.textSecondary),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: availableAvatars.map((emoji) {
                        final isSel = selectedAvatar == emoji;
                        return InkWell(
                          onTap: () => setModalState(() => selectedAvatar = emoji),
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: isSel ? OasisColors.primary.withValues(alpha: 0.2) : OasisColors.card,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSel ? OasisColors.primary : OasisColors.cardBorder,
                                width: isSel ? 2 : 1,
                              ),
                            ),
                            child: Center(
                              child: Text(emoji, style: const TextStyle(fontSize: 22)),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 18),

                    // Nickname
                    TextField(
                      controller: nameCtrl,
                      decoration: InputDecoration(
                        labelText: tr('nickname_field'),
                        filled: true,
                        fillColor: OasisColors.card,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Study field
                    TextField(
                      controller: fieldCtrl,
                      decoration: InputDecoration(
                        labelText: tr('study_field_field'),
                        filled: true,
                        fillColor: OasisColors.card,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Bio/Status
                    TextField(
                      controller: bioCtrl,
                      decoration: InputDecoration(
                        labelText: tr('status_bio_field'),
                        filled: true,
                        fillColor: OasisColors.card,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Save Button
                    ElevatedButton(
                      onPressed: () async {
                        final newName = nameCtrl.text.trim().isEmpty ? 'مستكشف الواحة' : nameCtrl.text.trim();
                        final newBio = bioCtrl.text.trim();
                        final newField = fieldCtrl.text.trim().isEmpty ? 'عام' : fieldCtrl.text.trim();

                        await _communityService.updateProfile(
                          displayName: newName,
                          avatar: selectedAvatar,
                          bio: newBio,
                          studyField: newField,
                        );

                        if (ctx.mounted) {
                          Navigator.pop(ctx);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: OasisColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: Text(
                        tr('save_profile_btn'),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
