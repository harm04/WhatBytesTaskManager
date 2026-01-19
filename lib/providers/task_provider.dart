
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:whatbytes_task_manager/features/tasks/controller/task_controller.dart';
import 'package:whatbytes_task_manager/models/task_model.dart';

final taskControllerProvider = Provider<TaskController>((ref) {
  return TaskController();
});


final taskNotifierProvider =
    AsyncNotifierProvider<TaskNotifier, List<TaskModel>>(() {
      return TaskNotifier();
    });


final tasksDueTodayProvider = FutureProvider<List<TaskModel>>((ref) async {
  final taskController = ref.read(taskControllerProvider);
  return await taskController.getTasksDueToday();
});


final tasksDueTomorrowProvider = FutureProvider<List<TaskModel>>((ref) async {
  final taskController = ref.read(taskControllerProvider);
  return await taskController.getTasksDueTomorrow();
});


final tasksDueThisWeekProvider = FutureProvider<List<TaskModel>>((ref) async {
  final taskController = ref.read(taskControllerProvider);
  return await taskController.getTasksDueThisWeek();
});


final completedTasksProvider = FutureProvider<List<TaskModel>>((ref) async {
  final taskController = ref.read(taskControllerProvider);
  return await taskController.getTasksByStatus(true);
});


final pendingTasksProvider = FutureProvider<List<TaskModel>>((ref) async {
  final taskController = ref.read(taskControllerProvider);
  return await taskController.getTasksByStatus(false);
});


final allTagsProvider = FutureProvider<List<String>>((ref) async {
  final taskController = ref.read(taskControllerProvider);
  return await taskController.getAllTags();
});