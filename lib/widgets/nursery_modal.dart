import 'package:flutter/material.dart';
import '../models/tree.dart';
import '../services/storage_service.dart';
import '../services/locale_service.dart';
import '../theme/app_theme.dart';
import 'tree_canvas.dart';

class NurseryModal extends StatefulWidget {
  final StorageService storage;
  final VoidCallback onDataChanged;
  final bool isSheet;

  const NurseryModal({
    super.key,
    required this.storage,
    required this.onDataChanged,
    this.isSheet = false,
  });

  @override
  State<NurseryModal> createState() => _NurseryModalState();
}

class _NurseryModalState extends State<NurseryModal> {
  late int _coins;
  late String _selectedTreeId;
  late List<String> _unlockedIds;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    setState(() {
      _coins = widget.storage.getCoins();
      _selectedTreeId = widget.storage.getSelectedTreeId();
      _unlockedIds = widget.storage.getUnlockedTreeIds();
    });
  }

  Future<void> _selectTree(String id) async {
    await widget.storage.setSelectedTreeId(id);
    _loadData();
    widget.onDataChanged();
  }

  Future<void> _buyTree(TreeSpecies species) async {
    if (_coins < species.priceCoins) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('رصيد العملات غير كافٍ لشراء ${species.nameAr}! 🪙'),
          backgroundColor: OasisColors.witheredRed,
        ),
      );
      return;
    }

    await widget.storage.setCoins(_coins - species.priceCoins);
    await widget.storage.unlockTree(species.id);
    await widget.storage.setSelectedTreeId(species.id);
    _loadData();
    widget.onDataChanged();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تهانينا! تم شراء واختيار ${species.nameAr} بنجاح! 🎉'),
          backgroundColor: OasisColors.primary,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final listWidget = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.isSheet) ...[
          // Header for modal
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Text('🏡', style: TextStyle(fontSize: 24)),
                  const SizedBox(width: 8),
                  Text(
                    tr('nursery_title'),
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ],
              ),
              _coinsBadge(),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            tr('coins_balance', {'coins': _coins}),
            style: const TextStyle(color: OasisColors.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 16),
        ],

        // Catalog list
        Expanded(
          child: ListView.separated(
            padding: EdgeInsets.zero,
            itemCount: TreeSpecies.catalog.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final species = TreeSpecies.catalog[index];
              final isUnlocked = _unlockedIds.contains(species.id);
              final isSelected = _selectedTreeId == species.id;

              return Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isSelected
                      ? OasisColors.primary.withValues(alpha: 0.12)
                      : OasisColors.card,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: isSelected
                        ? OasisColors.primary
                        : OasisColors.cardBorder,
                    width: isSelected ? 1.8 : 1.0,
                  ),
                ),
                child: Row(
                  children: [
                    // Miniature Tree Preview
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: OasisColors.background,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Center(
                        child: TreeCanvas(
                          progress: 1.0,
                          isFailed: false,
                          species: species,
                          size: 70,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),

                    // Tree details
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                species.iconEmoji,
                                style: const TextStyle(fontSize: 16),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                species.name(LocaleService.instance.currentLocale),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: OasisColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            species.descriptionAr,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: OasisColors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),

                    // Action button
                    if (isSelected)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: OasisColors.primary.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.check_circle_rounded, color: OasisColors.primary, size: 16),
                            const SizedBox(width: 4),
                            Text(
                              tr('selected'),
                              style: const TextStyle(
                                color: OasisColors.primary,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      )
                    else if (isUnlocked)
                      OutlinedButton(
                        onPressed: () => _selectTree(species.id),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: OasisColors.primary),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        ),
                        child: Text(tr('select'), style: const TextStyle(color: OasisColors.primary)),
                      )
                    else
                      ElevatedButton.icon(
                        onPressed: () => _buyTree(species),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: OasisColors.coinGoldDark,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        icon: const Icon(Icons.lock_open_rounded, size: 14),
                        label: Text(
                          '${species.priceCoins} 🪙',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );

    if (widget.isSheet) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        decoration: const BoxDecoration(
          color: OasisColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: listWidget,
      );
    }

    return Scaffold(
      backgroundColor: OasisColors.background,
      appBar: AppBar(
        backgroundColor: OasisColors.surface,
        elevation: 0,
        title: Row(
          children: [
            const Text('🏡', style: TextStyle(fontSize: 22)),
            const SizedBox(width: 8),
            Text(
              tr('nursery_title'),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(left: 16),
            child: Center(child: _coinsBadge()),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: listWidget,
      ),
    );
  }

  Widget _coinsBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: OasisColors.coinGold.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: OasisColors.coinGold.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.monetization_on_rounded, color: OasisColors.coinGold, size: 18),
          const SizedBox(width: 6),
          Text(
            '$_coins',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: OasisColors.coinGold,
            ),
          ),
        ],
      ),
    );
  }
}
