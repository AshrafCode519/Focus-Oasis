import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/session.dart';
import '../models/tree.dart';
import '../models/task.dart';

class StorageService {
  static const String _keyCoins = 'oasis_coins';
  static const String _keyUnlockedTrees = 'oasis_unlocked_trees';
  static const String _keySelectedTree = 'oasis_selected_tree';
  static const String _keySelectedTag = 'oasis_selected_tag';
  static const String _keyPlantedTrees = 'oasis_planted_trees';
  static const String _keySessions = 'oasis_sessions';
  static const String _keyTasks = 'oasis_tasks';
  static const String _keyFocusMinutes = 'oasis_focus_minutes';
  static const String _keyShortBreakMinutes = 'oasis_short_break_minutes';
  static const String _keyLongBreakMinutes = 'oasis_long_break_minutes';
  static const String _keyDailyTarget = 'oasis_daily_target';
  static const String _keyAmbientSound = 'oasis_ambient_sound';
  static const String _keyStrictMode = 'oasis_strict_mode';
  static const String _keyLocale = 'oasis_app_locale';

  final SharedPreferences _prefs;
  SharedPreferences get prefs => _prefs;

  StorageService(this._prefs);

  String getLocale() => _prefs.getString(_keyLocale) ?? 'ar';
  Future<void> setLocale(String langCode) async => await _prefs.setString(_keyLocale, langCode);

  bool getStrictMode() => _prefs.getBool(_keyStrictMode) ?? false;
  Future<void> setStrictMode(bool value) async => await _prefs.setBool(_keyStrictMode, value);

  static Future<StorageService> init() async {
    final prefs = await SharedPreferences.getInstance();
    final service = StorageService(prefs);
    await service.populateDemoDataIfEmpty();
    return service;
  }

  // --- Coins ---
  int getCoins() => _prefs.getInt(_keyCoins) ?? 120;
  Future<void> setCoins(int value) async {
    final clamped = value.clamp(0, 10000000);
    await _prefs.setInt(_keyCoins, clamped);
  }
  Future<void> addCoins(int amount) async {
    if (amount == 0) return;
    await setCoins(getCoins() + amount);
  }

  // --- Tree Selection & Unlocks ---
  String getSelectedTreeId() => _prefs.getString(_keySelectedTree) ?? 'classic_pine';
  Future<void> setSelectedTreeId(String id) async => await _prefs.setString(_keySelectedTree, id);

  List<String> getUnlockedTreeIds() {
    return _prefs.getStringList(_keyUnlockedTrees) ?? ['classic_pine', 'sakura_bloom'];
  }

  Future<void> unlockTree(String id) async {
    final list = getUnlockedTreeIds();
    if (!list.contains(id)) {
      list.add(id);
      await _prefs.setStringList(_keyUnlockedTrees, list);
    }
  }

  // --- Tag Selection ---
  String getSelectedTagId() => _prefs.getString(_keySelectedTag) ?? 'work';
  Future<void> setSelectedTagId(String id) async => await _prefs.setString(_keySelectedTag, id);

  // --- Planted Trees (Forest Oasis Grid) ---
  List<PlantedTree> getPlantedTrees() {
    final raw = _prefs.getString(_keyPlantedTrees);
    if (raw == null || raw.isEmpty) return [];
    try {
      final List<dynamic> list = jsonDecode(raw);
      return list.map((e) => PlantedTree.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> savePlantedTree(PlantedTree tree) async {
    final list = getPlantedTrees();
    list.insert(0, tree);
    final raw = jsonEncode(list.map((e) => e.toJson()).toList());
    await _prefs.setString(_keyPlantedTrees, raw);
  }

  // --- Sessions History ---
  List<FocusSession> getSessions() {
    final raw = _prefs.getString(_keySessions);
    if (raw == null || raw.isEmpty) return [];
    try {
      final List<dynamic> list = jsonDecode(raw);
      return list.map((e) => FocusSession.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveSession(FocusSession session) async {
    final list = getSessions();
    list.insert(0, session);
    final raw = jsonEncode(list.map((e) => e.toJson()).toList());
    await _prefs.setString(_keySessions, raw);
  }

  // --- Tasks ---
  List<PomodoroTask> getTasks() {
    final raw = _prefs.getString(_keyTasks);
    if (raw == null || raw.isEmpty) return [];
    try {
      final List<dynamic> list = jsonDecode(raw);
      return list.map((e) => PomodoroTask.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveTasks(List<PomodoroTask> tasks) async {
    final raw = jsonEncode(tasks.map((e) => e.toJson()).toList());
    await _prefs.setString(_keyTasks, raw);
  }

  // --- Durations & Daily Target ---
  int getFocusMinutes() => _prefs.getInt(_keyFocusMinutes) ?? 25;
  Future<void> setFocusMinutes(int value) async => await _prefs.setInt(_keyFocusMinutes, value);

  int getShortBreakMinutes() => _prefs.getInt(_keyShortBreakMinutes) ?? 5;
  Future<void> setShortBreakMinutes(int value) async => await _prefs.setInt(_keyShortBreakMinutes, value);

  int getLongBreakMinutes() => _prefs.getInt(_keyLongBreakMinutes) ?? 15;
  Future<void> setLongBreakMinutes(int value) async => await _prefs.setInt(_keyLongBreakMinutes, value);

  int getDailyTarget() => _prefs.getInt(_keyDailyTarget) ?? 4;
  Future<void> setDailyTarget(int value) async => await _prefs.setInt(_keyDailyTarget, value);

  String getAmbientSound() => _prefs.getString(_keyAmbientSound) ?? 'none';
  Future<void> setAmbientSound(String sound) async => await _prefs.setString(_keyAmbientSound, sound);

  // --- Demo Data Population ---
  Future<void> populateDemoDataIfEmpty({bool force = false}) async {
    if (!force && getPlantedTrees().isNotEmpty) return;

    final now = DateTime.now();
    const uuid = Uuid();

    // 1. Initial Tasks
    final demoTasks = [
      PomodoroTask(
        id: uuid.v4(),
        title: 'إعداد خطة مشروع Focus Oasis البرمجي',
        estimatedPomodoros: 4,
        completedPomodoros: 4,
        isCompleted: true,
        createdAt: now.subtract(const Duration(days: 2)),
      ),
      PomodoroTask(
        id: uuid.v4(),
        title: 'مراجعة خوارزمية نمو الشجرة ورسم Canvas',
        estimatedPomodoros: 3,
        completedPomodoros: 2,
        isCompleted: false,
        createdAt: now.subtract(const Duration(days: 1)),
      ),
      PomodoroTask(
        id: uuid.v4(),
        title: 'قراءة كتاب العادات الذرية (30 دقيقة)',
        estimatedPomodoros: 2,
        completedPomodoros: 1,
        isCompleted: false,
        createdAt: now,
      ),
    ];
    await saveTasks(demoTasks);

    // 2. Initial Planted Trees & Sessions
    final List<PlantedTree> demoTrees = [
      PlantedTree(
        id: uuid.v4(),
        sessionId: uuid.v4(),
        treeTypeId: 'sakura_bloom',
        isAlive: true,
        plantedAt: now.subtract(const Duration(hours: 2)),
        durationMinutes: 25,
        gridIndex: 0,
      ),
      PlantedTree(
        id: uuid.v4(),
        sessionId: uuid.v4(),
        treeTypeId: 'classic_pine',
        isAlive: true,
        plantedAt: now.subtract(const Duration(hours: 5)),
        durationMinutes: 45,
        gridIndex: 1,
      ),
      PlantedTree(
        id: uuid.v4(),
        sessionId: uuid.v4(),
        treeTypeId: 'golden_oak',
        isAlive: true,
        plantedAt: now.subtract(const Duration(days: 1, hours: 3)),
        durationMinutes: 25,
        gridIndex: 2,
      ),
      PlantedTree(
        id: uuid.v4(),
        sessionId: uuid.v4(),
        treeTypeId: 'desert_palm',
        isAlive: true,
        plantedAt: now.subtract(const Duration(days: 2, hours: 4)),
        durationMinutes: 30,
        gridIndex: 3,
      ),
      PlantedTree(
        id: uuid.v4(),
        sessionId: uuid.v4(),
        treeTypeId: 'classic_pine',
        isAlive: false, // Wilted sample to demonstrate penalty
        plantedAt: now.subtract(const Duration(days: 2, hours: 7)),
        durationMinutes: 12,
        gridIndex: 4,
      ),
      PlantedTree(
        id: uuid.v4(),
        sessionId: uuid.v4(),
        treeTypeId: 'zen_bonsai',
        isAlive: true,
        plantedAt: now.subtract(const Duration(days: 3, hours: 2)),
        durationMinutes: 50,
        gridIndex: 5,
      ),
    ];

    final rawTrees = jsonEncode(demoTrees.map((e) => e.toJson()).toList());
    await _prefs.setString(_keyPlantedTrees, rawTrees);

    // Corresponding sessions
    final List<FocusSession> demoSessions = demoTrees.map((t) {
      return FocusSession(
        id: t.sessionId,
        durationMinutes: t.durationMinutes,
        sessionType: SessionType.focus,
        status: t.isAlive ? SessionStatus.completed : SessionStatus.failed,
        treeTypeId: t.treeTypeId,
        startedAt: t.plantedAt,
        endedAt: t.plantedAt.add(Duration(minutes: t.durationMinutes)),
        coinsEarned: t.isAlive ? (t.durationMinutes * 2) : 0,
        taskId: demoTasks.first.id,
      );
    }).toList();

    final rawSessions = jsonEncode(demoSessions.map((e) => e.toJson()).toList());
    await _prefs.setString(_keySessions, rawSessions);

    // Unlocks & coins
    await unlockTree('sakura_bloom');
    await setCoins(180);
  }

  // --- Volume ---
  double getAmbientVolume() => _prefs.getDouble('oasis_ambient_volume') ?? 0.6;
  Future<void> setAmbientVolume(double value) async => await _prefs.setDouble('oasis_ambient_volume', value);

  // --- Backup & Restore (JSON) ---
  String exportBackupJson() {
    final data = {
      'app': 'Focus Oasis',
      'version': '1.0',
      'exported_at': DateTime.now().toIso8601String(),
      'coins': getCoins(),
      'unlocked_trees': getUnlockedTreeIds(),
      'selected_tree': getSelectedTreeId(),
      'selected_tag': getSelectedTagId(),
      'focus_minutes': getFocusMinutes(),
      'short_break_minutes': getShortBreakMinutes(),
      'long_break_minutes': getLongBreakMinutes(),
      'daily_target': getDailyTarget(),
      'ambient_sound': getAmbientSound(),
      'strict_mode': getStrictMode(),
      'locale': getLocale(),
      'planted_trees': getPlantedTrees().map((t) => t.toJson()).toList(),
      'sessions': getSessions().map((s) => s.toJson()).toList(),
      'tasks': getTasks().map((t) => t.toJson()).toList(),
    };
    return const JsonEncoder.withIndent('  ').convert(data);
  }

  Future<bool> importBackupJson(String rawJson) async {
    try {
      final Map<String, dynamic> data = jsonDecode(rawJson) as Map<String, dynamic>;
      if (data['coins'] != null) await setCoins(data['coins'] as int);
      if (data['unlocked_trees'] != null) {
        final List<String> list = (data['unlocked_trees'] as List).map((e) => e.toString()).toList();
        await _prefs.setStringList(_keyUnlockedTrees, list);
      }
      if (data['selected_tree'] != null) await setSelectedTreeId(data['selected_tree'] as String);
      if (data['selected_tag'] != null) await setSelectedTagId(data['selected_tag'] as String);
      if (data['focus_minutes'] != null) await setFocusMinutes(data['focus_minutes'] as int);
      if (data['short_break_minutes'] != null) await setShortBreakMinutes(data['short_break_minutes'] as int);
      if (data['long_break_minutes'] != null) await setLongBreakMinutes(data['long_break_minutes'] as int);
      if (data['daily_target'] != null) await setDailyTarget(data['daily_target'] as int);
      if (data['ambient_sound'] != null) await setAmbientSound(data['ambient_sound'] as String);
      if (data['strict_mode'] != null) await setStrictMode(data['strict_mode'] as bool);
      if (data['locale'] != null) await setLocale(data['locale'] as String);

      if (data['planted_trees'] != null) {
        final raw = jsonEncode(data['planted_trees']);
        await _prefs.setString(_keyPlantedTrees, raw);
      }
      if (data['sessions'] != null) {
        final raw = jsonEncode(data['sessions']);
        await _prefs.setString(_keySessions, raw);
      }
      if (data['tasks'] != null) {
        final raw = jsonEncode(data['tasks']);
        await _prefs.setString(_keyTasks, raw);
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  // --- Support & Donations ---
  bool isSupporter() => _prefs.getBool('oasis_is_supporter') ?? false;
  Future<void> setSupporter(bool value) async => await _prefs.setBool('oasis_is_supporter', value);

  String getDonationVodafone() => _prefs.getString('oasis_donation_vodafone') ?? '01000000000';
  Future<void> setDonationVodafone(String val) async => await _prefs.setString('oasis_donation_vodafone', val);

  String getDonationInstapay() => _prefs.getString('oasis_donation_instapay') ?? 'user@instapay';
  Future<void> setDonationInstapay(String val) async => await _prefs.setString('oasis_donation_instapay', val);

  String getDonationCoffee() => _prefs.getString('oasis_donation_coffee') ?? 'buymeacoffee.com/ashraf';
  Future<void> setDonationCoffee(String val) async => await _prefs.setString('oasis_donation_coffee', val);

  String getDonationPaypal() => _prefs.getString('oasis_donation_paypal') ?? 'paypal.me/ashraf';
  Future<void> setDonationPaypal(String val) async => await _prefs.setString('oasis_donation_paypal', val);

  // --- Community Profile ---
  String getUserDisplayName() => _prefs.getString('oasis_user_display_name') ?? 'أنا (مستكشف الواحة)';
  Future<void> setUserDisplayName(String name) async => await _prefs.setString('oasis_user_display_name', name);

  String getUserAvatar() => _prefs.getString('oasis_user_avatar') ?? '🌿';
  Future<void> setUserAvatar(String avatar) async => await _prefs.setString('oasis_user_avatar', avatar);

  String getUserBio() => _prefs.getString('oasis_user_bio') ?? 'أركز بحماس وإصرار لبناء واحة إنتاجيتي ✨';
  Future<void> setUserBio(String bio) async => await _prefs.setString('oasis_user_bio', bio);

  String getUserStudyField() => _prefs.getString('oasis_user_study_field') ?? 'برمجة وتطوير';
  Future<void> setUserStudyField(String field) async => await _prefs.setString('oasis_user_study_field', field);

  // --- Challenges Claimed ---
  List<String> getClaimedChallenges() => _prefs.getStringList('oasis_claimed_challenges') ?? [];
  bool isChallengeClaimed(String id) => getClaimedChallenges().contains(id);
  Future<void> claimChallenge(String id) async {
    final list = getClaimedChallenges();
    if (!list.contains(id)) {
      list.add(id);
      await _prefs.setStringList('oasis_claimed_challenges', list);
    }
  }

  // --- Cheers Sent ---
  List<String> getCheeredUsers() => _prefs.getStringList('oasis_cheered_users') ?? [];
  bool hasCheeredUser(String id) => getCheeredUsers().contains(id);
  Future<void> cheerUser(String id) async {
    final list = getCheeredUsers();
    if (!list.contains(id)) {
      list.add(id);
      await _prefs.setStringList('oasis_cheered_users', list);
    }
  }
}
