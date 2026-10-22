import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/supabase_config.dart';
import '../services/storage_service.dart';
import '../services/supabase_service.dart';
import '../theme/app_theme.dart';
import 'oasis_loading.dart';

class CloudSyncModal extends StatefulWidget {
  final StorageService storage;
  final VoidCallback onSyncComplete;

  const CloudSyncModal({
    super.key,
    required this.storage,
    required this.onSyncComplete,
  });

  static Future<void> show(
    BuildContext context, {
    required StorageService storage,
    required VoidCallback onSyncComplete,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CloudSyncModal(
        storage: storage,
        onSyncComplete: onSyncComplete,
      ),
    );
  }

  @override
  State<CloudSyncModal> createState() => _CloudSyncModalState();
}

class _CloudSyncModalState extends State<CloudSyncModal> with SingleTickerProviderStateMixin {
  final _supabaseService = SupabaseService();
  late TabController _tabController;

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();

  final _customUrlController = TextEditingController();
  final _customKeyController = TextEditingController();

  bool _isLoading = false;
  bool _showCustomConfig = false;
  String? _statusMessage;
  bool _isSuccessMessage = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadCustomConfig();
  }

  Future<void> _loadCustomConfig() async {
    final prefs = await SharedPreferences.getInstance();
    _customUrlController.text = SupabaseConfig.getUrl(prefs);
    _customKeyController.text = SupabaseConfig.getAnonKey(prefs);
    if (!SupabaseConfig.isConfigured(prefs)) {
      _showCustomConfig = true;
    }
    setState(() {});
  }

  @override
  void dispose() {
    _tabController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _customUrlController.dispose();
    _customKeyController.dispose();
    super.dispose();
  }

  Future<void> _handleAuth(bool isSignUp) async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showMessage('يرجى إدخال البريد الإلكتروني وكلمة المرور', isSuccess: false);
      return;
    }

    setState(() => _isLoading = true);
    try {
      if (isSignUp) {
        await _supabaseService.signUpWithEmail(
          email: email,
          password: password,
          displayName: _nameController.text.trim().isNotEmpty
              ? _nameController.text.trim()
              : null,
        );
        _showMessage('تم إنشاء الحساب بنجاح! يتم الآن المزامنة...', isSuccess: true);
      } else {
        await _supabaseService.signInWithEmail(
          email: email,
          password: password,
        );
        _showMessage('تم تسجيل الدخول بنجاح!', isSuccess: true);
      }

      await _triggerSync();
    } catch (e) {
      _showMessage('فشلت العملية: $e', isSuccess: false);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleAnonymousSignIn() async {
    setState(() => _isLoading = true);
    try {
      await _supabaseService.signInAnonymously();
      _showMessage('تم الدخول كضيف بنجاح!', isSuccess: true);
      await _triggerSync();
    } catch (e) {
      _showMessage('فشل الدخول كضيف: $e', isSuccess: false);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleSignOut() async {
    setState(() => _isLoading = true);
    try {
      await _supabaseService.signOut();
      _showMessage('تم تسجيل الخروج', isSuccess: true);
    } catch (e) {
      _showMessage('خطأ في تسجيل الخروج: $e', isSuccess: false);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _triggerSync() async {
    setState(() => _isLoading = true);
    final result = await _supabaseService.syncAll(widget.storage);
    widget.onSyncComplete();
    _showMessage(result.message, isSuccess: result.success);
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _saveCustomConfig() async {
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      await SupabaseConfig.saveCredentials(
        prefs: prefs,
        url: _customUrlController.text.trim(),
        anonKey: _customKeyController.text.trim(),
      );

      final success = await _supabaseService.init(prefs);
      if (success) {
        _showMessage('تم الاتصال بمشروع Supabase بنجاح!', isSuccess: true);
        setState(() => _showCustomConfig = false);
      } else {
        _showMessage('تعذر الاتصال بالمشروع، تحقق من صحة الرابط والمفتاح', isSuccess: false);
      }
    } catch (e) {
      _showMessage('خطأ: $e', isSuccess: false);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showMessage(String text, {required bool isSuccess}) {
    if (!mounted) return;
    setState(() {
      _statusMessage = text;
      _isSuccessMessage = isSuccess;
    });
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final user = _supabaseService.currentUser;
    final isConnected = _supabaseService.isInitialized;

    return Container(
      margin: EdgeInsets.only(bottom: bottomInset),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: const BoxDecoration(
        color: OasisColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 48,
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
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: OasisColors.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.cloud_sync_rounded, color: OasisColors.primary, size: 26),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'المزامنة السحابية اللحظية',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'مزامنة جلساتك وحديقتك عبر أجهزة الجوال وسطح المكتب',
                        style: TextStyle(fontSize: 12, color: OasisColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Status banner if any
            if (_statusMessage != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _isSuccessMessage
                      ? OasisColors.primary.withValues(alpha: 0.15)
                      : OasisColors.witheredRed.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _isSuccessMessage
                        ? OasisColors.primary.withValues(alpha: 0.4)
                        : OasisColors.witheredRed.withValues(alpha: 0.4),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _isSuccessMessage ? Icons.check_circle_rounded : Icons.info_outline_rounded,
                      color: _isSuccessMessage ? OasisColors.primary : OasisColors.witheredRed,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _statusMessage!,
                        style: TextStyle(
                          fontSize: 13,
                          color: _isSuccessMessage ? OasisColors.accentMint : OasisColors.witheredRed,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
            ],

            // Content: Either Logged In State OR Auth Form
            if (user != null) ...[
              _buildLoggedInView(user),
            ] else ...[
              _buildAuthTabs(),
            ],

            const SizedBox(height: 16),

            // Custom Supabase Project Config Collapsible
            _buildCustomConfigSection(isConnected),
          ],
        ),
      ),
    );
  }

  Widget _buildLoggedInView(dynamic user) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: OasisColors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: OasisColors.cardBorder),
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: OasisColors.primary,
                radius: 22,
                child: Text(
                  (user.email ?? 'U').substring(0, 1).toUpperCase(),
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.email ?? 'مستخدم مجهول',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    const Text(
                      'متصل بالسحابة • المزامنة الفورية مفعلة',
                      style: TextStyle(fontSize: 12, color: OasisColors.accentMint),
                    ),
                  ],
                ),
              ),
              Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  color: OasisColors.accentMint,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _triggerSync,
                  icon: _isLoading
                      ? const OasisLoadingIndicator(size: OasisLoadingSize.small)
                      : const Icon(Icons.sync_rounded),
                  label: const Text('مزامنة البيانات الآن'),
                ),
              ),
              const SizedBox(width: 10),
              OutlinedButton.icon(
                onPressed: _isLoading ? null : _handleSignOut,
                icon: const Icon(Icons.logout_rounded, color: OasisColors.witheredRed),
                label: const Text('خروج', style: TextStyle(color: OasisColors.witheredRed)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAuthTabs() {
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            color: OasisColors.card,
            borderRadius: BorderRadius.circular(14),
          ),
          child: TabBar(
            controller: _tabController,
            indicatorColor: OasisColors.primary,
            indicatorWeight: 3,
            labelColor: OasisColors.primary,
            unselectedLabelColor: OasisColors.textSecondary,
            tabs: const [
              Tab(text: 'تسجيل الدخول'),
              Tab(text: 'حساب جديد'),
            ],
          ),
        ),
        const SizedBox(height: 16),

        TextField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(
            labelText: 'البريد الإلكتروني',
            prefixIcon: const Icon(Icons.email_outlined, color: OasisColors.primary),
            filled: true,
            fillColor: OasisColors.card,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
        const SizedBox(height: 12),

        TextField(
          controller: _passwordController,
          obscureText: true,
          decoration: InputDecoration(
            labelText: 'كلمة المرور',
            prefixIcon: const Icon(Icons.lock_outline_rounded, color: OasisColors.primary),
            filled: true,
            fillColor: OasisColors.card,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
        const SizedBox(height: 12),

        // Display name for Sign Up
        AnimatedBuilder(
          animation: _tabController,
          builder: (context, _) {
            if (_tabController.index == 1) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: TextField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'الاسم المعروض (اختياري)',
                    prefixIcon: const Icon(Icons.person_outline_rounded, color: OasisColors.primary),
                    filled: true,
                    fillColor: OasisColors.card,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              );
            }
            return const SizedBox.shrink();
          },
        ),

        ElevatedButton(
          onPressed: _isLoading ? null : () => _handleAuth(_tabController.index == 1),
          child: _isLoading
              ? const OasisLoadingIndicator(size: OasisLoadingSize.small)
              : AnimatedBuilder(
                  animation: _tabController,
                  builder: (context, _) => Text(
                    _tabController.index == 0 ? 'تسجيل الدخول 🚀' : 'إنشاء حساب واحة 🌿',
                  ),
                ),
        ),
        const SizedBox(height: 8),

        TextButton.icon(
          onPressed: _isLoading ? null : _handleAnonymousSignIn,
          icon: const Icon(Icons.person_outline_rounded, size: 18),
          label: const Text('دخول سريع كضيف (Guest Mode)'),
        ),
      ],
    );
  }

  Widget _buildCustomConfigSection(bool isConnected) {
    return Container(
      decoration: BoxDecoration(
        color: OasisColors.card.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: OasisColors.cardBorder),
      ),
      child: ExpansionTile(
        initiallyExpanded: _showCustomConfig,
        leading: Icon(
          Icons.dns_rounded,
          color: isConnected ? OasisColors.accentMint : OasisColors.coinGold,
        ),
        title: Text(
          isConnected ? 'إعدادات مشروع Supabase (متصل)' : 'ربط مشروع Supabase المخصص',
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          isConnected ? 'المشروع مهيأ بنجاح' : 'أدخل بيانات مشروعك لتفعيل المزامنة الفعلية',
          style: const TextStyle(fontSize: 11, color: OasisColors.textSecondary),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'يمكنك استخدام مشروعك على Supabase عبر نسخ الـ URL والـ Anon Key من لوحة تحكم Supabase (Project Settings -> API). كما تجد كود بناء الجداول في ملف supabase_schema.sql',
                  style: TextStyle(fontSize: 12, color: OasisColors.textSecondary),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _customUrlController,
                  decoration: InputDecoration(
                    labelText: 'Project URL (e.g. https://xxx.supabase.co)',
                    filled: true,
                    fillColor: OasisColors.surface,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _customKeyController,
                  decoration: InputDecoration(
                    labelText: 'Project anon public key',
                    filled: true,
                    fillColor: OasisColors.surface,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _saveCustomConfig,
                  icon: const Icon(Icons.save_rounded, size: 18),
                  label: const Text('حفظ واختبار الاتصال'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
