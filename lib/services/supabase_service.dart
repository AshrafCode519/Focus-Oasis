import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';
import '../models/session.dart';
import '../models/task.dart';
import '../models/tree.dart';
import 'storage_service.dart';

class SyncResult {
  final bool success;
  final String message;
  final int sessionsSynced;
  final int treesSynced;
  final int tasksSynced;

  const SyncResult({
    required this.success,
    required this.message,
    this.sessionsSynced = 0,
    this.treesSynced = 0,
    this.tasksSynced = 0,
  });
}

class SupabaseService {
  static final SupabaseService _instance = SupabaseService._internal();
  factory SupabaseService() => _instance;
  SupabaseService._internal();

  SupabaseClient? _client;
  bool _isInitialized = false;
  RealtimeChannel? _timerChannel;
  final _timerBroadcastStreamController = StreamController<Map<String, dynamic>>.broadcast();

  bool get isInitialized => _isInitialized && _client != null;
  SupabaseClient? get client => _client;

  User? get currentUser => isInitialized ? _client?.auth.currentUser : null;
  bool get isAuthenticated => currentUser != null;

  Stream<AuthState>? get authStateChanges =>
      isInitialized ? _client?.auth.onAuthStateChange : null;

  Stream<Map<String, dynamic>> get remoteTimerStream =>
      _timerBroadcastStreamController.stream;

  Future<bool> init(SharedPreferences prefs) async {
    final url = SupabaseConfig.getUrl(prefs);
    final anonKey = SupabaseConfig.getAnonKey(prefs);

    if (!SupabaseConfig.isConfigured(prefs)) {
      debugPrint('Supabase is in demo/placeholder mode. Configure real credentials to enable cloud sync.');
      _isInitialized = false;
      return false;
    }

    try {
      await Supabase.initialize(
        url: url,
        // ignore: deprecated_member_use
        anonKey: anonKey,
        debug: kDebugMode,
      );
      _client = Supabase.instance.client;
      _isInitialized = true;

      // Subscribe to realtime channel if user is already logged in
      if (_client?.auth.currentUser != null) {
        _subscribeToRealtimeTimer();
      }

      // Listen for auth state changes
      _client?.auth.onAuthStateChange.listen((data) {
        if (data.session?.user != null) {
          _subscribeToRealtimeTimer();
        } else {
          _timerChannel?.unsubscribe();
          _timerChannel = null;
        }
      });

      return true;
    } catch (e) {
      debugPrint('Supabase initialization error: $e');
      _isInitialized = false;
      return false;
    }
  }

  // ---------------------------------------------------------------------------
  // Authentication
  // ---------------------------------------------------------------------------

  Future<AuthResponse> signInWithEmail({
    required String email,
    required String password,
  }) async {
    if (!isInitialized) {
      throw Exception('يرجى تهيئة مفاتيح Supabase أولاً من شاشة المزامنة');
    }
    final response = await _client!.auth.signInWithPassword(
      email: email.trim(),
      password: password,
    );
    _subscribeToRealtimeTimer();
    return response;
  }

  Future<AuthResponse> signUpWithEmail({
    required String email,
    required String password,
    String? displayName,
  }) async {
    if (!isInitialized) {
      throw Exception('يرجى تهيئة مفاتيح Supabase أولاً من شاشة المزامنة');
    }
    final response = await _client!.auth.signUp(
      email: email.trim(),
      password: password,
      data: displayName != null ? {'display_name': displayName.trim()} : null,
    );
    _subscribeToRealtimeTimer();
    return response;
  }

  Future<AuthResponse> signInAnonymously() async {
    if (!isInitialized) {
      throw Exception('يرجى تهيئة مفاتيح Supabase أولاً من شاشة المزامنة');
    }
    final response = await _client!.auth.signInAnonymously();
    _subscribeToRealtimeTimer();
    return response;
  }

  Future<void> signOut() async {
    if (!isInitialized) return;
    await _timerChannel?.unsubscribe();
    _timerChannel = null;
    await _client?.auth.signOut();
  }

  // ---------------------------------------------------------------------------
  // Realtime Timer Multi-Device Synchronization Channel
  // ---------------------------------------------------------------------------

  void _subscribeToRealtimeTimer() {
    final user = currentUser;
    if (user == null || !isInitialized) return;

    _timerChannel?.unsubscribe();
    final channelName = 'oasis_timer_${user.id}';

    _timerChannel = _client!.channel(channelName);
    _timerChannel!.onBroadcast(event: 'timer_update', callback: (payload) {
      _timerBroadcastStreamController.add(payload);
    }).subscribe();
  }

  Future<void> broadcastTimerUpdate({
    required String sessionType,
    required String status,
    required int remainingSeconds,
    required int totalSeconds,
    required String treeSpeciesId,
  }) async {
    if (!isAuthenticated || _timerChannel == null) return;

    try {
      await _timerChannel!.sendBroadcastMessage(
        event: 'timer_update',
        payload: {
          'sessionType': sessionType,
          'status': status,
          'remainingSeconds': remainingSeconds,
          'totalSeconds': totalSeconds,
          'treeSpeciesId': treeSpeciesId,
          'senderId': _client?.auth.currentUser?.id,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        },
      );
    } catch (e) {
      debugPrint('Failed to broadcast timer update: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // Full Data Sync (Local <-> Supabase Cloud)
  // ---------------------------------------------------------------------------

  Future<SyncResult> syncAll(StorageService storage) async {
    if (!isAuthenticated) {
      return const SyncResult(
        success: false,
        message: 'يجب تسجيل الدخول أولاً لتفعيل المزامنة السحابية',
      );
    }

    final userId = currentUser!.id;
    int syncedSessions = 0;
    int syncedTrees = 0;
    int syncedTasks = 0;

    try {
      // 1. Sync User Profile & Coins
      final remoteProfile = await _client!
          .from('profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();

      int localCoins = storage.getCoins();
      if (remoteProfile != null && remoteProfile['coins_balance'] != null) {
        int remoteCoins = remoteProfile['coins_balance'] as int;
        int resolvedCoins = remoteCoins > localCoins ? remoteCoins : localCoins;
        await storage.setCoins(resolvedCoins);
        if (resolvedCoins != remoteCoins) {
          await _client!
              .from('profiles')
              .update({'coins_balance': resolvedCoins, 'updated_at': DateTime.now().toIso8601String()})
              .eq('id', userId);
        }
      }

      // 2. Sync Focus Sessions
      final localSessions = storage.getSessions();
      final remoteSessionsData = await _client!
          .from('sessions')
          .select()
          .eq('user_id', userId);

      final remoteSessionIds = <String>{};
      for (final item in remoteSessionsData) {
        remoteSessionIds.add(item['id'].toString());
      }

      // Upload local sessions missing from cloud
      final List<Map<String, dynamic>> sessionsToUpload = [];
      for (final s in localSessions) {
        if (!remoteSessionIds.contains(s.id)) {
          sessionsToUpload.add({
            'id': s.id,
            'user_id': userId,
            'duration_minutes': s.durationMinutes,
            'session_type': s.sessionType.name,
            'status': s.status.name,
            'tree_type_id': s.treeTypeId,
            'coins_earned': s.coinsEarned,
            'task_id': s.taskId,
            'started_at': s.startedAt.toIso8601String(),
            'ended_at': s.endedAt?.toIso8601String(),
          });
        }
      }
      if (sessionsToUpload.isNotEmpty) {
        await _client!.from('sessions').upsert(sessionsToUpload);
        syncedSessions += sessionsToUpload.length;
      }

      // Download remote sessions missing locally
      final localSessionIds = localSessions.map((e) => e.id).toSet();
      for (final item in remoteSessionsData) {
        final id = item['id'].toString();
        if (!localSessionIds.contains(id)) {
          final newSession = FocusSession(
            id: id,
            durationMinutes: item['duration_minutes'] as int? ?? 25,
            sessionType: SessionType.values.firstWhere(
              (e) => e.name == item['session_type'],
              orElse: () => SessionType.focus,
            ),
            status: SessionStatus.values.firstWhere(
              (e) => e.name == item['status'],
              orElse: () => SessionStatus.completed,
            ),
            treeTypeId: item['tree_type_id'] as String? ?? 'classic_pine',
            startedAt: DateTime.parse(item['started_at'] as String),
            endedAt: item['ended_at'] != null ? DateTime.parse(item['ended_at'] as String) : null,
            coinsEarned: item['coins_earned'] as int? ?? 0,
            taskId: item['task_id'] as String?,
          );
          await storage.saveSession(newSession);
          syncedSessions++;
        }
      }

      // 3. Sync Planted Trees (Forest Grid)
      final localTrees = storage.getPlantedTrees();
      final remoteTreesData = await _client!
          .from('forest_grid')
          .select()
          .eq('user_id', userId);

      final remoteTreeIds = remoteTreesData.map((e) => e['id'].toString()).toSet();
      final List<Map<String, dynamic>> treesToUpload = [];

      for (final t in localTrees) {
        if (!remoteTreeIds.contains(t.id)) {
          treesToUpload.add({
            'id': t.id,
            'user_id': userId,
            'session_id': t.sessionId,
            'tree_type': t.treeTypeId,
            'is_alive': t.isAlive,
            'duration_minutes': t.durationMinutes,
            'grid_index': t.gridIndex,
            'planted_at': t.plantedAt.toIso8601String(),
          });
        }
      }
      if (treesToUpload.isNotEmpty) {
        await _client!.from('forest_grid').upsert(treesToUpload);
        syncedTrees += treesToUpload.length;
      }

      final localTreeIds = localTrees.map((e) => e.id).toSet();
      for (final item in remoteTreesData) {
        final id = item['id'].toString();
        if (!localTreeIds.contains(id)) {
          final newTree = PlantedTree(
            id: id,
            sessionId: item['session_id'] as String? ?? '',
            treeTypeId: item['tree_type'] as String? ?? 'classic_pine',
            isAlive: item['is_alive'] as bool? ?? true,
            plantedAt: DateTime.parse(item['planted_at'] as String),
            durationMinutes: item['duration_minutes'] as int? ?? 25,
            gridIndex: item['grid_index'] as int? ?? 0,
          );
          await storage.savePlantedTree(newTree);
          syncedTrees++;
        }
      }

      // 4. Sync Tasks
      final localTasks = storage.getTasks();
      final remoteTasksData = await _client!
          .from('tasks')
          .select()
          .eq('user_id', userId);

      final remoteTaskIds = remoteTasksData.map((e) => e['id'].toString()).toSet();
      final List<Map<String, dynamic>> tasksToUpload = [];

      for (final t in localTasks) {
        if (!remoteTaskIds.contains(t.id)) {
          tasksToUpload.add({
            'id': t.id,
            'user_id': userId,
            'title': t.title,
            'estimated_pomodoros': t.estimatedPomodoros,
            'completed_pomodoros': t.completedPomodoros,
            'is_completed': t.isCompleted,
            'created_at': t.createdAt.toIso8601String(),
          });
        }
      }
      if (tasksToUpload.isNotEmpty) {
        await _client!.from('tasks').upsert(tasksToUpload);
        syncedTasks += tasksToUpload.length;
      }

      final localTaskIds = localTasks.map((e) => e.id).toSet();
      final List<PomodoroTask> updatedTaskList = List.from(localTasks);
      for (final item in remoteTasksData) {
        final id = item['id'].toString();
        if (!localTaskIds.contains(id)) {
          updatedTaskList.add(
            PomodoroTask(
              id: id,
              title: item['title'] as String,
              estimatedPomodoros: item['estimated_pomodoros'] as int? ?? 1,
              completedPomodoros: item['completed_pomodoros'] as int? ?? 0,
              isCompleted: item['is_completed'] as bool? ?? false,
              createdAt: DateTime.parse(item['created_at'] as String),
            ),
          );
          syncedTasks++;
        }
      }
      if (updatedTaskList.length != localTasks.length) {
        await storage.saveTasks(updatedTaskList);
      }

      return SyncResult(
        success: true,
        message: 'تمت المزامنة بنجاح مع سحابة Supabase!',
        sessionsSynced: syncedSessions,
        treesSynced: syncedTrees,
        tasksSynced: syncedTasks,
      );
    } catch (e) {
      debugPrint('Sync error: $e');
      return SyncResult(
        success: false,
        message: 'حدث خطأ أثناء المزامنة: $e',
      );
    }
  }

  // Quick background push helpers
  Future<void> pushSession(FocusSession session) async {
    if (!isAuthenticated) return;
    try {
      await _client!.from('sessions').upsert({
        'id': session.id,
        'user_id': currentUser!.id,
        'duration_minutes': session.durationMinutes,
        'session_type': session.sessionType.name,
        'status': session.status.name,
        'tree_type_id': session.treeTypeId,
        'coins_earned': session.coinsEarned,
        'task_id': session.taskId,
        'started_at': session.startedAt.toIso8601String(),
        'ended_at': session.endedAt?.toIso8601String(),
      });
    } catch (e) {
      debugPrint('Error pushing session to Supabase: $e');
    }
  }

  Future<void> pushPlantedTree(PlantedTree tree) async {
    if (!isAuthenticated) return;
    try {
      await _client!.from('forest_grid').upsert({
        'id': tree.id,
        'user_id': currentUser!.id,
        'session_id': tree.sessionId,
        'tree_type': tree.treeTypeId,
        'is_alive': tree.isAlive,
        'duration_minutes': tree.durationMinutes,
        'grid_index': tree.gridIndex,
        'planted_at': tree.plantedAt.toIso8601String(),
      });
    } catch (e) {
      debugPrint('Error pushing tree to Supabase: $e');
    }
  }

  Future<void> pushTask(PomodoroTask task) async {
    if (!isAuthenticated) return;
    try {
      await _client!.from('tasks').upsert({
        'id': task.id,
        'user_id': currentUser!.id,
        'title': task.title,
        'estimated_pomodoros': task.estimatedPomodoros,
        'completed_pomodoros': task.completedPomodoros,
        'is_completed': task.isCompleted,
        'created_at': task.createdAt.toIso8601String(),
      });
    } catch (e) {
      debugPrint('Error pushing task to Supabase: $e');
    }
  }

  Future<void> updateCoins(int coins) async {
    if (!isAuthenticated) return;
    try {
      await _client!.from('profiles').update({
        'coins_balance': coins,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', currentUser!.id);
    } catch (e) {
      debugPrint('Error updating coins on Supabase: $e');
    }
  }
}
