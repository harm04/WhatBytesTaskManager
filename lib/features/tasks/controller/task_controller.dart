import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:whatbytes_task_manager/common/snackbar.dart';
import 'package:whatbytes_task_manager/models/task_model.dart';
import 'package:whatbytes_task_manager/providers/auth_provider.dart';
import 'package:whatbytes_task_manager/providers/task_provider.dart';

class TaskNotifier extends AsyncNotifier<List<TaskModel>> {
  late TaskController _taskController;

  @override
  Future<List<TaskModel>> build() async {
    _taskController = ref.read(taskControllerProvider);

    final authState = await ref.read(authStateProvider.future);
    if (authState == null) {
      return [];
    }

    return await _initTaskState();
  }

  Future<List<TaskModel>> _initTaskState() async {
    try {
      await Future.delayed(const Duration(milliseconds: 100));
      return await _taskController.loadTasks();
    } catch (e) {
      print('TaskNotifier error: $e');
      throw Exception('Failed to load tasks: $e');
    }
  }

  Future<void> createTask({
    required BuildContext context,
    required String title,
    required String description,
    required DateTime dueDate,
    required String priority,
    required List<String> tags,
  }) async {
    state = const AsyncValue.loading();
    try {
      final success = await _taskController.createTask(
        context: context,
        title: title,
        description: description,
        dueDate: dueDate,
        priority: priority,
        tags: tags,
      );

      if (success) {
        final tasks = await _taskController.loadTasks();
        state = AsyncValue.data(tasks);
      } else {
        state = AsyncValue.error('Failed to create task', StackTrace.current);
      }
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<void> editTask({
    required BuildContext context,
    required String taskId,
    required String title,
    required String description,
    required DateTime dueDate,
    required String priority,
    required List<String> tags,
  }) async {
    try {
      final success = await _taskController.editTask(
        context: context,
        taskId: taskId,
        title: title,
        description: description,
        dueDate: dueDate,
        priority: priority,
        tags: tags,
      );

      if (success) {
     
        final tasks = await _taskController.loadTasks();
        state = AsyncValue.data(tasks);
      }
    } catch (e) {
      print('Error in editTask notifier: $e');
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<void> markAsComplete(BuildContext context, String taskId) async {
    try {
      final success = await _taskController.markAsComplete(context, taskId);
      if (success) {
        final tasks = await _taskController.loadTasks();
        state = AsyncValue.data(tasks);
      }
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<void> markAsIncomplete(BuildContext context, String taskId) async {
    try {
      final success = await _taskController.markAsIncomplete(context, taskId);
      if (success) {
        final tasks = await _taskController.loadTasks();
        state = AsyncValue.data(tasks);
      }
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<void> deleteTask(BuildContext context, String taskId) async {
    try {
      final success = await _taskController.deleteTask(context, taskId);
      if (success) {
        final tasks = await _taskController.loadTasks();
        state = AsyncValue.data(tasks);
      }
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<void> toggleTaskCompletion(BuildContext context, String taskId) async {
    try {
      final success = await _taskController.toggleTaskCompletion(
        context,
        taskId,
      );
      if (success) {
        final tasks = await _taskController.loadTasks();
        state = AsyncValue.data(tasks);
      }
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  
 
  Future<void> refreshTasks() async {
    state = const AsyncValue.loading();
    try {
      final tasks = await _taskController.loadTasks();
      state = AsyncValue.data(tasks);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }
}

class TaskController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  TaskController() {
    _auth.authStateChanges().listen((User? user) {
      if (user == null) {
        print('User is currently signed out!');
      } else {
        print('User is signed in!');
      }
    });
  }


  String get _currentUserId => _auth.currentUser?.uid ?? '';


  Future<List<TaskModel>> loadTasks() async {
    try {
      if (_currentUserId.isEmpty) {
       
        return [];
      }



      final querySnapshot = await _firestore
          .collection('tasks')
          .where('userId', isEqualTo: _currentUserId)
          .orderBy('createdAt', descending: true)
          .get();

      final tasks = querySnapshot.docs
          .map((doc) => TaskModel.fromMap(doc.data()))
          .toList();

     
      return tasks;
    } catch (e) {
     
      throw Exception('Failed to load tasks: $e');
    }
  }


  Future<bool> createTask({
    required BuildContext context,
    required String title,
    required String description,
    required DateTime dueDate,
    required String priority,
    required List<String> tags,
  }) async {
    try {
      if (_currentUserId.isEmpty) {
        if (context.mounted) {
          showSnackbar(context, 'User not authenticated');
        }
        return false;
      }

      final taskId = _firestore.collection('tasks').doc().id;
      final now = DateTime.now();

      final task = TaskModel(
        id: taskId,
        title: title,
        description: description,
        dueDate: dueDate,
        priority: priority,
        tags: tags,
        isCompleted: false,
        createdAt: now,
        updatedAt: now,
        userId: _currentUserId,
      );

      await _firestore.collection('tasks').doc(taskId).set(task.toMap());

      if (context.mounted) {
        showSnackbar(context, 'Task created successfully!');
      }

      return true;
    } catch (e) {
      print('Error creating task: $e');
      if (context.mounted) {
        showSnackbar(context, 'Failed to create task');
      }
      return false;
    }
  }


  Future<bool> editTask({
    required BuildContext context,
    required String taskId,
    required String title,
    required String description,
    required DateTime dueDate,
    required String priority,
    required List<String> tags,
  }) async {
    try {
      if (_currentUserId.isEmpty) {
        if (context.mounted) {
          showSnackbar(context, 'User not authenticated');
        }
        return false;
      }

      final updates = {
        'title': title,
        'description': description,
        'dueDate': Timestamp.fromDate(dueDate),
        'priority': priority,
        'tags': tags,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      };

      await _firestore.collection('tasks').doc(taskId).update(updates);

      if (context.mounted) {
        showSnackbar(context, 'Task updated successfully!');
      }

      return true;
    } catch (e) {
      print('Error editing task: $e');
      if (context.mounted) {
        showSnackbar(context, 'Failed to update task');
      }
      return false;
    }
  }


  Future<bool> markAsComplete(BuildContext context, String taskId) async {
    try {
      if (_currentUserId.isEmpty) {
        if (context.mounted) {
          showSnackbar(context, 'User not authenticated');
        }
        return false;
      }

      await _firestore.collection('tasks').doc(taskId).update({
        'isCompleted': true,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });

      if (context.mounted) {
        showSnackbar(context, 'Task marked as complete!');
      }

      return true;
    } catch (e) {
      print('Error marking task as complete: $e');
      if (context.mounted) {
        showSnackbar(context, 'Failed to mark task as complete');
      }
      return false;
    }
  }


  Future<bool> markAsIncomplete(BuildContext context, String taskId) async {
    try {
      if (_currentUserId.isEmpty) {
        if (context.mounted) {
          showSnackbar(context, 'User not authenticated');
        }
        return false;
      }

      await _firestore.collection('tasks').doc(taskId).update({
        'isCompleted': false,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });

      if (context.mounted) {
        showSnackbar(context, 'Task marked as incomplete!');
      }

      return true;
    } catch (e) {
      print('Error marking task as incomplete: $e');
      if (context.mounted) {
        showSnackbar(context, 'Failed to mark task as incomplete');
      }
      return false;
    }
  }


  Future<bool> deleteTask(BuildContext context, String taskId) async {
    try {
      if (_currentUserId.isEmpty) {
        if (context.mounted) {
          showSnackbar(context, 'User not authenticated');
        }
        return false;
      }

      await _firestore.collection('tasks').doc(taskId).delete();

      if (context.mounted) {
        showSnackbar(context, 'Task deleted successfully!');
      }

      return true;
    } catch (e) {
      print('Error deleting task: $e');
      if (context.mounted) {
        showSnackbar(context, 'Failed to delete task');
      }
      return false;
    }
  }


  Future<TaskModel?> getTaskById(String taskId) async {
    try {
      final doc = await _firestore.collection('tasks').doc(taskId).get();
      if (doc.exists) {
        return TaskModel.fromMap(doc.data()!);
      }
    } catch (e) {
      print('Error getting task by ID: $e');
    }
    return null;
  }


  Future<List<TaskModel>> getTasksByStatus(bool isCompleted) async {
    try {
      if (_currentUserId.isEmpty) return [];

      final querySnapshot = await _firestore
          .collection('tasks')
          .where('userId', isEqualTo: _currentUserId)
          .where('isCompleted', isEqualTo: isCompleted)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => TaskModel.fromMap(doc.data()))
          .toList();
    } catch (e) {
      print('Error getting tasks by status: $e');
      return [];
    }
  }


  Future<List<TaskModel>> getTasksDueToday() async {
    try {
      if (_currentUserId.isEmpty) return [];

      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);
      final endOfDay = DateTime(today.year, today.month, today.day, 23, 59, 59);

      final querySnapshot = await _firestore
          .collection('tasks')
          .where('userId', isEqualTo: _currentUserId)
          .where(
            'dueDate',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay),
          )
          .where('dueDate', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
          .orderBy('dueDate')
          .get();

      return querySnapshot.docs
          .map((doc) => TaskModel.fromMap(doc.data()))
          .toList();
    } catch (e) {
      print('Error getting tasks due today: $e');
      return [];
    }
  }


  Future<List<TaskModel>> getTasksDueTomorrow() async {
    try {
      if (_currentUserId.isEmpty) return [];

      final tomorrow = DateTime.now().add(const Duration(days: 1));
      final startOfTomorrow = DateTime(
        tomorrow.year,
        tomorrow.month,
        tomorrow.day,
      );
      final endOfTomorrow = DateTime(
        tomorrow.year,
        tomorrow.month,
        tomorrow.day,
        23,
        59,
        59,
      );

      final querySnapshot = await _firestore
          .collection('tasks')
          .where('userId', isEqualTo: _currentUserId)
          .where(
            'dueDate',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startOfTomorrow),
          )
          .where(
            'dueDate',
            isLessThanOrEqualTo: Timestamp.fromDate(endOfTomorrow),
          )
          .orderBy('dueDate')
          .get();

      return querySnapshot.docs
          .map((doc) => TaskModel.fromMap(doc.data()))
          .toList();
    } catch (e) {
      print('Error getting tasks due tomorrow: $e');
      return [];
    }
  }


  Future<List<TaskModel>> getTasksDueThisWeek() async {
    try {
      if (_currentUserId.isEmpty) return [];

      final now = DateTime.now();
      final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
      final endOfWeek = startOfWeek.add(const Duration(days: 6));

      final startOfWeekDate = DateTime(
        startOfWeek.year,
        startOfWeek.month,
        startOfWeek.day,
      );
      final endOfWeekDate = DateTime(
        endOfWeek.year,
        endOfWeek.month,
        endOfWeek.day,
        23,
        59,
        59,
      );

      final querySnapshot = await _firestore
          .collection('tasks')
          .where('userId', isEqualTo: _currentUserId)
          .where(
            'dueDate',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startOfWeekDate),
          )
          .where(
            'dueDate',
            isLessThanOrEqualTo: Timestamp.fromDate(endOfWeekDate),
          )
          .orderBy('dueDate')
          .get();

      return querySnapshot.docs
          .map((doc) => TaskModel.fromMap(doc.data()))
          .toList();
    } catch (e) {
      print('Error getting tasks due this week: $e');
      return [];
    }
  }


  Future<List<TaskModel>> getTasksByPriority(String priority) async {
    try {
      if (_currentUserId.isEmpty) return [];

      final querySnapshot = await _firestore
          .collection('tasks')
          .where('userId', isEqualTo: _currentUserId)
          .where('priority', isEqualTo: priority)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => TaskModel.fromMap(doc.data()))
          .toList();
    } catch (e) {
      print('Error getting tasks by priority: $e');
      return [];
    }
  }

 

  Future<List<TaskModel>> getOverdueTasks() async {
    try {
      if (_currentUserId.isEmpty) return [];

      final today = DateTime.now();
      final startOfToday = DateTime(today.year, today.month, today.day);

      final querySnapshot = await _firestore
          .collection('tasks')
          .where('userId', isEqualTo: _currentUserId)
          .where('dueDate', isLessThan: Timestamp.fromDate(startOfToday))
          .where('isCompleted', isEqualTo: false)
          .get();

      return querySnapshot.docs
          .map((doc) => TaskModel.fromMap(doc.data()))
          .toList();
    } catch (e) {
      print('Error getting overdue tasks: $e');
      return [];
    }
  }




  Future<List<String>> getAllTags() async {
    try {
      if (_currentUserId.isEmpty) return [];

      final allTasks = await loadTasks();
      final allTags = <String>{};

      for (final task in allTasks) {
        allTags.addAll(task.tags);
      }

      return allTags.toList()..sort();
    } catch (e) {
      print('Error getting all tags: $e');
      return [];
    }
  }


  Future<bool> toggleTaskCompletion(BuildContext context, String taskId) async {
    try {
      final task = await getTaskById(taskId);
      if (task == null) {
        if (context.mounted) {
          showSnackbar(context, 'Task not found');
        }
        return false;
      }

      if (task.isCompleted) {
        return await markAsIncomplete(context, taskId);
      } else {
        return await markAsComplete(context, taskId);
      }
    } catch (e) {
      print('Error toggling task completion: $e');
      if (context.mounted) {
        showSnackbar(context, 'Failed to toggle task status');
      }
      return false;
    }
  }
}
