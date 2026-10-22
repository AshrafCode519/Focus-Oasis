import 'package:flutter/material.dart';

enum TreeStage {
  seed,
  sprout,
  growing,
  blooming,
  wilted;

  String get labelAr {
    switch (this) {
      case TreeStage.seed:
        return 'بذرة في التربة (0%)';
      case TreeStage.sprout:
        return 'برعم أخضر يافع (35%)';
      case TreeStage.growing:
        return 'نمو الفروع والأوراق (70%)';
      case TreeStage.blooming:
        return 'شجرة كاملة ومزهرة (100%)';
      case TreeStage.wilted:
        return 'شجرة ذابلة (انقطاع)';
    }
  }

  String label(String langCode) {
    if (langCode == 'ar') return labelAr;
    switch (this) {
      case TreeStage.seed:
        return 'Seed in Soil (0%)';
      case TreeStage.sprout:
        return 'Young Green Sprout (35%)';
      case TreeStage.growing:
        return 'Growing Branches & Leaves (70%)';
      case TreeStage.blooming:
        return 'Fully Bloomed Tree (100%)';
      case TreeStage.wilted:
        return 'Wilted Tree (Abandoned)';
    }
  }

  static TreeStage fromProgress(double progress, {bool isFailed = false}) {
    if (isFailed) return TreeStage.wilted;
    if (progress < 0.30) return TreeStage.seed;
    if (progress < 0.65) return TreeStage.sprout;
    if (progress < 0.999) return TreeStage.growing;
    return TreeStage.blooming;
  }
}

class TreeSpecies {
  final String id;
  final String nameEn;
  final String nameAr;
  final String descriptionAr;
  final int priceCoins;
  final bool unlockedByDefault;
  final Color primaryColor;
  final Color accentColor;
  final String iconEmoji;

  const TreeSpecies({
    required this.id,
    required this.nameEn,
    required this.nameAr,
    required this.descriptionAr,
    required this.priceCoins,
    required this.unlockedByDefault,
    required this.primaryColor,
    required this.accentColor,
    required this.iconEmoji,
  });

  String name(String langCode) => langCode == 'ar' ? nameAr : nameEn;

  static const List<TreeSpecies> catalog = [
    TreeSpecies(
      id: 'classic_pine',
      nameEn: 'Oasis Pine',
      nameAr: 'صنوبر الواحة',
      descriptionAr: 'شجرة صنوبر قوية ودائمة الخضرة ترمز للصمود والتركيز الهادئ.',
      priceCoins: 0,
      unlockedByDefault: true,
      primaryColor: Color(0xFF2E7D32),
      accentColor: Color(0xFF81C784),
      iconEmoji: '🌲',
    ),
    TreeSpecies(
      id: 'sakura_bloom',
      nameEn: 'Zen Sakura',
      nameAr: 'ساكورا الربيع',
      descriptionAr: 'شجرة يابانية ساحرة ذات أزهار وردية ناعمة تهدئ الذهن وتصفي الأفكار.',
      priceCoins: 60,
      unlockedByDefault: true,
      primaryColor: Color(0xFFE91E63),
      accentColor: Color(0xFFF48FB1),
      iconEmoji: '🌸',
    ),
    TreeSpecies(
      id: 'flowering_cactus',
      nameEn: 'Desert Blossom',
      nameAr: 'صبار الواحة المزهر',
      descriptionAr: 'صبار صحراوي صامد يتحدى العطش والملل، ويتوج قمته بزهرة بنفسجية نادرة.',
      priceCoins: 90,
      unlockedByDefault: false,
      primaryColor: Color(0xFF2E7D32),
      accentColor: Color(0xFFE91E63),
      iconEmoji: '🌵',
    ),
    TreeSpecies(
      id: 'golden_oak',
      nameEn: 'Golden Oak',
      nameAr: 'سنديان ذهبي',
      descriptionAr: 'شجرة فخمة ذات أوراق ذهبية مشعة تتلألأ عند إتمام جلسات التركيز الطويلة.',
      priceCoins: 120,
      unlockedByDefault: false,
      primaryColor: Color(0xFFF57F17),
      accentColor: Color(0xFFFFD54F),
      iconEmoji: '🌳',
    ),
    TreeSpecies(
      id: 'weeping_willow',
      nameEn: 'Weeping Willow',
      nameAr: 'الصفصاف الباكي',
      descriptionAr: 'أغصان متدلية رقيقة تتراقص مع النسيم، تدعو للسكينة والاستغراق في العمل.',
      priceCoins: 150,
      unlockedByDefault: false,
      primaryColor: Color(0xFF00695C),
      accentColor: Color(0xFF80CBC4),
      iconEmoji: '🌿',
    ),
    TreeSpecies(
      id: 'desert_palm',
      nameEn: 'Desert Palm',
      nameAr: 'نخلة الصحراء',
      descriptionAr: 'نخلة أصيلة باسقة تضفي روح الواحة العربية وعطائها المثمر الوافر.',
      priceCoins: 180,
      unlockedByDefault: false,
      primaryColor: Color(0xFF33691E),
      accentColor: Color(0xFFAED581),
      iconEmoji: '🌴',
    ),
    TreeSpecies(
      id: 'red_maple',
      nameEn: 'Scarlet Maple',
      nameAr: 'القيقب القرمزي',
      descriptionAr: 'أوراق خريفية متوهجة بلون الجمر تمنح طاقة الحماس والإنتاجية العالية.',
      priceCoins: 220,
      unlockedByDefault: false,
      primaryColor: Color(0xFFC62828),
      accentColor: Color(0xFFFF7043),
      iconEmoji: '🍁',
    ),
    TreeSpecies(
      id: 'zen_bonsai',
      nameEn: 'Zen Bonsai',
      nameAr: 'بونساي الحكمة',
      descriptionAr: 'تحفة يابانية متناهية الجمال تعكس الصبر والدقة وإتقان العمل بعناية فائقة.',
      priceCoins: 260,
      unlockedByDefault: false,
      primaryColor: Color(0xFF1B5E20),
      accentColor: Color(0xFF66BB6A),
      iconEmoji: '🪴',
    ),
    TreeSpecies(
      id: 'lavender_jacaranda',
      nameEn: 'Royal Jacaranda',
      nameAr: 'جاكاراندا البنفسج',
      descriptionAr: 'سحابة أرجوانية خيالية من الأزهار العطرة التي تحول واحتك إلى لوحة فنية.',
      priceCoins: 310,
      unlockedByDefault: false,
      primaryColor: Color(0xFF6A1B9A),
      accentColor: Color(0xFFCE93D8),
      iconEmoji: '🪻',
    ),
    TreeSpecies(
      id: 'ancient_baobab',
      nameEn: 'Ancient Baobab',
      nameAr: 'الباوباب العتيقة',
      descriptionAr: 'شجرة الخلود الإفريقية العظيمة بجذعها الأسطوري الضخم الذي يحمل أسرار الزمن.',
      priceCoins: 370,
      unlockedByDefault: false,
      primaryColor: Color(0xFF4E342E),
      accentColor: Color(0xFF9CCC65),
      iconEmoji: '🪵',
    ),
    TreeSpecies(
      id: 'moonlight_wisteria',
      nameEn: 'Moonlight Wisteria',
      nameAr: 'ويستيريا ضوء القمر',
      descriptionAr: 'عناقيد زهرية مشعة كالشلال تضيء عتمة الليل بنور تركيزك الداخلي.',
      priceCoins: 430,
      unlockedByDefault: false,
      primaryColor: Color(0xFF283593),
      accentColor: Color(0xFF80DEEA),
      iconEmoji: '🌙',
    ),
    TreeSpecies(
      id: 'cosmic_crystal_tree',
      nameEn: 'Cosmic Crystal Tree',
      nameAr: 'شجرة البلور الكونية',
      descriptionAr: 'شجرة أسطورية نادرة من الكريستال المشع تمنح هالة لا متناهية من الصفاء والتركيز.',
      priceCoins: 500,
      unlockedByDefault: false,
      primaryColor: Color(0xFF0D47A1),
      accentColor: Color(0xFFE0F7FA),
      iconEmoji: '✨',
    ),
  ];

  static TreeSpecies getById(String id) {
    return catalog.firstWhere(
      (s) => s.id == id,
      orElse: () => catalog.first,
    );
  }
}

class PlantedTree {
  final String id;
  final String sessionId;
  final String treeTypeId;
  final bool isAlive;
  final DateTime plantedAt;
  final int durationMinutes;
  final int gridIndex;

  const PlantedTree({
    required this.id,
    required this.sessionId,
    required this.treeTypeId,
    required this.isAlive,
    required this.plantedAt,
    required this.durationMinutes,
    required this.gridIndex,
  });

  TreeSpecies get species => TreeSpecies.getById(treeTypeId);

  Map<String, dynamic> toJson() => {
        'id': id,
        'sessionId': sessionId,
        'treeTypeId': treeTypeId,
        'isAlive': isAlive,
        'plantedAt': plantedAt.toIso8601String(),
        'durationMinutes': durationMinutes,
        'gridIndex': gridIndex,
      };

  factory PlantedTree.fromJson(Map<String, dynamic> json) => PlantedTree(
        id: json['id'] as String,
        sessionId: json['sessionId'] as String,
        treeTypeId: json['treeTypeId'] as String? ?? 'classic_pine',
        isAlive: json['isAlive'] as bool? ?? true,
        plantedAt: DateTime.tryParse(json['plantedAt']?.toString() ?? '') ?? DateTime.now(),
        durationMinutes: json['durationMinutes'] as int? ?? 25,
        gridIndex: json['gridIndex'] as int? ?? 0,
      );
}
