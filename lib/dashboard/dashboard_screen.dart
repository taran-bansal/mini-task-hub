import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../auth/auth_service.dart';
import '../services/task_service.dart';
import 'task_tile.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final taskService = Get.put(TaskService());
    final authService = Get.find<AuthService>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Tasks'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              try {
                await authService.signOut();
                Get.offAllNamed('/login');
              } catch (e) {
                Get.snackbar(
                  'Error',
                  e.toString(),
                  snackPosition: SnackPosition.BOTTOM,
                );
              }
            },
          ),
        ],
      ),
      body: Obx(
        () => taskService.tasks.isEmpty
            ? Center(
                child: Text(
                  'No tasks yet',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              )
            : ListView.builder(
                itemCount: taskService.tasks.length,
                padding: const EdgeInsets.all(16),
                itemBuilder: (context, index) {
                  final task = taskService.tasks[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: TaskTile(
                      task: task,
                      onDelete: () async {
                        try {
                          await taskService.deleteTask(task.id);
                        } catch (e) {
                          Get.snackbar(
                            'Error',
                            e.toString(),
                            snackPosition: SnackPosition.BOTTOM,
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
                            snackPosition: SnackPosition.BOTTOM,
                          );
                        }
                      },
                    ),
                  );
                },
              ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Get.dialog(
            AlertDialog(
              title: const Text('Add Task'),
              content: TextField(
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Enter task title',
                ),
                onSubmitted: (value) async {
                  if (value.isNotEmpty) {
                    try {
                      await taskService.addTask(value);
                      Get.back();
                    } catch (e) {
                      Get.snackbar(
                        'Error',
                        e.toString(),
                        snackPosition: SnackPosition.BOTTOM,
                      );
                    }
                  }
                },
              ),
              actions: [
                TextButton(
                  onPressed: () => Get.back(),
                  child: const Text('Cancel'),
                ),
              ],
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
