import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/sound_service.dart';
import '../services/locale_service.dart';
import '../theme/app_theme.dart';

enum BreathingTechnique {
  relax478,
  boxBreathing,
  quickReset;

  String get labelAr {
    switch (this) {
      case BreathingTechnique.relax478:
        return 'هدوء عميق (4-7-8)';
      case BreathingTechnique.boxBreathing:
        return 'تنفس الصندوق (4-4-4-4)';
      case BreathingTechnique.quickReset:
        return 'استرخاء سريع (4-4)';
    }
  }

  String label(String langCode) {
    if (langCode == 'ar') return labelAr;
    switch (this) {
      case BreathingTechnique.relax478:
        return 'Deep Calm (4-7-8)';
      case BreathingTechnique.boxBreathing:
        return 'Box Breathing (4-4-4-4)';
      case BreathingTechnique.quickReset:
        return 'Quick Refresh (4-4)';
    }
  }

  String get subtitleAr {
    switch (this) {
      case BreathingTechnique.relax478:
        return 'يقلل التوتر ويهدئ نبضات القلب فوراً';
      case BreathingTechnique.boxBreathing:
        return 'تقنية التركيز المتقدم لتهدئة الذهن';
      case BreathingTechnique.quickReset:
        return 'تنشيط لطيف وسريع أثناء الاستراحة';
    }
  }

  String subtitle(String langCode) {
    if (langCode == 'ar') return subtitleAr;
    switch (this) {
      case BreathingTechnique.relax478:
        return 'Reduces stress and soothes heart rate';
      case BreathingTechnique.boxBreathing:
        return 'Advanced focus technique to still the mind';
      case BreathingTechnique.quickReset:
        return 'Gentle reset during short breaks';
    }
  }

  List<BreathStep> get steps {
    switch (this) {
      case BreathingTechnique.relax478:
        return [
          const BreathStep(
            action: BreathAction.inhale,
            durationSeconds: 4,
            instruction: 'شهيق عميق من الأنف... 🌸',
            color: Color(0xFF10B981),
            freq: 528.0,
          ),
          const BreathStep(
            action: BreathAction.hold,
            durationSeconds: 7,
            instruction: 'احبس نَفَسَك بهدوء... 🧘‍♂️',
            color: Color(0xFFFBBF24),
            freq: 440.0,
          ),
          const BreathStep(
            action: BreathAction.exhale,
            durationSeconds: 8,
            instruction: 'زفير بطيء ومريح من الفم... 🍃',
            color: Color(0xFF38BDF8),
            freq: 396.0,
          ),
        ];
      case BreathingTechnique.boxBreathing:
        return [
          const BreathStep(
            action: BreathAction.inhale,
            durationSeconds: 4,
            instruction: 'شهيق عميق... 🌸',
            color: Color(0xFF10B981),
            freq: 528.0,
          ),
          const BreathStep(
            action: BreathAction.hold,
            durationSeconds: 4,
            instruction: 'حبس النَّفَس... 🧘‍♂️',
            color: Color(0xFFFBBF24),
            freq: 440.0,
          ),
          const BreathStep(
            action: BreathAction.exhale,
            durationSeconds: 4,
            instruction: 'زفير كامل... 🍃',
            color: Color(0xFF38BDF8),
            freq: 396.0,
          ),
          const BreathStep(
            action: BreathAction.hold,
            durationSeconds: 4,
            instruction: 'سكون واسترخاء... ✨',
            color: Color(0xFFA855F7),
            freq: 440.0,
          ),
        ];
      case BreathingTechnique.quickReset:
        return [
          const BreathStep(
            action: BreathAction.inhale,
            durationSeconds: 4,
            instruction: 'شهيق منعش... 🌸',
            color: Color(0xFF10B981),
            freq: 528.0,
          ),
          const BreathStep(
            action: BreathAction.exhale,
            durationSeconds: 4,
            instruction: 'زفير بطيء... 🍃',
            color: Color(0xFF38BDF8),
            freq: 396.0,
          ),
        ];
    }
  }
}

enum BreathAction { inhale, hold, exhale }

class BreathStep {
  final BreathAction action;
  final int durationSeconds;
  final String instruction;
  final Color color;
  final double freq;

  const BreathStep({
    required this.action,
    required this.durationSeconds,
    required this.instruction,
    required this.color,
    required this.freq,
  });

  String getInstruction(String langCode) {
    if (langCode == 'ar') return instruction;
    switch (action) {
      case BreathAction.inhale:
        return 'Deep Inhale... 🌸';
      case BreathAction.hold:
        return 'Hold Breath Gently... 🧘‍♂️';
      case BreathAction.exhale:
        return 'Slow, Releasing Exhale... 🍃';
    }
  }
}

class BreathingModal extends StatefulWidget {
  final VoidCallback? onComplete;

  const BreathingModal({super.key, this.onComplete});

  static void show(BuildContext context, {VoidCallback? onComplete}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => BreathingModal(onComplete: onComplete),
    );
  }

  @override
  State<BreathingModal> createState() => _BreathingModalState();
}

class _BreathingModalState extends State<BreathingModal>
    with SingleTickerProviderStateMixin {
  BreathingTechnique _technique = BreathingTechnique.relax478;
  int _currentStepIndex = 0;
  int _secondsLeftInStep = 4;
  int _completedCycles = 0;
  final int _targetCycles = 4;
  bool _isRunning = true;
  Timer? _stepTimer;
  late AnimationController _animController;
  final SoundService _soundService = SoundService();

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );
    _startTechnique(_technique);
  }

  @override
  void dispose() {
    _stepTimer?.cancel();
    _animController.dispose();
    super.dispose();
  }

  void _startTechnique(BreathingTechnique technique) {
    _stepTimer?.cancel();
    setState(() {
      _technique = technique;
      _currentStepIndex = 0;
      _completedCycles = 0;
      _isRunning = true;
    });
    _beginCurrentStep();
  }

  void _beginCurrentStep() {
    final step = _technique.steps[_currentStepIndex];
    setState(() {
      _secondsLeftInStep = step.durationSeconds;
    });

    _soundService.playCueSound(freq: step.freq);
    HapticFeedback.lightImpact();

    _animController.duration = Duration(seconds: step.durationSeconds);
    if (step.action == BreathAction.inhale) {
      _animController.forward(from: 0.0);
    } else if (step.action == BreathAction.exhale) {
      _animController.reverse(from: 1.0);
    }

    _stepTimer?.cancel();
    _stepTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!_isRunning) return;

      if (_secondsLeftInStep > 1) {
        setState(() {
          _secondsLeftInStep--;
        });
      } else {
        _advanceToNextStep();
      }
    });
  }

  void _advanceToNextStep() {
    if (_currentStepIndex < _technique.steps.length - 1) {
      setState(() {
        _currentStepIndex++;
      });
      _beginCurrentStep();
    } else {
      // Completed one cycle
      final newCompleted = _completedCycles + 1;
      if (newCompleted >= _targetCycles) {
        _stepTimer?.cancel();
        setState(() {
          _completedCycles = newCompleted;
          _isRunning = false;
        });
        _soundService.playSessionComplete();
        HapticFeedback.heavyImpact();
      } else {
        setState(() {
          _completedCycles = newCompleted;
          _currentStepIndex = 0;
        });
        _beginCurrentStep();
      }
    }
  }

  void _togglePlayPause() {
    setState(() {
      _isRunning = !_isRunning;
    });
    if (_isRunning) {
      if (_animController.isAnimating) {
        // already animating
      } else {
        final step = _technique.steps[_currentStepIndex];
        if (step.action == BreathAction.inhale) {
          _animController.forward();
        } else if (step.action == BreathAction.exhale) {
          _animController.reverse();
        }
      }
    } else {
      _animController.stop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final step = _technique.steps[_currentStepIndex];
    final isFinished = _completedCycles >= _targetCycles;

    return Container(
      height: MediaQuery.of(context).size.height * 0.88,
      decoration: const BoxDecoration(
        color: OasisColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          // Drag Handle & Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Column(
              children: [
                Center(
                  child: Container(
                    width: 44,
                    height: 5,
                    decoration: BoxDecoration(
                      color: OasisColors.cardBorder,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: OasisColors.accentMint.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: const Text('🫁', style: TextStyle(fontSize: 22)),
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              tr('breathing_title'),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: OasisColors.textPrimary,
                              ),
                            ),
                            Text(
                              _technique.subtitle(LocaleService.instance.currentLocale),
                              style: const TextStyle(
                                fontSize: 11,
                                color: OasisColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: OasisColors.textSecondary),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const Divider(height: 1, color: OasisColors.cardBorder),

          // Technique Selector Tabs
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: BreathingTechnique.values.map((tech) {
                  final isSelected = tech == _technique;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: InkWell(
                      onTap: () => _startTechnique(tech),
                      borderRadius: BorderRadius.circular(16),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? OasisColors.primary.withValues(alpha: 0.2)
                              : OasisColors.card,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected ? OasisColors.primary : OasisColors.cardBorder,
                            width: isSelected ? 1.5 : 1.0,
                          ),
                        ),
                        child: Text(
                          tech.label(LocaleService.instance.currentLocale),
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
            ),
          ),

          // Main Animation Area
          Expanded(
            child: Center(
              child: isFinished
                  ? _buildFinishedState()
                  : AnimatedBuilder(
                      animation: _animController,
                      builder: (context, child) {
                        double scale;
                        if (step.action == BreathAction.inhale) {
                          scale = 0.55 + (0.45 * _animController.value);
                        } else if (step.action == BreathAction.exhale) {
                          scale = 0.55 + (0.45 * _animController.value);
                        } else {
                          // Hold
                          scale = 1.0;
                        }

                        return Stack(
                          alignment: Alignment.center,
                          children: [
                            // Outer Glowing Aura Ring
                            Container(
                              width: 250 * scale,
                              height: 250 * scale,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: step.color.withValues(alpha: 0.12),
                                border: Border.all(
                                  color: step.color.withValues(alpha: 0.25),
                                  width: 2,
                                ),
                              ),
                            ),

                            // Middle Radiant Pulsing Ring
                            Container(
                              width: 200 * scale,
                              height: 200 * scale,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: RadialGradient(
                                  colors: [
                                    step.color.withValues(alpha: 0.35),
                                    step.color.withValues(alpha: 0.05),
                                  ],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: step.color.withValues(alpha: 0.4),
                                    blurRadius: 28 * scale,
                                    spreadRadius: 4,
                                  ),
                                ],
                              ),
                            ),

                            // Inner Core Ball
                            Container(
                              width: 140 * scale,
                              height: 140 * scale,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  colors: [
                                    step.color,
                                    step.color.withValues(alpha: 0.75),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  '$_secondsLeftInStep',
                                  style: const TextStyle(
                                    fontSize: 42,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    shadows: [
                                      Shadow(
                                        color: Colors.black45,
                                        blurRadius: 10,
                                        offset: Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
            ),
          ),

          // Stage Instruction & Cycle Pills
          if (!isFinished) ...[
            Text(
              step.getInstruction(LocaleService.instance.currentLocale),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: step.color,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              LocaleService.instance.currentLocale == 'ar'
                  ? 'الدورة ${_completedCycles + 1} من $_targetCycles'
                  : 'Cycle ${_completedCycles + 1} of $_targetCycles',
              style: const TextStyle(
                fontSize: 13,
                color: OasisColors.textSecondary,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_targetCycles, (index) {
                final isDone = index < _completedCycles;
                final isCurrent = index == _completedCycles;
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: isCurrent ? 24 : 10,
                  height: 8,
                  decoration: BoxDecoration(
                    color: isDone
                        ? OasisColors.primary
                        : isCurrent
                            ? OasisColors.primary.withValues(alpha: 0.7)
                            : OasisColors.cardBorder,
                    borderRadius: BorderRadius.circular(6),
                  ),
                );
              }),
            ),
            const SizedBox(height: 24),
          ],

          // Bottom Controls
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (!isFinished) ...[
                  IconButton.filledTonal(
                    icon: Icon(_isRunning ? Icons.pause_rounded : Icons.play_arrow_rounded),
                    iconSize: 28,
                    onPressed: _togglePlayPause,
                  ),
                  const SizedBox(width: 16),
                  OutlinedButton.icon(
                    onPressed: () => _startTechnique(_technique),
                    icon: const Icon(Icons.refresh_rounded, size: 18),
                    label: const Text('إعادة البدء'),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: OasisColors.cardBorder),
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                    ),
                  ),
                ] else ...[
                  ElevatedButton.icon(
                    onPressed: () {
                      widget.onComplete?.call();
                      Navigator.pop(context);
                    },
                    icon: const Icon(Icons.check_circle_rounded),
                    label: const Text('اكتمل الاسترخاء 🌿 العودة للمؤقت'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildFinishedState() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: OasisColors.primary.withValues(alpha: 0.15),
            shape: BoxShape.circle,
            border: Border.all(color: OasisColors.primary.withValues(alpha: 0.4)),
          ),
          child: const Text('🧘‍♀️', style: TextStyle(fontSize: 64)),
        ),
        const SizedBox(height: 20),
        const Text(
          'أحسنت! عقلك الآن أكثر صفاءً وهدوءاً',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: OasisColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'أكملت 4 دورات تنفس بنجاح. أصبحت مستعداً لجلسة تركيز مثمرة!',
          style: TextStyle(
            fontSize: 13,
            color: OasisColors.textSecondary,
          ),
        ),
      ],
    );
  }
}
