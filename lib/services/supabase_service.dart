import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';

class SupabaseService {
  static const String supabaseUrl = 'https://dwfxrpgkczxzrwvhfnrf.supabase.co';
  static const String supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImR3ZnhycGdrY3p4enJ3dmhmbnJmIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDUxNjMzOTMsImV4cCI6MjA2MDczOTM5M30.ynXPJh0eQqXWzN9njuuGTW_ispgfM1OkhJTqCXAktVc';

  final _supabase = Supabase.instance.client;

  static Future<void> initialize() async {
    try {
      await Supabase.initialize(
        url: supabaseUrl,
        anonKey: supabaseAnonKey,
        debug: kDebugMode,
      );
    } catch (e) {
      debugPrint('Error initializing Supabase: $e');
      rethrow;
    }
  }

  SupabaseService() {
    // _supabase = Supabase.instance.client;
  }

  Future<AuthResponse> signUp({
    required String email,
    required String password,
  }) async {
    try {
      return await _supabase.auth.signUp(
        email: email,
        password: password,
      );
    } catch (e) {
      debugPrint('Error during sign up: $e');
      rethrow;
    }
  }

  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    try {
      return await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      debugPrint('Error during sign in: $e');
      rethrow;
    }
  }

  Future<void> signOut() async {
    try {
      await _supabase.auth.signOut();
    } catch (e) {
      debugPrint('Error during sign out: $e');
      rethrow;
    }
  }

  Future<void> resetPassword(String email) async {
    await _supabase.auth.resetPasswordForEmail(email);
  }

  Future<List<Map<String, dynamic>>> getTasks() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      final response = await _supabase
          .from('tasks')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error fetching tasks: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> createTask({
    required String title,
    required bool isCompleted,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      final response = await _supabase
          .from('tasks')
          .insert({
            'title': title,
            'is_completed': isCompleted,
            'user_id': userId,
          })
          .select()
          .single();
      return response;
    } catch (e) {
      debugPrint('Error creating task: $e');
      rethrow;
    }
  }

  Future<void> deleteTask(String taskId) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      await _supabase
          .from('tasks')
          .delete()
          .eq('id', taskId)
          .eq('user_id', userId);
    } catch (e) {
      debugPrint('Error deleting task: $e');
      rethrow;
    }
  }

  Future<void> updateTaskStatus(String taskId, bool isCompleted) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      await _supabase
          .from('tasks')
          .update({'is_completed': isCompleted})
          .eq('id', taskId)
          .eq('user_id', userId);
    } catch (e) {
      debugPrint('Error updating task status: $e');
      rethrow;
    }
  }

  User? get currentUser => _supabase.auth.currentUser;
  bool get isAuthenticated => _supabase.auth.currentUser != null;
  SupabaseClient get client => _supabase;
}
