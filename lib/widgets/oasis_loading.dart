import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

enum OasisLoadingSize {
  small(24),
  medium(48),
  large(88);

  final double diameter;
  const OasisLoadingSize(this.diameter);
}

/// A luxury glowing animated loading indicator tailored to the Focus Oasis emerald & gold aesthetic.
class OasisLoadingIndicator extends StatefulWidget {
  final OasisLoadingSize size;
  final String? message;
  final Color? glowColor;

  const OasisLoadingIndicator({
    super.key,
    this.size = OasisLoadingSize.medium,
    this.message,
    this.glowColor,
  });

  @override
  State<OasisLoadingIndicator> createState() => _OasisLoadingIndicatorState();
}

class _OasisLoadingIndicatorState extends State<OasisLoadingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primary = widget.glowColor ?? OasisColors.primary;
    final d = widget.size.diameter;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: d,
            height: d,
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Stack(
                  alignment: Alignment.center,
                  children: [
                    // Outer Soft Ambient Glow
                    Container(
                      width: d * 0.9,
                      height: d * 0.9,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: primary.withValues(
                              alpha: 0.25 + 0.15 * math.sin(_controller.value * 2 * math.pi),
                            ),
                            blurRadius: d * 0.35,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                    ),

                    // Rotating Dual Gradient Arc
                    Transform.rotate(
                      angle: _controller.value * 2 * math.pi,
                      child: CustomPaint(
                        size: Size(d, d),
                        painter: _OasisSpinnerPainter(
                          colorA: primary,
                          colorB: OasisColors.coinGold,
                          strokeWidth: widget.size == OasisLoadingSize.small
                              ? 2.5
                              : (widget.size == OasisLoadingSize.medium ? 3.5 : 4.5),
                        ),
                      ),
                    ),

                    // Center Seedling Icon for medium/large
                    if (widget.size != OasisLoadingSize.small)
                      Transform.scale(
                        scale: 0.9 + 0.1 * math.sin(_controller.value * 2 * math.pi),
                        child: Icon(
                          Icons.eco_rounded,
                          size: d * 0.42,
                          color: primary,
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
          if (widget.message != null && widget.message!.isNotEmpty) ...[
            const SizedBox(height: 14),
            Text(
              widget.message!,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: OasisColors.textSecondary,
                fontSize: widget.size == OasisLoadingSize.large ? 14 : 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _OasisSpinnerPainter extends CustomPainter {
  final Color colorA;
  final Color colorB;
  final double strokeWidth;

  _OasisSpinnerPainter({
    required this.colorA,
    required this.colorB,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(
      strokeWidth / 2,
      strokeWidth / 2,
      size.width - strokeWidth,
      size.height - strokeWidth,
    );

    // Track
    final trackPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawOval(rect, trackPaint);

    // Arc
    final arcPaint = Paint()
      ..shader = SweepGradient(
        colors: [
          colorA.withValues(alpha: 0.0),
          colorA,
          colorB,
        ],
        stops: const [0.0, 0.6, 1.0],
      ).createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = strokeWidth;

    canvas.drawArc(rect, 0, math.pi * 1.5, false, arcPaint);
  }

  @override
  bool shouldRepaint(covariant _OasisSpinnerPainter oldDelegate) =>
      oldDelegate.colorA != colorA ||
      oldDelegate.colorB != colorB ||
      oldDelegate.strokeWidth != strokeWidth;
}
