import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import '../models/session.dart';
import '../models/tree.dart';
import '../theme/app_theme.dart';
import 'progress_ring.dart';
import 'tree_canvas.dart';

class MiniTimerWidget extends StatelessWidget {
  final int remainingSeconds;
  final int totalSeconds;
  final SessionType sessionType;
  final SessionStatus sessionStatus;
  final TreeSpecies species;
  final bool isWilted;
  final VoidCallback onPlayPause;
  final VoidCallback onGiveUp;
  final VoidCallback onRestoreFull;

  const MiniTimerWidget({
    super.key,
    required this.remainingSeconds,
    required this.totalSeconds,
    required this.sessionType,
    required this.sessionStatus,
    required this.species,
    required this.isWilted,
    required this.onPlayPause,
    required this.onGiveUp,
    required this.onRestoreFull,
  });

  String _formatTime(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  double get _progress {
    if (totalSeconds <= 0) return 0.0;
    return (totalSeconds - remainingSeconds) / totalSeconds;
  }

  @override
  Widget build(BuildContext context) {
    final isRunning = sessionStatus == SessionStatus.running;

    return Scaffold(
      backgroundColor: OasisColors.background,
      body: Container(
        decoration: BoxDecoration(
          color: OasisColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: OasisColors.cardBorder.withValues(alpha: 0.8), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.5),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          children: [
            // Drag-to-move Titlebar Area
            DragToMoveArea(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: OasisColors.card.withValues(alpha: 0.5),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                ),
                child: Row(
                  children: [
                    Text(
                      species.iconEmoji,
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        sessionType.labelAr,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: OasisColors.textPrimary,
                        ),
                      ),
                    ),
                    // Pin / Always on top indicator
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: OasisColors.primary.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.push_pin_rounded, size: 11, color: OasisColors.accentMint),
                          SizedBox(width: 3),
                          Text(
                            'طافية',
                            style: TextStyle(fontSize: 10, color: OasisColors.accentMint, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    // Maximize / Restore full size button
                    InkWell(
                      onTap: onRestoreFull,
                      borderRadius: BorderRadius.circular(8),
                      child: const Padding(
                        padding: EdgeInsets.all(4),
                        child: Icon(Icons.open_in_full_rounded, size: 14, color: OasisColors.textSecondary),
                      ),
                    ),
                    // Minimize to tray button
                    InkWell(
                      onTap: () => windowManager.hide(),
                      borderRadius: BorderRadius.circular(8),
                      child: const Padding(
                        padding: EdgeInsets.all(4),
                        child: Icon(Icons.close_rounded, size: 14, color: OasisColors.textSecondary),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Center Ring & Timer
            Expanded(
              child: Center(
                child: SizedBox(
                  width: 170,
                  height: 170,
                  child: CircularTimerRing(
                    progress: _progress,
                    sessionType: sessionType,
                    isWilted: isWilted,
                    size: 170,
                    strokeWidth: 8,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 65,
                          height: 55,
                          child: TreeCanvas(
                            progress: _progress,
                            species: species,
                            isFailed: isWilted,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _formatTime(remainingSeconds),
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.5,
                            color: OasisColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Mini Actions Footer
            Padding(
              padding: const EdgeInsets.only(bottom: 12, left: 16, right: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (isRunning) ...[
                    IconButton(
                      icon: const Icon(Icons.flag_outlined, size: 18, color: OasisColors.witheredRed),
                      tooltip: 'استسلام',
                      onPressed: onGiveUp,
                    ),
                    const SizedBox(width: 8),
                  ],
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isRunning ? OasisColors.breakBlue : OasisColors.primary,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: onPlayPause,
                    icon: Icon(
                      isRunning ? Icons.pause_rounded : Icons.play_arrow_rounded,
                      size: 20,
                    ),
                    label: Text(
                      isRunning ? 'إيقاف مؤقت' : 'بدء التركيز',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
