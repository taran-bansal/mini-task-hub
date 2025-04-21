import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../app/theme.dart';
import '../services/task_service.dart';
import 'task_model.dart';

class AddTaskScreen extends StatefulWidget {
  final DateTime? initialDate;
  final Task? taskToEdit;

  const AddTaskScreen({
    super.key,
    this.initialDate,
    this.taskToEdit,
  });

  @override
  State<AddTaskScreen> createState() => _AddTaskScreenState();
}

class _AddTaskScreenState extends State<AddTaskScreen> {
  final TaskService taskService = Get.find<TaskService>();
  late final TextEditingController titleController;
  late final TextEditingController descriptionController;
  late final FocusNode titleFocusNode;
  DateTime? selectedDueDate;
  bool clearDueDate = false;
  bool isEditing = false;

  @override
  void initState() {
    super.initState();
    isEditing = widget.taskToEdit != null;
    titleController = TextEditingController(
      text: isEditing ? widget.taskToEdit!.title : '',
    );
    descriptionController = TextEditingController(
      text: isEditing ? (widget.taskToEdit!.description ?? '') : '',
    );
    titleFocusNode = FocusNode()..requestFocus();
    selectedDueDate =
        isEditing ? widget.taskToEdit?.dueDate : widget.initialDate;
  }

  @override
  void dispose() {
    titleController.dispose();
    descriptionController.dispose();
    titleFocusNode.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: selectedDueDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (pickedDate != null) {
      setState(() {
        selectedDueDate = pickedDate;
        clearDueDate = false;
      });
    }
  }

  void _saveTask() {
    final title = titleController.text.trim();
    final description = descriptionController.text.trim();

    if (title.isEmpty) {
      Get.snackbar(
        'Error',
        'Task title cannot be empty',
        backgroundColor: Colors.red.withOpacity(0.8),
        colorText: Colors.white,
      );
      return;
    }

    try {
      if (isEditing) {
        taskService.updateTask(
          widget.taskToEdit!,
          title: title,
          description: description,
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
      } else {
        taskService.addTask(
          title,
          description: description,
          dueDate: selectedDueDate,
        );
        Get.back();
        Get.snackbar(
          'Success',
          'Task added successfully',
          backgroundColor: Colors.green.withOpacity(0.8),
          colorText: Colors.white,
        );
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        e.toString(),
        backgroundColor: Colors.red.withOpacity(0.8),
        colorText: Colors.white,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Task' : 'Add New Task'),
        backgroundColor: AppTheme.backgroundColor,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: titleController,
              focusNode: titleFocusNode,
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
            Card(
              elevation: 2,
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Due Date',
                      style: AppTheme.subheading.copyWith(fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.event, color: AppTheme.primaryColor),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            clearDueDate
                                ? 'None'
                                : selectedDueDate != null
                                    ? DateFormat('MMM d, y')
                                        .format(selectedDueDate!)
                                    : 'None',
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                        TextButton(
                          onPressed: clearDueDate ? null : _selectDate,
                          child: const Text('Change'),
                        ),
                      ],
                    ),
                    if (isEditing) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Checkbox(
                            value: clearDueDate,
                            onChanged: (value) {
                              setState(() {
                                clearDueDate = value ?? false;
                              });
                            },
                          ),
                          const Text('Clear due date'),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            OutlinedButton(
              onPressed: () => Get.back(),
              style: OutlinedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: const Text('Cancel'),
            ),
            const SizedBox(width: 12),
            ElevatedButton(
              onPressed: _saveTask,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accentYellow,
                foregroundColor: Colors.black,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: Text(isEditing ? 'Update Task' : 'Add Task'),
            ),
          ],
        ),
      ),
    );
  }
}
