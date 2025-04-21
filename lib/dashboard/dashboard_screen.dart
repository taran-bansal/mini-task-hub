import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../app/theme.dart';
import '../auth/auth_service.dart';
import '../services/task_service.dart';
import 'task_tile.dart';
import 'task_model.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final TaskService taskService = Get.find<TaskService>();
  final AuthService authService = Get.find<AuthService>();
  final RxString filterType = 'all'.obs; // 'all', 'active', 'completed'
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final RxString _searchQuery = ''.obs;
  final RxList<Task> _filteredTasks = <Task>[].obs;

  @override
  void initState() {
    super.initState();
    // Initial update for filtered tasks
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateFilteredTasks();
    });

    // Set up listeners for reactivity
    ever(taskService.tasks, (_) => _updateFilteredTasks());
    ever(filterType, (_) => _updateFilteredTasks());
    ever(_searchQuery, (_) => _updateFilteredTasks());
  }

  void _updateFilteredTasks() {
    // First filter by search query
    final searchFiltered = _searchQuery.value.isEmpty
        ? taskService.tasks
        : taskService.tasks.where(
            (task) => task.title
                .toLowerCase()
                .contains(_searchQuery.value.toLowerCase()),
          );

    // Then filter by completion status
    switch (filterType.value) {
      case 'active':
        _filteredTasks.value =
            searchFiltered.where((task) => !task.isCompleted).toList();
        break;
      case 'completed':
        _filteredTasks.value =
            searchFiltered.where((task) => task.isCompleted).toList();
        break;
      case 'all':
      default:
        _filteredTasks.value = searchFiltered.toList();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  Future<void> _handleSignOut() async {
    try {
      await authService.signOut();
      Get.offAllNamed('/login');
    } catch (e) {
      Get.snackbar(
        'Error',
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.8),
        colorText: Colors.white,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Custom App Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: AppTheme.backgroundColor,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'My Tasks',
                        style: AppTheme.subheading,
                      ),
                      CircleAvatar(
                        backgroundColor: AppTheme.surfaceColor,
                        child: IconButton(
                          icon: const Icon(Icons.logout, color: Colors.white),
                          onPressed: _handleSignOut,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Task statistics cards
                  Obx(() => _buildTaskStatistics()),
                  const SizedBox(height: 16),
                  // Search box
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TextField(
                      controller: _searchController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        hintText: 'Search tasks...',
                        prefixIcon: Icon(Icons.search, color: Colors.grey),
                        border: InputBorder.none,
                      ),
                      onChanged: (value) => _searchQuery.value = value,
                      focusNode: _searchFocusNode,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Filter chips
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _filterChip('All', 'all'),
                        const SizedBox(width: 8),
                        _filterChip('To Do', 'active'),
                        const SizedBox(width: 8),
                        _filterChip('Completed', 'completed'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Task list
            Expanded(
              child: Obx(() {
                // Show loading indicator when fetching tasks
                if (taskService.isLoading.value) {
                  return const Center(
                    child: CircularProgressIndicator(
                      valueColor:
                          AlwaysStoppedAnimation<Color>(AppTheme.accentYellow),
                    ),
                  );
                }

                // Show error message if there was an error
                if (taskService.hasError.value) {
                  return _buildErrorState(
                    taskService.errorMessage.value,
                    () => taskService.fetchTasks(),
                  );
                }

                if (taskService.tasks.isEmpty) {
                  // No tasks at all
                  return _buildEmptyState(
                    "You don't have any tasks yet",
                    "Tap the + button to add your first task",
                    Icons.task_alt,
                  );
                } else if (_filteredTasks.isEmpty) {
                  // No tasks matching the current filter
                  return _buildEmptyState(
                    "No matching tasks",
                    "Try changing your search or filter",
                    Icons.filter_list,
                  );
                } else {
                  return RefreshIndicator(
                    onRefresh: () async {
                      await taskService.fetchTasks();
                    },
                    color: AppTheme.accentYellow,
                    backgroundColor: AppTheme.surfaceColor,
                    child: ListView.builder(
                      itemCount: _filteredTasks.length,
                      padding: const EdgeInsets.all(16),
                      itemBuilder: (context, index) {
                        final task = _filteredTasks[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
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
                          ),
                        );
                      },
                    ),
                  );
                }
              }),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddTaskDialog(),
        backgroundColor: AppTheme.accentYellow,
        child: const Icon(Icons.add, color: Colors.black),
      ),
    );
  }

  Widget _filterChip(String label, String type) {
    return Obx(() {
      final isSelected = filterType.value == type;

      return GestureDetector(
        onTap: () => filterType.value = type,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.accentYellow : AppTheme.surfaceColor,
            borderRadius: BorderRadius.circular(30),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.black : Colors.white,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              fontSize: 14,
            ),
          ),
        ),
      );
    });
  }

  Widget _buildEmptyState(String title, String subtitle, IconData icon) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 80, color: AppTheme.primaryColor.withOpacity(0.5)),
            const SizedBox(height: 24),
            Text(
              title,
              style: AppTheme.subheading.copyWith(
                color: Colors.white.withOpacity(0.8),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: AppTheme.bodyText.copyWith(
                color: AppTheme.secondaryText,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showAddTaskDialog() async {
    final taskController = TextEditingController();
    final taskFocusNode = FocusNode();

    try {
      await Get.dialog(
        AlertDialog(
          title: const Text('Add New Task'),
          content: SafeArea(
            child: TextField(
              controller: taskController,
              focusNode: taskFocusNode,
              autofocus: true,
              decoration: const InputDecoration(
                hintText: 'Enter task title',
                border: OutlineInputBorder(),
              ),
              onSubmitted: (_) => _addTask(taskController.text),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Get.back(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => _addTask(taskController.text),
              child: const Text('Add Task'),
            ),
          ],
        ),
      );
    } finally {
      // Ensure resources are properly disposed even if dialog is dismissed
      taskFocusNode.dispose();
      taskController.dispose();
    }
  }

  Future<void> _addTask(String title) async {
    if (title.trim().isEmpty) {
      Get.snackbar(
        'Error',
        'Task title cannot be empty',
        backgroundColor: Colors.red.withOpacity(0.8),
        colorText: Colors.white,
      );
      return;
    }

    try {
      await taskService.addTask(title.trim());

      // Only try to close dialog if it's still showing
      if (Get.isDialogOpen ?? false) {
        Get.back();
      }

      Get.snackbar(
        'Success',
        'Task added successfully',
        backgroundColor: Colors.green.withOpacity(0.8),
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
  }

  Widget _buildTaskStatistics() {
    final totalTasks = taskService.tasks.length;
    final completedTasks =
        taskService.tasks.where((task) => task.isCompleted).length;
    final pendingTasks = totalTasks - completedTasks;

    // Use a smaller padding on small screens
    final screenWidth = MediaQuery.of(context).size.width;
    final isCompact = screenWidth < 360;
    final cardPadding = isCompact ? 8.0 : 12.0;
    final spaceBetween = isCompact ? 6.0 : 12.0;
    final iconSize = isCompact ? 16.0 : 20.0;
    final iconPadding = isCompact ? 6.0 : 8.0;
    final countTextSize = isCompact ? 14.0 : 16.0;
    final titleTextSize = isCompact ? 10.0 : 12.0;

    return Row(
      children: [
        _buildStatCard(
          'Total',
          totalTasks.toString(),
          Icons.list_alt,
          AppTheme.primaryColor,
          padding: cardPadding,
          iconSize: iconSize,
          iconPadding: iconPadding,
          countTextSize: countTextSize,
          titleTextSize: titleTextSize,
        ),
        SizedBox(width: spaceBetween),
        _buildStatCard(
          'To Do',
          pendingTasks.toString(),
          Icons.pending_actions,
          Colors.orange,
          padding: cardPadding,
          iconSize: iconSize,
          iconPadding: iconPadding,
          countTextSize: countTextSize,
          titleTextSize: titleTextSize,
        ),
        SizedBox(width: spaceBetween),
        _buildStatCard(
          'Completed',
          completedTasks.toString(),
          Icons.task_alt,
          Colors.green,
          padding: cardPadding,
          iconSize: iconSize,
          iconPadding: iconPadding,
          countTextSize: countTextSize,
          titleTextSize: titleTextSize,
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String title,
    String count,
    IconData icon,
    Color color, {
    double padding = 12.0,
    double iconSize = 20.0,
    double iconPadding = 8.0,
    double countTextSize = 16.0,
    double titleTextSize = 12.0,
  }) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.all(padding),
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.5), width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(iconPadding),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: iconSize),
            ),
            SizedBox(width: padding <= 8 ? 4 : 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    count,
                    style: TextStyle(
                      fontSize: countTextSize,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: titleTextSize,
                      color: AppTheme.secondaryText,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String message, VoidCallback onRetry) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error, size: 80, color: Colors.red.withOpacity(0.5)),
            const SizedBox(height: 24),
            Text(
              message,
              style: AppTheme.subheading.copyWith(
                color: Colors.white.withOpacity(0.8),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: onRetry,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
