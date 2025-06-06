import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:intl/intl.dart';
import '../app/theme.dart';
import 'task_model.dart';

class TaskTile extends StatelessWidget {
  final Task task;
  final VoidCallback onDelete;
  final VoidCallback onToggle;
  final VoidCallback? onEdit;

  const TaskTile({
    Key? key,
    required this.task,
    required this.onDelete,
    required this.onToggle,
    this.onEdit,
  }) : super(key: key);

  String _formatDate(DateTime date) {
    return DateFormat('MMM d, y').format(date);
  }

  @override
  Widget build(BuildContext context) {
    return Slidable(
      endActionPane: ActionPane(
        motion: const ScrollMotion(),
        children: [
          SlidableAction(
            onPressed: (_) => onDelete(),
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
            icon: Icons.delete,
            label: 'Delete',
            borderRadius: BorderRadius.circular(12),
          ),
          if (onEdit != null)
            SlidableAction(
              onPressed: (_) => onEdit!(),
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              icon: Icons.edit,
              label: 'Edit',
              borderRadius: BorderRadius.circular(12),
            ),
        ],
      ),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onToggle,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      // Checkbox
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: task.isCompleted
                              ? AppTheme.accentYellow
                              : Colors.transparent,
                          border: Border.all(
                            color: task.isCompleted
                                ? AppTheme.accentYellow
                                : Colors.grey.shade600,
                            width: 2,
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(2.0),
                          child: task.isCompleted
                              ? const Icon(Icons.check,
                                  size: 18.0, color: Colors.black)
                              : const SizedBox(width: 18, height: 18),
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Task details
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              task.title,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                                decoration: task.isCompleted
                                    ? TextDecoration.lineThrough
                                    : null,
                                decorationColor: AppTheme.accentYellow,
                                decorationThickness: 2,
                              ),
                            ),
                            if (task.dueDate != null) ...[
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(
                                    Icons.event,
                                    size: 14,
                                    color: _getDueDateColor(task.dueDate!),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Due: ${_formatDate(task.dueDate!)}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: _getDueDateColor(task.dueDate!),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                            const SizedBox(height: 4),
                            Text(
                              'Created: ${_formatDate(task.createdAt)}',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppTheme.secondaryText,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Status indicator
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: task.isCompleted
                              ? AppTheme.accentYellow.withOpacity(0.2)
                              : AppTheme.primaryColor.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          task.isCompleted ? 'Done' : 'To Do',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: task.isCompleted
                                ? AppTheme.accentYellow
                                : AppTheme.primaryColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  // Description section
                  if (task.description != null &&
                      task.description!.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.only(left: 36.0),
                      child: Text(
                        task.description!,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.8),
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Color _getDueDateColor(DateTime dueDate) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dueDateDay = DateTime(dueDate.year, dueDate.month, dueDate.day);

    if (dueDateDay.isBefore(today)) {
      return Colors.red; // Overdue
    } else if (dueDateDay.isAtSameMomentAs(today)) {
      return Colors.orange; // Due today
    } else {
      return Colors.green; // Future
    }
  }
}
