import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:whatbytes_task_manager/features/auth/controller/auth_controller.dart';
import 'package:whatbytes_task_manager/models/user_model.dart';

final authControllerProvider = Provider((ref) => AuthController());

final authStateProvider = AsyncNotifierProvider<AuthNotifier, UserModel?>(
  () => AuthNotifier(),
);
