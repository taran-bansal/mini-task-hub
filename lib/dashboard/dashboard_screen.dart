import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../services/task_service.dart';
import '../auth/auth_service.dart';
import 'task_tile.dart';
import '../app/theme.dart';
import 'calendar_screen.dart';
import 'pending_tasks_screen.dart';
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

  // Navigation state
  final RxInt _selectedIndex = 0.obs;

  @override
  void initState() {
    super.initState();
    // Make sure we're loading all tasks by default
    taskService.showOnlyToday.value = false;

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
    final tasks = taskService.tasks;

    // Apply filter type
    var filtered = <Task>[];
    if (filterType.value == 'all') {
      filtered = tasks.toList();
    } else if (filterType.value == 'active') {
      filtered = tasks.where((task) => !task.isCompleted).toList();
    } else if (filterType.value == 'completed') {
      filtered = tasks.where((task) => task.isCompleted).toList();
    }

    // Apply search filter if query is not empty
    if (_searchQuery.value.isNotEmpty) {
      filtered = filtered
          .where((task) => task.title
              .toLowerCase()
              .contains(_searchQuery.value.toLowerCase()))
          .toList();
    }

    _filteredTasks.value = filtered;
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
    return Scaffold(
      body: Obx(() {
        switch (_selectedIndex.value) {
          case 0:
            return _buildAllTasksScreen();
          case 1:
            return CalendarScreen();
          case 2:
            return PendingTasksScreen();
          default:
            return _buildAllTasksScreen();
        }
      }),
      bottomNavigationBar: Obx(() => BottomNavigationBar(
            currentIndex: _selectedIndex.value,
            onTap: (index) => _selectedIndex.value = index,
            backgroundColor: AppTheme.backgroundColor,
            selectedItemColor: AppTheme.accentYellow,
            unselectedItemColor: Colors.grey,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.home),
                label: 'Tasks',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.calendar_month),
                label: 'Calendar',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.pending_actions),
                label: 'Pending',
              ),
            ],
          )),
    );
  }

  Widget _buildAllTasksScreen() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tasks'),
        backgroundColor: AppTheme.backgroundColor,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _handleSignOut,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Container(
              decoration: BoxDecoration(
                color: AppTheme.surfaceColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const SizedBox(width: 16),
                  Icon(
                    Icons.search,
                    color: AppTheme.secondaryText,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Search tasks...',
                        hintStyle: TextStyle(color: AppTheme.secondaryText),
                        border: InputBorder.none,
                        contentPadding:
                            const EdgeInsets.symmetric(vertical: 15),
                      ),
                      onChanged: (value) => _searchQuery.value = value,
                      focusNode: _searchFocusNode,
                    ),
                  ),
                ],
              ),
            ),
          ),
          _buildTaskStatistics(),
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              children: [
                _buildFilterChip('All', 'all'),
                const SizedBox(width: 8),
                _buildFilterChip('Active', 'active'),
                const SizedBox(width: 8),
                _buildFilterChip('Completed', 'completed'),
              ],
            ),
          ),
          Expanded(
            child: Obx(() {
              if (taskService.isLoading.value) {
                return const Center(
                  child: CircularProgressIndicator(
                    valueColor:
                        AlwaysStoppedAnimation<Color>(AppTheme.accentYellow),
                  ),
                );
              }

              if (_filteredTasks.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.task_alt,
                        size: 64,
                        color: Colors.grey.withOpacity(0.5),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No tasks found',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey.withOpacity(0.8),
                        ),
                      ),
                    ],
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: () => taskService.fetchTasks(),
                color: AppTheme.accentYellow,
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
                    );
                  },
                ),
              );
            }),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddTaskDialog,
        backgroundColor: AppTheme.accentYellow,
        child: const Icon(Icons.add, color: Colors.black),
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    return Obx(() {
      final isSelected = filterType.value == value;
      return InkWell(
        onTap: () => filterType.value = value,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.accentYellow : AppTheme.surfaceColor,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.black : Colors.white,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      );
    });
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

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
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
      ),
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

  Future<void> _showAddTaskDialog() async {
    final taskController = TextEditingController();
    final descriptionController = TextEditingController();
    final taskFocusNode = FocusNode();
    DateTime? selectedDueDate;

    try {
      await Get.dialog(
        AlertDialog(
          title: const Text('Add New Task'),
          content: SafeArea(
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: taskController,
                    focusNode: taskFocusNode,
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
                              final DateTime initialPickDate =
                                  selectedDueDate ?? DateTime.now();
                              final pickedDate = await showDatePicker(
                                context: context,
                                initialDate: initialPickDate,
                                firstDate: DateTime.now()
                                    .subtract(const Duration(days: 365)),
                                lastDate: DateTime.now()
                                    .add(const Duration(days: 365)),
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
          ),
          actions: [
            TextButton(
              onPressed: () => Get.back(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (taskController.text.trim().isEmpty) {
                  Get.snackbar(
                    'Error',
                    'Task title cannot be empty',
                    backgroundColor: Colors.red.withOpacity(0.8),
                    colorText: Colors.white,
                  );
                  return;
                }

                taskService.addTask(
                  taskController.text.trim(),
                  description: descriptionController.text.trim(),
                  dueDate: selectedDueDate,
                );

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
              },
              child: const Text('Add Task'),
            ),
          ],
        ),
      );
    } finally {
      // Ensure resources are properly disposed even if dialog is dismissed
      taskFocusNode.dispose();
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

                                final DateTime initialPickDate =
                                    selectedDueDate ?? DateTime.now();
                                final pickedDate = await showDatePicker(
                                  context: context,
                                  initialDate: initialPickDate,
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
                if (taskController.text.trim().isEmpty) {
                  Get.snackbar(
                    'Error',
                    'Task title cannot be empty',
                    backgroundColor: Colors.red.withOpacity(0.8),
                    colorText: Colors.white,
                  );
                  return;
                }

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
