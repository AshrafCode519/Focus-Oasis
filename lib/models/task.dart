class PomodoroTask {
  final String id;
  final String title;
  final int estimatedPomodoros;
  final int completedPomodoros;
  final bool isCompleted;
  final DateTime createdAt;

  const PomodoroTask({
    required this.id,
    required this.title,
    this.estimatedPomodoros = 1,
    this.completedPomodoros = 0,
    this.isCompleted = false,
    required this.createdAt,
  });

  PomodoroTask copyWith({
    String? id,
    String? title,
    int? estimatedPomodoros,
    int? completedPomodoros,
    bool? isCompleted,
    DateTime? createdAt,
  }) {
    return PomodoroTask(
      id: id ?? this.id,
      title: title ?? this.title,
      estimatedPomodoros: estimatedPomodoros ?? this.estimatedPomodoros,
      completedPomodoros: completedPomodoros ?? this.completedPomodoros,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'estimatedPomodoros': estimatedPomodoros,
        'completedPomodoros': completedPomodoros,
        'isCompleted': isCompleted,
        'createdAt': createdAt.toIso8601String(),
      };

  factory PomodoroTask.fromJson(Map<String, dynamic> json) => PomodoroTask(
        id: json['id'] as String,
        title: json['title'] as String,
        estimatedPomodoros: json['estimatedPomodoros'] as int? ?? 1,
        completedPomodoros: json['completedPomodoros'] as int? ?? 0,
        isCompleted: json['isCompleted'] as bool? ?? false,
        createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ?? DateTime.now(),
      );
}
