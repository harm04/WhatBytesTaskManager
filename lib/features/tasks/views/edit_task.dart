import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:whatbytes_task_manager/common/widgets/textfield.dart';
import 'package:whatbytes_task_manager/models/task_model.dart';
import 'package:whatbytes_task_manager/providers/task_provider.dart';

class EditTaskScreen extends ConsumerStatefulWidget {
  final TaskModel task;

  const EditTaskScreen({super.key, required this.task});

  @override
  ConsumerState<EditTaskScreen> createState() => _EditTaskScreenState();
}

class _EditTaskScreenState extends ConsumerState<EditTaskScreen> {
  late TextEditingController _taskTitleController;
  late TextEditingController _taskDescriptionController;
  late TextEditingController _tagController;

  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  String? _selectedPriority;
  List<String> _tags = [];
  bool _isUpdatingTask = false;

  final List<String> _priorities = ['Low', 'Medium', 'High'];
  // ignore: unused_field

  @override
  void initState() {
    super.initState();
    _initializeWithTaskData();
  }

  void _initializeWithTaskData() {
    _taskTitleController = TextEditingController(text: widget.task.title);
    _taskDescriptionController = TextEditingController(
      text: widget.task.description,
    );
    _tagController = TextEditingController();
    _selectedDate = widget.task.dueDate;
    _selectedTime = TimeOfDay.fromDateTime(widget.task.dueDate);
    _selectedPriority = widget.task.priority;
    _tags = List.from(widget.task.tags);
  }

  @override
  void dispose() {
    _taskTitleController.dispose();
    _taskDescriptionController.dispose();
    _tagController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.blue,
              brightness: Brightness.light,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  

  void _addTag() {
    final tagText = _tagController.text.trim();
    if (tagText.isNotEmpty && !_tags.contains(tagText)) {
      setState(() {
        _tags.add(tagText);
        _tagController.clear();
      });
    }
  }

  void _removeTag(String tag) {
    setState(() {
      _tags.remove(tag);
    });
  }

  

  Future<void> _updateTask() async {
    if (_taskTitleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Task title is required')));
      return;
    }

    if (_selectedDate == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select a due date')));
      return;
    }

    if (_selectedTime == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select a due time')));
      return;
    }

    setState(() {
      _isUpdatingTask = true;
    });

    try {
      final dueDateTime = DateTime(
        _selectedDate!.year,
        _selectedDate!.month,
        _selectedDate!.day,
        _selectedTime!.hour,
        _selectedTime!.minute,
      );

      await ref
          .read(taskNotifierProvider.notifier)
          .editTask(
            context: context,
            taskId: widget.task.id,
            title: _taskTitleController.text.trim(),
            description: _taskDescriptionController.text.trim(),
            dueDate: dueDateTime,
            priority: _selectedPriority ?? 'Medium',
            tags: _tags,
          );

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      print('Error updating task: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to update task: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUpdatingTask = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Task'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Task Title',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            SizedBox(height: 5),
            TextFormField(
              maxLength: 50,
              controller: _taskTitleController,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Enter Task Title',
                hintStyle: TextStyle(color: Colors.grey, fontSize: 14),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Task title is required';
                }
                return null;
              },
            ),

            Text(
              'Task Description',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            SizedBox(height: 5),
            CustomTextField(
              maxLines: 5,
              maxLength: 200,
              hintText: 'Enter Task Description',
              controller: _taskDescriptionController,
            ),

            Text(
              'Due Date',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            SizedBox(height: 5),
            GestureDetector(
              onTap: () => _selectDate(context),
              child: AbsorbPointer(
                child: CustomTextField(
                  hintText: _selectedDate == null
                      ? 'Select Due Date'
                      : DateFormat.yMMMMd().format(_selectedDate!),
                  controller: TextEditingController(
                    text: _selectedDate == null
                        ? ''
                        : DateFormat.yMMMMd().format(_selectedDate!),
                  ),
                  suffixIcon: Icon(Icons.calendar_today),
                ),
              ),
            ),
            SizedBox(height: 10),

           Text(
                  'Priority',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
                SizedBox(height: 5),
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: DropdownButtonFormField<String>(
                    value: _selectedPriority,
                    decoration: InputDecoration(
                      hintText: 'Select Priority',
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 16,
                      ),
                      suffixIcon: Icon(Icons.arrow_drop_down),
                    ),
                    items: _priorities.map((String priority) {
                      return DropdownMenuItem<String>(
                        value: priority,
                        child: Text(priority),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      setState(() {
                        _selectedPriority = newValue;
                      });
                    },
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  'Tags',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
                SizedBox(height: 5),
                CustomTagsTextfield(
                  hintText: 'Click enter to add tag',
                  controller: _tagController,
                  onSubmitted: (_) => _addTag(),
                ),
                if (_tags.isNotEmpty) ...[
                  SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _tags.map((tag) {
                      return Chip(
                        label: Text(tag),
                        onDeleted: () => _removeTag(tag),
                        deleteIcon: Icon(Icons.close, size: 18),
                        backgroundColor: Colors.blue.shade50,
                        side: BorderSide(color: Colors.blue.shade200),
                      );
                    }).toList(),
                  ),
                ],
                SizedBox(height: 20),

               
                   

            const SizedBox(height: 24),

      
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isUpdatingTask ? null : _updateTask,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isUpdatingTask
                    ? const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                              strokeWidth: 2,
                            ),
                          ),
                          SizedBox(width: 12),
                          Text('Updating Task...'),
                        ],
                      )
                    : const Text(
                        'Update Task',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
