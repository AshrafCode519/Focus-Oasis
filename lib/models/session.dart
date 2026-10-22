enum SessionType {
  focus,
  shortBreak,
  longBreak;

  String get labelAr {
    switch (this) {
      case SessionType.focus:
        return 'جلسة تركيز';
      case SessionType.shortBreak:
        return 'استراحة قصيرة';
      case SessionType.longBreak:
        return 'استراحة طويلة';
    }
  }

  String get labelEn {
    switch (this) {
      case SessionType.focus:
        return 'Focus';
      case SessionType.shortBreak:
        return 'Short Break';
      case SessionType.longBreak:
        return 'Long Break';
    }
  }

  String label(String langCode) => langCode == 'ar' ? labelAr : labelEn;

  int get defaultMinutes {
    switch (this) {
      case SessionType.focus:
        return 25;
      case SessionType.shortBreak:
        return 5;
      case SessionType.longBreak:
        return 15;
    }
  }
}

enum SessionStatus {
  running,
  completed,
  failed,
  idle;

  String get labelAr {
    switch (this) {
      case SessionStatus.running:
        return 'جارية';
      case SessionStatus.completed:
        return 'مكتملة';
      case SessionStatus.failed:
        return 'ذابلة (ملغاة)';
      case SessionStatus.idle:
        return 'خاملة';
    }
  }

  String get labelEn {
    switch (this) {
      case SessionStatus.running:
        return 'Running';
      case SessionStatus.completed:
        return 'Completed';
      case SessionStatus.failed:
        return 'Wilted';
      case SessionStatus.idle:
        return 'Idle';
    }
  }

  String label(String langCode) => langCode == 'ar' ? labelAr : labelEn;
}

class FocusSession {
  final String id;
  final int durationMinutes;
  final SessionType sessionType;
  final SessionStatus status;
  final String treeTypeId;
  final DateTime startedAt;
  final DateTime? endedAt;
  final int coinsEarned;
  final String? taskId;
  final String? tagId;

  const FocusSession({
    required this.id,
    required this.durationMinutes,
    required this.sessionType,
    required this.status,
    required this.treeTypeId,
    required this.startedAt,
    this.endedAt,
    this.coinsEarned = 0,
    this.taskId,
    this.tagId,
  });

  FocusSession copyWith({
    String? id,
    int? durationMinutes,
    SessionType? sessionType,
    SessionStatus? status,
    String? treeTypeId,
    DateTime? startedAt,
    DateTime? endedAt,
    int? coinsEarned,
    String? taskId,
    String? tagId,
  }) {
    return FocusSession(
      id: id ?? this.id,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      sessionType: sessionType ?? this.sessionType,
      status: status ?? this.status,
      treeTypeId: treeTypeId ?? this.treeTypeId,
      startedAt: startedAt ?? this.startedAt,
      endedAt: endedAt ?? this.endedAt,
      coinsEarned: coinsEarned ?? this.coinsEarned,
      taskId: taskId ?? this.taskId,
      tagId: tagId ?? this.tagId,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'durationMinutes': durationMinutes,
        'sessionType': sessionType.name,
        'status': status.name,
        'treeTypeId': treeTypeId,
        'startedAt': startedAt.toIso8601String(),
        'endedAt': endedAt?.toIso8601String(),
        'coinsEarned': coinsEarned,
        'taskId': taskId,
        'tagId': tagId,
      };

  factory FocusSession.fromJson(Map<String, dynamic> json) => FocusSession(
        id: json['id'] as String,
        durationMinutes: json['durationMinutes'] as int? ?? 25,
        sessionType: SessionType.values.firstWhere(
          (e) => e.name == json['sessionType'],
          orElse: () => SessionType.focus,
        ),
        status: SessionStatus.values.firstWhere(
          (e) => e.name == json['status'],
          orElse: () => SessionStatus.completed,
        ),
        treeTypeId: json['treeTypeId'] as String? ?? 'classic_pine',
        startedAt: DateTime.tryParse(json['startedAt']?.toString() ?? '') ?? DateTime.now(),
        endedAt: json['endedAt'] != null
            ? DateTime.tryParse(json['endedAt'].toString())
            : null,
        coinsEarned: json['coinsEarned'] as int? ?? 0,
        taskId: json['taskId'] as String?,
        tagId: json['tagId'] as String?,
      );
}
