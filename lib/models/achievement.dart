class Achievement {
  final String id;
  final String titleAr;
  final String titleEn;
  final String descriptionAr;
  final String descriptionEn;
  final String iconEmoji;
  final int rewardCoins;
  final int maxRequirement;

  const Achievement({
    required this.id,
    required this.titleAr,
    required this.titleEn,
    required this.descriptionAr,
    required this.descriptionEn,
    required this.iconEmoji,
    required this.rewardCoins,
    required this.maxRequirement,
  });

  String title(String langCode) => langCode == 'ar' ? titleAr : titleEn;
  String description(String langCode) => langCode == 'ar' ? descriptionAr : descriptionEn;

  static const List<Achievement> catalog = [
    Achievement(
      id: 'first_tree',
      titleAr: 'البذرة الأولى 🌰',
      titleEn: 'First Seedling 🌰',
      descriptionAr: 'أكمل أول جلسة تركيز ناجحة واغرس أول شجرة في واحتك',
      descriptionEn: 'Complete your first successful focus session and plant your first tree',
      iconEmoji: '🌱',
      rewardCoins: 30,
      maxRequirement: 1,
    ),
    Achievement(
      id: 'five_trees',
      titleAr: 'بستان البداية 🌲',
      titleEn: 'Starter Grove 🌲',
      descriptionAr: 'ازرع 5 أشجار حية في واحتك الافتراضية',
      descriptionEn: 'Plant 5 flourishing trees in your virtual forest oasis',
      iconEmoji: '🌳',
      rewardCoins: 60,
      maxRequirement: 5,
    ),
    Achievement(
      id: 'focus_century',
      titleAr: 'مئوية التركيز ⏱️',
      titleEn: 'Century of Focus ⏱️',
      descriptionAr: 'أنجز 100 دقيقة من التركيز العميق والمتواصل',
      descriptionEn: 'Achieve 100 minutes of continuous, deep focused work',
      iconEmoji: '⏳',
      rewardCoins: 100,
      maxRequirement: 100,
    ),
    Achievement(
      id: 'daily_goal',
      titleAr: 'قناص الهدف 🎯',
      titleEn: 'Goal Hunter 🎯',
      descriptionAr: 'حقق هدف الجلسات اليومي المحدد بالكامل اليوم',
      descriptionEn: 'Fully reach your daily target sessions count today',
      iconEmoji: '🎯',
      rewardCoins: 50,
      maxRequirement: 1,
    ),
    Achievement(
      id: 'tree_collector',
      titleAr: 'عاشق الطبيعة 🌸',
      titleEn: 'Nature Collector 🌸',
      descriptionAr: 'قم بفتح وشراء 3 أنواع مختلفة من الأشجار من المشتل',
      descriptionEn: 'Unlock and own 3 distinct tree species from the nursery',
      iconEmoji: '🌺',
      rewardCoins: 120,
      maxRequirement: 3,
    ),
    Achievement(
      id: 'task_crusher',
      titleAr: 'سيد الإنجاز 📋',
      titleEn: 'Task Crusher 📋',
      descriptionAr: 'أكمل 3 مهام من قائمة مهام بومودورو بنجاح',
      descriptionEn: 'Successfully complete 3 tasks from your pomodoro task list',
      iconEmoji: '🏆',
      rewardCoins: 75,
      maxRequirement: 3,
    ),
    Achievement(
      id: 'steel_focus',
      titleAr: 'التركيز الفولاذي 🛡️',
      titleEn: 'Steel Will 🛡️',
      descriptionAr: 'أكمل جلسة تركيز بنجاح مع تفعيل وضع الصرامة (Strict Mode)',
      descriptionEn: 'Complete a focus session with Strict Mode fully enabled',
      iconEmoji: '⚔️',
      rewardCoins: 80,
      maxRequirement: 1,
    ),
  ];
}

class UserAchievementProgress {
  final Achievement achievement;
  final int currentProgress;
  final bool isUnlocked;
  final bool isClaimed;

  const UserAchievementProgress({
    required this.achievement,
    required this.currentProgress,
    required this.isUnlocked,
    required this.isClaimed,
  });

  double get percent =>
      (currentProgress / achievement.maxRequirement).clamp(0.0, 1.0);
}
