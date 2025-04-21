import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../dashboard/task_model.dart';

class TaskService extends GetxService {
  final _supabase = Supabase.instance.client;
  final tasks = <Task>[].obs;
  final isLoading = false.obs;
  final hasError = false.obs;
  final errorMessage = ''.obs;

  @override
  void onInit() {
    super.onInit();
    fetchTasks();
  }

  Future<void> fetchTasks() async {
    try {
      isLoading.value = true;
      hasError.value = false;
      errorMessage.value = '';

      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        hasError.value = true;
        errorMessage.value = 'User not authenticated';
        return;
      }

      final response = await _supabase
          .from('tasks')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      tasks.value = (response as List)
          .map((json) => Task.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      hasError.value = true;
      errorMessage.value = 'Could not fetch tasks: ${e.toString()}';
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> addTask(String title) async {
    try {
      isLoading.value = true;
      hasError.value = false;
      errorMessage.value = '';

      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        hasError.value = true;
        errorMessage.value = 'User not authenticated';
        return;
      }

      final response = await _supabase.from('tasks').insert({
        'title': title,
        'is_completed': false,
        'user_id': userId,
      }).select();

      if (response != null && response.isNotEmpty) {
        final newTask = Task.fromJson(response.first as Map<String, dynamic>);
        tasks.insert(0, newTask);
      }
    } catch (e) {
      hasError.value = true;
      errorMessage.value = 'Could not add task: ${e.toString()}';
      throw 'Could not add task: ${e.toString()}';
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> deleteTask(String taskId) async {
    try {
      isLoading.value = true;
      hasError.value = false;
      errorMessage.value = '';

      await _supabase.from('tasks').delete().eq('id', taskId);
      tasks.removeWhere((task) => task.id == taskId);
    } catch (e) {
      hasError.value = true;
      errorMessage.value = 'Could not delete task: ${e.toString()}';
      throw 'Could not delete task: ${e.toString()}';
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> toggleTaskCompletion(Task task) async {
    try {
      isLoading.value = true;
      hasError.value = false;
      errorMessage.value = '';

      final updatedStatus = !task.isCompleted;

      await _supabase
          .from('tasks')
          .update({'is_completed': updatedStatus}).eq('id', task.id);

      final index = tasks.indexWhere((t) => t.id == task.id);
      if (index != -1) {
        // Create a new task with updated completion status
        final updatedTask = task.copyWith(isCompleted: updatedStatus);

        // Replace the task in the list
        tasks[index] = updatedTask;
        tasks.refresh();
      }
    } catch (e) {
      hasError.value = true;
      errorMessage.value = 'Could not update task: ${e.toString()}';
      throw 'Could not update task: ${e.toString()}';
    } finally {
      isLoading.value = false;
    }
  }

  // Task statistics
  int get totalTasks => tasks.length;
  int get completedTasks => tasks.where((task) => task.isCompleted).length;
  int get pendingTasks => totalTasks - completedTasks;
  double get completionRate => totalTasks > 0 ? completedTasks / totalTasks : 0;
}
