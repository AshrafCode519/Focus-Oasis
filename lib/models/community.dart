import '../services/storage_service.dart';
import 'session.dart';

enum ChallengeCategory { daily, weekly, milestone }

class FocusChallenge {
  final String id;
  final String titleAr;
  final String titleEn;
  final String descAr;
  final String descEn;
  final ChallengeCategory category;
  final String icon;
  final int rewardCoins;
  final int target;
  final String unit; // 'mins', 'sessions', 'trees', 'days'

  const FocusChallenge({
    required this.id,
    required this.titleAr,
    required this.titleEn,
    required this.descAr,
    required this.descEn,
    required this.category,
    required this.icon,
    required this.rewardCoins,
    required this.target,
    required this.unit,
  });

  String title(String lang) {
    if (lang == 'ar') return titleAr;
    return titleEn;
  }

  String description(String lang) {
    if (lang == 'ar') return descAr;
    return descEn;
  }

  int calculateCurrentValue(StorageService storage) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final sessions = storage.getSessions();
    final completedSessions = sessions.where((s) => s.status == SessionStatus.completed && s.sessionType == SessionType.focus).toList();
    final trees = storage.getPlantedTrees().where((t) => t.isAlive).toList();

    switch (id) {
      // Daily 100 mins
      case 'daily_100_mins':
        final todayMins = completedSessions
            .where((s) => s.startedAt.year == today.year && s.startedAt.month == today.month && s.startedAt.day == today.day)
            .fold(0, (sum, s) => sum + s.durationMinutes);
        return todayMins.clamp(0, target);

      // Daily 4 Pomodoros
      case 'daily_4_sessions':
        final todayCount = completedSessions
            .where((s) => s.startedAt.year == today.year && s.startedAt.month == today.month && s.startedAt.day == today.day)
            .length;
        return todayCount.clamp(0, target);

      // Early Bird session (before 12 PM)
      case 'early_bird_session':
        final hasEarlyBird = completedSessions.any((s) =>
            s.startedAt.year == today.year &&
            s.startedAt.month == today.month &&
            s.startedAt.day == today.day &&
            s.startedAt.hour < 12);
        return hasEarlyBird ? 1 : 0;

      // Weekly Marathon (300 mins)
      case 'weekly_marathon_300':
        final weekStart = today.subtract(Duration(days: today.weekday - 1));
        final weekMins = completedSessions
            .where((s) => s.startedAt.isAfter(weekStart.subtract(const Duration(seconds: 1))))
            .fold(0, (sum, s) => sum + s.durationMinutes);
        return weekMins.clamp(0, target);

      // Weekly 10 Blooming Trees
      case 'weekly_10_trees':
        final weekStart = today.subtract(Duration(days: today.weekday - 1));
        final weekTrees = trees.where((t) => t.plantedAt.isAfter(weekStart.subtract(const Duration(seconds: 1)))).length;
        return weekTrees.clamp(0, target);

      // 3 Days Streak
      case 'streak_3_days':
        final streak = _calculateStreak(completedSessions);
        return streak.clamp(0, target);

      // Plant 25 Total Trees
      case 'milestone_25_trees':
        return trees.length.clamp(0, target);

      // 1000 Total Minutes Focus
      case 'milestone_1000_mins':
        final totalMins = completedSessions.fold(0, (sum, s) => sum + s.durationMinutes);
        return totalMins.clamp(0, target);

      default:
        return 0;
    }
  }

  double getProgress(StorageService storage) {
    if (target <= 0) return 0.0;
    final val = calculateCurrentValue(storage);
    return (val / target).clamp(0.0, 1.0);
  }

  bool isCompleted(StorageService storage) {
    return calculateCurrentValue(storage) >= target;
  }

  static int _calculateStreak(List<FocusSession> completedSessions) {
    if (completedSessions.isEmpty) return 0;
    final datesWithFocus = completedSessions
        .map((s) => DateTime(s.startedAt.year, s.startedAt.month, s.startedAt.day))
        .toSet();

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    DateTime checkDate;
    if (datesWithFocus.contains(today)) {
      checkDate = today;
    } else if (datesWithFocus.contains(yesterday)) {
      checkDate = yesterday;
    } else {
      return 0;
    }

    int streak = 0;
    while (datesWithFocus.contains(checkDate)) {
      streak++;
      checkDate = checkDate.subtract(const Duration(days: 1));
    }
    return streak;
  }

  static const List<FocusChallenge> allChallenges = [
    // Daily Challenges
    FocusChallenge(
      id: 'daily_100_mins',
      titleAr: 'تحدي مئوية اليوم 💯',
      titleEn: 'Daily Century (100 Mins) 💯',
      descAr: 'أنجز 100 دقيقة من التركيز والمذاكرة خلال اليوم',
      descEn: 'Complete 100 minutes of deep study today',
      category: ChallengeCategory.daily,
      icon: '⏱️',
      rewardCoins: 50,
      target: 100,
      unit: 'mins',
    ),
    FocusChallenge(
      id: 'daily_4_sessions',
      titleAr: 'رباعية التركيز 🎯',
      titleEn: 'Focus Quartet (4 Sessions) 🎯',
      descAr: 'أتمم 4 جلسات بومودورو مكتملة بنجاح اليوم',
      descEn: 'Finish 4 successful Pomodoro sessions today',
      category: ChallengeCategory.daily,
      icon: '🌿',
      rewardCoins: 40,
      target: 4,
      unit: 'sessions',
    ),
    FocusChallenge(
      id: 'early_bird_session',
      titleAr: 'طائر الصباح الباكر 🌅',
      titleEn: 'Early Bird Focus 🌅',
      descAr: 'أنهِ جلسة تركيز صباحية قبل حلول الساعة 12 ظهراً',
      descEn: 'Complete a morning focus session before 12:00 PM',
      category: ChallengeCategory.daily,
      icon: '☀️',
      rewardCoins: 35,
      target: 1,
      unit: 'sessions',
    ),

    // Weekly Challenges
    FocusChallenge(
      id: 'weekly_marathon_300',
      titleAr: 'ماراثون الأسبوع (5 ساعات) 🏃',
      titleEn: 'Weekly Marathon (5 Hours) 🏃',
      descAr: 'اجمع 300 دقيقة تركيز على مدار أيام الأسبوع',
      descEn: 'Accumulate 300 minutes of focus this week',
      category: ChallengeCategory.weekly,
      icon: '🔥',
      rewardCoins: 150,
      target: 300,
      unit: 'mins',
    ),
    FocusChallenge(
      id: 'weekly_10_trees',
      titleAr: 'غابة الأسبوع المزهرة 🌲',
      titleEn: 'Blooming Week Forest 🌲',
      descAr: 'ازرع 10 أشجار مزهرة دون استسلام هذا الأسبوع',
      descEn: 'Plant 10 blooming trees without giving up this week',
      category: ChallengeCategory.weekly,
      icon: '🌸',
      rewardCoins: 120,
      target: 10,
      unit: 'trees',
    ),
    FocusChallenge(
      id: 'streak_3_days',
      titleAr: 'صانع العادات (3 أيام متتالية) ⚡',
      titleEn: 'Habit Builder (3-Day Streak) ⚡',
      descAr: 'حافظ على سلسلة تركيز يومية متواصلة لمدة 3 أيام',
      descEn: 'Maintain a daily focus streak for 3 consecutive days',
      category: ChallengeCategory.weekly,
      icon: '🔥',
      rewardCoins: 90,
      target: 3,
      unit: 'days',
    ),

    // Milestones
    FocusChallenge(
      id: 'milestone_25_trees',
      titleAr: 'واحة الـ 25 شجرة 🏆',
      titleEn: '25 Trees Oasis 🏆',
      descAr: 'قم بغرس وتنمية 25 شجرة حية مزهرة في واحتك',
      descEn: 'Plant and grow 25 alive blooming trees in your oasis',
      category: ChallengeCategory.milestone,
      icon: '🌳',
      rewardCoins: 250,
      target: 25,
      unit: 'trees',
    ),
    FocusChallenge(
      id: 'milestone_1000_mins',
      titleAr: 'نادي الألف دقيقة 👑',
      titleEn: '1,000 Minutes Elite 👑',
      descAr: 'أنجز 1000 دقيقة إجمالية من التركيز الصافي',
      descEn: 'Log 1,000 total minutes of pure focus time',
      category: ChallengeCategory.milestone,
      icon: '👑',
      rewardCoins: 400,
      target: 1000,
      unit: 'mins',
    ),
  ];
}

class LeaderboardUser {
  final String id;
  final String name;
  final String avatar;
  final String studyField;
  final String statusMessage;
  final int todayMinutes;
  final int weekMinutes;
  final int allTimeMinutes;
  final int treesPlanted;
  final int streakDays;
  final bool isCurrentUser;
  final bool isLiveNow;
  final String currentTreeSpeciesId;
  final String? activeTask;
  final int cheersCount;
  final String badgeTitle;

  const LeaderboardUser({
    required this.id,
    required this.name,
    required this.avatar,
    required this.studyField,
    required this.statusMessage,
    required this.todayMinutes,
    required this.weekMinutes,
    required this.allTimeMinutes,
    required this.treesPlanted,
    required this.streakDays,
    this.isCurrentUser = false,
    this.isLiveNow = false,
    this.currentTreeSpeciesId = 'classic_pine',
    this.activeTask,
    this.cheersCount = 0,
    required this.badgeTitle,
  });

  int getMinutesForFilter(String filter) {
    switch (filter) {
      case 'today':
        return todayMinutes;
      case 'week':
        return weekMinutes;
      case 'all':
      default:
        return allTimeMinutes;
    }
  }

  LeaderboardUser copyWith({
    int? cheersCount,
    bool? isCurrentUser,
    String? name,
    String? avatar,
    String? statusMessage,
    String? studyField,
  }) {
    return LeaderboardUser(
      id: id,
      name: name ?? this.name,
      avatar: avatar ?? this.avatar,
      studyField: studyField ?? this.studyField,
      statusMessage: statusMessage ?? this.statusMessage,
      todayMinutes: todayMinutes,
      weekMinutes: weekMinutes,
      allTimeMinutes: allTimeMinutes,
      treesPlanted: treesPlanted,
      streakDays: streakDays,
      isCurrentUser: isCurrentUser ?? this.isCurrentUser,
      isLiveNow: isLiveNow,
      currentTreeSpeciesId: currentTreeSpeciesId,
      activeTask: activeTask,
      cheersCount: cheersCount ?? this.cheersCount,
      badgeTitle: badgeTitle,
    );
  }
}
