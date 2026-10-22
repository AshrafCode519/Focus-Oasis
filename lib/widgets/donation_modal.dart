import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/storage_service.dart';
import '../services/locale_service.dart';
import '../theme/app_theme.dart';

class DonationModal extends StatefulWidget {
  final StorageService storage;
  final VoidCallback? onSupporterStatusChanged;

  const DonationModal({
    super.key,
    required this.storage,
    this.onSupporterStatusChanged,
  });

  static void show(
    BuildContext context, {
    required StorageService storage,
    VoidCallback? onSupporterStatusChanged,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DonationModal(
        storage: storage,
        onSupporterStatusChanged: onSupporterStatusChanged,
      ),
    );
  }

  @override
  State<DonationModal> createState() => _DonationModalState();
}

class _DonationModalState extends State<DonationModal> {
  late bool _isSupporter;

  @override
  void initState() {
    super.initState();
    _isSupporter = widget.storage.isSupporter();
  }

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('تم نسخ $label إلى الحافظة بنجاح! 📋'),
        backgroundColor: OasisColors.primary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _claimSupporterReward() async {
    if (_isSupporter) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('أنت مسجل بالفعل كأحد الرعاة الفخريين للواحة! 🌟 شكراً لك من القلب.'),
          backgroundColor: OasisColors.coinGoldDark,
        ),
      );
      return;
    }

    await widget.storage.setSupporter(true);
    await widget.storage.addCoins(500);
    setState(() => _isSupporter = true);
    widget.onSupporterStatusChanged?.call();

    if (mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: OasisColors.surface,
          title: const Column(
            children: [
              Text('🎉', style: TextStyle(fontSize: 48)),
              SizedBox(height: 8),
              Text(
                'شكراً جزيلاً لدعمك النبيل! ❤️',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'مساهمتك تعني الكثير لاستمرار وتطوير واحة التركيز! تم منحك وسام الراعي الفخري وإضافة 500 عملة ذهبية 🪙 إلى رصيدك.',
                textAlign: TextAlign.center,
                style: TextStyle(color: OasisColors.textSecondary, fontSize: 13),
              ),
              SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.workspace_premium_rounded, color: OasisColors.coinGold, size: 24),
                  SizedBox(width: 8),
                  Text(
                    'راعي فخري معتمد 🌟',
                    style: TextStyle(
                      color: OasisColors.coinGold,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('سعيد بالمساهمة 🌿'),
            ),
          ],
        ),
      );
    }
  }

  void _showEditPaymentInfoDialog() {
    final vodafoneCtrl = TextEditingController(text: widget.storage.getDonationVodafone());
    final instapayCtrl = TextEditingController(text: widget.storage.getDonationInstapay());
    final coffeeCtrl = TextEditingController(text: widget.storage.getDonationCoffee());
    final paypalCtrl = TextEditingController(text: widget.storage.getDonationPaypal());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: OasisColors.surface,
        title: const Row(
          children: [
            Text('✏️', style: TextStyle(fontSize: 20)),
            SizedBox(width: 8),
            Text('تخصيص بيانات التبرع والدعم'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'يمكنك تعديل أرقام وحسابات الدفع التي تظهر للمستخدمين عند رغبتهم في دعمك:',
                style: TextStyle(fontSize: 12, color: OasisColors.textSecondary),
              ),
              const SizedBox(height: 12),
              _field(vodafoneCtrl, 'فودافون كاش / محفظة إلكترونية', Icons.phone_android_rounded),
              const SizedBox(height: 10),
              _field(instapayCtrl, 'معرف إنستاباي (InstaPay IPN)', Icons.account_balance_rounded),
              const SizedBox(height: 10),
              _field(coffeeCtrl, 'رابط Buy Me a Coffee', Icons.coffee_rounded),
              const SizedBox(height: 10),
              _field(paypalCtrl, 'رابط PayPal.me', Icons.payment_rounded),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () async {
              await widget.storage.setDonationVodafone(vodafoneCtrl.text.trim());
              await widget.storage.setDonationInstapay(instapayCtrl.text.trim());
              await widget.storage.setDonationCoffee(coffeeCtrl.text.trim());
              await widget.storage.setDonationPaypal(paypalCtrl.text.trim());
              if (context.mounted) {
                Navigator.pop(context);
                setState(() {});
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('تم حفظ بيانات الدعم والتبرع بنجاح! ✅'),
                    backgroundColor: OasisColors.primary,
                  ),
                );
              }
            },
            child: const Text('حفظ التعديلات'),
          ),
        ],
      ),
    );
  }

  Widget _field(TextEditingController ctrl, String label, IconData icon) {
    return TextField(
      controller: ctrl,
      style: const TextStyle(fontSize: 13),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontSize: 12, color: OasisColors.textSecondary),
        prefixIcon: Icon(icon, size: 18, color: OasisColors.primary),
        filled: true,
        fillColor: OasisColors.card,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: OasisColors.cardBorder),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vodafone = widget.storage.getDonationVodafone();
    final instapay = widget.storage.getDonationInstapay();
    final coffee = widget.storage.getDonationCoffee();
    final paypal = widget.storage.getDonationPaypal();

    return Container(
      height: MediaQuery.of(context).size.height * 0.88,
      decoration: const BoxDecoration(
        color: OasisColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          // Drag Handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 44,
              height: 5,
              decoration: BoxDecoration(
                color: OasisColors.cardBorder,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFD97706).withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Text('☕', style: TextStyle(fontSize: 24)),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tr('donation_title'),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: OasisColors.textPrimary,
                          ),
                        ),
                        Text(
                          _isSupporter ? tr('supporter_badge') : tr('donation_subtitle'),
                          style: TextStyle(
                            fontSize: 11,
                            color: _isSupporter ? OasisColors.coinGold : OasisColors.textSecondary,
                            fontWeight: _isSupporter ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit_note_rounded, color: OasisColors.primary),
                      tooltip: 'تعديل بيانات الدفع',
                      onPressed: _showEditPaymentInfoDialog,
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

          // Scrollable Body
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Warm Message Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFFD97706).withValues(alpha: 0.2),
                          OasisColors.primary.withValues(alpha: 0.12),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: const Color(0xFFD97706).withValues(alpha: 0.35),
                      ),
                    ),
                    child: const Row(
                      children: [
                        Text('💖', style: TextStyle(fontSize: 34)),
                        SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'تطبيق واحة التركيز مجاني 100% وبدون إعلانات',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white),
                              ),
                              SizedBox(height: 3),
                              Text(
                                'إذا كان التطبيق يساعدك في إنجاز مهامك وزيادة تركيزك، فإن دعمك بكوب قهوة ☕ يساعد في تغطية تكاليف الخوادم وتطوير مزايا جديدة باستمرار.',
                                style: TextStyle(fontSize: 11, color: Colors.white70, height: 1.4),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  const Text(
                    'طرق الدعم والتبرع المتاحة:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: OasisColors.textPrimary),
                  ),
                  const SizedBox(height: 12),

                  // Option 1: Vodafone Cash / E-Wallets (Egypt & Arab region)
                  _buildPaymentCard(
                    iconText: '📱',
                    title: 'فودافون كاش ومحافظ الهاتف',
                    subtitle: 'تحويل مباشر لمحفظة الكاش (داخل مصر)',
                    value: vodafone,
                    copyLabel: 'رقم محفظة فودافون كاش',
                    color: const Color(0xFFEF4444),
                  ),
                  const SizedBox(height: 10),

                  // Option 2: InstaPay IPN
                  _buildPaymentCard(
                    iconText: '⚡',
                    title: 'إنستاباي (InstaPay IPN)',
                    subtitle: 'تحويل بنكي لحظي فوري عبر المعرف',
                    value: instapay,
                    copyLabel: 'معرف إنستاباي',
                    color: const Color(0xFF8B5CF6),
                  ),
                  const SizedBox(height: 10),

                  // Option 3: Buy Me a Coffee
                  _buildPaymentCard(
                    iconText: '☕',
                    title: 'اشترِ لي قهوة (Buy Me a Coffee)',
                    subtitle: 'دعم سريع ببطاقات الفيزا والماستركارد دولياً',
                    value: coffee,
                    copyLabel: 'رابط Buy Me a Coffee',
                    color: const Color(0xFFFBBF24),
                  ),
                  const SizedBox(height: 10),

                  // Option 4: PayPal
                  _buildPaymentCard(
                    iconText: '💳',
                    title: 'بايبال (PayPal.me)',
                    subtitle: 'دعم آمن وسريع عبر بايبال من أي مكان',
                    value: paypal,
                    copyLabel: 'رابط بايبال',
                    color: const Color(0xFF38BDF8),
                  ),
                  const SizedBox(height: 20),

                  // Supporter Claim Section
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: OasisColors.card,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: _isSupporter
                            ? OasisColors.coinGold
                            : OasisColors.cardBorder,
                      ),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Text(_isSupporter ? '👑' : '🎁', style: const TextStyle(fontSize: 24)),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _isSupporter ? 'أنت راعٍ فخري معتمد!' : 'هل قمت بالتبرع والدعم بالفعل؟',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                      color: _isSupporter ? OasisColors.coinGold : OasisColors.textPrimary,
                                    ),
                                  ),
                                  Text(
                                    _isSupporter
                                        ? 'شكراً لك على دعمك الكريم ومساعدتك للواحة.'
                                        : 'اضغط هنا للحصول على وسام الراعي الفخري و 500 عملة واحة فورية!',
                                    style: const TextStyle(fontSize: 11, color: OasisColors.textSecondary),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _claimSupporterReward,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _isSupporter
                                  ? OasisColors.surface
                                  : OasisColors.coinGold,
                              foregroundColor: _isSupporter ? OasisColors.coinGold : Colors.black,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              side: _isSupporter
                                  ? const BorderSide(color: OasisColors.coinGold)
                                  : null,
                            ),
                            icon: Icon(
                              _isSupporter
                                  ? Icons.check_circle_rounded
                                  : Icons.favorite_rounded,
                              size: 18,
                            ),
                            label: Text(
                              _isSupporter
                                  ? 'وسام الراعي الفخري مفعّل 🌟'
                                  : 'لقد قمت بالدعم! استلم وسامك وهديتك ❤️',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentCard({
    required String iconText,
    required String title,
    required String subtitle,
    required String value,
    required String copyLabel,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: OasisColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: OasisColors.cardBorder),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(iconText, style: const TextStyle(fontSize: 22)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: OasisColors.textPrimary),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 10, color: OasisColors.textSecondary),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: OasisColors.surface,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: OasisColors.cardBorder),
                  ),
                  child: Text(
                    value,
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ),
              ],
            ),
          ),
          IconButton.filledTonal(
            icon: const Icon(Icons.copy_rounded, size: 16),
            tooltip: 'نسخ $copyLabel',
            onPressed: () => _copyToClipboard(value, copyLabel),
          ),
        ],
      ),
    );
  }
}
