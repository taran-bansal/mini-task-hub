import 'package:supabase_flutter/supabase_flutter.dart';
import '../dashboard/task_model.dart';

class SupabaseService {
  static final supabase = Supabase.instance.client;
  static const String _tasksTable = 'tasks';

  // Authentication Methods
  Future<AuthResponse> signUp({
    required String email,
    required String password,
  }) async {
    return await supabase.auth.signUp(
      email: email,
      password: password,
    );
  }

  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    return await supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  Future<void> signOut() async {
    await supabase.auth.signOut();
  }

  // Task Methods
  Future<List<Task>> getTasks() async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    final response = await supabase
        .from(_tasksTable)
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);

    return (response as List).map((task) => Task.fromJson(task)).toList();
  }

  Future<Task> createTask(String title) async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    final task = {
      'title': title,
      'is_completed': false,
      'user_id': userId,
    };

    final response =
        await supabase.from(_tasksTable).insert(task).select().single();

    return Task.fromJson(response);
  }

  Future<void> deleteTask(String taskId) async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    await supabase
        .from(_tasksTable)
        .delete()
        .eq('id', taskId)
        .eq('user_id', userId);
  }

  Future<Task> toggleTaskCompletion(Task task) async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    final response = await supabase
        .from(_tasksTable)
        .update({'is_completed': !task.isCompleted})
        .eq('id', task.id)
        .eq('user_id', userId)
        .select()
        .single();

    return Task.fromJson(response);
  }
}
