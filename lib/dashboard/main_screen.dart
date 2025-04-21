import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../app/theme.dart';
import '../services/supabase_service.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final _supabaseService = SupabaseService();

  Future<void> _handleSignOut() async {
    try {
      await _supabaseService.signOut();
      Get.offAllNamed('/login');
    } catch (e) {
      Get.snackbar(
        'Error',
        e.toString(),
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mini Task Hub'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _handleSignOut,
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Welcome back!',
                style: AppTheme.heading,
              ),
              const SizedBox(height: 8),
              Text(
                'Your tasks for today',
                style:
                    AppTheme.bodyText.copyWith(color: AppTheme.secondaryText),
              ),
              const SizedBox(height: 24),
              // TODO: Add task list here
              const Center(
                child: Text('Task list coming soon...'),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: Implement add task
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
