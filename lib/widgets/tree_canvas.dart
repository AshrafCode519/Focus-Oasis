import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/tree.dart';

class TreeCanvas extends StatefulWidget {
  final double progress; // 0.0 to 1.0
  final bool isFailed;
  final TreeSpecies species;
  final double size;

  const TreeCanvas({
    super.key,
    required this.progress,
    required this.isFailed,
    required this.species,
    this.size = 280,
  });

  @override
  State<TreeCanvas> createState() => _TreeCanvasState();
}

class _TreeCanvasState extends State<TreeCanvas> with SingleTickerProviderStateMixin {
  late AnimationController _breezeController;

  @override
  void initState() {
    super.initState();
    _breezeController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _breezeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _breezeController,
      builder: (context, child) {
        return CustomPaint(
          size: Size(widget.size, widget.size),
          painter: _TreePainter(
            progress: widget.progress.clamp(0.0, 1.0),
            isFailed: widget.isFailed,
            species: widget.species,
            breezeValue: _breezeController.value,
          ),
        );
      },
    );
  }
}

class _TreePainter extends CustomPainter {
  final double progress;
  final bool isFailed;
  final TreeSpecies species;
  final double breezeValue;

  _TreePainter({
    required this.progress,
    required this.isFailed,
    required this.species,
    required this.breezeValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double cx = size.width / 2;
    final double cy = size.height * 0.82; // Soil baseline

    _drawSoil(canvas, size, cx, cy);

    if (isFailed) {
      _drawWiltedTree(canvas, cx, cy, size);
      return;
    }

    if (progress < 0.30) {
      _drawSeedStage(canvas, cx, cy, progress / 0.30);
    } else if (progress < 0.65) {
      final stageProgress = (progress - 0.30) / 0.35;
      _drawSproutStage(canvas, cx, cy, stageProgress);
    } else if (progress < 0.999) {
      final stageProgress = (progress - 0.65) / 0.349;
      _drawGrowingTree(canvas, cx, cy, stageProgress);
    } else {
      _drawBloomingTree(canvas, cx, cy);
    }
  }

  void _drawSoil(Canvas canvas, Size size, double cx, double cy) {
    final soilRect = Rect.fromCenter(
      center: Offset(cx, cy + 18),
      width: size.width * 0.72,
      height: 36,
    );

    // Soil gradient
    final soilPaint = Paint()
      ..shader = RadialGradient(
        colors: isFailed
            ? [const Color(0xFF4A3B32), const Color(0xFF261D18)]
            : [const Color(0xFF2E453B), const Color(0xFF14241E)],
      ).createShader(soilRect);

    canvas.drawOval(soilRect, soilPaint);

    // Soil outline / glow
    final borderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..color = isFailed
          ? const Color(0xFF6B4F3B).withValues(alpha: 0.5)
          : species.accentColor.withValues(alpha: 0.3);

    canvas.drawOval(soilRect, borderPaint);

    // Little pebbles/moss dots
    final dotPaint = Paint()..color = isFailed ? const Color(0xFF5A483E) : species.primaryColor.withValues(alpha: 0.6);
    canvas.drawCircle(Offset(cx - 40, cy + 14), 2.5, dotPaint);
    canvas.drawCircle(Offset(cx + 35, cy + 16), 3.0, dotPaint);
    canvas.drawCircle(Offset(cx + 60, cy + 18), 2.0, dotPaint);
    canvas.drawCircle(Offset(cx - 70, cy + 19), 2.2, dotPaint);
  }

  // Stage 1: Seed
  void _drawSeedStage(Canvas canvas, double cx, double cy, double localProgress) {
    final seedY = cy + 4 - (localProgress * 8);

    // Glow
    final glowPaint = Paint()
      ..color = species.accentColor.withValues(alpha: 0.25 + 0.15 * math.sin(breezeValue * math.pi))
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
    canvas.drawCircle(Offset(cx, seedY), 16, glowPaint);

    // Seed shell
    final seedPaint = Paint()
      ..color = const Color(0xFF8D6E63)
      ..style = PaintingStyle.fill;
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, seedY), width: 14, height: 18),
      seedPaint,
    );

    // Tiny sprout tip peeking
    if (localProgress > 0.4) {
      final sproutHeight = (localProgress - 0.4) * 20;
      final sproutPaint = Paint()
        ..color = species.accentColor
        ..strokeWidth = 3.5
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(
        Offset(cx, seedY - 8),
        Offset(cx, seedY - 8 - sproutHeight),
        sproutPaint,
      );
    }
  }

  // Stage 2: Sprout
  void _drawSproutStage(Canvas canvas, double cx, double cy, double localProgress) {
    final double stemHeight = 25 + (localProgress * 35);
    final double sway = math.sin(breezeValue * math.pi * 2) * 4;

    // Stem
    final stemPath = Path();
    stemPath.moveTo(cx, cy + 5);
    stemPath.quadraticBezierTo(cx + sway * 0.5, cy - stemHeight * 0.5, cx + sway, cy - stemHeight);

    final stemPaint = Paint()
      ..color = species.primaryColor
      ..strokeWidth = 4.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    canvas.drawPath(stemPath, stemPaint);

    // Two tender leaves
    final leafTip = Offset(cx + sway, cy - stemHeight);
    final leafSize = 12 + (localProgress * 14);

    final leafPaint = Paint()..color = species.accentColor;

    // Left leaf
    canvas.save();
    canvas.translate(leafTip.dx, leafTip.dy);
    canvas.rotate(-0.5 + (sway * 0.05));
    canvas.drawOval(
      Rect.fromCenter(center: Offset(-leafSize * 0.7, -4), width: leafSize * 1.3, height: leafSize * 0.7),
      leafPaint,
    );
    canvas.restore();

    // Right leaf
    canvas.save();
    canvas.translate(leafTip.dx, leafTip.dy);
    canvas.rotate(0.5 - (sway * 0.05));
    canvas.drawOval(
      Rect.fromCenter(center: Offset(leafSize * 0.7, -4), width: leafSize * 1.3, height: leafSize * 0.7),
      leafPaint,
    );
    canvas.restore();
  }

  // Stage 3: Growing Tree
  void _drawGrowingTree(Canvas canvas, double cx, double cy, double localProgress) {
    final double treeScale = 0.6 + (localProgress * 0.35);
    final double sway = math.sin(breezeValue * math.pi * 2) * 6;

    // Trunk
    final trunkPaint = Paint()
      ..color = const Color(0xFF6D4C41)
      ..strokeWidth = 8.0 * treeScale
      ..strokeCap = StrokeCap.round;

    final topTrunk = Offset(cx + sway * 0.6, cy - (80 * treeScale));
    canvas.drawLine(Offset(cx, cy + 5), topTrunk, trunkPaint);

    // Branches
    final branchPaint = Paint()
      ..color = const Color(0xFF5D4037)
      ..strokeWidth = 5.0 * treeScale
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(
      Offset(cx + sway * 0.3, cy - (45 * treeScale)),
      Offset(cx - (35 * treeScale) + sway, cy - (65 * treeScale)),
      branchPaint,
    );
    canvas.drawLine(
      Offset(cx + sway * 0.4, cy - (55 * treeScale)),
      Offset(cx + (35 * treeScale) + sway, cy - (75 * treeScale)),
      branchPaint,
    );

    // Foliage Clusters
    _drawFoliageClusters(canvas, topTrunk, treeScale, sway);
  }

  // Stage 4: Majestic Blooming Tree
  void _drawBloomingTree(Canvas canvas, double cx, double cy) {
    const double treeScale = 1.0;
    final double sway = math.sin(breezeValue * math.pi * 2) * 8;

    // Glowing aura
    final auraPaint = Paint()
      ..color = species.accentColor.withValues(alpha: 0.18 + 0.08 * math.sin(breezeValue * math.pi))
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 28);
    canvas.drawCircle(Offset(cx, cy - 90), 85, auraPaint);

    // Strong sturdy Trunk
    final trunkPath = Path();
    trunkPath.moveTo(cx - 10, cy + 8);
    trunkPath.quadraticBezierTo(cx - 6, cy - 50, cx - 6 + (sway * 0.4), cy - 90);
    trunkPath.lineTo(cx + 6 + (sway * 0.4), cy - 90);
    trunkPath.quadraticBezierTo(cx + 6, cy - 50, cx + 10, cy + 8);
    trunkPath.close();

    final trunkPaint = Paint()..color = const Color(0xFF5D4037);
    canvas.drawPath(trunkPath, trunkPaint);

    // Bark texture lines
    final barkPaint = Paint()
      ..color = const Color(0xFF4E342E)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;
    canvas.drawLine(Offset(cx - 2, cy), Offset(cx - 1 + (sway * 0.2), cy - 70), barkPaint);

    // Branches
    final branchPaint = Paint()
      ..color = const Color(0xFF5D4037)
      ..strokeWidth = 6.0
      ..strokeCap = StrokeCap.round;

    final topTrunk = Offset(cx + (sway * 0.4), cy - 90);
    canvas.drawLine(Offset(cx, cy - 50), Offset(cx - 45 + sway, cy - 75), branchPaint);
    canvas.drawLine(Offset(cx, cy - 60), Offset(cx + 45 + sway, cy - 85), branchPaint);

    // Foliage & Blooms
    _drawFoliageClusters(canvas, topTrunk, treeScale, sway, isFullBloom: true);

    // Sparkling floating pollen/stars
    final sparklePaint = Paint()..color = species.accentColor;
    for (int i = 0; i < 6; i++) {
      final angle = (i * math.pi / 3) + (breezeValue * 0.5);
      final dist = 75 + (i * 7 % 25);
      final sx = cx + math.cos(angle) * dist;
      final sy = (cy - 90) + math.sin(angle) * (dist * 0.7);
      canvas.drawCircle(Offset(sx, sy), 2.5 + (i % 2), sparklePaint);
    }
  }

  void _drawFoliageClusters(
    Canvas canvas,
    Offset center,
    double scale,
    double sway, {
    bool isFullBloom = false,
  }) {
    if (species.id == 'flowering_cactus') {
      _drawCactus(canvas, center, scale, sway);
      return;
    }

    if (species.id == 'weeping_willow') {
      _drawWillow(canvas, center, scale, sway);
      return;
    }

    if (species.id == 'desert_palm') {
      _drawPalmFronds(canvas, center, scale, sway);
      return;
    }

    if (species.id == 'classic_pine') {
      _drawPineTiers(canvas, center, scale, sway);
      return;
    }

    if (species.id == 'zen_bonsai') {
      _drawBonsai(canvas, center, scale, sway);
      return;
    }

    if (species.id == 'ancient_baobab') {
      _drawBaobab(canvas, center, scale, sway);
      return;
    }

    if (species.id == 'cosmic_crystal_tree') {
      _drawCrystalTree(canvas, center, scale, sway);
      return;
    }

    if (species.id == 'moonlight_wisteria') {
      _drawWisteria(canvas, center, scale, sway);
      return;
    }

    if (species.id == 'lavender_jacaranda') {
      _drawJacaranda(canvas, center, scale, sway, isFullBloom: isFullBloom);
      return;
    }

    if (species.id == 'red_maple') {
      _drawMaple(canvas, center, scale, sway);
      return;
    }

    // Default & Sakura & Golden Oak: Clustered rounded foliage
    final primaryFoliage = Paint()..color = species.primaryColor;
    final accentFoliage = Paint()..color = species.accentColor;

    final clusters = [
      Offset(center.dx, center.dy - (25 * scale)),
      Offset(center.dx - (35 * scale) + (sway * 0.5), center.dy - (10 * scale)),
      Offset(center.dx + (35 * scale) + (sway * 0.5), center.dy - (10 * scale)),
      Offset(center.dx - (20 * scale) + (sway * 0.7), center.dy + (10 * scale)),
      Offset(center.dx + (20 * scale) + (sway * 0.7), center.dy + (10 * scale)),
    ];

    final double baseRadius = (32 * scale);

    // Shadow foliage
    for (final c in clusters) {
      canvas.drawCircle(Offset(c.dx, c.dy + 3), baseRadius, primaryFoliage);
    }

    // Highlight foliage
    for (final c in clusters) {
      canvas.drawCircle(Offset(c.dx - 4, c.dy - 4), baseRadius * 0.85, accentFoliage);
    }

    // Flowers for Sakura
    if (species.id == 'sakura_bloom' && isFullBloom) {
      final petalPaint = Paint()..color = Colors.white;
      for (final c in clusters) {
        canvas.drawCircle(Offset(c.dx + 6, c.dy - 5), 4, petalPaint);
        canvas.drawCircle(Offset(c.dx - 8, c.dy + 4), 3.5, petalPaint);
        canvas.drawCircle(Offset(c.dx + 12, c.dy + 8), 3, petalPaint);
      }
    }
  }

  void _drawCactus(Canvas canvas, Offset center, double scale, double sway) {
    final cactusBodyPaint = Paint()..color = species.primaryColor;
    final cactusAccentPaint = Paint()..color = species.accentColor;

    // Main Column
    final mainRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(center.dx, center.dy + (10 * scale)), width: 34 * scale, height: 75 * scale),
      Radius.circular(16 * scale),
    );
    canvas.drawRRect(mainRect, cactusBodyPaint);

    // Left Arm
    final leftArm = Path();
    leftArm.moveTo(center.dx - (10 * scale), center.dy + (25 * scale));
    leftArm.lineTo(center.dx - (34 * scale), center.dy + (25 * scale));
    leftArm.quadraticBezierTo(center.dx - (44 * scale), center.dy + (25 * scale), center.dx - (44 * scale), center.dy + (5 * scale));
    leftArm.lineTo(center.dx - (44 * scale), center.dy - (12 * scale));

    final armPaint = Paint()
      ..color = species.primaryColor
      ..strokeWidth = 14 * scale
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(leftArm, armPaint);

    // Right Arm
    final rightArm = Path();
    rightArm.moveTo(center.dx + (10 * scale), center.dy + (12 * scale));
    rightArm.lineTo(center.dx + (34 * scale), center.dy + (12 * scale));
    rightArm.quadraticBezierTo(center.dx + (44 * scale), center.dy + (12 * scale), center.dx + (44 * scale), center.dy - (5 * scale));
    rightArm.lineTo(center.dx + (44 * scale), center.dy - (22 * scale));
    canvas.drawPath(rightArm, armPaint);

    // Blossom Flower on top
    final flowerCenter = Offset(center.dx + (sway * 0.2), center.dy - (30 * scale));
    for (int i = 0; i < 6; i++) {
      final angle = (i * math.pi / 3);
      final px = flowerCenter.dx + math.cos(angle) * (9 * scale);
      final py = flowerCenter.dy + math.sin(angle) * (9 * scale);
      canvas.drawCircle(Offset(px, py), 6 * scale, cactusAccentPaint);
    }
    canvas.drawCircle(flowerCenter, 5 * scale, Paint()..color = const Color(0xFFFBBF24));
  }

  void _drawWillow(Canvas canvas, Offset center, double scale, double sway) {
    final willowPaint = Paint()
      ..color = species.primaryColor
      ..strokeWidth = 2.5 * scale
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final leafPaint = Paint()..color = species.accentColor;

    // Central dome
    canvas.drawOval(
      Rect.fromCenter(center: Offset(center.dx, center.dy - (15 * scale)), width: 65 * scale, height: 35 * scale),
      Paint()..color = species.primaryColor.withValues(alpha: 0.8),
    );

    // 8 Cascading Weeping Vines
    final offsets = [-45, -32, -18, -6, 6, 18, 32, 45];
    for (int i = 0; i < offsets.length; i++) {
      final ox = offsets[i] * scale;
      final start = Offset(center.dx + ox, center.dy - (12 * scale));
      final vineLength = (60 + (i.isEven ? 18 : 0)) * scale;
      final vineSway = math.sin(breezeValue * math.pi * 2 + (i * 0.5)) * (10 * scale);

      final path = Path();
      path.moveTo(start.dx, start.dy);
      path.quadraticBezierTo(
        start.dx + vineSway * 0.5,
        start.dy + (vineLength * 0.5),
        start.dx + vineSway,
        start.dy + vineLength,
      );
      canvas.drawPath(path, willowPaint);

      // Droplet leaves
      canvas.drawCircle(Offset(start.dx + vineSway, start.dy + vineLength), 3.5 * scale, leafPaint);
      canvas.drawCircle(Offset(start.dx + vineSway * 0.7, start.dy + vineLength * 0.65), 3.0 * scale, leafPaint);
    }
  }

  void _drawBonsai(Canvas canvas, Offset center, double scale, double sway) {
    final foliagePrimary = Paint()..color = species.primaryColor;
    final foliageAccent = Paint()..color = species.accentColor;

    // 3 Flattened cloud pads
    final pads = [
      Offset(center.dx - (35 * scale) + (sway * 0.4), center.dy + (5 * scale)),
      Offset(center.dx + (30 * scale) + (sway * 0.4), center.dy - (10 * scale)),
      Offset(center.dx - (5 * scale) + (sway * 0.2), center.dy - (30 * scale)),
    ];

    for (final p in pads) {
      // Oval cloud pad
      canvas.drawOval(
        Rect.fromCenter(center: Offset(p.dx, p.dy + (2 * scale)), width: 44 * scale, height: 16 * scale),
        foliagePrimary,
      );
      canvas.drawOval(
        Rect.fromCenter(center: Offset(p.dx, p.dy - (2 * scale)), width: 38 * scale, height: 13 * scale),
        foliageAccent,
      );
    }
  }

  void _drawBaobab(Canvas canvas, Offset center, double scale, double sway) {
    // Massive wide baobab canopy
    final canopyPaint = Paint()..color = species.accentColor;
    final shadowPaint = Paint()..color = species.primaryColor;

    final flatRect = Rect.fromCenter(
      center: Offset(center.dx + (sway * 0.2), center.dy - (20 * scale)),
      width: 105 * scale,
      height: 38 * scale,
    );
    canvas.drawOval(flatRect.translate(0, 3), shadowPaint);
    canvas.drawOval(flatRect, canopyPaint);
  }

  void _drawCrystalTree(Canvas canvas, Offset center, double scale, double sway) {
    final crystalPaint = Paint()
      ..color = species.accentColor.withValues(alpha: 0.85)
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 1.5 * scale
      ..style = PaintingStyle.stroke;

    // Prismatic crystal facets
    final shards = [
      [Offset(center.dx, center.dy - (45 * scale)), Offset(center.dx - (18 * scale), center.dy - (10 * scale)), Offset(center.dx, center.dy + (5 * scale))],
      [Offset(center.dx, center.dy - (45 * scale)), Offset(center.dx + (18 * scale), center.dy - (10 * scale)), Offset(center.dx, center.dy + (5 * scale))],
      [Offset(center.dx - (20 * scale), center.dy - (12 * scale)), Offset(center.dx - (42 * scale), center.dy + (5 * scale)), Offset(center.dx - (10 * scale), center.dy + (18 * scale))],
      [Offset(center.dx + (20 * scale), center.dy - (12 * scale)), Offset(center.dx + (42 * scale), center.dy + (5 * scale)), Offset(center.dx + (10 * scale), center.dy + (18 * scale))],
    ];

    for (final s in shards) {
      final path = Path();
      path.moveTo(s[0].dx + (sway * 0.2), s[0].dy);
      path.lineTo(s[1].dx + (sway * 0.2), s[1].dy);
      path.lineTo(s[2].dx + (sway * 0.2), s[2].dy);
      path.close();

      canvas.drawPath(path, crystalPaint);
      canvas.drawPath(path, borderPaint);
    }
  }

  void _drawWisteria(Canvas canvas, Offset center, double scale, double sway) {
    final wisteriaPaint = Paint()..color = species.primaryColor;
    final blossomPaint = Paint()..color = species.accentColor;

    // Dome canopy
    canvas.drawOval(
      Rect.fromCenter(center: Offset(center.dx, center.dy - (15 * scale)), width: 75 * scale, height: 35 * scale),
      wisteriaPaint,
    );

    // Hanging flower teardrop lanterns
    final positions = [-35, -22, -10, 0, 10, 22, 35];
    for (int i = 0; i < positions.length; i++) {
      final x = center.dx + (positions[i] * scale) + (sway * 0.4);
      final y = center.dy - (5 * scale);
      final chainLength = (25 + (i.isEven ? 12 : 0)) * scale;

      for (double step = 0; step < chainLength; step += (6 * scale)) {
        final radius = (4.5 - (step / chainLength * 2.2)) * scale;
        canvas.drawCircle(Offset(x, y + step), radius.clamp(1.5, 5.0), blossomPaint);
      }
    }
  }

  void _drawJacaranda(Canvas canvas, Offset center, double scale, double sway, {bool isFullBloom = false}) {
    final primaryFoliage = Paint()..color = species.primaryColor;
    final accentFoliage = Paint()..color = species.accentColor;

    final clusters = [
      Offset(center.dx, center.dy - (25 * scale)),
      Offset(center.dx - (35 * scale) + (sway * 0.5), center.dy - (10 * scale)),
      Offset(center.dx + (35 * scale) + (sway * 0.5), center.dy - (10 * scale)),
      Offset(center.dx - (20 * scale) + (sway * 0.7), center.dy + (10 * scale)),
      Offset(center.dx + (20 * scale) + (sway * 0.7), center.dy + (10 * scale)),
    ];

    final double baseRadius = (32 * scale);
    for (final c in clusters) {
      canvas.drawCircle(Offset(c.dx, c.dy + 3), baseRadius, primaryFoliage);
    }
    for (final c in clusters) {
      canvas.drawCircle(Offset(c.dx - 4, c.dy - 4), baseRadius * 0.85, accentFoliage);
    }

    // Falling violet petals
    if (isFullBloom) {
      final petalPaint = Paint()..color = species.accentColor.withValues(alpha: 0.75);
      for (int i = 0; i < 5; i++) {
        final px = center.dx - (40 * scale) + (i * 20 * scale) + sway;
        final py = center.dy + (25 * scale) + (i * 8 * scale);
        canvas.drawCircle(Offset(px, py), 2.5 * scale, petalPaint);
      }
    }
  }

  void _drawMaple(Canvas canvas, Offset center, double scale, double sway) {
    final primaryFoliage = Paint()..color = species.primaryColor;
    final accentFoliage = Paint()..color = species.accentColor;

    final clusters = [
      Offset(center.dx, center.dy - (28 * scale)),
      Offset(center.dx - (38 * scale) + (sway * 0.5), center.dy - (10 * scale)),
      Offset(center.dx + (38 * scale) + (sway * 0.5), center.dy - (10 * scale)),
      Offset(center.dx - (22 * scale) + (sway * 0.7), center.dy + (12 * scale)),
      Offset(center.dx + (22 * scale) + (sway * 0.7), center.dy + (12 * scale)),
    ];

    for (final c in clusters) {
      canvas.drawCircle(Offset(c.dx, c.dy + 2), 28 * scale, primaryFoliage);
      canvas.drawCircle(Offset(c.dx - 3, c.dy - 3), 22 * scale, accentFoliage);
    }
  }

  void _drawPineTiers(Canvas canvas, Offset center, double scale, double sway) {
    final pinePaint = Paint()..color = species.primaryColor;
    final pineAccent = Paint()..color = species.accentColor;

    for (int i = 0; i < 3; i++) {
      final tierWidth = (80 - (i * 20)) * scale;
      final tierHeight = (38 * scale);
      final tierY = center.dy + (15 * scale) - (i * 28 * scale);

      final path = Path();
      path.moveTo(center.dx + (sway * 0.3), tierY - tierHeight);
      path.lineTo(center.dx + (tierWidth / 2) + (sway * 0.2), tierY);
      path.lineTo(center.dx - (tierWidth / 2) + (sway * 0.2), tierY);
      path.close();

      canvas.drawPath(path, pinePaint);

      // Light edge
      final lightPath = Path();
      lightPath.moveTo(center.dx + (sway * 0.3), tierY - tierHeight);
      lightPath.lineTo(center.dx - (tierWidth / 2) + (sway * 0.2), tierY);
      lightPath.lineTo(center.dx + (sway * 0.3), tierY);
      lightPath.close();

      canvas.drawPath(lightPath, pineAccent);
    }
  }

  void _drawPalmFronds(Canvas canvas, Offset center, double scale, double sway) {
    final frondPaint = Paint()
      ..color = species.primaryColor
      ..strokeWidth = 6.0 * scale
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final numFronds = 6;
    for (int i = 0; i < numFronds; i++) {
      final angle = (i * math.pi / 3) + (sway * 0.04);
      final fx = center.dx + math.cos(angle) * (55 * scale);
      final fy = center.dy + math.sin(angle) * (40 * scale) + (15 * scale);

      final frondPath = Path();
      frondPath.moveTo(center.dx, center.dy);
      frondPath.quadraticBezierTo(
        center.dx + math.cos(angle) * (30 * scale),
        center.dy - (15 * scale),
        fx,
        fy,
      );
      canvas.drawPath(frondPath, frondPaint);
    }
  }

  // Penalty / Failed Wilted Tree State
  void _drawWiltedTree(Canvas canvas, double cx, double cy, Size size) {
    // Gloomy smoke/mist aura
    final mistPaint = Paint()
      ..color = const Color(0xFFEF4444).withValues(alpha: 0.08)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20);
    canvas.drawCircle(Offset(cx, cy - 60), 60, mistPaint);

    final dryTrunkPaint = Paint()
      ..color = const Color(0xFF5D4037)
      ..strokeWidth = 7.0
      ..strokeCap = StrokeCap.round;

    // Drooping, broken trunk
    final trunkPath = Path();
    trunkPath.moveTo(cx, cy + 6);
    trunkPath.cubicTo(cx - 8, cy - 30, cx + 18, cy - 60, cx + 12, cy - 90);
    canvas.drawPath(
      trunkPath,
      dryTrunkPaint..style = PaintingStyle.stroke,
    );

    // Bare, sharp, leafless branches
    final dryBranchPaint = Paint()
      ..color = const Color(0xFF4E342E)
      ..strokeWidth = 4.0
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(Offset(cx + 8, cy - 50), Offset(cx - 30, cy - 65), dryBranchPaint);
    canvas.drawLine(Offset(cx - 30, cy - 65), Offset(cx - 40, cy - 80), dryBranchPaint);

    canvas.drawLine(Offset(cx + 14, cy - 70), Offset(cx + 42, cy - 80), dryBranchPaint);
    canvas.drawLine(Offset(cx + 42, cy - 80), Offset(cx + 35, cy - 95), dryBranchPaint);

    // A few dead fallen leaves on the ground
    final deadLeafPaint = Paint()..color = const Color(0xFF9E7854);
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx - 28, cy + 12), width: 10, height: 5),
      deadLeafPaint,
    );
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx + 25, cy + 14), width: 12, height: 6),
      deadLeafPaint,
    );
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx + 40, cy + 10), width: 8, height: 4),
      deadLeafPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _TreePainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.isFailed != isFailed ||
        oldDelegate.species.id != species.id ||
        oldDelegate.breezeValue != breezeValue;
  }
}
