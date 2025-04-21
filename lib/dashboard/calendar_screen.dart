import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../app/theme.dart';
import '../services/task_service.dart';
import 'task_tile.dart';
import 'task_model.dart';
import 'add_task_screen.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  final TaskService taskService = Get.find<TaskService>();
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  final Map<DateTime, List<Task>> _eventsByDay = {};
  final RxBool _forceRebuild = false.obs;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _groupTasksByDay();

    // Listen for task changes to update events
    ever(taskService.tasks, (_) {
      _groupTasksByDay();
      // Force UI update through this observable
      _forceRebuild.toggle();
    });
  }

  void _groupTasksByDay() {
    _eventsByDay.clear();

    for (final task in taskService.tasks) {
      if (task.dueDate != null) {
        final date = DateTime(
          task.dueDate!.year,
          task.dueDate!.month,
          task.dueDate!.day,
        );

        if (_eventsByDay[date] == null) {
          _eventsByDay[date] = [];
        }

        _eventsByDay[date]!.add(task);
      }
    }

    if (mounted) setState(() {});
  }

  List<Task> _getTasksForDay(DateTime day) {
    final normalizedDay = DateTime(day.year, day.month, day.day);
    return _eventsByDay[normalizedDay] ?? [];
  }

  int _getTaskCountForDay(DateTime day) {
    return _getTasksForDay(day).length;
  }

  @override
  Widget build(BuildContext context) {
    // Listen to _forceRebuild value to trigger rebuilds when tasks change
    _forceRebuild.value;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Calendar'),
        backgroundColor: AppTheme.backgroundColor,
        elevation: 0,
      ),
      body: Column(
        children: [
          TableCalendar(
            headerStyle: HeaderStyle(
              formatButtonTextStyle: TextStyle(color: Colors.white),
              titleTextStyle: TextStyle(color: Colors.white, fontSize: 16),
              titleCentered: true,
              formatButtonDecoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.3),
                borderRadius: BorderRadius.circular(16),
              ),
              leftChevronIcon: Icon(Icons.chevron_left, color: Colors.white),
              rightChevronIcon: Icon(Icons.chevron_right, color: Colors.white),
            ),
            daysOfWeekStyle: DaysOfWeekStyle(
              weekdayStyle: TextStyle(color: Colors.white70),
              weekendStyle:
                  TextStyle(color: AppTheme.accentYellow.withOpacity(0.7)),
            ),
            calendarStyle: CalendarStyle(
              outsideDaysVisible: false,
              defaultTextStyle: TextStyle(color: Colors.white),
              weekendTextStyle: TextStyle(color: AppTheme.accentYellow),
              selectedDecoration: BoxDecoration(
                color: AppTheme.accentYellow,
                shape: BoxShape.circle,
              ),
              todayDecoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.5),
                shape: BoxShape.circle,
              ),
              markersMaxCount: 3,
              markerDecoration: BoxDecoration(
                color: AppTheme.accentYellow,
                shape: BoxShape.circle,
              ),
              markerSize: 6,
            ),
            firstDay: DateTime.now().subtract(const Duration(days: 365)),
            lastDay: DateTime.now().add(const Duration(days: 365)),
            focusedDay: _focusedDay,
            calendarFormat: _calendarFormat,
            eventLoader: _getTasksForDay,
            startingDayOfWeek: StartingDayOfWeek.monday,
            selectedDayPredicate: (day) {
              return isSameDay(_selectedDay, day);
            },
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
            },
            onFormatChanged: (format) {
              setState(() {
                _calendarFormat = format;
              });
            },
            onPageChanged: (focusedDay) {
              _focusedDay = focusedDay;
            },
          ),
          const Divider(color: AppTheme.dividerColor),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Icon(Icons.task_alt, color: AppTheme.accentYellow, size: 20),
                const SizedBox(width: 8),
                Text(
                  _selectedDay == null
                      ? 'Tasks for Today'
                      : 'Tasks for ${DateFormat('MMM d, y').format(_selectedDay!)}',
                  style: AppTheme.subheading.copyWith(fontSize: 18),
                ),
              ],
            ),
          ),
          Expanded(
            child: _selectedDay == null
                ? _buildEmptyState(
                    'No date selected', 'Select a date to view tasks')
                : _buildTasksListForSelectedDay(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Get.to(() => AddTaskScreen(initialDate: _selectedDay)),
        backgroundColor: AppTheme.accentYellow,
        child: const Icon(Icons.add, color: Colors.black),
      ),
    );
  }

  Widget _buildTasksListForSelectedDay() {
    final tasksForDay = _getTasksForDay(_selectedDay!);

    if (tasksForDay.isEmpty) {
      return _buildEmptyState(
        'No tasks for this date',
        'Add tasks with due dates to see them here',
      );
    }

    return ListView.builder(
      itemCount: tasksForDay.length,
      padding: const EdgeInsets.all(16),
      itemBuilder: (context, index) {
        final task = tasksForDay[index];
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
            onEdit: () => Get.to(() => AddTaskScreen(taskToEdit: task)),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(String title, String subtitle) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.calendar_today,
            size: 80,
            color: AppTheme.primaryColor.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: AppTheme.subheading.copyWith(
              color: Colors.white.withOpacity(0.8),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(
              color: AppTheme.secondaryText,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
