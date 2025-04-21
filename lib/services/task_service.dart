import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import '../dashboard/task_model.dart';

class TaskService extends GetxService {
  final _supabase = Supabase.instance.client;
  final tasks = <Task>[].obs;
  final isLoading = false.obs;
  final hasError = false.obs;
  final errorMessage = ''.obs;

  // Filter for today's tasks
  final Rx<DateTime?> selectedDate = Rx<DateTime?>(DateTime.now());
  final RxBool showOnlyToday = true.obs;

  @override
  void onInit() {
    super.onInit();
    fetchTasks();

    // Set up listeners for reactivity
    ever(selectedDate, (_) => fetchTasks());
    ever(showOnlyToday, (_) => fetchTasks());
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

      var query = _supabase.from('tasks').select().eq('user_id', userId);

      // Apply date filter if showOnlyToday is true
      if (showOnlyToday.value && selectedDate.value != null) {
        // Format date as ISO string and filter tasks for the selected date
        final dateStr = DateFormat('yyyy-MM-dd').format(selectedDate.value!);
        query = query.or('due_date.eq.$dateStr,due_date.is.null');
      }

      final response = await query.order('created_at', ascending: false);

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

  Future<void> addTask(String title,
      {String? description, DateTime? dueDate}) async {
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

      final taskData = {
        'title': title,
        'is_completed': false,
        'user_id': userId,
      };

      // Add optional fields if provided
      if (description != null && description.isNotEmpty) {
        taskData['description'] = description;
      }

      if (dueDate != null) {
        taskData['due_date'] = dueDate.toIso8601String();
      }

      final response = await _supabase.from('tasks').insert(taskData).select();

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

  Future<void> updateTask(Task task,
      {String? title,
      String? description,
      DateTime? dueDate,
      bool? clearDueDate}) async {
    try {
      isLoading.value = true;
      hasError.value = false;
      errorMessage.value = '';

      final updateData = <String, dynamic>{};

      if (title != null && title.isNotEmpty) {
        updateData['title'] = title;
      }

      if (description != null) {
        updateData['description'] = description.isEmpty ? null : description;
      }

      if (clearDueDate == true) {
        updateData['due_date'] = null;
      } else if (dueDate != null) {
        updateData['due_date'] = dueDate.toIso8601String();
      }

      if (updateData.isEmpty) return;

      await _supabase.from('tasks').update(updateData).eq('id', task.id);

      final index = tasks.indexWhere((t) => t.id == task.id);
      if (index != -1) {
        // Create updated task
        final updatedTask = task.copyWith(
          title: title,
          description: description,
          dueDate: dueDate,
          clearDueDate: clearDueDate ?? false,
        );

        // Replace in list
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

  // Get tasks for a specific date
  List<Task> getTasksForDate(DateTime date) {
    final dateStr = DateFormat('yyyy-MM-dd').format(date);
    return tasks.where((task) {
      if (task.dueDate == null) return false;
      return DateFormat('yyyy-MM-dd').format(task.dueDate!) == dateStr;
    }).toList();
  }

  // Get all pending/incomplete tasks
  List<Task> get pendingTasks =>
      tasks.where((task) => !task.isCompleted).toList();

  // Task statistics
  int get totalTasks => tasks.length;
  int get completedTasks => tasks.where((task) => task.isCompleted).length;
  int get pendingTasksCount => totalTasks - completedTasks;
  double get completionRate => totalTasks > 0 ? completedTasks / totalTasks : 0;
}
