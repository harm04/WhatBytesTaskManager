import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:whatbytes_task_manager/features/tasks/views/add_task.dart';
import 'package:whatbytes_task_manager/features/tasks/widgets/task_card.dart';
import 'package:whatbytes_task_manager/models/task_model.dart';
import 'package:whatbytes_task_manager/providers/auth_provider.dart';
import 'package:whatbytes_task_manager/providers/task_provider.dart';

class AllTasksScreen extends ConsumerStatefulWidget {
  const AllTasksScreen({super.key});

  @override
  ConsumerState<AllTasksScreen> createState() => _AllTasksScreenState();
}

enum TaskStatus { all, completed, incomplete }

class _AllTasksScreenState extends ConsumerState<AllTasksScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedPriorityFilter = 'All';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<TaskModel> _filterTasksByPriority(List<TaskModel> tasks) {
    if (_selectedPriorityFilter == 'All') {
      return tasks;
    }
    return tasks
        .where((task) => task.priority == _selectedPriorityFilter)
        .toList();
  }

  List<TaskModel> _getTasksByStatus(List<TaskModel> tasks, TaskStatus status) {
    switch (status) {
      case TaskStatus.all:
        return tasks;
      case TaskStatus.completed:
        return tasks.where((task) => task.isCompleted).toList();
      case TaskStatus.incomplete:
        return tasks.where((task) => !task.isCompleted).toList();
    }
  }

  Map<String, List<TaskModel>> _groupTasksByDueDate(List<TaskModel> tasks) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final startOfWeek = today.subtract(Duration(days: today.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 6));

    final todayTasks = <TaskModel>[];
    final tomorrowTasks = <TaskModel>[];
    final thisWeekTasks = <TaskModel>[];
    final otherTasks = <TaskModel>[];

    for (final task in tasks) {
      final taskDate = DateTime(
        task.dueDate.year,
        task.dueDate.month,
        task.dueDate.day,
      );

      if (taskDate.isAtSameMomentAs(today)) {
        todayTasks.add(task);
      } else if (taskDate.isAtSameMomentAs(tomorrow)) {
        tomorrowTasks.add(task);
      } else if (taskDate.isAfter(
            startOfWeek.subtract(const Duration(days: 1)),
          ) &&
          taskDate.isBefore(endOfWeek.add(const Duration(days: 1)))) {
        thisWeekTasks.add(task);
      } else {
        otherTasks.add(task);
      }
    }

    todayTasks.sort((a, b) => a.dueDate.compareTo(b.dueDate));
    tomorrowTasks.sort((a, b) => a.dueDate.compareTo(b.dueDate));
    thisWeekTasks.sort((a, b) => a.dueDate.compareTo(b.dueDate));
    otherTasks.sort((a, b) => a.dueDate.compareTo(b.dueDate));

    return {
      'Today': todayTasks,
      'Tomorrow': tomorrowTasks,
      'This Week': thisWeekTasks,
      'Other': otherTasks,
    };
  }

  Widget _buildTaskSection(String title, List<TaskModel> tasks) {
    if (tasks.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            '$title (${tasks.length})',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
        ),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: tasks.length,
          itemBuilder: (context, index) => TaskCard(task: tasks[index]),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildAllTasksView(List<TaskModel> tasks) {
    final groupedTasks = _groupTasksByDueDate(tasks);

    if (tasks.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.task_alt, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No tasks found',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            SizedBox(height: 8),
            Text(
              'Tap the + button to create your first task',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        ref.read(taskNotifierProvider.notifier).refreshTasks();
      },
      child: SingleChildScrollView(
        child: Column(
          children: [
            _buildTaskSection('Today', groupedTasks['Today']!),
            _buildTaskSection('Tomorrow', groupedTasks['Tomorrow']!),
            _buildTaskSection('This Week', groupedTasks['This Week']!),
            _buildTaskSection('Other', groupedTasks['Other']!),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _buildTasksTabView(List<TaskModel> tasks, TaskStatus status) {
    final filteredTasks = _getTasksByStatus(tasks, status);

    if (filteredTasks.isEmpty) {
      String message = '';
      switch (status) {
        case TaskStatus.all:
          message = 'No tasks found';
          break;
        case TaskStatus.completed:
          message = 'No completed tasks';
          break;
        case TaskStatus.incomplete:
          message = 'No incomplete tasks';
          break;
      }

      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.task_alt, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              message,
              style: const TextStyle(fontSize: 18, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    if (status == TaskStatus.all) {
      return _buildAllTasksView(filteredTasks);
    } else {
      return RefreshIndicator(
        onRefresh: () async {
          ref.read(taskNotifierProvider.notifier).refreshTasks();
        },
        child: ListView.builder(
          itemCount: filteredTasks.length,
          itemBuilder: (context, index) => TaskCard(task: filteredTasks[index]),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final tasksAsyncValue = ref.watch(taskNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('WhatBytes Task Manager'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            onSelected: (value) {
              setState(() {
                _selectedPriorityFilter = value;
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'All',
                child: Row(
                  children: [
                    Icon(Icons.all_inclusive),
                    SizedBox(width: 8),
                    Text('All Priorities'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'High',
                child: Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: const BoxDecoration(shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 8),
                    const Text('High Priority'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'Medium',
                child: Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: const BoxDecoration(shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 8),
                    const Text('Medium Priority'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'Low',
                child: Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: const BoxDecoration(shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 8),
                    const Text('Low Priority'),
                  ],
                ),
              ),
            ],
          ),

          PopupMenuButton(
            onSelected: (value) {
              if (value == 'logout') {
                ref.read(authStateProvider.notifier).signOut();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Logout'),
                  ],
                ),
              ),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'Completed'),
            Tab(text: 'Incomplete'),
          ],
        ),
      ),
      body: authState.when(
        data: (user) {
          if (user == null) {
            return const Center(child: Text('No user data'));
          }

          return tasksAsyncValue.when(
            data: (tasks) {
              final filteredTasks = _filterTasksByPriority(tasks);

              return TabBarView(
                controller: _tabController,
                children: [
                  _buildTasksTabView(filteredTasks, TaskStatus.all),
                  _buildTasksTabView(filteredTasks, TaskStatus.completed),
                  _buildTasksTabView(filteredTasks, TaskStatus.incomplete),
                ],
              );
            },
            loading: () {
              return const Center(child: CircularProgressIndicator());
            },
            error: (error, stack) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error, size: 64),
                    const SizedBox(height: 16),
                    Text('Error loading tasks: $error'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        ref.read(taskNotifierProvider.notifier).refreshTasks();
                      },
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              );
            },
          );
        },
        loading: () {
          return const Center(child: CircularProgressIndicator());
        },
        error: (error, stack) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error, size: 64),
                const SizedBox(height: 16),
                Text('Error: $error', textAlign: TextAlign.center),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddTasksScreen()),
          );

          if (result == true) {
            ref.read(taskNotifierProvider.notifier).refreshTasks();
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
