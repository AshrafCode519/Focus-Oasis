import 'package:flutter/material.dart';
import '../models/session.dart';
import '../models/tree.dart';
import '../models/tag.dart';
import '../services/storage_service.dart';
import '../services/locale_service.dart';
import '../theme/app_theme.dart';

class AnalyticsView extends StatefulWidget {
  final StorageService storage;

  const AnalyticsView({super.key, required this.storage});

  @override
  State<AnalyticsView> createState() => _AnalyticsViewState();
}

class _AnalyticsViewState extends State<AnalyticsView> {
  DateTime? _selectedHeatmapDate;

  static const Map<String, List<String>> _dayNamesMap = {
    'ar': ['الإثنين', 'الثلاثاء', 'الأربعاء', 'الخميس', 'الجمعة', 'السبت', 'الأحد'],
    'en': ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'],
    'fr': ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'],
    'es': ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'],
  };

  static const Map<String, List<String>> _fullDayNamesMap = {
    'ar': ['الإثنين', 'الثلاثاء', 'الأربعاء', 'الخميس', 'الجمعة', 'السبت', 'الأحد'],
    'en': ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'],
    'fr': ['Lundi', 'Mardi', 'Mercredi', 'Jeudi', 'Vendredi', 'Samedi', 'Dimanche'],
    'es': ['Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo'],
  };

  static const Map<String, List<String>> _monthsMap = {
    'ar': ['يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو', 'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر'],
    'en': ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'],
    'fr': ['Janv.', 'Févr.', 'Mars', 'Avr.', 'Mai', 'Juin', 'Juil.', 'Août', 'Sept.', 'Oct.', 'Nov.', 'Déc.'],
    'es': ['Ene.', 'Feb.', 'Mar.', 'Abr.', 'May.', 'Jun.', 'Jul.', 'Ago.', 'Sept.', 'Oct.', 'Nov.', 'Dic.'],
  };

  String _formatSessionDate(DateTime dt, String lang) {
    final months = _monthsMap[lang] ?? _monthsMap['en']!;
    final hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
    final period = lang == 'ar' ? (dt.hour >= 12 ? 'م' : 'ص') : (dt.hour >= 12 ? 'PM' : 'AM');
    final minuteStr = dt.minute.toString().padLeft(2, '0');
    return '${dt.day} ${months[dt.month - 1]} - $hour:$minuteStr $period';
  }

  String _formatHeatmapDate(DateTime dt, String lang) {
    final days = _fullDayNamesMap[lang] ?? _fullDayNamesMap['en']!;
    final months = _monthsMap[lang] ?? _monthsMap['en']!;
    final dayStr = days[dt.weekday - 1];
    final monthStr = months[dt.month - 1];
    if (lang == 'ar') {
      return '$dayStr، ${dt.day} $monthStr ${dt.year}';
    }
    return '$dayStr, ${dt.day} $monthStr ${dt.year}';
  }

  int _calculateStreak(List<FocusSession> completedSessions) {
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

  @override
  Widget build(BuildContext context) {
    final sessions = widget.storage.getSessions();
    final completedSessions = sessions.where((s) => s.status == SessionStatus.completed).toList();
    final totalMinutes = completedSessions.fold(0, (sum, s) => sum + s.durationMinutes);
    final totalHours = (totalMinutes / 60.0).toStringAsFixed(1);
    final aliveTrees = widget.storage.getPlantedTrees().where((t) => t.isAlive).length;
    final wiltedTrees = widget.storage.getPlantedTrees().where((t) => !t.isAlive).length;
    final totalTrees = aliveTrees + wiltedTrees;
    final successRate = totalTrees == 0 ? 100 : ((aliveTrees / totalTrees) * 100).round();
    final streakDays = _calculateStreak(completedSessions);

    return Scaffold(
      backgroundColor: OasisColors.background,
      appBar: AppBar(
        backgroundColor: OasisColors.surface,
        elevation: 0,
        title: Row(
          children: [
            const Text('📊', style: TextStyle(fontSize: 22)),
            const SizedBox(width: 8),
            Text(
              tr('analytics_title'),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Streak Card 🔥
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFB45309), Color(0xFFD97706)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFD97706).withValues(alpha: 0.3),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Text('🔥', style: TextStyle(fontSize: 32)),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tr('streak_title'),
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          tr('streak_days', {'count': streakDays}),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          streakDays > 0
                              ? tr('streak_subtitle_active')
                              : tr('streak_subtitle_empty'),
                          style: const TextStyle(color: Colors.white, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Metrics Grid
            Row(
              children: [
                Expanded(
                  child: _metricBox(
                    title: tr('focus_hours'),
                    value: '$totalHours ${tr('hours_suffix')}',
                    subtitle: tr('total_minutes_sub', {'count': totalMinutes}),
                    icon: '⏱️',
                    color: OasisColors.primaryGlow,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _metricBox(
                    title: tr('living_trees'),
                    value: '$aliveTrees 🌳',
                    subtitle: tr('wilted_count_sub', {'count': wiltedTrees}),
                    icon: '🌸',
                    color: OasisColors.accentMint,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _metricBox(
                    title: tr('completion_rate'),
                    value: '$successRate%',
                    subtitle: tr('of_all_sessions'),
                    icon: '🎯',
                    color: OasisColors.coinGold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Productivity Activity Heatmap (GitHub / Forest Style)
            _buildHeatmapCard(completedSessions),
            const SizedBox(height: 24),

            // Weekly Focus Bar Chart Card (Real Data)
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: OasisColors.card,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: OasisColors.cardBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            tr('weekly_focus_title'),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: OasisColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            tr('weekly_focus_sub'),
                            style: const TextStyle(color: OasisColors.textSecondary, fontSize: 12),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: OasisColors.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: OasisColors.cardBorder),
                        ),
                        child: Text(
                          tr('last_7_days'),
                          style: const TextStyle(fontSize: 11, color: OasisColors.primary),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Dynamic Bars
                  _buildDynamicWeeklyBarChart(completedSessions),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Tag Distribution Card (Dynamic Data)
            _buildTagDistributionCard(completedSessions),
            const SizedBox(height: 24),

            // Session History Log
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  tr('recent_sessions_title'),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Text(
                  tr('sessions_logged', {'count': sessions.length}),
                  style: const TextStyle(fontSize: 12, color: OasisColors.textSecondary),
                ),
              ],
            ),
            const SizedBox(height: 12),

            if (sessions.isEmpty)
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: OasisColors.card,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: OasisColors.cardBorder),
                ),
                child: Center(
                  child: Text(
                    tr('no_sessions_yet'),
                    style: const TextStyle(color: OasisColors.textSecondary, fontSize: 13),
                  ),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: sessions.take(8).length,
                separatorBuilder: (context, index) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final s = sessions[index];
                  final species = TreeSpecies.getById(s.treeTypeId);
                  final isSuccess = s.status == SessionStatus.completed;
                  final lang = LocaleService.instance.currentLocale;
                  final tag = FocusTag.getById(s.tagId ?? 'general');

                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: OasisColors.card,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: OasisColors.cardBorder),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: isSuccess
                                ? OasisColors.primary.withValues(alpha: 0.15)
                                : OasisColors.witheredRed.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            isSuccess ? species.iconEmoji : '🥀',
                            style: const TextStyle(fontSize: 18),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    isSuccess ? species.name(lang) : tr('wilted_session_prefix', {'species': species.name(lang)}),
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                      color: isSuccess
                                          ? OasisColors.textPrimary
                                          : OasisColors.witheredRed,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: tag.color.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      '${tag.icon} ${tag.name(lang)}',
                                      style: TextStyle(fontSize: 10, color: tag.color, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _formatSessionDate(s.startedAt, lang),
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: OasisColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '${s.durationMinutes} ${tr('mins_suffix')}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: OasisColors.textPrimary,
                              ),
                            ),
                            if (isSuccess && s.coinsEarned > 0)
                              Text(
                                '+${s.coinsEarned} 🪙',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: OasisColors.coinGold,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _metricBox({
    required String title,
    required String value,
    required String subtitle,
    required String icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      decoration: BoxDecoration(
        color: OasisColors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: OasisColors.cardBorder),
      ),
      child: Column(
        children: [
          Text(icon, style: const TextStyle(fontSize: 20)),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
          ),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 10, color: OasisColors.textSecondary),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Productivity Activity Heatmap (GitHub / Forest Style)
  // ---------------------------------------------------------------------------
  Widget _buildHeatmapCard(List<FocusSession> completedSessions) {
    // Generate last 70 days (10 weeks of 7 days)
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    const int totalDays = 70;

    // Map day string YYYY-MM-DD -> total minutes
    final Map<String, int> dailyMinutes = {};
    final Map<String, int> dailyTrees = {};

    for (final s in completedSessions) {
      final key = '${s.startedAt.year}-${s.startedAt.month.toString().padLeft(2, '0')}-${s.startedAt.day.toString().padLeft(2, '0')}';
      dailyMinutes[key] = (dailyMinutes[key] ?? 0) + s.durationMinutes;
      dailyTrees[key] = (dailyTrees[key] ?? 0) + 1;
    }

    final List<DateTime> daysList = [];
    for (int i = totalDays - 1; i >= 0; i--) {
      daysList.add(today.subtract(Duration(days: i)));
    }

    // Selected day info
    final activeDate = _selectedHeatmapDate ?? today;
    final activeKey = '${activeDate.year}-${activeDate.month.toString().padLeft(2, '0')}-${activeDate.day.toString().padLeft(2, '0')}';
    final activeMins = dailyMinutes[activeKey] ?? 0;
    final activeTreesCount = dailyTrees[activeKey] ?? 0;
    final lang = LocaleService.instance.currentLocale;
    final activeDateFormatted = _formatHeatmapDate(activeDate, lang);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: OasisColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: OasisColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Text('🌿', style: TextStyle(fontSize: 18)),
                  const SizedBox(width: 8),
                  Text(
                    tr('heatmap_title'),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: OasisColors.textPrimary,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  _legendSquare(OasisColors.surface),
                  const SizedBox(width: 3),
                  _legendSquare(const Color(0xFF065F46)),
                  const SizedBox(width: 3),
                  _legendSquare(const Color(0xFF059669)),
                  const SizedBox(width: 3),
                  _legendSquare(const Color(0xFF10B981)),
                  const SizedBox(width: 3),
                  _legendSquare(const Color(0xFF34D399)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Horizontal scrollable Heatmap Grid
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: List.generate(10, (weekIdx) {
                return Padding(
                  padding: const EdgeInsets.only(right: 5),
                  child: Column(
                    children: List.generate(7, (dayIdx) {
                      final itemIdx = (weekIdx * 7) + dayIdx;
                      if (itemIdx >= daysList.length) return const SizedBox();
                      final date = daysList[itemIdx];
                      final key = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
                      final mins = dailyMinutes[key] ?? 0;
                      final isSelected = _selectedHeatmapDate != null &&
                          _selectedHeatmapDate!.year == date.year &&
                          _selectedHeatmapDate!.month == date.month &&
                          _selectedHeatmapDate!.day == date.day;

                      Color cellColor;
                      if (mins == 0) {
                        cellColor = OasisColors.surface;
                      } else if (mins <= 25) {
                        cellColor = const Color(0xFF065F46);
                      } else if (mins <= 55) {
                        cellColor = const Color(0xFF059669);
                      } else if (mins <= 100) {
                        cellColor = const Color(0xFF10B981);
                      } else {
                        cellColor = const Color(0xFF34D399);
                      }

                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedHeatmapDate = date;
                          });
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          margin: const EdgeInsets.all(2.5),
                          width: 18,
                          height: 18,
                          decoration: BoxDecoration(
                            color: cellColor,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: isSelected
                                  ? Colors.white
                                  : mins > 0
                                      ? cellColor.withValues(alpha: 0.5)
                                      : OasisColors.cardBorder,
                              width: isSelected ? 2.0 : 0.8,
                            ),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: cellColor.withValues(alpha: 0.8),
                                      blurRadius: 6,
                                      spreadRadius: 1,
                                    ),
                                  ]
                                : null,
                          ),
                        ),
                      );
                    }),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 14),

          // Selected Day Interactive Info Banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: OasisColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: OasisColors.cardBorder),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      const Icon(Icons.event_note_rounded, size: 16, color: OasisColors.primary),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          activeDateFormatted,
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  activeMins > 0
                      ? '$activeMins ${tr('mins_suffix')} | $activeTreesCount 🌳'
                      : tr('no_activity'),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: activeMins > 0 ? OasisColors.accentMint : OasisColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _legendSquare(Color color) {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(2),
        border: Border.all(color: OasisColors.cardBorder, width: 0.5),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Dynamic Weekly Bar Chart
  // ---------------------------------------------------------------------------
  Widget _buildDynamicWeeklyBarChart(List<FocusSession> completedSessions) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final lang = LocaleService.instance.currentLocale;
    final days = _dayNamesMap[lang] ?? _dayNamesMap['en']!;

    // Collect last 7 days
    final List<Map<String, dynamic>> last7Days = [];
    double maxMins = 30.0;

    for (int i = 6; i >= 0; i--) {
      final date = today.subtract(Duration(days: i));
      final daySessions = completedSessions.where((s) =>
          s.startedAt.year == date.year &&
          s.startedAt.month == date.month &&
          s.startedAt.day == date.day);
      final int mins = daySessions.fold(0, (sum, s) => sum + s.durationMinutes);
      if (mins > maxMins) maxMins = mins.toDouble();

      final dayName = days[date.weekday - 1];
      last7Days.add({
        'day': dayName,
        'mins': mins,
        'isToday': i == 0,
      });
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: last7Days.map((d) {
        final double mins = (d['mins'] as int).toDouble();
        final double heightFactor = (mins / maxMins).clamp(0.12, 1.0);
        final bool isToday = d['isToday'] as bool;

        return Column(
          children: [
            Text(
              '${mins.toInt()} ${tr('mins_suffix')}',
              style: TextStyle(
                fontSize: 10,
                color: isToday ? OasisColors.primaryGlow : OasisColors.textSecondary,
                fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            const SizedBox(height: 6),
            Container(
              width: 24,
              height: 120 * heightFactor,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isToday
                      ? [OasisColors.primary, OasisColors.primaryGlow]
                      : mins > 0
                          ? [
                              OasisColors.cardBorder,
                              OasisColors.primary.withValues(alpha: 0.6),
                            ]
                          : [
                              OasisColors.surface,
                              OasisColors.cardBorder,
                            ],
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                ),
                borderRadius: BorderRadius.circular(8),
                boxShadow: isToday && mins > 0
                    ? [
                        BoxShadow(
                          color: OasisColors.primary.withValues(alpha: 0.4),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              d['day'] as String,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                color: isToday ? OasisColors.primary : OasisColors.textSecondary,
              ),
            ),
          ],
        );
      }).toList(),
    );
  }

  // ---------------------------------------------------------------------------
  // Dynamic Tag Distribution
  // ---------------------------------------------------------------------------
  Widget _buildTagDistributionCard(List<FocusSession> completedSessions) {
    final Map<String, int> tagMins = {};
    int totalFocusMins = 0;

    for (final s in completedSessions) {
      final tagId = s.tagId ?? 'general';
      tagMins[tagId] = (tagMins[tagId] ?? 0) + s.durationMinutes;
      totalFocusMins += s.durationMinutes;
    }

    // Sort presets by minutes
    final sortedPresets = List<FocusTag>.from(FocusTag.presets)
      ..sort((a, b) => (tagMins[b.id] ?? 0).compareTo(tagMins[a.id] ?? 0));

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: OasisColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: OasisColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                tr('tag_distribution_title'),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: OasisColors.textPrimary,
                ),
              ),
              Text(
                tr('minutes_logged', {'count': totalFocusMins}),
                style: const TextStyle(fontSize: 11, color: OasisColors.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...sortedPresets.map((tag) {
            final mins = tagMins[tag.id] ?? 0;
            final double fraction = totalFocusMins == 0 ? 0.0 : (mins / totalFocusMins);
            final percent = '${(fraction * 100).round()}%';
            final lang = LocaleService.instance.currentLocale;

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _tagBar(
                '${tag.icon} ${tag.name(lang)} ($mins ${tr('mins_suffix')})',
                fraction,
                percent,
                tag.color,
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _tagBar(String title, double fraction, String percent, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: const TextStyle(fontSize: 13, color: OasisColors.textPrimary)),
            Text(percent, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: color)),
          ],
        ),
        const SizedBox(height: 5),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: fraction,
            minHeight: 7,
            backgroundColor: OasisColors.surface,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }
}
