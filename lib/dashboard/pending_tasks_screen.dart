import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../app/theme.dart';
import '../services/task_service.dart';
import 'task_tile.dart';
import 'task_model.dart';

class PendingTasksScreen extends StatefulWidget {
  const PendingTasksScreen({super.key});

  @override
  State<PendingTasksScreen> createState() => _PendingTasksScreenState();
}

class _PendingTasksScreenState extends State<PendingTasksScreen> {
  final TaskService taskService = Get.find<TaskService>();

  @override
  void initState() {
    super.initState();
    // Make sure we're loading all tasks, not just today's
    taskService.showOnlyToday.value = false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pending Tasks'),
        backgroundColor: AppTheme.backgroundColor,
        elevation: 0,
      ),
      body: Obx(() {
        if (taskService.isLoading.value) {
          return const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.accentYellow),
            ),
          );
        }

        final pendingTasks = taskService.pendingTasks;

        if (pendingTasks.isEmpty) {
          return _buildEmptyState(
            'No pending tasks',
            'All tasks are completed. Great job!',
          );
        }

        // Group tasks by due date
        final Map<String, List<Task>> tasksByDueDate = {};

        // Add tasks without due date to a special group
        final tasksWithoutDueDate =
            pendingTasks.where((task) => task.dueDate == null).toList();
        if (tasksWithoutDueDate.isNotEmpty) {
          tasksByDueDate['No due date'] = tasksWithoutDueDate;
        }

        // Group tasks with due date
        final tasksWithDueDate =
            pendingTasks.where((task) => task.dueDate != null).toList();

        // Sort tasks by due date (ascending)
        tasksWithDueDate.sort((a, b) {
          return a.dueDate!.compareTo(b.dueDate!);
        });

        // Group tasks by date
        for (final task in tasksWithDueDate) {
          final dateStr = _formatDueDate(task.dueDate!);
          if (tasksByDueDate[dateStr] == null) {
            tasksByDueDate[dateStr] = [];
          }
          tasksByDueDate[dateStr]!.add(task);
        }

        // Get sorted due date keys
        final sortedKeys = tasksByDueDate.keys.toList()
          ..sort((a, b) {
            if (a == 'No due date') return 1;
            if (b == 'No due date') return -1;
            return 0;
          });

        return ListView.builder(
          itemCount: sortedKeys.length,
          itemBuilder: (context, index) {
            final dateKey = sortedKeys[index];
            final tasksForDate = tasksByDueDate[dateKey]!;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDateHeader(dateKey),
                ...tasksForDate
                    .map((task) => Padding(
                          padding: const EdgeInsets.only(
                              bottom: 12, left: 16, right: 16),
                          child: TaskTile(
                            task: task,
                            onDelete: () async {
                              try {
                                await taskService.deleteTask(task.id);
                                Get.snackbar(
                                  'Success',
                                  'Task deleted successfully',
                                  backgroundColor:
                                      Colors.green.withOpacity(0.8),
                                  colorText: Colors.white,
                                  duration: const Duration(seconds: 2),
                                );
                              } catch (e) {
                                Get.snackbar(
                                  'Error',
                                  e.toString(),
                                  backgroundColor: Colors.red.withOpacity(0.8),
                                  colorText: Colors.white,
                                );
                              }
                            },
                            onToggle: () async {
                              try {
                                await taskService.toggleTaskCompletion(task);
                              } catch (e) {
                                Get.snackbar(
                                  'Error',
                                  e.toString(),
                                  backgroundColor: Colors.red.withOpacity(0.8),
                                  colorText: Colors.white,
                                );
                              }
                            },
                            onEdit: () => _showEditTaskDialog(task),
                          ),
                        ))
                    .toList(),
              ],
            );
          },
        );
      }),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddTaskDialog(),
        backgroundColor: AppTheme.accentYellow,
        child: const Icon(Icons.add, color: Colors.black),
      ),
    );
  }

  Widget _buildDateHeader(String dateKey) {
    final isOverdue = dateKey != 'No due date' && _isDateOverdue(dateKey);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: AppTheme.backgroundColor.withOpacity(0.7),
      child: Row(
        children: [
          Icon(
            isOverdue ? Icons.warning : Icons.event,
            color: isOverdue ? Colors.red : AppTheme.accentYellow,
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            dateKey,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isOverdue ? Colors.red : Colors.white,
            ),
          ),
          if (isOverdue) ...[
            const SizedBox(width: 8),
            Text(
              'OVERDUE',
              style: TextStyle(
                fontSize: 12,
                color: Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
          ]
        ],
      ),
    );
  }

  bool _isDateOverdue(String dateStr) {
    try {
      final format = DateFormat('MMM d, y');
      final date = format.parse(dateStr);
      final today = DateTime.now();
      final todayFormatted = DateTime(today.year, today.month, today.day);
      final dateFormatted = DateTime(date.year, date.month, date.day);

      return dateFormatted.isBefore(todayFormatted);
    } catch (e) {
      return false;
    }
  }

  String _formatDueDate(DateTime date) {
    return DateFormat('MMM d, y').format(date);
  }

  Widget _buildEmptyState(String title, String subtitle) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.task_alt,
            size: 80,
            color: Colors.green.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: AppTheme.subheading.copyWith(
              color: Colors.white.withOpacity(0.8),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(
              color: AppTheme.secondaryText,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Future<void> _showAddTaskDialog() async {
    final taskController = TextEditingController();
    final descriptionController = TextEditingController();
    final focusNode = FocusNode();
    DateTime? selectedDueDate;

    try {
      await Get.dialog(
        AlertDialog(
          title: const Text('Add New Task'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: taskController,
                  focusNode: focusNode,
                  autofocus: true,
                  decoration: const InputDecoration(
                    labelText: 'Task Title',
                    hintText: 'Enter task title',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description (Optional)',
                    hintText: 'Enter task description',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                StatefulBuilder(
                  builder: (context, setStateLocal) {
                    return Row(
                      children: [
                        Icon(Icons.event, color: AppTheme.primaryColor),
                        const SizedBox(width: 8),
                        Text(
                          'Due Date: ${selectedDueDate != null ? DateFormat('MMM d, y').format(selectedDueDate!) : 'None'}',
                        ),
                        const Spacer(),
                        TextButton(
                          onPressed: () async {
                            final pickedDate = await showDatePicker(
                              context: context,
                              initialDate: DateTime.now(),
                              firstDate: DateTime.now()
                                  .subtract(const Duration(days: 365)),
                              lastDate:
                                  DateTime.now().add(const Duration(days: 365)),
                            );

                            if (pickedDate != null) {
                              setStateLocal(() {
                                selectedDueDate = pickedDate;
                              });
                            }
                          },
                          child: const Text('Select'),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Get.back(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (taskController.text.trim().isNotEmpty) {
                  taskService.addTask(
                    taskController.text.trim(),
                    description: descriptionController.text.trim(),
                    dueDate: selectedDueDate,
                  );
                  Get.back();
                  Get.snackbar(
                    'Success',
                    'Task added successfully',
                    backgroundColor: Colors.green.withOpacity(0.8),
                    colorText: Colors.white,
                  );
                } else {
                  Get.snackbar(
                    'Error',
                    'Task title cannot be empty',
                    backgroundColor: Colors.red.withOpacity(0.8),
                    colorText: Colors.white,
                  );
                }
              },
              child: const Text('Add Task'),
            ),
          ],
        ),
      );
    } finally {
      focusNode.dispose();
      taskController.dispose();
      descriptionController.dispose();
    }
  }

  Future<void> _showEditTaskDialog(Task task) async {
    final taskController = TextEditingController(text: task.title);
    final descriptionController =
        TextEditingController(text: task.description ?? '');
    final focusNode = FocusNode();
    DateTime? selectedDueDate = task.dueDate;
    bool clearDueDate = false;

    try {
      await Get.dialog(
        AlertDialog(
          title: const Text('Edit Task'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: taskController,
                  focusNode: focusNode,
                  autofocus: true,
                  decoration: const InputDecoration(
                    labelText: 'Task Title',
                    hintText: 'Enter task title',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description (Optional)',
                    hintText: 'Enter task description',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                StatefulBuilder(
                  builder: (context, setStateLocal) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.event, color: AppTheme.primaryColor),
                            const SizedBox(width: 8),
                            Text(
                              clearDueDate
                                  ? 'Due Date: None'
                                  : 'Due Date: ${selectedDueDate != null ? DateFormat('MMM d, y').format(selectedDueDate!) : 'None'}',
                            ),
                            const Spacer(),
                            TextButton(
                              onPressed: () async {
                                if (clearDueDate) {
                                  setStateLocal(() {
                                    clearDueDate = false;
                                    selectedDueDate = task.dueDate;
                                  });
                                  return;
                                }

                                final pickedDate = await showDatePicker(
                                  context: context,
                                  initialDate:
                                      selectedDueDate ?? DateTime.now(),
                                  firstDate: DateTime.now()
                                      .subtract(const Duration(days: 365)),
                                  lastDate: DateTime.now()
                                      .add(const Duration(days: 365)),
                                );

                                if (pickedDate != null) {
                                  setStateLocal(() {
                                    selectedDueDate = pickedDate;
                                    clearDueDate = false;
                                  });
                                }
                              },
                              child: const Text('Change'),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            Checkbox(
                              value: clearDueDate,
                              onChanged: (value) {
                                setStateLocal(() {
                                  clearDueDate = value ?? false;
                                });
                              },
                            ),
                            const Text('Clear due date'),
                          ],
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Get.back(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (taskController.text.trim().isNotEmpty) {
                  taskService.updateTask(
                    task,
                    title: taskController.text.trim(),
                    description: descriptionController.text.trim(),
                    dueDate: clearDueDate ? null : selectedDueDate,
                    clearDueDate: clearDueDate,
                  );
                  Get.back();
                  Get.snackbar(
                    'Success',
                    'Task updated successfully',
                    backgroundColor: Colors.green.withOpacity(0.8),
                    colorText: Colors.white,
                  );
                } else {
                  Get.snackbar(
                    'Error',
                    'Task title cannot be empty',
                    backgroundColor: Colors.red.withOpacity(0.8),
                    colorText: Colors.white,
                  );
                }
              },
              child: const Text('Update Task'),
            ),
          ],
        ),
      );
    } finally {
      focusNode.dispose();
      taskController.dispose();
      descriptionController.dispose();
    }
  }
}
