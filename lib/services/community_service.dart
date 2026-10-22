import 'package:flutter/material.dart';
import '../models/community.dart';
import '../models/session.dart';
import 'storage_service.dart';
import 'supabase_service.dart';

class CommunityService extends ChangeNotifier {
  static final CommunityService _instance = CommunityService._internal();
  factory CommunityService() => _instance;
  CommunityService._internal();

  StorageService? _storage;
  SupabaseService? _supabase;

  void init(StorageService storage, [SupabaseService? supabase]) {
    _storage = storage;
    _supabase = supabase;
  }

  // Preset community peers
  static const List<LeaderboardUser> _basePeers = [
    LeaderboardUser(
      id: 'peer_1',
      name: 'د. أحمد خليل',
      avatar: '🩺',
      studyField: 'طب وجراحة',
      statusMessage: 'مراجعة الباطنة العامة استعداداً لاختبارات الزمالة 📚',
      todayMinutes: 210,
      weekMinutes: 1180,
      allTimeMinutes: 5420,
      treesPlanted: 142,
      streakDays: 14,
      isLiveNow: true,
      currentTreeSpeciesId: 'olive_peace',
      activeTask: 'مذاكرة أمراض القلب والشرايين',
      cheersCount: 42,
      badgeTitle: '🥇 متصدر الواحة',
    ),
    LeaderboardUser(
      id: 'peer_2',
      name: 'م. سارة المهدي',
      avatar: '💻',
      studyField: 'هندسة البرمجيات',
      statusMessage: 'بناء تطبيق مفتوح المصدر بالذكاء الاصطناعي 🚀',
      todayMinutes: 185,
      weekMinutes: 980,
      allTimeMinutes: 4890,
      treesPlanted: 128,
      streakDays: 11,
      isLiveNow: true,
      currentTreeSpeciesId: 'sakura_bloom',
      activeTask: 'تطوير خوارزمية المعالجة اللغوية',
      cheersCount: 38,
      badgeTitle: '🥈 أسطورة الكود',
    ),
    LeaderboardUser(
      id: 'peer_3',
      name: 'نور الهدى',
      avatar: '📚',
      studyField: 'ثانوية عامة متفوقة',
      statusMessage: 'حل 150 مسألة فيزياء وكيمياء اليوم دون توقف ⚡',
      todayMinutes: 160,
      weekMinutes: 840,
      allTimeMinutes: 4120,
      treesPlanted: 98,
      streakDays: 9,
      isLiveNow: true,
      currentTreeSpeciesId: 'cedar_lebanon',
      activeTask: 'حل النماذج الوزارية في الفيزياء',
      cheersCount: 31,
      badgeTitle: '🥉 دودة الكتب',
    ),
    LeaderboardUser(
      id: 'peer_4',
      name: 'عمر الفاروق',
      avatar: '🦅',
      studyField: 'علوم الحاسب والأمن السيبراني',
      statusMessage: 'التحضير لشهادة OSCP واختبار الاختراق الأخلاقي 🛡️',
      todayMinutes: 135,
      weekMinutes: 720,
      allTimeMinutes: 3750,
      treesPlanted: 85,
      streakDays: 7,
      isLiveNow: false,
      currentTreeSpeciesId: 'bamboo_grove',
      cheersCount: 24,
      badgeTitle: 'حارس الواحة',
    ),
    LeaderboardUser(
      id: 'peer_5',
      name: 'ليلى الهاشمي',
      avatar: '✍️',
      studyField: 'أدب وترجمة فورية',
      statusMessage: 'ترجمة 20 صفحة من الرواية التاريخية 🌸',
      todayMinutes: 115,
      weekMinutes: 650,
      allTimeMinutes: 3240,
      treesPlanted: 74,
      streakDays: 6,
      isLiveNow: true,
      currentTreeSpeciesId: 'lavender_field',
      activeTask: 'ترجمة الفصل السابع من الأدب المقارن',
      cheersCount: 19,
      badgeTitle: 'فنانة الكلمات',
    ),
    LeaderboardUser(
      id: 'peer_6',
      name: 'ياسين كريم',
      avatar: '🎨',
      studyField: 'تصميم الواجهات UI/UX',
      statusMessage: 'إتقان التصميم الثلاثي الأبعاد وحركات المايكرو ✨',
      todayMinutes: 95,
      weekMinutes: 520,
      allTimeMinutes: 2890,
      treesPlanted: 62,
      streakDays: 5,
      isLiveNow: false,
      currentTreeSpeciesId: 'japanese_maple',
      cheersCount: 15,
      badgeTitle: 'مبدع التصميم',
    ),
    LeaderboardUser(
      id: 'peer_7',
      name: 'مريم العوضي',
      avatar: '🤖',
      studyField: 'ذكاء اصطناعي وتعلم آلة',
      statusMessage: 'تدريب نماذج الرؤية الحاسوبية على خوادم سحابية 🧠',
      todayMinutes: 80,
      weekMinutes: 460,
      allTimeMinutes: 2430,
      treesPlanted: 53,
      streakDays: 4,
      isLiveNow: true,
      currentTreeSpeciesId: 'redwood_giant',
      activeTask: 'ضبط معاملات نموذج التصنيف العصبي',
      cheersCount: 12,
      badgeTitle: 'عقل المستقبل',
    ),
    LeaderboardUser(
      id: 'peer_8',
      name: 'كريم منصور',
      avatar: '🌌',
      studyField: 'فيزياء فلكية ورياضيات',
      statusMessage: 'دراسة معادلات النسبية العامة والجاذبية الكمية 🔭',
      todayMinutes: 65,
      weekMinutes: 390,
      allTimeMinutes: 2110,
      treesPlanted: 46,
      streakDays: 3,
      isLiveNow: false,
      currentTreeSpeciesId: 'golden_acacia',
      cheersCount: 9,
      badgeTitle: 'مستكشف النجوم',
    ),
  ];

  LeaderboardUser getCurrentUserEntry() {
    if (_storage == null) {
      return const LeaderboardUser(
        id: 'me',
        name: 'أنا',
        avatar: '🌿',
        studyField: 'عام',
        statusMessage: '',
        todayMinutes: 0,
        weekMinutes: 0,
        allTimeMinutes: 0,
        treesPlanted: 0,
        streakDays: 0,
        isCurrentUser: true,
        badgeTitle: 'مستكشف الواحة',
      );
    }

    final storage = _storage!;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final weekStart = today.subtract(Duration(days: today.weekday - 1));

    final sessions = storage.getSessions();
    final completed = sessions.where((s) => s.status == SessionStatus.completed && s.sessionType == SessionType.focus).toList();

    final todayMins = completed
        .where((s) => s.startedAt.year == today.year && s.startedAt.month == today.month && s.startedAt.day == today.day)
        .fold(0, (sum, s) => sum + s.durationMinutes);

    final weekMins = completed
        .where((s) => s.startedAt.isAfter(weekStart.subtract(const Duration(seconds: 1))))
        .fold(0, (sum, s) => sum + s.durationMinutes);

    final allTimeMins = completed.fold(0, (sum, s) => sum + s.durationMinutes);

    final aliveTrees = storage.getPlantedTrees().where((t) => t.isAlive).length;
    final streak = _calculateStreak(completed);

    String badge = 'مستكشف الواحة 🌱';
    if (allTimeMins >= 1000) {
      badge = 'سيد التركيز 👑';
    } else if (allTimeMins >= 500) {
      badge = 'بطل الواحة 🌟';
    } else if (todayMins >= 100) {
      badge = 'شعلة اليوم 🔥';
    }

    return LeaderboardUser(
      id: 'current_user',
      name: storage.getUserDisplayName(),
      avatar: storage.getUserAvatar(),
      studyField: storage.getUserStudyField(),
      statusMessage: storage.getUserBio(),
      todayMinutes: todayMins,
      weekMinutes: weekMins,
      allTimeMinutes: allTimeMins,
      treesPlanted: aliveTrees,
      streakDays: streak,
      isCurrentUser: true,
      isLiveNow: true,
      currentTreeSpeciesId: storage.getSelectedTreeId(),
      cheersCount: storage.getCheeredUsers().length * 2 + 5,
      badgeTitle: badge,
    );
  }

  List<LeaderboardUser> getLeaderboard(String filter) {
    final me = getCurrentUserEntry();
    final list = List<LeaderboardUser>.from(_basePeers)..add(me);

    list.sort((a, b) {
      final valB = b.getMinutesForFilter(filter);
      final valA = a.getMinutesForFilter(filter);
      return valB.compareTo(valA);
    });

    return list;
  }

  int getCurrentUserRank(String filter) {
    final board = getLeaderboard(filter);
    final idx = board.indexWhere((u) => u.isCurrentUser);
    return idx >= 0 ? (idx + 1) : board.length;
  }

  int getMinutesToRankAhead(String filter) {
    final board = getLeaderboard(filter);
    final idx = board.indexWhere((u) => u.isCurrentUser);
    if (idx <= 0) return 0; // Already #1!

    final aheadUser = board[idx - 1];
    final me = board[idx];
    final gap = aheadUser.getMinutesForFilter(filter) - me.getMinutesForFilter(filter);
    return gap > 0 ? (gap + 1) : 1;
  }

  List<LeaderboardUser> getLiveStudents() {
    final me = getCurrentUserEntry();
    final livePeers = _basePeers.where((p) => p.isLiveNow).toList();
    return [me, ...livePeers];
  }

  Future<void> updateProfile({
    required String displayName,
    required String avatar,
    required String bio,
    required String studyField,
  }) async {
    if (_storage == null) return;
    await _storage!.setUserDisplayName(displayName);
    await _storage!.setUserAvatar(avatar);
    await _storage!.setUserBio(bio);
    await _storage!.setUserStudyField(studyField);

    // Sync to Supabase profile if authenticated
    if (_supabase != null && _supabase!.isAuthenticated) {
      try {
        await _supabase!.client?.from('profiles').update({
          'display_name': displayName,
          'avatar_icon': avatar,
          'bio_status': bio,
          'study_field': studyField,
        }).eq('id', _supabase!.currentUser!.id);
      } catch (e) {
        debugPrint('Supabase profile update error: $e');
      }
    }

    notifyListeners();
  }

  Future<bool> sendCheer(String userId) async {
    if (_storage == null) return false;
    if (_storage!.hasCheeredUser(userId)) return false;

    await _storage!.cheerUser(userId);
    notifyListeners();
    return true;
  }

  Future<bool> claimChallengeReward(FocusChallenge challenge) async {
    if (_storage == null) return false;
    if (_storage!.isChallengeClaimed(challenge.id)) return false;
    if (!challenge.isCompleted(_storage!)) return false;

    await _storage!.claimChallenge(challenge.id);
    await _storage!.addCoins(challenge.rewardCoins);
    notifyListeners();
    return true;
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
}
