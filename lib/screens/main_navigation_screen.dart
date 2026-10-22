import 'package:flutter/material.dart';
import '../services/storage_service.dart';
import '../services/locale_service.dart';
import '../theme/app_theme.dart';
import '../widgets/analytics_view.dart';
import '../widgets/challenges_leaderboard_view.dart';
import '../widgets/nursery_modal.dart';
import '../widgets/oasis_grid.dart';
import '../widgets/tasks_sheet.dart';
import 'home_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  final StorageService storage;

  const MainNavigationScreen({super.key, required this.storage});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;
  String? _activeTaskId;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
      builder: (context, opacity, child) => Opacity(opacity: opacity, child: child),
      child: Scaffold(
        backgroundColor: OasisColors.background,
        body: IndexedStack(
        index: _currentIndex,
        children: [
          // 0: Focus Timer Screen
          HomeScreen(
            storage: widget.storage,
            onOpenTab: (index) => setState(() => _currentIndex = index),
          ),

          // 1: Forest Oasis Grid
          OasisGridView(storage: widget.storage),

          // 2: Challenges & Community Leaderboard
          ChallengesLeaderboardView(storage: widget.storage),

          // 3: Tasks Manager
          TasksSheet(
            storage: widget.storage,
            activeTaskId: _activeTaskId,
            onSelectActiveTask: (id) => setState(() => _activeTaskId = id),
            isSheet: false,
          ),

          // 4: Tree Nursery Store
          NurseryModal(
            storage: widget.storage,
            onDataChanged: () => setState(() {}),
            isSheet: false,
          ),

          // 5: Analytics & Streak Insights
          AnalyticsView(storage: widget.storage),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: OasisColors.surface,
          border: Border(
            top: BorderSide(color: OasisColors.cardBorder.withValues(alpha: 0.6)),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Expanded(child: _navItem(0, Icons.timer_rounded, tr('nav_timer'))),
                Expanded(child: _navItem(1, Icons.forest_rounded, tr('nav_oasis'))),
                Expanded(child: _navItem(2, Icons.military_tech_rounded, tr('nav_challenges'))),
                Expanded(child: _navItem(3, Icons.check_circle_outline_rounded, tr('nav_tasks'))),
                Expanded(child: _navItem(4, Icons.storefront_rounded, tr('nav_nursery'))),
                Expanded(child: _navItem(5, Icons.bar_chart_rounded, tr('nav_analytics'))),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

  Widget _navItem(int index, IconData icon, String label) {
    final isSelected = _currentIndex == index;
    return InkWell(
      onTap: () => setState(() => _currentIndex = index),
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected
              ? OasisColors.primary.withValues(alpha: 0.16)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? OasisColors.primary.withValues(alpha: 0.5)
                : Colors.transparent,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 20,
              color: isSelected ? OasisColors.primaryGlow : OasisColors.textSecondary,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? OasisColors.primaryGlow : OasisColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
