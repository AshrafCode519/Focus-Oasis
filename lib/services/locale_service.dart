import 'package:flutter/material.dart';
import 'storage_service.dart';

class AppLanguage {
  final String code;
  final String name;
  final String nativeName;
  final String flag;
  final bool isRtl;

  const AppLanguage({
    required this.code,
    required this.name,
    required this.nativeName,
    required this.flag,
    this.isRtl = false,
  });
}

class LocaleService extends ChangeNotifier {
  static final LocaleService instance = LocaleService._internal();
  factory LocaleService() => instance;
  LocaleService._internal();

  StorageService? _storage;
  String _currentLocale = 'ar';

  static const List<AppLanguage> supportedLanguages = [
    AppLanguage(
      code: 'ar',
      name: 'Arabic',
      nativeName: 'العربية',
      flag: '🇸🇦',
      isRtl: true,
    ),
    AppLanguage(
      code: 'en',
      name: 'English',
      nativeName: 'English',
      flag: '🇺🇸',
      isRtl: false,
    ),
    AppLanguage(
      code: 'fr',
      name: 'French',
      nativeName: 'Français',
      flag: '🇫🇷',
      isRtl: false,
    ),
    AppLanguage(
      code: 'es',
      name: 'Spanish',
      nativeName: 'Español',
      flag: '🇪🇸',
      isRtl: false,
    ),
  ];

  String get currentLocale => _currentLocale;
  bool get isRtl => _currentLocale == 'ar';
  Locale get locale => Locale(_currentLocale);

  AppLanguage get currentLanguage =>
      supportedLanguages.firstWhere((l) => l.code == _currentLocale, orElse: () => supportedLanguages.first);

  void init(StorageService storage) {
    _storage = storage;
    _currentLocale = storage.getLocale();
  }

  Future<void> setLocale(String code) async {
    if (_currentLocale == code) return;
    _currentLocale = code;
    await _storage?.setLocale(code);
    notifyListeners();
  }

  Future<void> cycleNextLanguage() async {
    final idx = supportedLanguages.indexWhere((l) => l.code == _currentLocale);
    final nextIdx = (idx + 1) % supportedLanguages.length;
    await setLocale(supportedLanguages[nextIdx].code);
  }

  String t(String key, [Map<String, dynamic>? params]) {
    final langMap = _translations[_currentLocale] ?? _translations['ar']!;
    String value = langMap[key] ?? _translations['en']?[key] ?? _translations['ar']?[key] ?? key;

    if (params != null) {
      params.forEach((paramKey, paramValue) {
        value = value.replaceAll('{$paramKey}', paramValue.toString());
      });
    }
    return value;
  }

  // --- Complete Translation Dictionaries ---
  static const Map<String, Map<String, String>> _translations = {
    // ----------------------------------------------------
    // ARABIC (العربية)
    // ----------------------------------------------------
    'ar': {
      'app_title': 'واحة التركيز',
      'app_subtitle': 'بومودورو • واحة خضراء',
      'nav_timer': 'المؤقت',
      'nav_oasis': 'الواحة',
      'nav_tasks': 'المهام',
      'nav_nursery': 'المشتل',
      'nav_challenges': 'التحديات',
      'nav_analytics': 'التحليلات',

      // Timer Controls
      'start_focus': 'ابدأ التركيز 🌿',
      'pause': 'إيقاف مؤقت ⏸️',
      'resume': 'متابعة التركيز ▶️',
      'give_up': 'استسلام 🏳️',
      'plant_new_tree': 'غرس شجرة جديدة 🌱',
      'wilted_tree_sub': 'شجرة ذابلة (اضغط لغرس جديدة)',
      'session_focus': 'جلسة تركيز',
      'session_short_break': 'استراحة قصيرة',
      'session_long_break': 'استراحة طويلة',
      'start_short_break_action': 'بدء استراحة قصيرة ☕',
      'start_focus_action': 'بدء جلسة تركيز 🌿',
      'active_task_prefix': 'المهمة النشطة: {task}',
      'breathing_banner': 'تمرين تنفس واسترخاء موجه (4-7-8)',
      'breathing_suggestion': 'أو خذ دقيقة لتمرين تنفس مهدئ (4-7-8) ✨',

      // Presets
      'mins_suffix': 'د',

      // Give Up Dialog
      'give_up_title': 'هل تود الاستسلام حقاً؟',
      'give_up_desc': 'إلغاء الجلسة الآن سيؤدي إلى جفاف شجرة {species} وتحولها إلى شجرة ذابلة في واحتك! هل أنت متأكد؟',
      'continue_focus': 'متابعة التركيز',
      'confirm_give_up': 'استسلام',

      // Success Dialog
      'session_complete_title': 'جلسة تركيز مثمرة! 🌿',
      'break_complete_title': 'انتهت الاستراحة! ☕',
      'session_complete_desc': 'رائع جداً! أتممت جلسة التركيز بنجاح وازدادت واحتك شجرة مزهرة جديدة وكسبت {coins} عملة ذهبية.',
      'break_complete_desc': 'حان وقت العودة لنشاطك وتركيزك بحماس وطاقة متجددة!',

      // Tooltips
      'tooltip_ambient': 'أصوات الطبيعة والتركيز',
      'tooltip_cloud': 'المزامنة السحابية والحساب',
      'tooltip_achievements': 'الأوسمة والإنجازات 🏆',
      'tooltip_breathing': 'تمرين التنفس والاسترخاء 🫁',
      'tooltip_pip': 'النافذة المصغرة العائمة (Always on Top)',
      'tooltip_donate': 'دعم المطور والتبرع ☕💖',
      'tooltip_settings': 'إعدادات المؤقت والهدف',
      'tooltip_language': 'تغيير اللغة (Change Language)',
      'tooltip_more': 'المزيد من الأدوات والخيارات',
      'daily_target_badge': 'هدف اليوم',
      'tags_title': 'اختر وسم جلسة التركيز 🏷️',

      // Settings Dialog
      'settings_title': 'إعدادات المؤقت والواحة ⚙️',
      'focus_duration': 'مدة جلسة التركيز (دقائق):',
      'short_break_duration': 'مدة الاستراحة القصيرة (دقائق):',
      'long_break_duration': 'مدة الاستراحة الطويلة (دقائق):',
      'daily_target_sessions': 'الهدف اليومي (عدد الجلسات):',
      'strict_mode': 'وضع الصرامة (Strict Mode)',
      'strict_mode_desc': 'مغادرة التطبيق تقتل الشجرة فوراً',
      'language_label': 'لغة التطبيق / App Language:',
      'backup_section': 'النسخ الاحتياطي ونقل البيانات 📦',
      'backup_desc': 'تصدير أو استيراد أشجارك ومهامك وإحصائياتك',
      'export_json': 'تصدير JSON',
      'import_json': 'استيراد JSON',
      'support_tile_title': 'دعم وتطوير واحة التركيز',
      'support_tile_sub': 'ادعم استمرار التطبيق وخوادمه بكوب قهوة',
      'cancel': 'إلغاء',
      'save_settings': 'حفظ الإعدادات',
      'backup_exported': 'تم نسخ النسخة الاحتياطية بنجاح إلى الحافظة! 📋',
      'backup_imported_ok': 'تم استيراد بياناتك وواحتك بنجاح! 🎉',
      'backup_imported_err': 'فشل استيراد النسخة الاحتياطية. يرجى التحقق من صحة كود JSON.',

      // Tasks
      'tasks_title': 'مهام بومودورو 📋',
      'task_input_hint': 'أضف مهمة جديدة للتركيز عليها...',
      'no_tasks': 'لا توجد مهام حالياً. ابدأ بإضافة مهمتك الأولى!',
      'delete': 'حذف',
      'set_active': 'تحديد كمهمة نشطة',
      'active_task': 'المهمة النشطة',
      'pomodoros_count': '{done}/{target} بومودورو',
      'add': 'إضافة',

      // Nursery
      'nursery_title': 'مشـتل الأشـجار 🏡',
      'unlocked': 'تم الفتح',
      'selected': 'مختارة حالياً',
      'select': 'اختيار',
      'buy_tree': 'فتح بـ {coins} عملة',
      'coins_balance': 'رصيدك: {coins} عملة ذهبية',
      'insufficient_coins': 'رصيد العملات غير كافٍ!',

      // Oasis
      'oasis_title': 'واحتي الخضراء 🌲',
      'total_trees': 'إجمالي الأشجار',
      'living_trees': 'أشجار مزهرة',
      'wilted_trees': 'أشجار ذابلة',
      'share_oasis': 'مشاركة إنجاز واحتي 📸',
      'no_trees_yet': 'واحتك فارغة حالياً. أكمل أول جلسة تركيز لتغرس أول شجرة هنا!',
      'status_label': 'الحالة:',
      'tree_status_alive': 'مكتملة ومزهرة 🌸',
      'tree_status_wilted': 'ذابلة (تم قطع الجلسة) 🥀',
      'session_duration': 'مدة الجلسة:',
      'plant_date': 'تاريخ الغرس:',
      'close': 'إغلاق',

      // Analytics
      'analytics_title': 'التحليلات ومستوى الإنتاجية 📊',
      'focus_hours': 'ساعات التركيز',
      'focus_days_streak': 'أيام متتالية',
      'completion_rate': 'نسبة النجاح',
      'weekly_heatmap': 'خريطة الإنتاجية الأسبوعية',
      'tag_distribution': 'توزيع الوقت حسب التصنيف',
      'history_sessions': 'سجل الجلسات الأخيرة',
      'streak_title': 'سلسلة التركيز المتواصلة',
      'streak_subtitle_active': 'أنت تسير بخطى رائعة نحو إتقان إدارة وقتك.',
      'streak_subtitle_empty': 'ابدأ جلسة تركيز اليوم لبناء سلسلة إنجاز جديدة!',
      'streak_days': '{count} أيام متتالية!',
      'total_minutes_sub': '{count} دقيقة إجمالية',
      'wilted_count_sub': '{count} ذابلة 🥀',
      'of_all_sessions': 'من كافة الجلسات',
      'heatmap_title': 'مخطط نشاط الواحة (آخر 10 أسابيع)',
      'no_activity': 'لا يوجد نشاط',
      'weekly_focus_title': 'نشاط التركيز الأسبوعي',
      'weekly_focus_sub': 'معدل الدقائق المنجزة في آخر 7 أيام',
      'last_7_days': 'آخر 7 أيام',
      'tag_distribution_title': 'توزيع التركيز حسب مجالات العمل',
      'minutes_logged': '{count} دقيقة مسجلة',
      'recent_sessions_title': 'سجل الجلسات الأخيرة',
      'sessions_logged': '{count} جلسة مسجلة',
      'no_sessions_yet': 'لا توجد جلسات مسجلة بعد. ابدأ أول جلسة تركيز لتملأ واحتك!',
      'wilted_session_prefix': 'جلسة ذابلة ({species})',
      'hours_suffix': 'س',

      // Breathing
      'breathing_title': 'جلسة التنفس والاسترخاء (4-7-8) 🫁',
      'breathing_desc': 'طريقة علمية معتمدة لتهدئة الجهاز العصبي، خفض هرمون التوتر وتجديد صفاء الذهن بين جلسات العمل.',
      'breathing_inhale': 'شـهـيـق...',
      'breathing_hold': 'احـبـس...',
      'breathing_exhale': 'زفـيـر...',
      'breathing_start': 'ابدأ تمرين التنفس (دقيقة واحدة) ✨',
      'breathing_stop': 'إنهاء التمرين ⏹️',
      'breathing_cycles': 'الدورات المكتملة: {count}',

      // Achievements
      'achievements_title': 'الأوسمة والإنجازات 🏆',
      'claim_reward': 'استلام {coins} عملة ✨',
      'claimed': 'تم الاستلام ✓',

      // Donations
      'donation_title': 'دعم وتطوير واحة التركيز ☕💖',
      'donation_subtitle': 'مشروع مجاني ومفتوح المصدر وخالٍ تماماً من الإعلانات',
      'donation_desc': 'تم بناء هذا التطبيق بحب وشغف لمساعدة الجميع على التركيز والإنجاز دون أي تشتيت أو إعلانات مزعجة. إذا كان التطبيق مفيداً في يومك ودراستك، يسعدنا دعمك الرمزي لنستمر في دفع تكاليف الخوادم وتطوير مزايا جديدة!',
      'copy': 'نسخ',
      'copied': 'تم النسخ!',
      'became_supporter': 'أنا داعم الآن ✨',
      'supporter_badge': 'أنت داعم رسمي للواحة! شكراً لك من القلب 🌟',

      // Community & Challenges
      'challenges_title': 'تحديات ومتصدرو الواحة 🏆⚔️',
      'tab_leaderboard': 'المتصدرون',
      'tab_challenges': 'التحديات',
      'tab_live_room': 'يدرسون الآن 🟢',
      'filter_today': 'اليوم',
      'filter_week': 'هذا الأسبوع',
      'filter_all_time': 'كل الأوقات',
      'community_rankings': 'قائمة المتصدرين',
      'participants': 'مشارك',
      'rank_first_motivation': 'أنت في صدارة الواحة حالياً! حافظ على تميزك وعرشك 👑🔥',
      'rank_gap_motivation': 'يفصلك {mins} دقيقة فقط لتتجاوز المركز #{nextRank} 🚀',
      'you_label': 'أنت',
      'cheer_sent_snack': 'أرسلت تشجيعاً وطاقة إيجابية إلى {name}! ⚡👏',
      'challenges_banner_title': 'تحديات التركيز اليومية والأسبوعية',
      'challenges_banner_sub': 'أكمل التحديات واكسب عملات ذهبية لفتح أشجار نادرة 🌲',
      'challenge_daily_title': 'تحديات اليوم (تتجدد يومياً)',
      'challenge_weekly_title': 'تحديات الأسبوع',
      'challenge_milestone_title': 'أوسمة الإنجاز الفارقة',
      'claim_action': 'استلام الجائزة ✨',
      'challenge_reward_claimed_snack': 'مبروك! استلمت {coins} عملة ذهبية لحسابك 🎉',
      'in_progress_status': 'جاري الإنجاز ⏳',
      'live_room_header_title': '{count} طلاب ومطورين يركزون الآن في الواحة 🟢',
      'live_room_header_sub': 'أنت لست وحدك! استشعر طاقة الإنجاز المشتركة وواصل التقدم',
      'send_energy_btn': 'أرسل طاقة ⚡',
      'energy_sent': 'تم التشجيع 👏',
      'edit_profile_title': 'تعديل ملفك في قائمة المتصدرين',
      'choose_avatar_label': 'اختر شعارك وأيقونتك المفضلة:',
      'nickname_field': 'الاسم أو اللقب المستعار',
      'study_field_field': 'مجال دراستك أو عملك (مثال: طب، برمجة...)',
      'status_bio_field': 'حالتك أو هدفك الحالي',
      'save_profile_btn': 'حفظ التعديلات',
      'tooltip_challenges': 'التحديات وقائمة المتصدرين 🏆⚔️',

      // Tags
      'tag_work': 'عمل',
      'tag_study': 'دراسة',
      'tag_code': 'برمجة',
      'tag_reading': 'قراءة',
      'tag_creative': 'إبداع',
      'tag_general': 'عام',
    },

    // ----------------------------------------------------
    // ENGLISH (English)
    // ----------------------------------------------------
    'en': {
      'app_title': 'Focus Oasis',
      'app_subtitle': 'Pomodoro • Green Forest',
      'nav_timer': 'Timer',
      'nav_oasis': 'Oasis',
      'nav_tasks': 'Tasks',
      'nav_nursery': 'Nursery',
      'nav_challenges': 'Challenges',
      'nav_analytics': 'Analytics',

      // Timer Controls
      'start_focus': 'Start Focus 🌿',
      'pause': 'Pause ⏸️',
      'resume': 'Resume ▶️',
      'give_up': 'Give Up 🏳️',
      'plant_new_tree': 'Plant New Tree 🌱',
      'wilted_tree_sub': 'Wilted tree (tap to plant new)',
      'session_focus': 'Focus Session',
      'session_short_break': 'Short Break',
      'session_long_break': 'Long Break',
      'start_short_break_action': 'Start Short Break ☕',
      'start_focus_action': 'Start Focus Session 🌿',
      'active_task_prefix': 'Active Task: {task}',
      'breathing_banner': 'Mindful Breathing Exercise (4-7-8)',
      'breathing_suggestion': 'Or take a minute for mindful breathing (4-7-8) ✨',

      // Presets
      'mins_suffix': 'm',

      // Give Up Dialog
      'give_up_title': 'Do you really want to give up?',
      'give_up_desc': 'Canceling the session now will wither your {species} tree in your oasis! Are you sure you want to quit?',
      'continue_focus': 'Keep Focusing',
      'confirm_give_up': 'Give Up',

      // Success Dialog
      'session_complete_title': 'Focus Session Completed! 🌿',
      'break_complete_title': 'Break Time Ended! ☕',
      'session_complete_desc': 'Awesome work! You completed your focus session, planted a flourishing tree, and earned {coins} coins.',
      'break_complete_desc': 'Time to get back to deep work with fresh energy and focus!',

      // Tooltips
      'tooltip_ambient': 'Nature & Ambient Sounds',
      'tooltip_cloud': 'Cloud Sync & Account',
      'tooltip_achievements': 'Badges & Achievements 🏆',
      'tooltip_breathing': 'Mindful Breathing & Relaxation 🫁',
      'tooltip_pip': 'Floating Mini Window (Always on Top)',
      'tooltip_donate': 'Support Developer & Tip Jar ☕💖',
      'tooltip_settings': 'Timer & Oasis Settings',
      'tooltip_language': 'Change Language',
      'tooltip_more': 'More Tools & Options',
      'daily_target_badge': 'Daily Target',
      'tags_title': 'Select Focus Tag 🏷️',

      // Settings Dialog
      'settings_title': 'Timer & Oasis Settings ⚙️',
      'focus_duration': 'Focus Duration (minutes):',
      'short_break_duration': 'Short Break Duration (minutes):',
      'long_break_duration': 'Long Break Duration (minutes):',
      'daily_target_sessions': 'Daily Target (Sessions):',
      'strict_mode': 'Strict Mode',
      'strict_mode_desc': 'Leaving the app wilts the tree immediately',
      'language_label': 'App Language:',
      'backup_section': 'Backup & Data Portability 📦',
      'backup_desc': 'Export or import your trees, tasks, and statistics',
      'export_json': 'Export JSON',
      'import_json': 'Import JSON',
      'support_tile_title': 'Support & Develop Focus Oasis',
      'support_tile_sub': 'Help keep the app and servers running with a coffee',
      'cancel': 'Cancel',
      'save_settings': 'Save Settings',
      'backup_exported': 'Backup copied to clipboard! 📋',
      'backup_imported_ok': 'Data and oasis restored successfully! 🎉',
      'backup_imported_err': 'Failed to import backup. Please check your JSON format.',

      // Tasks
      'tasks_title': 'Pomodoro Tasks 📋',
      'task_input_hint': 'Add a new task to focus on...',
      'no_tasks': 'No tasks yet. Start by adding your first task!',
      'delete': 'Delete',
      'set_active': 'Set as active task',
      'active_task': 'Active Task',
      'pomodoros_count': '{done}/{target} pomodoros',
      'add': 'Add',

      // Nursery
      'nursery_title': 'Tree Nursery 🏡',
      'unlocked': 'Unlocked',
      'selected': 'Selected',
      'select': 'Select',
      'buy_tree': 'Unlock for {coins} coins',
      'coins_balance': 'Your balance: {coins} coins',
      'insufficient_coins': 'Not enough coins!',

      // Oasis
      'oasis_title': 'My Green Oasis 🌲',
      'total_trees': 'Total Trees',
      'living_trees': 'Thriving Trees',
      'wilted_trees': 'Wilted Trees',
      'share_oasis': 'Share My Oasis 📸',
      'no_trees_yet': 'Your oasis is empty. Complete a focus session to grow your first tree here!',
      'status_label': 'Status:',
      'tree_status_alive': 'Healthy & Blooming 🌸',
      'tree_status_wilted': 'Wilted (Abandoned) 🥀',
      'session_duration': 'Session Duration:',
      'plant_date': 'Planted Date:',
      'close': 'Close',

      // Analytics
      'analytics_title': 'Analytics & Productivity 📊',
      'focus_hours': 'Focus Hours',
      'focus_days_streak': 'Day Streak',
      'completion_rate': 'Success Rate',
      'weekly_heatmap': 'Weekly Focus Heatmap',
      'tag_distribution': 'Time Distribution by Tag',
      'history_sessions': 'Recent Session History',
      'streak_title': 'Focus Streak',
      'streak_subtitle_active': 'You are making great progress mastering your time.',
      'streak_subtitle_empty': 'Start a focus session today to build a new streak!',
      'streak_days': '{count} consecutive days!',
      'total_minutes_sub': '{count} total minutes',
      'wilted_count_sub': '{count} wilted 🥀',
      'of_all_sessions': 'Of all sessions',
      'heatmap_title': 'Oasis Activity Map (Last 10 Weeks)',
      'no_activity': 'No activity',
      'weekly_focus_title': 'Weekly Focus Activity',
      'weekly_focus_sub': 'Minutes completed in the last 7 days',
      'last_7_days': 'Last 7 Days',
      'tag_distribution_title': 'Focus Distribution by Category',
      'minutes_logged': '{count} minutes logged',
      'recent_sessions_title': 'Recent Sessions Log',
      'sessions_logged': '{count} sessions logged',
      'no_sessions_yet': 'No sessions logged yet. Complete your first session to grow your oasis!',
      'wilted_session_prefix': 'Wilted session ({species})',
      'hours_suffix': 'h',

      // Breathing
      'breathing_title': 'Mindful Breathing (4-7-8) 🫁',
      'breathing_desc': 'A scientifically proven technique to soothe the nervous system, reduce cortisol, and restore crystal clarity.',
      'breathing_inhale': 'Inhale...',
      'breathing_hold': 'Hold...',
      'breathing_exhale': 'Exhale...',
      'breathing_start': 'Start Breathing (1 minute) ✨',
      'breathing_stop': 'End Exercise ⏹️',
      'breathing_cycles': 'Cycles completed: {count}',

      // Achievements
      'achievements_title': 'Badges & Achievements 🏆',
      'claim_reward': 'Claim {coins} coins ✨',
      'claimed': 'Claimed ✓',

      // Donations
      'donation_title': 'Support Focus Oasis ☕💖',
      'donation_subtitle': 'Free, Open-Source & 100% Ad-Free Project',
      'donation_desc': 'Built with love and dedication to help everyone focus deeply without distractions or ads. If this tool brings value to your workflow, your tip helps pay server costs and fund new features!',
      'copy': 'Copy',
      'copied': 'Copied!',
      'became_supporter': 'I am a Supporter ✨',
      'supporter_badge': 'You are an official Oasis Supporter! Thank you from the bottom of our hearts 🌟',

      // Community & Challenges
      'challenges_title': 'Challenges & Leaderboard 🏆⚔️',
      'tab_leaderboard': 'Leaderboard',
      'tab_challenges': 'Challenges',
      'tab_live_room': 'Studying Now 🟢',
      'filter_today': 'Today',
      'filter_week': 'This Week',
      'filter_all_time': 'All Time',
      'community_rankings': 'Community Rankings',
      'participants': 'participants',
      'rank_first_motivation': 'You are currently #1 in the Oasis! Keep reigning 👑🔥',
      'rank_gap_motivation': 'Only {mins} mins needed to overtake rank #{nextRank} 🚀',
      'you_label': 'You',
      'cheer_sent_snack': 'Sent positive focus energy to {name}! ⚡👏',
      'challenges_banner_title': 'Daily & Weekly Focus Quests',
      'challenges_banner_sub': 'Conquer challenges to earn gold coins and unlock rare species 🌲',
      'challenge_daily_title': 'Daily Quests (Resets Daily)',
      'challenge_weekly_title': 'Weekly Challenges',
      'challenge_milestone_title': 'Milestone Achievements',
      'claim_action': 'Claim Reward ✨',
      'challenge_reward_claimed_snack': 'Congratulations! Claimed {coins} gold coins 🎉',
      'in_progress_status': 'In Progress ⏳',
      'live_room_header_title': '{count} peers are deeply studying right now 🟢',
      'live_room_header_sub': 'You are never alone! Share the momentum and keep thriving',
      'send_energy_btn': 'Send Energy ⚡',
      'energy_sent': 'Cheered 👏',
      'edit_profile_title': 'Edit Leaderboard Profile',
      'choose_avatar_label': 'Choose your avatar:',
      'nickname_field': 'Display Name / Nickname',
      'study_field_field': 'Study or Work Field (e.g. Code, Medicine...)',
      'status_bio_field': 'Status / Current Motto',
      'save_profile_btn': 'Save Profile',
      'tooltip_challenges': 'Challenges & Leaderboard 🏆⚔️',

      // Tags
      'tag_work': 'Work',
      'tag_study': 'Study',
      'tag_code': 'Coding',
      'tag_reading': 'Reading',
      'tag_creative': 'Creative',
      'tag_general': 'General',
    },

    // ----------------------------------------------------
    // FRENCH (Français)
    // ----------------------------------------------------
    'fr': {
      'app_title': 'Oasis de Focus',
      'app_subtitle': 'Pomodoro • Forêt Verte',
      'nav_timer': 'Minuteur',
      'nav_oasis': 'Oasis',
      'nav_tasks': 'Tâches',
      'nav_nursery': 'Pépinière',
      'nav_challenges': 'Défis',
      'nav_analytics': 'Analyses',

      'start_focus': 'Commencer Focus 🌿',
      'pause': 'Pause ⏸️',
      'resume': 'Reprendre ▶️',
      'give_up': 'Abandonner 🏳️',
      'plant_new_tree': 'Planter un arbre 🌱',
      'wilted_tree_sub': 'Arbre fané (toucher pour replanter)',
      'session_focus': 'Session Focus',
      'session_short_break': 'Pause courte',
      'session_long_break': 'Pause longue',
      'start_short_break_action': 'Prendre une pause ☕',
      'start_focus_action': 'Commencer session focus 🌿',
      'active_task_prefix': 'Tâche active: {task}',
      'breathing_banner': 'Exercice de respiration consciente (4-7-8)',
      'breathing_suggestion': 'Ou prenez une minute de respiration (4-7-8) ✨',
      'mins_suffix': 'm',

      'give_up_title': 'Voulez-vous vraiment abandonner ?',
      'give_up_desc': 'Annuler la session maintenant fera dépérir votre arbre {species} dans votre oasis ! Êtes-vous sûr ?',
      'continue_focus': 'Continuer',
      'confirm_give_up': 'Abandonner',

      'session_complete_title': 'Session terminée avec succès ! 🌿',
      'break_complete_title': 'Pause terminée ! ☕',
      'session_complete_desc': 'Bravo ! Vous avez terminé votre session et gagné {coins} pièces.',
      'break_complete_desc': 'C\'est l\'heure de replonger dans le travail avec énergie !',

      'tooltip_ambient': 'Sons d\'ambiance et nature',
      'tooltip_cloud': 'Synchronisation cloud',
      'tooltip_achievements': 'Succès et trophées 🏆',
      'tooltip_breathing': 'Respiration et relaxation 🫁',
      'tooltip_pip': 'Mini fenêtre flottante',
      'tooltip_donate': 'Soutenir le développeur ☕💖',
      'tooltip_settings': 'Paramètres du minuteur',
      'tooltip_language': 'Changer de langue',
      'tooltip_more': 'Plus d\'options et outils',
      'daily_target_badge': 'Objectif du jour',
      'tags_title': 'Choisir l\'étiquette de focus 🏷️',

      'settings_title': 'Paramètres de l\'Oasis ⚙️',
      'focus_duration': 'Durée Focus (minutes):',
      'short_break_duration': 'Durée Pause Courte (minutes):',
      'long_break_duration': 'Durée Pause Longue (minutes):',
      'daily_target_sessions': 'Objectif quotidien (sessions):',
      'strict_mode': 'Mode Strict',
      'strict_mode_desc': 'Quitter l\'appli flétrit l\'arbre immédiatement',
      'language_label': 'Langue de l\'application:',
      'backup_section': 'Sauvegarde et portabilité 📦',
      'backup_desc': 'Exporter ou importer vos données',
      'export_json': 'Exporter JSON',
      'import_json': 'Importer JSON',
      'support_tile_title': 'Soutenir le projet',
      'support_tile_sub': 'Offrez un café pour soutenir le développement',
      'cancel': 'Annuler',
      'save_settings': 'Enregistrer',
      'backup_exported': 'Sauvegarde copiée dans le presse-papiers ! 📋',
      'backup_imported_ok': 'Données restaurées avec succès ! 🎉',
      'backup_imported_err': 'Échec de l\'importation.',

      'tasks_title': 'Tâches Pomodoro 📋',
      'task_input_hint': 'Ajouter une tâche à accomplir...',
      'no_tasks': 'Aucune tâche pour le moment.',
      'delete': 'Supprimer',
      'set_active': 'Définir comme active',
      'active_task': 'Tâche active',
      'pomodoros_count': '{done}/{target} pomodoros',
      'add': 'Ajouter',

      'nursery_title': 'Pépinière d\'arbres 🏡',
      'unlocked': 'Débloqué',
      'selected': 'Sélectionné',
      'select': 'Choisir',
      'buy_tree': 'Débloquer pour {coins} pièces',
      'coins_balance': 'Votre solde: {coins} pièces',
      'insufficient_coins': 'Pièces insuffisantes !',

      'oasis_title': 'Mon Oasis Verte 🌲',
      'total_trees': 'Total des arbres',
      'living_trees': 'Arbres florissants',
      'wilted_trees': 'Arbres fanés',
      'share_oasis': 'Partager mon oasis 📸',
      'no_trees_yet': 'Votre oasis est vide. Plantez votre premier arbre !',
      'status_label': 'Statut :',
      'tree_status_alive': 'Sain & Épanoui 🌸',
      'tree_status_wilted': 'Flétri (Abandonné) 🥀',
      'session_duration': 'Durée de la session :',
      'plant_date': 'Date de plantation :',
      'close': 'Fermer',

      'analytics_title': 'Analyses et productivité 📊',
      'focus_hours': 'Heures de focus',
      'focus_days_streak': 'Série de jours',
      'completion_rate': 'Taux de réussite',
      'weekly_heatmap': 'Carte de concentration',
      'tag_distribution': 'Répartition par catégorie',
      'history_sessions': 'Historique récent',
      'streak_title': 'Série de concentration',
      'streak_subtitle_active': 'Vous progressez remarquablement vers la maîtrise de votre temps.',
      'streak_subtitle_empty': 'Commencez une session aujourd\'hui pour lancer votre série !',
      'streak_days': '{count} jours consécutifs !',
      'total_minutes_sub': '{count} minutes au total',
      'wilted_count_sub': '{count} flétris 🥀',
      'of_all_sessions': 'Sur toutes les sessions',
      'heatmap_title': 'Activité de l\'Oasis (10 dernières semaines)',
      'no_activity': 'Aucune activité',
      'weekly_focus_title': 'Activité hebdomadaire',
      'weekly_focus_sub': 'Minutes accomplies au cours des 7 derniers jours',
      'last_7_days': '7 derniers jours',
      'tag_distribution_title': 'Distribution du temps par domaine',
      'minutes_logged': '{count} minutes enregistrées',
      'recent_sessions_title': 'Historique récent',
      'sessions_logged': '{count} sessions enregistrées',
      'no_sessions_yet': 'Aucune session pour le moment. Plantez votre premier arbre !',
      'wilted_session_prefix': 'Session flétrie ({species})',
      'hours_suffix': 'h',

      'breathing_title': 'Respiration consciente (4-7-8) 🫁',
      'breathing_desc': 'Une méthode apaisante pour détendre le corps et clarifier l\'esprit.',
      'breathing_inhale': 'Inspirez...',
      'breathing_hold': 'Retenez...',
      'breathing_exhale': 'Expirez...',
      'breathing_start': 'Démarrer (1 minute) ✨',
      'breathing_stop': 'Terminer ⏹️',
      'breathing_cycles': 'Cycles terminés: {count}',

      'achievements_title': 'Succès et badges 🏆',
      'claim_reward': 'Réclamer {coins} pièces ✨',
      'claimed': 'Réclamé ✓',

      'donation_title': 'Soutenir Focus Oasis ☕💖',
      'donation_subtitle': 'Projet gratuit, open source et sans publicité',
      'donation_desc': 'Ce projet est conçu pour vous aider à rester concentré en toute sérénité.',
      'copy': 'Copier',
      'copied': 'Copié !',
      'became_supporter': 'Je suis un soutien ✨',
      'supporter_badge': 'Vous êtes un soutien officiel ! Merci du fond du cœur 🌟',

      // Community & Challenges
      'challenges_title': 'Défis & Classement 🏆⚔️',
      'tab_leaderboard': 'Classement',
      'tab_challenges': 'Défis',
      'tab_live_room': 'Étudient Actuellement 🟢',
      'filter_today': 'Aujourd\'hui',
      'filter_week': 'Cette Semaine',
      'filter_all_time': 'Tous les Temps',
      'community_rankings': 'Classement Communautaire',
      'participants': 'participants',
      'rank_first_motivation': 'Vous êtes en tête de l\'Oasis ! Continuez à briller 👑🔥',
      'rank_gap_motivation': 'Plus que {mins} min pour dépasser la place #{nextRank} 🚀',
      'you_label': 'Vous',
      'cheer_sent_snack': 'Énergie positive envoyée à {name} ! ⚡👏',
      'challenges_banner_title': 'Défis de Focus Quotidiens et Hebdomadaires',
      'challenges_banner_sub': 'Relevez les défis et gagnez des pièces d\'or 🌲',
      'challenge_daily_title': 'Défis Quotidiens',
      'challenge_weekly_title': 'Défis Hebdomadaires',
      'challenge_milestone_title': 'Paliers Majeurs',
      'claim_action': 'Réclamer ✨',
      'challenge_reward_claimed_snack': 'Félicitations ! {coins} pièces reçues 🎉',
      'in_progress_status': 'En cours ⏳',
      'live_room_header_title': '{count} apprenants étudient actuellement 🟢',
      'live_room_header_sub': 'Vous n\'êtes pas seul ! Partagez l\'énergie collective',
      'send_energy_btn': 'Envoyer Énergie ⚡',
      'energy_sent': 'Encouragé 👏',
      'edit_profile_title': 'Modifier le profil',
      'choose_avatar_label': 'Choisissez votre avatar :',
      'nickname_field': 'Nom d\'affichage / Pseudo',
      'study_field_field': 'Domaine d\'activité (ex. Médecine, Code...)',
      'status_bio_field': 'Statut / Objectif actuel',
      'save_profile_btn': 'Enregistrer',
      'tooltip_challenges': 'Défis et Classement 🏆⚔️',

      'tag_work': 'Travail',
      'tag_study': 'Études',
      'tag_code': 'Programmation',
      'tag_reading': 'Lecture',
      'tag_creative': 'Créativité',
      'tag_general': 'Général',
    },

    // ----------------------------------------------------
    // SPANISH (Español)
    // ----------------------------------------------------
    'es': {
      'app_title': 'Oasis de Enfoque',
      'app_subtitle': 'Pomodoro • Bosque Verde',
      'nav_timer': 'Temporizador',
      'nav_oasis': 'Oasis',
      'nav_tasks': 'Tareas',
      'nav_nursery': 'Vivero',
      'nav_challenges': 'Desafíos',
      'nav_analytics': 'Estadísticas',

      'start_focus': 'Iniciar Enfoque 🌿',
      'pause': 'Pausar ⏸️',
      'resume': 'Continuar ▶️',
      'give_up': 'Rendirse 🏳️',
      'plant_new_tree': 'Plantar nuevo árbol 🌱',
      'wilted_tree_sub': 'Árbol marchito (toca para plantar)',
      'session_focus': 'Sesión de Enfoque',
      'session_short_break': 'Pausa corta',
      'session_long_break': 'Pausa larga',
      'start_short_break_action': 'Tomar pausa corta ☕',
      'start_focus_action': 'Iniciar sesión de enfoque 🌿',
      'active_task_prefix': 'Tarea activa: {task}',
      'breathing_banner': 'Ejercicio de respiración guiada (4-7-8)',
      'breathing_suggestion': 'O tómate un minuto para respirar (4-7-8) ✨',
      'mins_suffix': 'm',

      'give_up_title': '¿Seguro que deseas rendirte?',
      'give_up_desc': '¡Cancelar la sesión marchitará tu árbol {species} en tu oasis! ¿Estás seguro?',
      'continue_focus': 'Continuar enfoque',
      'confirm_give_up': 'Rendirse',

      'session_complete_title': '¡Sesión completada con éxito! 🌿',
      'break_complete_title': '¡Terminó el descanso! ☕',
      'session_complete_desc': '¡Fantástico trabajo! Has plantado un árbol floreciente y ganado {coins} monedas.',
      'break_complete_desc': '¡Es hora de volver al trabajo con energía renovada!',

      'tooltip_ambient': 'Sonidos ambientales y naturaleza',
      'tooltip_cloud': 'Sincronización en la nube',
      'tooltip_achievements': 'Logros y medallas 🏆',
      'tooltip_breathing': 'Respiración consciente 🫁',
      'tooltip_pip': 'Ventana flotante mini (Always on top)',
      'tooltip_donate': 'Apoyar al creador ☕💖',
      'tooltip_settings': 'Ajustes del temporizador',
      'tooltip_language': 'Cambiar idioma',
      'tooltip_more': 'Más herramientas y opciones',
      'daily_target_badge': 'Meta del día',
      'tags_title': 'Seleccionar etiqueta de enfoque 🏷️',

      'settings_title': 'Ajustes de Oasis ⚙️',
      'focus_duration': 'Duración Enfoque (minutos):',
      'short_break_duration': 'Pausa Corta (minutos):',
      'long_break_duration': 'Pausa Larga (minutos):',
      'daily_target_sessions': 'Meta diaria (sesiones):',
      'strict_mode': 'Modo Estricto',
      'strict_mode_desc': 'Salir de la app marchita el árbol de inmediato',
      'language_label': 'Idioma de la aplicación:',
      'backup_section': 'Copia de seguridad y datos 📦',
      'backup_desc': 'Exporta o importa tus árboles, tareas y estadísticas',
      'export_json': 'Exportar JSON',
      'import_json': 'Importar JSON',
      'support_tile_title': 'Apoyar Focus Oasis',
      'support_tile_sub': 'Invítanos a un café para continuar el desarrollo',
      'cancel': 'Cancelar',
      'save_settings': 'Guardar ajustes',
      'backup_exported': '¡Copia guardada en el portapapeles! 📋',
      'backup_imported_ok': '¡Datos restaurados con éxito! 🎉',
      'backup_imported_err': 'Error al importar datos.',

      'tasks_title': 'Tareas Pomodoro 📋',
      'task_input_hint': 'Añadir una tarea para enfocar...',
      'no_tasks': 'Sin tareas aún. ¡Añade tu primera tarea!',
      'delete': 'Eliminar',
      'set_active': 'Fijar como activa',
      'active_task': 'Tarea activa',
      'pomodoros_count': '{done}/{target} pomodoros',
      'add': 'Añadir',

      'nursery_title': 'Vivero de Árboles 🏡',
      'unlocked': 'Desbloqueado',
      'selected': 'Seleccionado',
      'select': 'Seleccionar',
      'buy_tree': 'Desbloquear por {coins} monedas',
      'coins_balance': 'Tu saldo: {coins} monedas',
      'insufficient_coins': '¡Monedas insuficientes!',

      'oasis_title': 'Mi Oasis Verde 🌲',
      'total_trees': 'Total de árboles',
      'living_trees': 'Árboles vivos',
      'wilted_trees': 'Árboles marchitos',
      'share_oasis': 'Compartir mi oasis 📸',
      'no_trees_yet': 'Tu oasis está vacío. ¡Completa una sesión para plantar tu primer árbol!',
      'status_label': 'Estado:',
      'tree_status_alive': 'Floreciente y Sano 🌸',
      'tree_status_wilted': 'Marchito (Abandonado) 🥀',
      'session_duration': 'Duración de la sesión:',
      'plant_date': 'Fecha de plantación:',
      'close': 'Cerrar',

      'analytics_title': 'Estadísticas y productividad 📊',
      'focus_hours': 'Horas de enfoque',
      'focus_days_streak': 'Días seguidos',
      'completion_rate': 'Tasa de éxito',
      'weekly_heatmap': 'Mapa de calor semanal',
      'tag_distribution': 'Distribución por etiqueta',
      'history_sessions': 'Historial reciente',
      'streak_title': 'Racha de enfoque',
      'streak_subtitle_active': 'Estás progresando a paso firme hacia el dominio de tu tiempo.',
      'streak_subtitle_empty': '¡Inicia una sesión hoy para empezar una nueva racha!',
      'streak_days': '¡{count} días consecutivos!',
      'total_minutes_sub': '{count} minutos en total',
      'wilted_count_sub': '{count} marchitos 🥀',
      'of_all_sessions': 'De todas las sesiones',
      'heatmap_title': 'Mapa de actividad del Oasis (Últimas 10 semanas)',
      'no_activity': 'Sin actividad',
      'weekly_focus_title': 'Actividad de enfoque semanal',
      'weekly_focus_sub': 'Minutos completados en los últimos 7 días',
      'last_7_days': 'Últimos 7 días',
      'tag_distribution_title': 'Distribución del tiempo por categoría',
      'minutes_logged': '{count} minutos registrados',
      'recent_sessions_title': 'Registro de sesiones recientes',
      'sessions_logged': '{count} sesiones registradas',
      'no_sessions_yet': 'No hay sesiones registradas aún. ¡Completa tu primera sesión!',
      'wilted_session_prefix': 'Sesión marchita ({species})',
      'hours_suffix': 'h',

      'breathing_title': 'Respiración consciente (4-7-8) 🫁',
      'breathing_desc': 'Técnica calmante para despejar la mente y reducir el estrés.',
      'breathing_inhale': 'Inhala...',
      'breathing_hold': 'Mantén...',
      'breathing_exhale': 'Exhala...',
      'breathing_start': 'Iniciar ejercicio (1 min) ✨',
      'breathing_stop': 'Terminar ⏹️',
      'breathing_cycles': 'Ciclos completados: {count}',

      'achievements_title': 'Logros y medallas 🏆',
      'claim_reward': 'Reclamar {coins} monedas ✨',
      'claimed': 'Reclamado ✓',

      'donation_title': 'Apoyar Focus Oasis ☕💖',
      'donation_subtitle': 'Proyecto gratuito, código abierto y sin anuncios',
      'donation_desc': 'Creado para ofrecerte un entorno de estudio y concentración puro.',
      'copy': 'Copiar',
      'copied': '¡Copiado!',
      'became_supporter': '¡Soy un patrocinador! ✨',
      'supporter_badge': '¡Eres un patrocinador oficial! Gracias de corazón 🌟',

      // Community & Challenges
      'challenges_title': 'Desafíos y Clasificación 🏆⚔️',
      'tab_leaderboard': 'Clasificación',
      'tab_challenges': 'Desafíos',
      'tab_live_room': 'Estudiando Ahora 🟢',
      'filter_today': 'Hoy',
      'filter_week': 'Esta Semana',
      'filter_all_time': 'Todo el Tiempo',
      'community_rankings': 'Tabla de Clasificación',
      'participants': 'participantes',
      'rank_first_motivation': '¡Estás en la cima del Oasis! Mantén tu corona 👑🔥',
      'rank_gap_motivation': '¡Solo {mins} min para superar el puesto #{nextRank} 🚀',
      'you_label': 'Tú',
      'cheer_sent_snack': '¡Enviaste energía positiva a {name}! ⚡👏',
      'challenges_banner_title': 'Desafíos de Enfoque Diarios y Semanales',
      'challenges_banner_sub': 'Completa misiones para ganar monedas de oro 🌲',
      'challenge_daily_title': 'Desafíos Diarios',
      'challenge_weekly_title': 'Desafíos Semanales',
      'challenge_milestone_title': 'Logros Históricos',
      'claim_action': 'Reclamar ✨',
      'challenge_reward_claimed_snack': '¡Felicidades! Reclamaste {coins} monedas 🎉',
      'in_progress_status': 'En progreso ⏳',
      'live_room_header_title': '{count} compañeros están enfocados ahora 🟢',
      'live_room_header_sub': '¡No estás solo! Comparte el ritmo de trabajo',
      'send_energy_btn': 'Enviar Energía ⚡',
      'energy_sent': 'Animado 👏',
      'edit_profile_title': 'Editar Perfil',
      'choose_avatar_label': 'Elige tu avatar:',
      'nickname_field': 'Nombre o Apodo',
      'study_field_field': 'Área de estudio (ej. Medicina, Código...)',
      'status_bio_field': 'Estado o Meta actual',
      'save_profile_btn': 'Guardar Cambios',
      'tooltip_challenges': 'Desafíos y Clasificación 🏆⚔️',

      'tag_work': 'Trabajo',
      'tag_study': 'Estudio',
      'tag_code': 'Código',
      'tag_reading': 'Lectura',
      'tag_creative': 'Creatividad',
      'tag_general': 'General',
    },
  };
}

/// Global helper for convenient string translation: tr('key')
String tr(String key, [Map<String, dynamic>? params]) {
  return LocaleService.instance.t(key, params);
}
