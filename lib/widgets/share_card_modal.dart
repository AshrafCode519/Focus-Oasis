import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';

class ShareCardModal extends StatelessWidget {
  final StorageService storage;

  const ShareCardModal({super.key, required this.storage});

  static void show(BuildContext context, {required StorageService storage}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ShareCardModal(storage: storage),
    );
  }

  @override
  Widget build(BuildContext context) {
    final planted = storage.getPlantedTrees();
    final aliveCount = planted.where((t) => t.isAlive).length;
    final totalMins = planted
        .where((t) => t.isAlive)
        .fold(0, (sum, t) => sum + t.durationMinutes);
    final int hours = totalMins ~/ 60;
    final int remainingMins = totalMins % 60;
    final double successRate =
        planted.isEmpty ? 100.0 : (aliveCount / planted.length) * 100.0;
    final coins = storage.getCoins();

    final timeString = hours > 0
        ? '$hours س و $remainingMins د'
        : '$totalMins دقيقة';

    return Container(
      decoration: const BoxDecoration(
        color: OasisColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag handle
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
          const SizedBox(height: 16),

          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Text('📸', style: TextStyle(fontSize: 24)),
                  SizedBox(width: 10),
                  Text(
                    'بطاقة إنجاز الواحة',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // The Share Card Canvas
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF162E25),
                  OasisColors.card,
                  const Color(0xFF0F1E19),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: OasisColors.primary.withValues(alpha: 0.5), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: OasisColors.primary.withValues(alpha: 0.25),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top Identity
                Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.asset(
                        'assets/images/app_icon.jpg',
                        width: 44,
                        height: 44,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'واحة التركيز • Focus Oasis',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: OasisColors.textPrimary,
                          ),
                        ),
                        Text(
                          'تقرير الإنتاجية والتركيز العميق',
                          style: TextStyle(fontSize: 11, color: OasisColors.accentMint),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Stats Grid (4 blocks)
                Row(
                  children: [
                    Expanded(
                      child: _buildShareStat(
                        title: 'وقت التركيز',
                        value: timeString,
                        icon: '⏱️',
                        color: OasisColors.accentMint,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildShareStat(
                        title: 'الأشجار الحية',
                        value: '$aliveCount شجرة',
                        icon: '🌳',
                        color: OasisColors.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildShareStat(
                        title: 'نسبة النجاح',
                        value: '${successRate.toInt()}%',
                        icon: '🎯',
                        color: OasisColors.coinGold,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildShareStat(
                        title: 'عملات الواحة',
                        value: '$coins 🪙',
                        icon: '💎',
                        color: const Color(0xFF60A5FA),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Motivational footer quote
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    '«كل دقيقة تركيز تغرس شجرة حية في مستقبلك» 🌿',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: OasisColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Copy Summary Button
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              backgroundColor: OasisColors.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            icon: const Icon(Icons.copy_rounded, size: 20),
            label: const Text(
              'نسخ ملخص إنجازي لمشاركته',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            onPressed: () {
              final shareText = '''
🌿 إنجازي في واحة التركيز • Focus Oasis:
⏱️ وقت التركيز: $timeString
🌳 الأشجار المزروعة: $aliveCount شجرة
🎯 نسبة الالتزام والنجاح: ${successRate.toInt()}%
🪙 عملات الواحة: $coins

«كل دقيقة تركيز تغرس شجرة حية في مستقبلك» 🌴✨
''';
              Clipboard.setData(ClipboardData(text: shareText));
              HapticFeedback.mediumImpact();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  backgroundColor: OasisColors.card,
                  content: const Text(
                    'تم نسخ بطاقة الإنجاز إلى الحافظة! يمكنك لصقها الآن في واتساب أو أي تطبيق 📋✨',
                    style: TextStyle(color: OasisColors.accentMint, fontWeight: FontWeight.bold),
                  ),
                  duration: const Duration(seconds: 3),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildShareStat({
    required String title,
    required String value,
    required String icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: OasisColors.surface.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(icon, style: const TextStyle(fontSize: 16)),
              const SizedBox(width: 6),
              Text(
                title,
                style: const TextStyle(fontSize: 11, color: OasisColors.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
