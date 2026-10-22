import '../models/achievement.dart';
import '../models/session.dart';
import 'storage_service.dart';

class AchievementService {
  static const String _keyClaimedAchievements = 'oasis_claimed_achievements';

  final StorageService storage;

  AchievementService(this.storage);

  List<String> getClaimedAchievementIds() {
    return storage.prefs.getStringList(_keyClaimedAchievements) ?? [];
  }

  Future<void> claimReward(String achievementId) async {
    final achievement = Achievement.catalog.firstWhere((a) => a.id == achievementId);
    final claimed = getClaimedAchievementIds();
    if (!claimed.contains(achievementId)) {
      claimed.add(achievementId);
      await storage.prefs.setStringList(_keyClaimedAchievements, claimed);
      await storage.addCoins(achievement.rewardCoins);
    }
  }

  List<UserAchievementProgress> getAchievementsProgress() {
    final claimed = getClaimedAchievementIds();
    final plantedTrees = storage.getPlantedTrees();
    final aliveTreesCount = plantedTrees.where((t) => t.isAlive).length;
    final totalFocusMinutes = plantedTrees
        .where((t) => t.isAlive)
        .fold(0, (sum, t) => sum + t.durationMinutes);
    final unlockedTreesCount = storage.getUnlockedTreeIds().length;
    final tasks = storage.getTasks();
    final completedTasksCount = tasks.where((t) => t.isCompleted).length;

    // Check daily goal
    final today = DateTime.now();
    final sessions = storage.getSessions();
    final todayCompletedSessions = sessions.where((s) =>
        s.status == SessionStatus.completed &&
        s.sessionType == SessionType.focus &&
        s.startedAt.year == today.year &&
        s.startedAt.month == today.month &&
        s.startedAt.day == today.day).length;
    final dailyTarget = storage.getDailyTarget();
    final dailyGoalAchieved = todayCompletedSessions >= dailyTarget;

    // Check strict mode session
    final hasCompletedSession = sessions.any((s) =>
        s.status == SessionStatus.completed && s.sessionType == SessionType.focus);

    return Achievement.catalog.map((a) {
      int current = 0;
      switch (a.id) {
        case 'first_tree':
          current = aliveTreesCount >= 1 ? 1 : 0;
          break;
        case 'five_trees':
          current = aliveTreesCount;
          break;
        case 'focus_century':
          current = totalFocusMinutes;
          break;
        case 'daily_goal':
          current = dailyGoalAchieved ? 1 : 0;
          break;
        case 'tree_collector':
          current = unlockedTreesCount;
          break;
        case 'task_crusher':
          current = completedTasksCount;
          break;
        case 'steel_focus':
          current = (storage.getStrictMode() && hasCompletedSession) ? 1 : 0;
          break;
      }

      final isUnlocked = current >= a.maxRequirement;
      final isClaimed = claimed.contains(a.id);

      return UserAchievementProgress(
        achievement: a,
        currentProgress: current.clamp(0, a.maxRequirement),
        isUnlocked: isUnlocked,
        isClaimed: isClaimed,
      );
    }).toList();
  }
}
