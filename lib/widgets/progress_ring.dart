import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/session.dart';
import '../services/locale_service.dart';
import '../theme/app_theme.dart';

class CircularTimerRing extends StatelessWidget {
  final double progress; // 0.0 to 1.0 (elapsed/total)
  final SessionType sessionType;
  final bool isWilted;
  final double size;
  final double strokeWidth;
  final Widget child;

  const CircularTimerRing({
    super.key,
    required this.progress,
    required this.sessionType,
    required this.isWilted,
    required this.size,
    this.strokeWidth = 10,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size(size, size),
            painter: _RingPainter(
              progress: progress.clamp(0.0, 1.0),
              sessionType: sessionType,
              isWilted: isWilted,
              strokeWidth: strokeWidth,
            ),
          ),
          child,
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  final SessionType sessionType;
  final bool isWilted;
  final double strokeWidth;

  _RingPainter({
    required this.progress,
    required this.sessionType,
    required this.isWilted,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // 1. Background Track
    final trackPaint = Paint()
      ..color = const Color(0xFF192A25).withValues(alpha: 0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawCircle(center, radius, trackPaint);

    // 2. Active Progress Arc
    if (progress > 0.0) {
      final sweepAngle = 2 * math.pi * progress;
      const startAngle = -math.pi / 2; // Start from top 12 o'clock

      List<Color> gradientColors;
      if (isWilted) {
        gradientColors = [OasisColors.witheredRed, const Color(0xFFB91C1C)];
      } else {
        switch (sessionType) {
          case SessionType.focus:
            gradientColors = [OasisColors.primary, OasisColors.accentMint];
            break;
          case SessionType.shortBreak:
            gradientColors = [OasisColors.breakBlue, const Color(0xFF38BDF8)];
            break;
          case SessionType.longBreak:
            gradientColors = [OasisColors.breakPurple, const Color(0xFFC084FC)];
            break;
        }
      }

      final rect = Rect.fromCircle(center: center, radius: radius);
      final activePaint = Paint()
        ..shader = SweepGradient(
          startAngle: 0.0,
          endAngle: 2 * math.pi,
          colors: gradientColors,
          transform: const GradientRotation(-math.pi / 2),
        ).createShader(rect)
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = strokeWidth;

      canvas.drawArc(rect, startAngle, sweepAngle, false, activePaint);

      // Glowing dot at the head of the arc
      final currentAngle = startAngle + sweepAngle;
      final headX = center.dx + radius * math.cos(currentAngle);
      final headY = center.dy + radius * math.sin(currentAngle);

      final glowPaint = Paint()
        ..color = gradientColors.last.withValues(alpha: 0.6)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
      canvas.drawCircle(Offset(headX, headY), strokeWidth * 0.9, glowPaint);

      final headDot = Paint()..color = Colors.white;
      canvas.drawCircle(Offset(headX, headY), strokeWidth * 0.45, headDot);
    }
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.sessionType != sessionType ||
        oldDelegate.isWilted != isWilted ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}

// Daily Target Circles Bar
class DailyTargetRings extends StatelessWidget {
  final int completedToday;
  final int targetCount;

  const DailyTargetRings({
    super.key,
    required this.completedToday,
    required this.targetCount,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveTarget = targetCount.clamp(1, 12);
    return Container(
      constraints: const BoxConstraints(maxWidth: 420),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: OasisColors.surface.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: OasisColors.cardBorder.withValues(alpha: 0.5)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.track_changes_rounded, color: OasisColors.coinGold, size: 18),
            const SizedBox(width: 8),
            Text(
              '${tr('daily_target_badge')}: $completedToday/$targetCount',
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: OasisColors.textSecondary,
              ),
            ),
            const SizedBox(width: 10),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(effectiveTarget, (index) {
                final isDone = index < completedToday;
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 2.5),
                  width: 13,
                  height: 13,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isDone ? OasisColors.primary : Colors.transparent,
                    border: Border.all(
                      color: isDone ? OasisColors.primaryGlow : OasisColors.cardBorder,
                      width: 1.5,
                    ),
                    boxShadow: isDone
                        ? [
                            BoxShadow(
                              color: OasisColors.primary.withValues(alpha: 0.5),
                              blurRadius: 5,
                              spreadRadius: 1,
                            ),
                          ]
                        : null,
                  ),
                  child: isDone
                      ? const Icon(Icons.check, size: 8, color: Colors.white)
                      : null,
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}
