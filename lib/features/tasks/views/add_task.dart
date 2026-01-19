import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:whatbytes_task_manager/common/snackbar.dart';
import 'package:whatbytes_task_manager/common/widgets/button_widget.dart';
import 'package:whatbytes_task_manager/common/widgets/textfield.dart';
import 'package:whatbytes_task_manager/providers/task_provider.dart';

class AddTasksScreen extends ConsumerStatefulWidget {
  const AddTasksScreen({super.key});

  @override
  ConsumerState<AddTasksScreen> createState() => _AddTasksScreenState();
}

class _AddTasksScreenState extends ConsumerState<AddTasksScreen> {
  final TextEditingController _taskTitleController = TextEditingController();
  final TextEditingController _taskDescriptionController =
      TextEditingController();
  final TextEditingController _dueDateController = TextEditingController();
  final TextEditingController _tagsController = TextEditingController();

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  DateTime? _selectedDate;
  String? _selectedPriority = 'Medium';
  List<String> _tags = [];
  bool _isCreatingTask = false;

  final List<String> _priorityOptions = ['Low', 'Medium', 'High'];

  @override
  void dispose() {
    _taskTitleController.dispose();
    _taskDescriptionController.dispose();
    _dueDateController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  final List<String> _monthNames = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  @override
  void initState() {
    super.initState();
    _dueDateController.text = _formatDate(DateTime.now());
    _selectedDate = DateTime.now();
  }

  String _formatDate(DateTime date) {
    return "${date.day} ${_monthNames[date.month - 1]}, ${date.year}";
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _dueDateController.text = _formatDate(picked);
      });
    }
  }

  void _addTag(String tag) {
    final trimmedTag = tag.trim();
    if (trimmedTag.isNotEmpty && !_tags.contains(trimmedTag)) {
      setState(() {
        _tags.add(trimmedTag);
        _tagsController.clear();
      });
    }
  }

  void _removeTag(String tag) {
    setState(() {
      _tags.remove(tag);
    });
  }

  Future<void> _createTask() async {
    if (_taskTitleController.text.trim().isEmpty) {
      showSnackbar(context, 'Task title is required');
      return;
    }

    setState(() {
      _isCreatingTask = true;
    });

    try {
      await ref
          .read(taskNotifierProvider.notifier)
          .createTask(
            context: context,
            title: _taskTitleController.text.trim(),
            description: _taskDescriptionController.text.trim(),
            dueDate: _selectedDate ?? DateTime.now(),
            priority: _selectedPriority ?? 'Medium',
            tags: _tags,
          );

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      print('Error creating task: $e');
      if (mounted) {
        showSnackbar(context, 'Failed to create task: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCreatingTask = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Create New Task')),
      body: Padding(
        padding: const EdgeInsets.all(18.0),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
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
                      hintText: _formatDate(DateTime.now()),
                      controller: _dueDateController,
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
                    items: _priorityOptions.map((String priority) {
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
                  controller: _tagsController,
                  onSubmitted: _addTag,
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

                GestureDetector(
                  onTap: _isCreatingTask ? null : _createTask,
                  child: ButtonWidget(
                    text: _isCreatingTask ? 'Creating...' : 'Create Task',
                  ),
                ),
                SizedBox(height: 50),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
