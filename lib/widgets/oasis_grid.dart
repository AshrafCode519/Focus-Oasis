import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/tree.dart';
import '../services/storage_service.dart';
import '../services/locale_service.dart';
import '../theme/app_theme.dart';
import 'tree_canvas.dart';
import 'achievements_modal.dart';
import 'share_card_modal.dart';

class OasisGridView extends StatefulWidget {
  final StorageService storage;

  const OasisGridView({super.key, required this.storage});

  @override
  State<OasisGridView> createState() => _OasisGridViewState();
}

class _OasisGridViewState extends State<OasisGridView> {
  late List<PlantedTree> _plantedTrees;

  @override
  void initState() {
    super.initState();
    _loadTrees();
  }

  void _loadTrees() {
    setState(() {
      _plantedTrees = widget.storage.getPlantedTrees();
    });
  }

  @override
  Widget build(BuildContext context) {
    final int aliveCount = _plantedTrees.where((t) => t.isAlive).length;
    final int wiltedCount = _plantedTrees.where((t) => !t.isAlive).length;
    final int totalMinutes = _plantedTrees
        .where((t) => t.isAlive)
        .fold(0, (sum, t) => sum + t.durationMinutes);
    final double successRate = _plantedTrees.isEmpty
        ? 100.0
        : (aliveCount / _plantedTrees.length) * 100.0;

    return Scaffold(
      backgroundColor: OasisColors.background,
      appBar: AppBar(
        backgroundColor: OasisColors.surface,
        elevation: 0,
        title: Row(
          children: [
            const Text('🏝️', style: TextStyle(fontSize: 22)),
            const SizedBox(width: 8),
            Text(
              tr('oasis_title'),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.emoji_events_rounded, color: OasisColors.coinGold),
            onPressed: () => AchievementsModal.show(
              context,
              storage: widget.storage,
              onDataChanged: _loadTrees,
            ),
            tooltip: tr('tooltip_achievements'),
          ),
          IconButton(
            icon: const Icon(Icons.share_rounded, color: OasisColors.accentMint),
            onPressed: () => ShareCardModal.show(context, storage: widget.storage),
            tooltip: tr('share_oasis'),
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadTrees,
            tooltip: tr('refresh'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Stats Row
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    title: tr('living_trees'),
                    value: '$aliveCount',
                    icon: '🌳',
                    color: OasisColors.primary,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildStatCard(
                    title: tr('wilted_trees'),
                    value: '$wiltedCount',
                    icon: '🥀',
                    color: OasisColors.witheredRed,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildStatCard(
                    title: tr('focus_hours'),
                    value: (totalMinutes / 60.0).toStringAsFixed(1),
                    icon: '⏱️',
                    color: OasisColors.coinGold,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildStatCard(
                    title: tr('completion_rate'),
                    value: '${successRate.toStringAsFixed(0)}%',
                    icon: '🎯',
                    color: OasisColors.accentMint,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Section title
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'أشجارك المزروعة (${_plantedTrees.length})',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                Text(
                  'كل شجرة تمثل جلسة تركيز حقيقية',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Forest Grid
            if (_plantedTrees.isEmpty)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 20),
                decoration: BoxDecoration(
                  color: OasisColors.card,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: OasisColors.cardBorder),
                ),
                child: Column(
                  children: [
                    const Text('🌱', style: TextStyle(fontSize: 48)),
                    const SizedBox(height: 12),
                    const Text(
                      'واحتك فارغة حالياً!',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: OasisColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'ابدأ جلسة بومودورو جديدة وازرع أول بذرة لتشهد نموها في غابتك.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: OasisColors.textSecondary, fontSize: 14),
                    ),
                  ],
                ),
              )
            else
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 180,
                  mainAxisSpacing: 14,
                  crossAxisSpacing: 14,
                  childAspectRatio: 0.82,
                ),
                itemCount: _plantedTrees.length,
                itemBuilder: (context, index) {
                  final tree = _plantedTrees[index];

                  return InkWell(
                    borderRadius: BorderRadius.circular(18),
                    onTap: () => _showTreeDetailsDialog(context, tree),
                    child: Container(
                      decoration: BoxDecoration(
                        color: tree.isAlive
                            ? OasisColors.card
                            : OasisColors.witheredRed.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: tree.isAlive
                              ? OasisColors.cardBorder
                              : OasisColors.witheredRed.withValues(alpha: 0.3),
                        ),
                      ),
                      padding: const EdgeInsets.all(10),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Center(
                              child: TreeCanvas(
                                progress: tree.isAlive ? 1.0 : 0.5,
                                isFailed: !tree.isAlive,
                                species: tree.species,
                                size: 85,
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            tree.species.name(LocaleService.instance.currentLocale),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: OasisColors.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                tree.isAlive
                                    ? Icons.check_circle_rounded
                                    : Icons.cancel_rounded,
                                size: 12,
                                color: tree.isAlive
                                    ? OasisColors.primary
                                    : OasisColors.witheredRed,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${tree.durationMinutes} ${tr('mins_suffix')}',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: tree.isAlive
                                      ? OasisColors.textSecondary
                                      : OasisColors.witheredRed,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
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
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 11, color: OasisColors.textSecondary),
          ),
        ],
      ),
    );
  }

  void _showTreeDetailsDialog(BuildContext context, PlantedTree tree) {
    final dateFormat = DateFormat('yyyy/MM/dd - h:mm a');
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Text(tree.isAlive ? tree.species.iconEmoji : '🥀'),
            const SizedBox(width: 8),
            Text(tree.species.name(LocaleService.instance.currentLocale)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: SizedBox(
                height: 120,
                child: TreeCanvas(
                  progress: tree.isAlive ? 1.0 : 0.5,
                  isFailed: !tree.isAlive,
                  species: tree.species,
                  size: 110,
                ),
              ),
            ),
            const SizedBox(height: 14),
            _detailRow(tr('status_label'), tree.isAlive ? tr('tree_status_alive') : tr('tree_status_wilted')),
            _detailRow(tr('session_duration'), '${tree.durationMinutes} ${tr('mins_suffix')}'),
            _detailRow(tr('plant_date'), dateFormat.format(tree.plantedAt)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(tr('close')),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: OasisColors.textSecondary, fontSize: 13)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
        ],
      ),
    );
  }
}
