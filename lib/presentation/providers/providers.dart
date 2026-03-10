import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../../data/datasources/firebase_task_datasource.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../data/repositories/task_repository_impl.dart';
import '../../domain/entities/task_entity.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/repositories/task_repository.dart';

final httpClientProvider = Provider<http.Client>((ref) {
  final client = http.Client();
  ref.onDispose(client.close);
  return client;
});

final firebaseTaskDataSourceProvider = Provider<FirebaseTaskDataSource>((ref) {
  return FirebaseTaskDataSource(client: ref.watch(httpClientProvider));
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl();
});

final taskRepositoryProvider = Provider<TaskRepository>((ref) {
  return TaskRepositoryImpl(ref.watch(firebaseTaskDataSourceProvider));
});

final authStateProvider = StreamProvider<UserEntity?>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges;
});

final currentUserProvider = Provider<UserEntity?>((ref) {
  return ref
      .watch(authStateProvider)
      .when(data: (user) => user, loading: () => null, error: (_, __) => null);
});

class AuthState {
  final bool isLoading;
  final String? error;

  const AuthState({this.isLoading = false, this.error});

  AuthState copyWith({bool? isLoading, String? error}) {
    return AuthState(isLoading: isLoading ?? this.isLoading, error: error);
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _authRepository;

  AuthNotifier(this._authRepository) : super(const AuthState());

  Future<bool> signIn(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _authRepository.signInWithEmailAndPassword(email, password);
      state = state.copyWith(isLoading: false);
      return true;
    } on Exception catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: _parseAuthError(e.toString()),
      );
      return false;
    }
  }

  Future<bool> signUp(String email, String password, String name) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _authRepository.signUpWithEmailAndPassword(email, password, name);
      state = state.copyWith(isLoading: false);
      return true;
    } on Exception catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: _parseAuthError(e.toString()),
      );
      return false;
    }
  }

  Future<bool> signInWithGoogle() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final user = await _authRepository.signInWithGoogle();
      state = state.copyWith(isLoading: false);
      return user != null;
    } on Exception catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: _parseAuthError(e.toString()),
      );
      return false;
    }
  }

  Future<void> signOut() async {
    await _authRepository.signOut();
  }

  void clearError() {
    state = state.copyWith(error: null);
  }

  String _parseAuthError(String error) {
    if (error.contains('user-not-found')) {
      return 'No account found with this email.';
    }
    if (error.contains('wrong-password')) return 'Incorrect password.';
    if (error.contains('email-already-in-use')) {
      return 'An account already exists with this email.';
    }
    if (error.contains('weak-password')) return 'Password is too weak.';
    if (error.contains('invalid-email')) return 'Invalid email address.';
    if (error.contains('network-request-failed')) {
      return 'Network error. Check your connection.';
    }
    return 'Authentication failed. Please try again.';
  }
}

final authNotifierProvider = StateNotifierProvider<AuthNotifier, AuthState>((
  ref,
) {
  return AuthNotifier(ref.watch(authRepositoryProvider));
});

class TaskEntityState {
  final TaskEntity task;
  final bool isDeleting;
  final bool isUpdating;

  const TaskEntityState({
    required this.task,
    this.isDeleting = false,
    this.isUpdating = false,
  });

  TaskEntityState copyWith({
    TaskEntity? task,
    bool? isDeleting,
    bool? isUpdating,
  }) {
    return TaskEntityState(
      task: task ?? this.task,
      isDeleting: isDeleting ?? this.isDeleting,
      isUpdating: isUpdating ?? this.isUpdating,
    );
  }
}

class TaskNotifier extends StateNotifier<AsyncValue<List<TaskEntityState>>> {
  final TaskRepository _taskRepository;
  final AuthRepository _authRepository;

  TaskNotifier(this._taskRepository, this._authRepository)
    : super(const AsyncValue.loading()) {
    fetchTasks();
  }

  Future<void> fetchTasks() async {
    state = const AsyncValue.loading();
    try {
      final user = _authRepository.currentUser;
      if (user == null) {
        state = const AsyncValue.data([]);
        return;
      }
      final token = await _authRepository.getIdToken();
      if (token == null) throw Exception('Not authenticated');
      final tasks = await _taskRepository.getTasks(user.uid, token);
      tasks.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      state = AsyncValue.data(
        tasks.map((t) => TaskEntityState(task: t)).toList(),
      );
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addTask(TaskEntity task) async {
    try {
      final token = await _authRepository.getIdToken();
      if (token == null) throw Exception('Not authenticated');
      final newTask = await _taskRepository.addTask(task, token);
      state.whenData((tasks) {
        state = AsyncValue.data([TaskEntityState(task: newTask), ...tasks]);
      });
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> updateTask(TaskEntity task) async {
    _setTaskLoading(task.id, isUpdating: true);
    try {
      final token = await _authRepository.getIdToken();
      if (token == null) throw Exception('Not authenticated');
      final updated = await _taskRepository.updateTask(task, token);
      state.whenData((tasks) {
        state = AsyncValue.data(
          tasks
              .map(
                (t) => t.task.id == updated.id
                    ? TaskEntityState(task: updated)
                    : t,
              )
              .toList(),
        );
      });
    } catch (e, st) {
      _setTaskLoading(task.id, isUpdating: false);
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> toggleTask(TaskEntity task) async {
    await updateTask(
      task.copyWith(isCompleted: !task.isCompleted, updatedAt: DateTime.now()),
    );
  }

  Future<void> deleteTask(String taskId, String userId) async {
    _setTaskLoading(taskId, isDeleting: true);
    try {
      final token = await _authRepository.getIdToken();
      if (token == null) throw Exception('Not authenticated');
      await _taskRepository.deleteTask(taskId, userId, token);
      state.whenData((tasks) {
        state = AsyncValue.data(
          tasks.where((t) => t.task.id != taskId).toList(),
        );
      });
    } catch (e, st) {
      _setTaskLoading(taskId, isDeleting: false);
      state = AsyncValue.error(e, st);
    }
  }

  void _setTaskLoading(String taskId, {bool? isDeleting, bool? isUpdating}) {
    state.whenData((tasks) {
      state = AsyncValue.data(
        tasks.map((t) {
          if (t.task.id == taskId) {
            return t.copyWith(isDeleting: isDeleting, isUpdating: isUpdating);
          }
          return t;
        }).toList(),
      );
    });
  }
}

final tasksProvider =
    StateNotifierProvider<TaskNotifier, AsyncValue<List<TaskEntityState>>>((
      ref,
    ) {
      final taskRepo = ref.watch(taskRepositoryProvider);
      final authRepo = ref.watch(authRepositoryProvider);
      return TaskNotifier(taskRepo, authRepo);
    });

enum TaskFilter { all, active, completed }

final taskFilterProvider = StateProvider<TaskFilter>((ref) => TaskFilter.all);

final filteredTasksProvider = Provider<AsyncValue<List<TaskEntityState>>>((
  ref,
) {
  final filter = ref.watch(taskFilterProvider);
  final tasksAsync = ref.watch(tasksProvider);

  return tasksAsync.whenData((tasks) {
    switch (filter) {
      case TaskFilter.active:
        return tasks.where((t) => !t.task.isCompleted).toList();
      case TaskFilter.completed:
        return tasks.where((t) => t.task.isCompleted).toList();
      case TaskFilter.all:
        return tasks;
    }
  });
});

final taskStatsProvider = Provider<({int total, int completed, int active})>((
  ref,
) {
  final tasksAsync = ref.watch(tasksProvider);
  return tasksAsync.when(
    data: (tasks) => (
      total: tasks.length,
      completed: tasks.where((t) => t.task.isCompleted).length,
      active: tasks.where((t) => !t.task.isCompleted).length,
    ),
    loading: () => (total: 0, completed: 0, active: 0),
    error: (_, __) => (total: 0, completed: 0, active: 0),
  );
});
