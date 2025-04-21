import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../dashboard/task_model.dart';

class TaskService extends GetxService {
  final _supabase = Supabase.instance.client;
  final tasks = <Task>[].obs;

  @override
  void onInit() {
    super.onInit();
    fetchTasks();
  }

  Future<void> fetchTasks() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      final response = await _supabase
          .from('tasks')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      tasks.value = (response as List)
          .map((json) => Task.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw 'Could not fetch tasks: ${e.toString()}';
    }
  }

  Future<void> addTask(String title) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

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
      throw 'Could not add task: ${e.toString()}';
    }
  }

  Future<void> deleteTask(String taskId) async {
    try {
      await _supabase.from('tasks').delete().eq('id', taskId);
      tasks.removeWhere((task) => task.id == taskId);
    } catch (e) {
      throw 'Could not delete task: ${e.toString()}';
    }
  }

  Future<void> toggleTaskCompletion(Task task) async {
    try {
      await _supabase
          .from('tasks')
          .update({'is_completed': !task.isCompleted}).eq('id', task.id);

      final index = tasks.indexWhere((t) => t.id == task.id);
      if (index != -1) {
        tasks[index].isCompleted = !tasks[index].isCompleted;
        tasks.refresh();
      }
    } catch (e) {
      throw 'Could not update task: ${e.toString()}';
    }
  }
}
