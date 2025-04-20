import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../app/theme.dart';
import '../services/supabase_service.dart';
import 'task_model.dart';
import 'task_tile.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _supabaseService = SupabaseService();
  final _tasks = <Task>[].obs;
  final _isLoading = true.obs;

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    try {
      _isLoading.value = true;
      final tasks = await _supabaseService.getTasks();
      _tasks.assignAll(tasks);
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to load tasks',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      _isLoading.value = false;
    }
  }

  Future<void> _addTask() async {
    final controller = TextEditingController();
    final taskTitle = await Get.dialog<String>(
      AlertDialog(
        title: Text(
          'Add Task',
          style: AppTheme.heading.copyWith(fontSize: 20),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Enter task title',
          ),
          onSubmitted: (value) => Get.back(result: value),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text(
              'Cancel',
              style: AppTheme.linkText,
            ),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                Get.back(result: controller.text);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );

    if (taskTitle?.isNotEmpty ?? false) {
      try {
        final task = await _supabaseService.createTask(taskTitle!);
        _tasks.insert(0, task);
      } catch (e) {
        Get.snackbar(
          'Error',
          'Failed to create task',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    }
    controller.dispose();
  }

  Future<void> _deleteTask(Task task) async {
    try {
      await _supabaseService.deleteTask(task.id);
      _tasks.remove(task);
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to delete task',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  Future<void> _toggleTask(Task task) async {
    try {
      final updatedTask = await _supabaseService.toggleTaskCompletion(task);
      final index = _tasks.indexWhere((t) => t.id == task.id);
      if (index != -1) {
        _tasks[index] = updatedTask;
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to update task',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'DayTask',
          style: AppTheme.brandText,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await _supabaseService.signOut();
              Get.offAllNamed('/login');
            },
          ),
        ],
      ),
      body: Obx(
        () => _isLoading.value
            ? const Center(child: CircularProgressIndicator())
            : _tasks.isEmpty
                ? Center(
                    child: Text(
                      'No tasks yet\nTap + to add a new task',
                      style: AppTheme.bodyText,
                      textAlign: TextAlign.center,
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _tasks.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final task = _tasks[index];
                      return TaskTile(
                        key: ValueKey(task.id),
                        task: task,
                        onDelete: () => _deleteTask(task),
                        onToggle: (value) => _toggleTask(task),
                      );
                    },
                  ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addTask,
        backgroundColor: AppTheme.accentYellow,
        child: const Icon(
          Icons.add,
          color: Colors.black,
        ),
      ),
    );
  }
}
