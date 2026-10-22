import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/achievement.dart';
import '../services/achievement_service.dart';
import '../services/storage_service.dart';
import '../services/locale_service.dart';
import '../theme/app_theme.dart';

class AchievementsModal extends StatefulWidget {
  final StorageService storage;
  final VoidCallback onDataChanged;

  const AchievementsModal({
    super.key,
    required this.storage,
    required this.onDataChanged,
  });

  static Future<void> show(
    BuildContext context, {
    required StorageService storage,
    required VoidCallback onDataChanged,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => SizedBox(
        height: MediaQuery.of(context).size.height * 0.85,
        child: AchievementsModal(
          storage: storage,
          onDataChanged: onDataChanged,
        ),
      ),
    );
  }

  @override
  State<AchievementsModal> createState() => _AchievementsModalState();
}

class _AchievementsModalState extends State<AchievementsModal> {
  late AchievementService _achievementService;
  late List<UserAchievementProgress> _achievements;

  @override
  void initState() {
    super.initState();
    _achievementService = AchievementService(widget.storage);
    _loadData();
  }

  void _loadData() {
    setState(() {
      _achievements = _achievementService.getAchievementsProgress();
    });
  }

  Future<void> _claim(UserAchievementProgress progress) async {
    HapticFeedback.heavyImpact();
    await _achievementService.claimReward(progress.achievement.id);
    widget.onDataChanged();
    _loadData();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: OasisColors.card,
          content: Row(
            children: [
              const Text('🎉', style: TextStyle(fontSize: 22)),
              const SizedBox(width: 10),
              Text(
                'مبروك! حصلت على +${progress.achievement.rewardCoins} عملة واحة 🪙',
                style: const TextStyle(color: OasisColors.coinGold, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final int unlockedCount = _achievements.where((a) => a.isUnlocked).length;
    final int totalCount = _achievements.length;
    final double overallProgress = totalCount > 0 ? unlockedCount / totalCount : 0.0;

    return Container(
      decoration: const BoxDecoration(
        color: OasisColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 44,
              height: 5,
              decoration: BoxDecoration(
                color: OasisColors.cardBorder,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Text('🏆', style: TextStyle(fontSize: 26)),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tr('achievements_title'),
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Total Progress Banner
          Container(
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
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: OasisColors.primary.withValues(alpha: 0.4)),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'مستوى الإنجاز العام: $unlockedCount من $totalCount',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    Text(
                      '${(overallProgress * 100).toInt()}%',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: OasisColors.accentMint,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: overallProgress,
                    minHeight: 8,
                    backgroundColor: OasisColors.surface,
                    valueColor: const AlwaysStoppedAnimation(OasisColors.primary),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Achievements List
          Expanded(
            child: ListView.separated(
              itemCount: _achievements.length,
              separatorBuilder: (context, index) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final item = _achievements[index];
                return _buildAchievementCard(item);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAchievementCard(UserAchievementProgress item) {
    final a = item.achievement;
    final isUnlocked = item.isUnlocked;
    final isClaimed = item.isClaimed;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isUnlocked
            ? OasisColors.card
            : OasisColors.card.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isUnlocked
              ? (isClaimed
                  ? OasisColors.cardBorder
                  : OasisColors.coinGold.withValues(alpha: 0.6))
              : OasisColors.cardBorder.withValues(alpha: 0.4),
          width: (isUnlocked && !isClaimed) ? 1.5 : 1.0,
        ),
      ),
      child: Row(
        children: [
          // Icon Circle
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: isUnlocked
                  ? OasisColors.surface
                  : Colors.black.withValues(alpha: 0.3),
              shape: BoxShape.circle,
              border: Border.all(
                color: isUnlocked
                    ? OasisColors.accentMint.withValues(alpha: 0.5)
                    : Colors.transparent,
              ),
            ),
            child: Center(
              child: Text(
                isUnlocked ? a.iconEmoji : '🔒',
                style: TextStyle(
                  fontSize: 22,
                  color: isUnlocked ? null : Colors.grey,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),

          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  a.title(LocaleService.instance.currentLocale),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: isUnlocked
                        ? OasisColors.textPrimary
                        : OasisColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  a.description(LocaleService.instance.currentLocale),
                  style: const TextStyle(
                    fontSize: 11,
                    color: OasisColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),

                // Progress Bar
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: item.percent,
                          minHeight: 5,
                          backgroundColor: OasisColors.surface,
                          valueColor: AlwaysStoppedAnimation(
                            isUnlocked
                                ? OasisColors.accentMint
                                : OasisColors.textMuted,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${item.currentProgress}/${a.maxRequirement}',
                      style: const TextStyle(
                        fontSize: 10,
                        color: OasisColors.textMuted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),

          // Action Button / Badge
          if (isClaimed) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: OasisColors.primary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: OasisColors.primary.withValues(alpha: 0.4)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.check_circle_rounded, size: 14, color: OasisColors.accentMint),
                  const SizedBox(width: 4),
                  Text(
                    tr('claimed'),
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: OasisColors.accentMint,
                    ),
                  ),
                ],
              ),
            ),
          ] else if (isUnlocked) ...[
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: OasisColors.coinGold,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () => _claim(item),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('🪙', style: TextStyle(fontSize: 13)),
                  const SizedBox(width: 4),
                  Text(
                    '+${a.rewardCoins}',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ] else ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '+${a.rewardCoins} 🪙',
                style: const TextStyle(
                  fontSize: 11,
                  color: OasisColors.textMuted,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
