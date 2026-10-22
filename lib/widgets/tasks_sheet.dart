import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/task.dart';
import '../services/storage_service.dart';
import '../services/supabase_service.dart';
import '../services/locale_service.dart';
import '../theme/app_theme.dart';

class TasksSheet extends StatefulWidget {
  final StorageService storage;
  final String? activeTaskId;
  final ValueChanged<String?> onSelectActiveTask;
  final bool isSheet;

  const TasksSheet({
    super.key,
    required this.storage,
    required this.activeTaskId,
    required this.onSelectActiveTask,
    this.isSheet = false,
  });

  @override
  State<TasksSheet> createState() => _TasksSheetState();
}

class _TasksSheetState extends State<TasksSheet> {
  late List<PomodoroTask> _tasks;
  final TextEditingController _taskController = TextEditingController();
  int _estimatedPomodoros = 2;

  @override
  void initState() {
    super.initState();
    _tasks = widget.storage.getTasks();
  }

  @override
  void dispose() {
    _taskController.dispose();
    super.dispose();
  }

  void _saveTasks() {
    widget.storage.saveTasks(_tasks);
    setState(() {});
  }

  void _addTask() {
    final title = _taskController.text.trim();
    if (title.isEmpty) return;

    final newTask = PomodoroTask(
      id: const Uuid().v4(),
      title: title,
      estimatedPomodoros: _estimatedPomodoros,
      completedPomodoros: 0,
      isCompleted: false,
      createdAt: DateTime.now(),
    );

    _tasks.insert(0, newTask);
    _taskController.clear();
    _estimatedPomodoros = 2;
    _saveTasks();
    SupabaseService().pushTask(newTask);
  }

  void _toggleTask(PomodoroTask task) {
    final index = _tasks.indexWhere((t) => t.id == task.id);
    if (index != -1) {
      _tasks[index] = task.copyWith(isCompleted: !task.isCompleted);
      if (_tasks[index].isCompleted && widget.activeTaskId == task.id) {
        widget.onSelectActiveTask(null);
      }
      _saveTasks();
      SupabaseService().pushTask(_tasks[index]);
    }
  }

  void _deleteTask(String id) {
    _tasks.removeWhere((t) => t.id == id);
    if (widget.activeTaskId == id) {
      widget.onSelectActiveTask(null);
    }
    _saveTasks();
  }

  @override
  Widget build(BuildContext context) {
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.isSheet) ...[
          // Header for modal sheet
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Text('📝', style: TextStyle(fontSize: 22)),
                  const SizedBox(width: 8),
                  Text(
                    tr('tasks_title'),
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 12),
        ],

        // Add Task Input Box
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: OasisColors.card,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: OasisColors.cardBorder),
          ),
          child: Column(
            children: [
              TextField(
                controller: _taskController,
                decoration: InputDecoration(
                  hintText: tr('task_input_hint'),
                  hintStyle: const TextStyle(color: OasisColors.textMuted, fontSize: 14),
                  border: InputBorder.none,
                  isDense: true,
                ),
                onSubmitted: (_) => _addTask(),
              ),
              const Divider(color: OasisColors.cardBorder, height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Text(
                        '🍅 ',
                        style: const TextStyle(fontSize: 14),
                      ),
                      ...List.generate(5, (index) {
                        final count = index + 1;
                        final isSelected = _estimatedPomodoros == count;
                        return InkWell(
                          onTap: () => setState(() => _estimatedPomodoros = count),
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 2),
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? OasisColors.primary.withValues(alpha: 0.2)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isSelected
                                    ? OasisColors.primary
                                    : Colors.transparent,
                              ),
                            ),
                            child: Text(
                              '$count',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                color: isSelected ? OasisColors.primary : OasisColors.textMuted,
                              ),
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                  ElevatedButton.icon(
                    onPressed: _addTask,
                    icon: const Icon(Icons.add_rounded, size: 16),
                    label: Text(tr('add')),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Tasks List
        Expanded(
          child: _tasks.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('📝', style: TextStyle(fontSize: 40)),
                      const SizedBox(height: 8),
                      Text(
                        tr('no_tasks'),
                        style: const TextStyle(color: OasisColors.textMuted),
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  itemCount: _tasks.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final task = _tasks[index];
                    final isActive = widget.activeTaskId == task.id;

                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: isActive
                            ? OasisColors.primary.withValues(alpha: 0.12)
                            : OasisColors.card,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isActive
                              ? OasisColors.primary
                              : OasisColors.cardBorder,
                          width: isActive ? 1.5 : 1.0,
                        ),
                      ),
                      child: Row(
                        children: [
                          Checkbox(
                            value: task.isCompleted,
                            activeColor: OasisColors.primary,
                            onChanged: (_) => _toggleTask(task),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  task.title,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: task.isCompleted
                                        ? OasisColors.textMuted
                                        : OasisColors.textPrimary,
                                    decoration: task.isCompleted
                                        ? TextDecoration.lineThrough
                                        : null,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Row(
                                  children: [
                                    Text(
                                      tr('pomodoros_count', {
                                        'done': task.completedPomodoros,
                                        'target': task.estimatedPomodoros,
                                      }),
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: OasisColors.textSecondary,
                                      ),
                                    ),
                                    if (isActive) ...[
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 6, vertical: 1),
                                        decoration: BoxDecoration(
                                          color: OasisColors.primary,
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          tr('active_task'),
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                          ),
                          if (!task.isCompleted)
                            IconButton(
                              icon: Icon(
                                isActive
                                    ? Icons.radio_button_checked_rounded
                                    : Icons.radio_button_unchecked_rounded,
                                color: isActive
                                    ? OasisColors.primary
                                    : OasisColors.textMuted,
                              ),
                              tooltip: isActive ? tr('active_task') : tr('set_active'),
                              onPressed: () {
                                widget.onSelectActiveTask(
                                    isActive ? null : task.id);
                                setState(() {});
                              },
                            ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline_rounded,
                                color: OasisColors.textMuted, size: 18),
                            tooltip: tr('delete'),
                            onPressed: () => _deleteTask(task.id),
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
        height: MediaQuery.of(context).size.height * 0.78,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        decoration: const BoxDecoration(
          color: OasisColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: content,
      );
    }

    return Scaffold(
      backgroundColor: OasisColors.background,
      appBar: AppBar(
        backgroundColor: OasisColors.surface,
        elevation: 0,
        title: const Row(
          children: [
            Text('📝', style: TextStyle(fontSize: 22)),
            SizedBox(width: 8),
            Text(
              'إدارة المهام والتركيز',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: content,
      ),
    );
  }
}
