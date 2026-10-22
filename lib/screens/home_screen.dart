import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:uuid/uuid.dart';
import '../models/session.dart';
import '../models/tree.dart';
import '../models/task.dart';
import '../models/tag.dart';
import '../services/sound_service.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';
import '../widgets/nursery_modal.dart';
import '../widgets/progress_ring.dart';
import '../widgets/tree_canvas.dart';
import '../widgets/cloud_sync_modal.dart';
import '../widgets/mini_timer_widget.dart';
import '../widgets/achievements_modal.dart';
import '../widgets/breathing_modal.dart';
import '../widgets/donation_modal.dart';
import '../widgets/challenges_leaderboard_view.dart';
import '../services/supabase_service.dart';
import '../services/desktop_service.dart';
import '../services/locale_service.dart';

class HomeScreen extends StatefulWidget {
  final StorageService storage;
  final ValueChanged<int>? onOpenTab;

  const HomeScreen({
    super.key,
    required this.storage,
    this.onOpenTab,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  // Timer state
  SessionType _sessionType = SessionType.focus;
  SessionStatus _sessionStatus = SessionStatus.idle;
  int _totalSeconds = 25 * 60;
  int _remainingSeconds = 25 * 60;
  Timer? _timer;

  // Selected Tree & Forest
  late TreeSpecies _currentSpecies;
  int _coins = 0;
  int _completedToday = 0;
  int _dailyTarget = 4;
  String? _activeTaskId;
  String _selectedTagId = 'work';
  bool _isWilted = false;

  final SoundService _soundService = SoundService();
  final SupabaseService _supabaseService = SupabaseService();
  StreamSubscription? _remoteTimerSub;
  StreamSubscription? _authSub;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refreshFromStorage();
    _soundService.init(initialVolume: widget.storage.getAmbientVolume());

    _remoteTimerSub = _supabaseService.remoteTimerStream.listen((data) {
      if (!mounted) return;
      final remoteRemaining = data['remainingSeconds'] as int?;
      final remoteTotal = data['totalSeconds'] as int?;
      final remoteTypeStr = data['sessionType'] as String?;
      final remoteStatusStr = data['status'] as String?;

      if (remoteRemaining != null && remoteTotal != null && remoteTypeStr != null) {
        final remoteType = SessionType.values.firstWhere(
          (e) => e.name == remoteTypeStr,
          orElse: () => SessionType.focus,
        );
        final remoteStatus = SessionStatus.values.firstWhere(
          (e) => e.name == remoteStatusStr,
          orElse: () => SessionStatus.idle,
        );

        setState(() {
          _sessionType = remoteType;
          _sessionStatus = remoteStatus;
          _remainingSeconds = remoteRemaining;
          _totalSeconds = remoteTotal;
        });
      }
    });

    _authSub = _supabaseService.authStateChanges?.listen((_) {
      if (mounted) setState(() {});
    });

    DesktopService().onTogglePlayPause = () {
      if (!mounted) return;
      if (_sessionStatus == SessionStatus.running) {
        _pauseTimer();
      } else {
        _startTimer();
      }
    };
  }

  void _refreshFromStorage() {
    final speciesId = widget.storage.getSelectedTreeId();
    final today = DateTime.now();
    final sessions = widget.storage.getSessions();
    final todaySessions = sessions.where((s) =>
        s.status == SessionStatus.completed &&
        s.sessionType == SessionType.focus &&
        s.startedAt.year == today.year &&
        s.startedAt.month == today.month &&
        s.startedAt.day == today.day);

    _currentSpecies = TreeSpecies.getById(speciesId);
    _coins = widget.storage.getCoins();
    _dailyTarget = widget.storage.getDailyTarget();
    _completedToday = todaySessions.length;
    _selectedTagId = widget.storage.getSelectedTagId();

    if (_sessionStatus == SessionStatus.idle) {
      _resetTimerToType(_sessionType);
    } else if (mounted) {
      setState(() {});
    }
  }

  void _resetTimerToType(SessionType type) {
    int minutes;
    switch (type) {
      case SessionType.focus:
        minutes = widget.storage.getFocusMinutes();
        break;
      case SessionType.shortBreak:
        minutes = widget.storage.getShortBreakMinutes();
        break;
      case SessionType.longBreak:
        minutes = widget.storage.getLongBreakMinutes();
        break;
    }
    _sessionType = type;
    _totalSeconds = minutes * 60;
    _remainingSeconds = minutes * 60;
    _sessionStatus = SessionStatus.idle;
    _isWilted = false;
    if (mounted) {
      setState(() {});
    }
  }

  void _startTimer() {
    setState(() {
      _sessionStatus = SessionStatus.running;
      _isWilted = false;
    });

    _supabaseService.broadcastTimerUpdate(
      sessionType: _sessionType.name,
      status: SessionStatus.running.name,
      remainingSeconds: _remainingSeconds,
      totalSeconds: _totalSeconds,
      treeSpeciesId: _currentSpecies.id,
    );
    HapticFeedback.lightImpact();

    final ambient = widget.storage.getAmbientSound();
    if (ambient != 'none') {
      _soundService.playAmbient(ambient);
    }

    _updateTabTitle();
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        setState(() {
          _remainingSeconds--;
        });
        _updateTabTitle();
      } else {
        _onSessionComplete();
      }
    });
  }

  void _updateTabTitle() {
    final timeStr = _formatTime(_remainingSeconds);
    final icon = _sessionType == SessionType.focus ? '🌿' : '☕';
    SystemChrome.setApplicationSwitcherDescription(
      ApplicationSwitcherDescription(
        label: '($timeStr) ${tr('app_title')} $icon',
        primaryColor: OasisColors.primary.toARGB32(),
      ),
    );
  }

  void _resetTabTitle() {
    SystemChrome.setApplicationSwitcherDescription(
      ApplicationSwitcherDescription(
        label: '${tr('app_title')} • Focus Oasis',
        primaryColor: OasisColors.primary.toARGB32(),
      ),
    );
  }

  void _pauseTimer() {
    _timer?.cancel();
    _resetTabTitle();
    _soundService.stopAmbient();
    HapticFeedback.lightImpact();
    _supabaseService.broadcastTimerUpdate(
      sessionType: _sessionType.name,
      status: SessionStatus.idle.name,
      remainingSeconds: _remainingSeconds,
      totalSeconds: _totalSeconds,
      treeSpeciesId: _currentSpecies.id,
    );
    setState(() {
      _sessionStatus = SessionStatus.idle;
    });
  }

  Future<void> _onSessionComplete() async {
    _timer?.cancel();
    _resetTabTitle();
    await _soundService.stopAmbient();
    await _soundService.playSessionComplete();
    HapticFeedback.heavyImpact();

    final durationMins = _totalSeconds ~/ 60;
    final coinsAwarded = _sessionType == SessionType.focus ? (durationMins * 2) : 0;

    // 1. Save Session
    final session = FocusSession(
      id: const Uuid().v4(),
      durationMinutes: durationMins,
      sessionType: _sessionType,
      status: SessionStatus.completed,
      treeTypeId: _currentSpecies.id,
      startedAt: DateTime.now().subtract(Duration(minutes: durationMins)),
      endedAt: DateTime.now(),
      coinsEarned: coinsAwarded,
      taskId: _activeTaskId,
      tagId: _selectedTagId,
    );
    await widget.storage.saveSession(session);
    _supabaseService.pushSession(session);

    // 2. If focus session, plant living tree & reward coins
    if (_sessionType == SessionType.focus) {
      final tree = PlantedTree(
        id: const Uuid().v4(),
        sessionId: session.id,
        treeTypeId: _currentSpecies.id,
        isAlive: true,
        plantedAt: DateTime.now(),
        durationMinutes: durationMins,
        gridIndex: widget.storage.getPlantedTrees().length,
      );
      await widget.storage.savePlantedTree(tree);
      await widget.storage.addCoins(coinsAwarded);
      _supabaseService.pushPlantedTree(tree);
      _supabaseService.updateCoins(widget.storage.getCoins());

      // Increment active task completed pomodoros
      if (_activeTaskId != null) {
        final tasks = widget.storage.getTasks();
        final idx = tasks.indexWhere((t) => t.id == _activeTaskId);
        if (idx != -1) {
          tasks[idx] = tasks[idx].copyWith(
            completedPomodoros: tasks[idx].completedPomodoros + 1,
          );
          await widget.storage.saveTasks(tasks);
        }
      }
    }

    _refreshFromStorage();

    if (mounted) {
      _showCompletionDialog(coinsAwarded);
    }
  }

  void _showCompletionDialog(int coinsAwarded) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: OasisColors.surface,
        title: Center(
          child: Column(
            children: [
              const Text('🎉', style: TextStyle(fontSize: 48)),
              const SizedBox(height: 8),
              Text(
                _sessionType == SessionType.focus
                    ? tr('session_complete_title')
                    : tr('break_complete_title'),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
              ),
            ],
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_sessionType == SessionType.focus) ...[
              Text(
                tr('session_complete_desc', {'coins': coinsAwarded}),
                textAlign: TextAlign.center,
                style: const TextStyle(color: OasisColors.textSecondary, fontSize: 14),
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: OasisColors.coinGold.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: OasisColors.coinGold.withValues(alpha: 0.4)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.monetization_on_rounded, color: OasisColors.coinGold),
                    const SizedBox(width: 8),
                    Text(
                      '+$coinsAwarded',
                      style: const TextStyle(
                        color: OasisColors.coinGold,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              Text(
                tr('break_complete_desc'),
                textAlign: TextAlign.center,
                style: const TextStyle(color: OasisColors.textSecondary, fontSize: 14),
              ),
            ],
          ],
        ),
        actions: [
          Center(
            child: Column(
              children: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    if (_sessionType == SessionType.focus) {
                      _resetTimerToType(SessionType.shortBreak);
                    } else {
                      _resetTimerToType(SessionType.focus);
                    }
                  },
                  child: Text(
                    _sessionType == SessionType.focus
                        ? tr('start_short_break_action')
                        : tr('start_focus_action'),
                  ),
                ),
                if (_sessionType == SessionType.focus) ...[
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _resetTimerToType(SessionType.shortBreak);
                      BreathingModal.show(context);
                    },
                    icon: const Text('🫁', style: TextStyle(fontSize: 16)),
                    label: Text(
                      tr('breathing_suggestion'),
                      style: const TextStyle(color: OasisColors.accentMint, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Penalty / Give up
  Future<void> _confirmGiveUp() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: OasisColors.surface,
        title: Row(
          children: [
            const Text('🥀', style: TextStyle(fontSize: 24)),
            const SizedBox(width: 8),
            Text(tr('give_up_title')),
          ],
        ),
        content: Text(
          tr('give_up_desc', {'species': _currentSpecies.name(LocaleService.instance.currentLocale)}),
          style: const TextStyle(color: OasisColors.textSecondary, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(tr('continue_focus')),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: OasisColors.witheredRed),
            onPressed: () => Navigator.pop(context, true),
            child: Text(tr('confirm_give_up')),
          ),
        ],
      ),
    );

    if (confirm == true) {
      _applyGiveUpPenalty();
    }
  }

  Future<void> _applyGiveUpPenalty() async {
    _timer?.cancel();
    _resetTabTitle();
    await _soundService.stopAmbient();
    await _soundService.playTreeWithered();
    HapticFeedback.vibrate();

    final elapsedMins = (_totalSeconds - _remainingSeconds) ~/ 60;

    // Save failed session
    final session = FocusSession(
      id: const Uuid().v4(),
      durationMinutes: elapsedMins,
      sessionType: _sessionType,
      status: SessionStatus.failed,
      treeTypeId: _currentSpecies.id,
      startedAt: DateTime.now().subtract(Duration(minutes: elapsedMins)),
      endedAt: DateTime.now(),
      coinsEarned: 0,
      taskId: _activeTaskId,
      tagId: _selectedTagId,
    );
    await widget.storage.saveSession(session);
    _supabaseService.pushSession(session);

    // Save wilted tree
    if (_sessionType == SessionType.focus) {
      final tree = PlantedTree(
        id: const Uuid().v4(),
        sessionId: session.id,
        treeTypeId: _currentSpecies.id,
        isAlive: false,
        plantedAt: DateTime.now(),
        durationMinutes: elapsedMins,
        gridIndex: widget.storage.getPlantedTrees().length,
      );
      await widget.storage.savePlantedTree(tree);
      _supabaseService.pushPlantedTree(tree);
    }

    setState(() {
      _sessionStatus = SessionStatus.failed;
      _isWilted = true;
    });

    _refreshFromStorage();
  }

  double get _currentProgress {
    if (_totalSeconds <= 0) return 0.0;
    return (_totalSeconds - _remainingSeconds) / _totalSeconds;
  }

  String _formatTime(int totalSecs) {
    final mins = totalSecs ~/ 60;
    final secs = totalSecs % 60;
    return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    final isStrictMode = widget.storage.getStrictMode();
    if (isStrictMode && _sessionStatus == SessionStatus.running && _sessionType == SessionType.focus) {
      if (state == AppLifecycleState.paused || state == AppLifecycleState.hidden) {
        _applyGiveUpPenalty();
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    _remoteTimerSub?.cancel();
    _authSub?.cancel();
    _soundService.stopAmbient();
    DesktopService().onTogglePlayPause = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (DesktopService().isMiniMode) {
      return MiniTimerWidget(
        remainingSeconds: _remainingSeconds,
        totalSeconds: _totalSeconds,
        sessionType: _sessionType,
        sessionStatus: _sessionStatus,
        species: _currentSpecies,
        isWilted: _isWilted,
        onPlayPause: () {
          if (_sessionStatus == SessionStatus.running) {
            _pauseTimer();
          } else {
            _startTimer();
          }
        },
        onGiveUp: _confirmGiveUp,
        onRestoreFull: () async {
          await DesktopService().switchToFullMode();
          if (mounted) setState(() {});
        },
      );
    }

    final activeTask = widget.storage.getTasks().cast<PomodoroTask?>().firstWhere(
          (t) => t?.id == _activeTaskId,
          orElse: () => null,
        );

    return Scaffold(
      backgroundColor: OasisColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          child: Column(
            children: [
              // Top Bar Navigation
              _buildTopBar(),
              const SizedBox(height: 20),

              // Session Mode Selector (Focus / Short Break / Long Break)
              _buildModeSelector(),
              const SizedBox(height: 16),

              // Focus Context Bar (Active Tag + Daily Target in ONE sleek row)
              _buildFocusContextBar(activeTask),
              const SizedBox(height: 24),

              // The Centerpiece: Ring + Tree
              Center(
                child: CircularTimerRing(
                  progress: _currentProgress,
                  sessionType: _sessionType,
                  isWilted: _isWilted,
                  size: 280,
                  strokeWidth: 10,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Tree Canvas
                      SizedBox(
                        width: 165,
                        height: 155,
                        child: TreeCanvas(
                          progress: _isWilted ? 0.5 : _currentProgress,
                          isFailed: _isWilted,
                          species: _currentSpecies,
                          size: 155,
                        ),
                      ),
                      const SizedBox(height: 2),

                      // Digital Countdown Display
                      Text(
                        _formatTime(_remainingSeconds),
                        style: Theme.of(context).textTheme.displayLarge?.copyWith(
                              color: _isWilted
                                  ? OasisColors.witheredRed
                                  : OasisColors.textPrimary,
                            ),
                      ),
                      const SizedBox(height: 2),

                      // Tree stage label
                      Text(
                        TreeStage.fromProgress(_currentProgress, isFailed: _isWilted)
                            .label(LocaleService.instance.currentLocale),
                        style: TextStyle(
                          fontSize: 12,
                          color: _isWilted
                              ? OasisColors.witheredRed
                              : OasisColors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 22),

              // Duration Presets when Idle
              if (_sessionStatus == SessionStatus.idle && !_isWilted)
                _buildDurationPresets(),

              const SizedBox(height: 20),

              // Primary Action Buttons
              _buildActionButtons(),

              const SizedBox(height: 24),

              // Daily Focus Wisdom Card
              _buildDailyQuote(),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDailyQuote() {
    final quotesAr = [
      'التركيز ليس أن تقول نعم للشيء، بل أن تقول لا لمئات الأشياء الأخرى الجيدة.',
      'النجاح هو مجموع جهود صغيرة تتكرر يوماً بعد يوم دون استسلام.',
      'لا تنتظر اللحظة المثالية، بل خذ اللحظة الحالية واجعلها عظيمة.',
      'الشجرة العظيمة بدأت ببذرة صغيرة صمدت أمام الرياح والعواصف.',
      'إن لم تخطط لوقتك بنفسك، فسيقوم الآخرون بتخطيطه لك حتماً.',
      'البساطة والتركيز على خطوة واحدة هما جوهر الإتقان الحقيقي.',
      'دقيقة واحدة من التركيز الصافي تفوق ساعات طويلة من التشتت والتردد.',
      'راحة اليوم بعد إنجاز حقيقي ألذّ ألف مرة من راحة الهروب والتسويف.',
    ];
    final quotesEn = [
      'Focus is not saying yes to one thing, it is saying no to a hundred other good ideas.',
      'Success is the sum of small efforts repeated day in and day out without giving up.',
      'Do not wait for the perfect moment; take the present moment and make it magnificent.',
      'A great tree started as a tiny seedling that weathered all winds and storms.',
      'If you do not plan your own time, others will inevitably plan it for you.',
      'Simplicity and single-tasking are the true essence of ultimate mastery.',
      'One minute of pure, deep focus is worth hours of scattered hesitation.',
      'Rest earned after real achievement tastes a thousand times sweeter than avoidance.',
    ];
    final isAr = LocaleService.instance.currentLocale == 'ar';
    final activeQuotes = isAr ? quotesAr : quotesEn;
    final dayOfYear = DateTime.now().difference(DateTime(DateTime.now().year, 1, 1)).inDays;
    final quote = activeQuotes[dayOfYear % activeQuotes.length];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: OasisColors.card.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: OasisColors.cardBorder.withValues(alpha: 0.6)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: OasisColors.coinGold.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Text('✨', style: TextStyle(fontSize: 16)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              quote,
              style: const TextStyle(
                fontSize: 12,
                color: OasisColors.textSecondary,
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.start,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 780;
        final isVeryNarrow = constraints.maxWidth < 380;

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // App Identity
            Flexible(
              fit: FlexFit.loose,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: OasisColors.primary.withValues(alpha: 0.5)),
                      boxShadow: [
                        BoxShadow(
                          color: OasisColors.primary.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(11),
                      child: Image.asset(
                        'assets/images/app_icon.jpg',
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          tr('app_title'),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: OasisColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (!isVeryNarrow)
                          Text(
                            _currentSpecies.name(LocaleService.instance.currentLocale),
                            style: const TextStyle(fontSize: 11, color: OasisColors.accentMint),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),

            // Action Icons: Language / Coins / More Menu (or Full Row on wide screens)
            Flexible(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Quick Language Switcher
                    InkWell(
                      onTap: () => _showLanguagePicker(context),
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
                        decoration: BoxDecoration(
                          color: OasisColors.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: OasisColors.primary.withValues(alpha: 0.4)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              LocaleService.instance.currentLanguage.flag,
                              style: const TextStyle(fontSize: 13),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              LocaleService.instance.currentLocale.toUpperCase(),
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: OasisColors.accentMint,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),

                    // Coins button (opens Nursery)
                    InkWell(
                      onTap: _openNursery,
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                        decoration: BoxDecoration(
                          color: OasisColors.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: OasisColors.coinGold.withValues(alpha: 0.4)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.monetization_on_rounded, color: OasisColors.coinGold, size: 15),
                            const SizedBox(width: 4),
                            Text(
                              '$_coins',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: OasisColors.coinGold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  if (!isCompact) ...[
                    const SizedBox(width: 4),

                    // Ambient Sound Picker
                    IconButton(
                      icon: Icon(
                        _soundService.isPlaying
                            ? Icons.volume_up_rounded
                            : Icons.volume_mute_rounded,
                        color: _soundService.isPlaying
                            ? OasisColors.primary
                            : OasisColors.textSecondary,
                        size: 20,
                      ),
                      tooltip: tr('tooltip_ambient'),
                      padding: const EdgeInsets.all(7),
                      constraints: const BoxConstraints(),
                      onPressed: _showAmbientSoundDialog,
                    ),
                    const SizedBox(width: 4),

                    // Cloud Sync Button
                    IconButton(
                      icon: Icon(
                        _supabaseService.isAuthenticated
                            ? Icons.cloud_done_rounded
                            : Icons.cloud_queue_rounded,
                        color: _supabaseService.isAuthenticated
                            ? OasisColors.accentMint
                            : OasisColors.textSecondary,
                        size: 20,
                      ),
                      tooltip: tr('tooltip_cloud'),
                      padding: const EdgeInsets.all(7),
                      constraints: const BoxConstraints(),
                      onPressed: _openCloudSync,
                    ),
                    const SizedBox(width: 4),

                    // Challenges & Leaderboard Button
                    IconButton(
                      icon: const Icon(Icons.military_tech_rounded, color: OasisColors.coinGold, size: 20),
                      tooltip: tr('tooltip_challenges'),
                      padding: const EdgeInsets.all(7),
                      constraints: const BoxConstraints(),
                      onPressed: _openChallenges,
                    ),
                    const SizedBox(width: 4),

                    // Achievements Button
                    IconButton(
                      icon: const Icon(Icons.emoji_events_rounded, color: OasisColors.coinGold, size: 20),
                      tooltip: tr('tooltip_achievements'),
                      padding: const EdgeInsets.all(7),
                      constraints: const BoxConstraints(),
                      onPressed: _openAchievements,
                    ),
                    const SizedBox(width: 4),

                    // Mindful Breathing & Relaxation
                    IconButton(
                      icon: const Icon(Icons.self_improvement_rounded, color: OasisColors.accentMint, size: 20),
                      tooltip: tr('tooltip_breathing'),
                      padding: const EdgeInsets.all(7),
                      constraints: const BoxConstraints(),
                      onPressed: () => BreathingModal.show(context),
                    ),
                    const SizedBox(width: 4),

                    // Mini Mode Button (Desktop only)
                    if (DesktopService().isDesktop) ...[
                      IconButton(
                        icon: const Icon(Icons.picture_in_picture_alt_rounded, color: OasisColors.accentMint, size: 20),
                        tooltip: tr('tooltip_pip'),
                        padding: const EdgeInsets.all(7),
                        constraints: const BoxConstraints(),
                        onPressed: () async {
                          await DesktopService().switchToMiniMode();
                          if (mounted) setState(() {});
                        },
                      ),
                      const SizedBox(width: 4),
                    ],

                    // Donation & Support Button
                    IconButton(
                      icon: Icon(
                        Icons.volunteer_activism_rounded,
                        color: widget.storage.isSupporter() ? OasisColors.coinGold : const Color(0xFFF472B6),
                        size: 20,
                      ),
                      tooltip: tr('tooltip_donate'),
                      padding: const EdgeInsets.all(7),
                      constraints: const BoxConstraints(),
                      onPressed: _openDonation,
                    ),
                    const SizedBox(width: 4),

                    // Settings Button
                    IconButton(
                      icon: const Icon(Icons.tune_rounded, color: OasisColors.textSecondary, size: 20),
                      tooltip: tr('tooltip_settings'),
                      padding: const EdgeInsets.all(7),
                      constraints: const BoxConstraints(),
                      onPressed: _showSettingsDialog,
                    ),
                  ] else ...[
                    // Compact Mode: Single More Tools dropdown menu
                    const SizedBox(width: 4),
                    _buildMoreToolsMenu(),
                  ],
                ],
              ),
            ),
          ),
        ],
      );
    },
  );
  }

  Widget _buildMoreToolsMenu() {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert_rounded, color: OasisColors.textSecondary, size: 20),
      tooltip: tr('tooltip_more'),
      padding: const EdgeInsets.all(7),
      constraints: const BoxConstraints(),
      color: OasisColors.surface,
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: OasisColors.cardBorder),
      ),
      onSelected: (action) {
        switch (action) {
          case 'sound':
            _showAmbientSoundDialog();
            break;
          case 'settings':
            _showSettingsDialog();
            break;
          case 'cloud':
            _openCloudSync();
            break;
          case 'challenges':
            _openChallenges();
            break;
          case 'achievements':
            _openAchievements();
            break;
          case 'breathing':
            BreathingModal.show(context);
            break;
          case 'donate':
            _openDonation();
            break;
          case 'pip':
            DesktopService().switchToMiniMode();
            if (mounted) setState(() {});
            break;
        }
      },
      itemBuilder: (context) => [
        // Ambient Sound
        PopupMenuItem(
          value: 'sound',
          child: Row(
            children: [
              Icon(
                _soundService.isPlaying ? Icons.volume_up_rounded : Icons.volume_mute_rounded,
                color: _soundService.isPlaying ? OasisColors.primary : OasisColors.textSecondary,
                size: 20,
              ),
              const SizedBox(width: 10),
              Text(
                tr('tooltip_ambient'),
                style: const TextStyle(fontSize: 13, color: OasisColors.textPrimary),
              ),
            ],
          ),
        ),

        // Settings
        PopupMenuItem(
          value: 'settings',
          child: Row(
            children: [
              const Icon(Icons.tune_rounded, color: OasisColors.textSecondary, size: 20),
              const SizedBox(width: 10),
              Text(
                tr('tooltip_settings'),
                style: const TextStyle(fontSize: 13, color: OasisColors.textPrimary),
              ),
            ],
          ),
        ),

        // Cloud Sync
        PopupMenuItem(
          value: 'cloud',
          child: Row(
            children: [
              Icon(
                _supabaseService.isAuthenticated
                    ? Icons.cloud_done_rounded
                    : Icons.cloud_queue_rounded,
                color: _supabaseService.isAuthenticated
                    ? OasisColors.accentMint
                    : OasisColors.textSecondary,
                size: 20,
              ),
              const SizedBox(width: 10),
              Text(
                tr('tooltip_cloud'),
                style: const TextStyle(fontSize: 13, color: OasisColors.textPrimary),
              ),
            ],
          ),
        ),

        // Challenges & Leaderboard
        PopupMenuItem(
          value: 'challenges',
          child: Row(
            children: [
              const Icon(Icons.military_tech_rounded, color: OasisColors.coinGold, size: 20),
              const SizedBox(width: 10),
              Text(
                tr('tooltip_challenges'),
                style: const TextStyle(fontSize: 13, color: OasisColors.textPrimary),
              ),
            ],
          ),
        ),

        // Achievements
        PopupMenuItem(
          value: 'achievements',
          child: Row(
            children: [
              const Icon(Icons.emoji_events_rounded, color: OasisColors.coinGold, size: 20),
              const SizedBox(width: 10),
              Text(
                tr('tooltip_achievements'),
                style: const TextStyle(fontSize: 13, color: OasisColors.textPrimary),
              ),
            ],
          ),
        ),

        // Mindful Breathing
        PopupMenuItem(
          value: 'breathing',
          child: Row(
            children: [
              const Icon(Icons.self_improvement_rounded, color: OasisColors.accentMint, size: 20),
              const SizedBox(width: 10),
              Text(
                tr('tooltip_breathing'),
                style: const TextStyle(fontSize: 13, color: OasisColors.textPrimary),
              ),
            ],
          ),
        ),

        // Donation & Support
        PopupMenuItem(
          value: 'donate',
          child: Row(
            children: [
              Icon(
                Icons.volunteer_activism_rounded,
                color: widget.storage.isSupporter() ? OasisColors.coinGold : const Color(0xFFF472B6),
                size: 20,
              ),
              const SizedBox(width: 10),
              Text(
                tr('tooltip_donate'),
                style: const TextStyle(fontSize: 13, color: OasisColors.textPrimary),
              ),
            ],
          ),
        ),

        // Mini Mode if Desktop
        if (DesktopService().isDesktop)
          PopupMenuItem(
            value: 'pip',
            child: Row(
              children: [
                const Icon(Icons.picture_in_picture_alt_rounded, color: OasisColors.accentMint, size: 20),
                const SizedBox(width: 10),
                Text(
                  tr('tooltip_pip'),
                  style: const TextStyle(fontSize: 13, color: OasisColors.textPrimary),
                ),
              ],
            ),
          ),
      ],
    );
  }

  void _openChallenges() {
    if (widget.onOpenTab != null) {
      widget.onOpenTab!(2);
    } else {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => SizedBox(
          height: MediaQuery.of(context).size.height * 0.88,
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            child: ChallengesLeaderboardView(storage: widget.storage),
          ),
        ),
      );
    }
  }

  void _openAchievements() {
    AchievementsModal.show(
      context,
      storage: widget.storage,
      onDataChanged: () {
        _refreshFromStorage();
        if (mounted) setState(() {});
      },
    );
  }

  void _openDonation() {
    DonationModal.show(
      context,
      storage: widget.storage,
      onSupporterStatusChanged: () {
        _refreshFromStorage();
        if (mounted) setState(() {});
      },
    );
  }

  void _showLanguagePicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: OasisColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Text('🌐', style: TextStyle(fontSize: 22)),
                          const SizedBox(width: 8),
                          Text(
                            tr('language_label'),
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: OasisColors.textPrimary),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, color: OasisColors.textSecondary),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ...LocaleService.supportedLanguages.map((lang) {
                    final isSelected = LocaleService.instance.currentLocale == lang.code;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: InkWell(
                        onTap: () async {
                          await LocaleService.instance.setLocale(lang.code);
                          if (mounted) setState(() {});
                          if (ctx.mounted) Navigator.pop(ctx);
                        },
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: isSelected ? OasisColors.primary.withValues(alpha: 0.15) : OasisColors.card,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isSelected ? OasisColors.primary : OasisColors.cardBorder,
                              width: isSelected ? 1.5 : 1.0,
                            ),
                          ),
                          child: Row(
                            children: [
                              Text(lang.flag, style: const TextStyle(fontSize: 22)),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      lang.nativeName,
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                        color: isSelected ? OasisColors.accentMint : OasisColors.textPrimary,
                                      ),
                                    ),
                                    Text(
                                      lang.name,
                                      style: const TextStyle(fontSize: 11, color: OasisColors.textMuted),
                                    ),
                                  ],
                                ),
                              ),
                              if (isSelected)
                                const Icon(Icons.check_circle_rounded, color: OasisColors.primary, size: 22),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFocusContextBar(PomodoroTask? activeTask) {
    if (_sessionType != SessionType.focus) {
      // Guided Breathing shortcut during breaks
      return InkWell(
        onTap: () => BreathingModal.show(context),
        borderRadius: BorderRadius.circular(18),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 360),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: OasisColors.accentMint.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: OasisColors.accentMint.withValues(alpha: 0.35)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🫁', style: TextStyle(fontSize: 16)),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  tr('breathing_banner'),
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.bold,
                    color: OasisColors.accentMint,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 6),
              const Icon(Icons.arrow_forward_ios_rounded, size: 11, color: OasisColors.accentMint),
            ],
          ),
        ),
      );
    }

    final currentTag = FocusTag.presets.firstWhere(
      (t) => t.id == _selectedTagId,
      orElse: () => FocusTag.presets.first,
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Active Tag Pill (Tap to select any tag)
            InkWell(
              onTap: () => _showTagPickerSheet(context),
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: currentTag.color.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: currentTag.color.withValues(alpha: 0.45)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(currentTag.icon, style: const TextStyle(fontSize: 14)),
                    const SizedBox(width: 6),
                    Text(
                      currentTag.name(LocaleService.instance.currentLocale),
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.bold,
                        color: currentTag.color,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(Icons.unfold_more_rounded, size: 14, color: currentTag.color),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 10),

            // Daily Target Pill
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: OasisColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: OasisColors.cardBorder),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.track_changes_rounded, color: OasisColors.coinGold, size: 15),
                  const SizedBox(width: 6),
                  Text(
                    '$_completedToday/$_dailyTarget',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: OasisColors.textSecondary,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(_dailyTarget.clamp(1, 6), (index) {
                      final isDone = index < _completedToday;
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isDone ? OasisColors.primary : OasisColors.cardBorder.withValues(alpha: 0.4),
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ),
          ],
        ),

        // Active Task Pill
        if (activeTask != null) ...[
          const SizedBox(height: 10),
          Container(
            constraints: const BoxConstraints(maxWidth: 360),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: OasisColors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: OasisColors.primary.withValues(alpha: 0.4)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('📌', style: TextStyle(fontSize: 14)),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    tr('active_task_prefix', {'task': activeTask.title}),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: OasisColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                InkWell(
                  onTap: () => setState(() => _activeTaskId = null),
                  child: const Icon(Icons.close_rounded, size: 16, color: OasisColors.textMuted),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  void _showTagPickerSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: OasisColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Text('🏷️', style: TextStyle(fontSize: 20)),
                        const SizedBox(width: 8),
                        Text(
                          tr('tags_title'),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: OasisColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: OasisColors.textSecondary),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  alignment: WrapAlignment.center,
                  children: FocusTag.presets.map((tag) {
                    final isSelected = _selectedTagId == tag.id;
                    return InkWell(
                      onTap: () async {
                        setState(() => _selectedTagId = tag.id);
                        await widget.storage.setSelectedTagId(tag.id);
                        if (ctx.mounted) Navigator.pop(ctx);
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? tag.color.withValues(alpha: 0.22)
                              : OasisColors.card,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected ? tag.color : OasisColors.cardBorder,
                            width: isSelected ? 1.8 : 1.0,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(tag.icon, style: const TextStyle(fontSize: 16)),
                            const SizedBox(width: 8),
                            Text(
                              tag.name(LocaleService.instance.currentLocale),
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                color: isSelected ? Colors.white : OasisColors.textSecondary,
                              ),
                            ),
                            if (isSelected) ...[
                              const SizedBox(width: 6),
                              Icon(Icons.check_rounded, size: 16, color: tag.color),
                            ],
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 14),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildModeSelector() {
    return Container(
      constraints: const BoxConstraints(maxWidth: 420),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: OasisColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: OasisColors.cardBorder),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _modePill(SessionType.focus, '${tr('session_focus')} 🌿'),
            _modePill(SessionType.shortBreak, '${tr('session_short_break')} ☕'),
            _modePill(SessionType.longBreak, '${tr('session_long_break')} 🌴'),
          ],
        ),
      ),
    );
  }

  Widget _modePill(SessionType type, String label) {
    final isSelected = _sessionType == type;
    return InkWell(
      onTap: _sessionStatus == SessionStatus.running
          ? null
          : () => _resetTimerToType(type),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? OasisColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? Colors.white : OasisColors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildDurationPresets() {
    final presets = [15, 25, 45, 60];
    final currentMins = _totalSeconds ~/ 60;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: presets.map((mins) {
          final isSelected = currentMins == mins;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: InkWell(
              onTap: () {
                setState(() {
                  _totalSeconds = mins * 60;
                  _remainingSeconds = mins * 60;
                });
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isSelected
                      ? OasisColors.primary.withValues(alpha: 0.15)
                      : OasisColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? OasisColors.primary : OasisColors.cardBorder,
                  ),
                ),
                child: Text(
                  '$mins ${tr('mins_suffix')}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected ? OasisColors.primary : OasisColors.textSecondary,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildActionButtons() {
    if (_isWilted) {
      return ElevatedButton.icon(
        onPressed: () => _resetTimerToType(_sessionType),
        style: ElevatedButton.styleFrom(
          backgroundColor: OasisColors.surface,
          side: const BorderSide(color: OasisColors.cardBorder),
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
        ),
        icon: const Icon(Icons.refresh_rounded, color: OasisColors.primary),
        label: Text(
          tr('plant_new_tree'),
          style: const TextStyle(color: OasisColors.textPrimary, fontWeight: FontWeight.bold),
        ),
      );
    }

    if (_sessionStatus == SessionStatus.running) {
      return Wrap(
        alignment: WrapAlignment.center,
        spacing: 12,
        runSpacing: 8,
        children: [
          ElevatedButton.icon(
            onPressed: _pauseTimer,
            style: ElevatedButton.styleFrom(
              backgroundColor: OasisColors.surface,
              side: const BorderSide(color: OasisColors.cardBorder),
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
            ),
            icon: const Icon(Icons.pause_rounded, color: OasisColors.textPrimary),
            label: Text(tr('pause')),
          ),
          OutlinedButton.icon(
            onPressed: _confirmGiveUp,
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: OasisColors.witheredRed),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            icon: const Icon(Icons.close_rounded, color: OasisColors.witheredRed, size: 18),
            label: Text(tr('give_up'), style: const TextStyle(color: OasisColors.witheredRed)),
          ),
        ],
      );
    }

    // Idle
    return ElevatedButton.icon(
      onPressed: _startTimer,
      icon: const Icon(Icons.play_arrow_rounded, size: 24),
      label: Text(
        _sessionType == SessionType.focus ? tr('start_focus') : tr('start_short_break_action'),
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 15),
      ),
    );
  }

  void _openNursery() {
    if (widget.onOpenTab != null) {
      widget.onOpenTab!(4);
      return;
    }
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => SizedBox(
        height: MediaQuery.of(context).size.height * 0.75,
        child: NurseryModal(
          storage: widget.storage,
          onDataChanged: _refreshFromStorage,
          isSheet: true,
        ),
      ),
    );
  }

  void _openCloudSync() {
    CloudSyncModal.show(
      context,
      storage: widget.storage,
      onSyncComplete: () {
        _refreshFromStorage();
        if (mounted) setState(() {});
      },
    );
  }

  void _showAmbientSoundDialog() {
    final currentSound = widget.storage.getAmbientSound();
    double currentVolume = widget.storage.getAmbientVolume();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: OasisColors.surface,
            title: const Row(
              children: [
                Text('🎧', style: TextStyle(fontSize: 22)),
                SizedBox(width: 8),
                Text('أصوات الطبيعة والتركيز'),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Volume Slider Card
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: OasisColors.card,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: OasisColors.cardBorder),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.volume_up_rounded, size: 16, color: OasisColors.primary),
                                SizedBox(width: 6),
                                Text(
                                  'مستوى صوت الخلفية',
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            Text(
                              '${(currentVolume * 100).round()}%',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: OasisColors.primary,
                              ),
                            ),
                          ],
                        ),
                        Slider(
                          value: currentVolume,
                          min: 0.0,
                          max: 1.0,
                          divisions: 10,
                          activeColor: OasisColors.primary,
                          onChanged: (val) async {
                            setDialogState(() => currentVolume = val);
                            await widget.storage.setAmbientVolume(val);
                            await _soundService.setVolume(val);
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Sound Options
                  ...SoundService.options.map((opt) {
                    final isSelected = opt.id == currentSound;
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 6),
                      leading: Text(opt.icon, style: const TextStyle(fontSize: 24)),
                      title: Text(opt.nameAr, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                      subtitle: Text(opt.nameEn, style: const TextStyle(fontSize: 11, color: OasisColors.textSecondary)),
                      trailing: isSelected
                          ? const Icon(Icons.check_circle_rounded, color: OasisColors.primary)
                          : null,
                      onTap: () async {
                        await widget.storage.setAmbientSound(opt.id);
                        if (_sessionStatus == SessionStatus.running) {
                          await _soundService.playAmbient(opt.id);
                        }
                        if (context.mounted) {
                          Navigator.pop(context);
                        }
                        setState(() {});
                      },
                    );
                  }),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showSettingsDialog() {
    int focusM = widget.storage.getFocusMinutes();
    int shortM = widget.storage.getShortBreakMinutes();
    int longM = widget.storage.getLongBreakMinutes();
    int target = widget.storage.getDailyTarget();
    bool strictMode = widget.storage.getStrictMode();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: OasisColors.surface,
            title: Text(tr('settings_title')),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Language Selection
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: OasisColors.card,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: OasisColors.cardBorder),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.language_rounded, size: 16, color: OasisColors.accentMint),
                            const SizedBox(width: 6),
                            Text(
                              tr('language_label'),
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: LocaleService.supportedLanguages.map((lang) {
                            final isSelected = LocaleService.instance.currentLocale == lang.code;
                            return ChoiceChip(
                              label: Text('${lang.flag} ${lang.nativeName}'),
                              selected: isSelected,
                              selectedColor: OasisColors.primary,
                              backgroundColor: OasisColors.surface,
                              labelStyle: TextStyle(
                                fontSize: 11,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                color: isSelected ? Colors.white : OasisColors.textSecondary,
                              ),
                              onSelected: (selected) async {
                                if (selected) {
                                  await LocaleService.instance.setLocale(lang.code);
                                  setDialogState(() {});
                                  setState(() {});
                                }
                              },
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  _sliderTile(tr('focus_duration'), focusM, 5, 60, (v) {
                    setDialogState(() => focusM = v);
                  }),
                  _sliderTile(tr('short_break_duration'), shortM, 1, 15, (v) {
                    setDialogState(() => shortM = v);
                  }),
                  _sliderTile(tr('long_break_duration'), longM, 5, 30, (v) {
                    setDialogState(() => longM = v);
                  }),
                  _sliderTile(tr('daily_target_sessions'), target, 1, 12, (v) {
                    setDialogState(() => target = v);
                  }),
                  const Divider(height: 20),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text('${tr('strict_mode')} 🛡️', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                    subtitle: Text(tr('strict_mode_desc'), style: const TextStyle(fontSize: 11, color: OasisColors.textSecondary)),
                    value: strictMode,
                    activeThumbColor: OasisColors.primary,
                    onChanged: (val) {
                      setDialogState(() => strictMode = val);
                    },
                  ),
                  const Divider(height: 24),

                  // Backup & Restore Section
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: OasisColors.card,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: OasisColors.cardBorder),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.shield_outlined, size: 16, color: OasisColors.coinGold),
                            const SizedBox(width: 6),
                            Text(
                              tr('backup_section'),
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () {
                                  final jsonStr = widget.storage.exportBackupJson();
                                  Clipboard.setData(ClipboardData(text: jsonStr));
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(tr('backup_exported')),
                                      backgroundColor: OasisColors.primary,
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.download_rounded, size: 16),
                                label: Text(tr('export_json'), style: const TextStyle(fontSize: 11)),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                  side: const BorderSide(color: OasisColors.cardBorder),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () {
                                  Navigator.pop(context);
                                  _showImportBackupDialog();
                                },
                                icon: const Icon(Icons.upload_rounded, size: 16, color: OasisColors.accentMint),
                                label: Text(tr('import_json'), style: const TextStyle(fontSize: 11, color: OasisColors.accentMint)),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                  side: BorderSide(color: OasisColors.accentMint.withValues(alpha: 0.5)),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Support & Donation Tile
                  InkWell(
                    onTap: () {
                      Navigator.pop(context);
                      DonationModal.show(
                        context,
                        storage: widget.storage,
                        onSupporterStatusChanged: () {
                          _refreshFromStorage();
                          if (mounted) setState(() {});
                        },
                      );
                    },
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFFD97706).withValues(alpha: 0.15),
                            OasisColors.primary.withValues(alpha: 0.08),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: const Color(0xFFD97706).withValues(alpha: 0.4),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Text('☕', style: TextStyle(fontSize: 20)),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  tr('support_tile_title'),
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                                ),
                                Text(
                                  tr('support_tile_sub'),
                                  style: const TextStyle(fontSize: 10, color: OasisColors.textSecondary),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 13,
                            color: widget.storage.isSupporter() ? OasisColors.coinGold : const Color(0xFFD97706),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(tr('cancel')),
              ),
              ElevatedButton(
                onPressed: () async {
                  await widget.storage.setFocusMinutes(focusM);
                  await widget.storage.setShortBreakMinutes(shortM);
                  await widget.storage.setLongBreakMinutes(longM);
                  await widget.storage.setDailyTarget(target);
                  await widget.storage.setStrictMode(strictMode);
                  _refreshFromStorage();
                  if (context.mounted) {
                    Navigator.pop(context);
                  }
                },
                child: Text(tr('save_settings')),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showImportBackupDialog() {
    final textController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: OasisColors.surface,
        title: const Row(
          children: [
            Text('📥', style: TextStyle(fontSize: 22)),
            SizedBox(width: 8),
            Text('استيراد نسخة احتياطية'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'الصق نص النسخة الاحتياطية بصيغة (JSON) لاستعادة كافة الأشجار والجلسات والعملات:',
              style: TextStyle(fontSize: 12, color: OasisColors.textSecondary),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: textController,
              maxLines: 5,
              style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
              decoration: InputDecoration(
                hintText: '{"app": "Focus Oasis", ...}',
                filled: true,
                fillColor: OasisColors.card,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: OasisColors.cardBorder),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () async {
              final raw = textController.text.trim();
              if (raw.isEmpty) return;
              final success = await widget.storage.importBackupJson(raw);
              if (context.mounted) {
                Navigator.pop(context);
                if (success) {
                  _refreshFromStorage();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('تهانينا! تمت استعادة كافة بياناتك بنجاح! 🎉'),
                      backgroundColor: OasisColors.primary,
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('عذراً، تنسيق JSON غير صالح أو به خطأ! ⚠️'),
                      backgroundColor: OasisColors.witheredRed,
                    ),
                  );
                }
              }
            },
            child: const Text('استعادة البيانات'),
          ),
        ],
      ),
    );
  }

  Widget _sliderTile(String title, int value, int min, int max, ValueChanged<int> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: const TextStyle(fontSize: 13, color: OasisColors.textSecondary)),
            Text('$value دقيقة', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          ],
        ),
        Slider(
          value: value.toDouble(),
          min: min.toDouble(),
          max: max.toDouble(),
          divisions: max - min,
          activeColor: OasisColors.primary,
          onChanged: (v) => onChanged(v.round()),
        ),
      ],
    );
  }
}
