import 'package:flutter/material.dart';

class FocusTag {
  final String id;
  final String nameAr;
  final String nameEn;
  final String icon;
  final Color color;

  const FocusTag({
    required this.id,
    required this.nameAr,
    required this.nameEn,
    required this.icon,
    required this.color,
  });

  String name(String langCode) => langCode == 'ar' ? nameAr : nameEn;

  static const List<FocusTag> presets = [
    FocusTag(
      id: 'work',
      nameAr: 'عمل',
      nameEn: 'Work',
      icon: '💼',
      color: Color(0xFF38BDF8),
    ),
    FocusTag(
      id: 'study',
      nameAr: 'دراسة',
      nameEn: 'Study',
      icon: '📚',
      color: Color(0xFFFBBF24),
    ),
    FocusTag(
      id: 'code',
      nameAr: 'برمجة',
      nameEn: 'Coding',
      icon: '⚡',
      color: Color(0xFF10B981),
    ),
    FocusTag(
      id: 'reading',
      nameAr: 'قراءة',
      nameEn: 'Reading',
      icon: '📖',
      color: Color(0xFFA855F7),
    ),
    FocusTag(
      id: 'creative',
      nameAr: 'إبداع',
      nameEn: 'Creative',
      icon: '🎨',
      color: Color(0xFFEC4899),
    ),
    FocusTag(
      id: 'general',
      nameAr: 'عام',
      nameEn: 'General',
      icon: '🎯',
      color: Color(0xFF6EE7B7),
    ),
  ];

  static FocusTag getById(String id) {
    return presets.firstWhere(
      (t) => t.id == id,
      orElse: () => presets.last,
    );
  }
}
