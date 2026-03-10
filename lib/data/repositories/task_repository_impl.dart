import '../../domain/entities/task_entity.dart';
import '../../domain/repositories/task_repository.dart';
import '../datasources/firebase_task_datasource.dart';
import '../models/task_model.dart';

class TaskRepositoryImpl implements TaskRepository {
  final FirebaseTaskDataSource _dataSource;

  TaskRepositoryImpl(this._dataSource);

  @override
  Future<List<TaskEntity>> getTasks(String userId, String idToken) async {
    return await _dataSource.getTasks(userId, idToken);
  }

  @override
  Future<TaskEntity> addTask(TaskEntity task, String idToken) async {
    final model = TaskModel.fromEntity(task);
    return await _dataSource.addTask(model, idToken);
  }

  @override
  Future<TaskEntity> updateTask(TaskEntity task, String idToken) async {
    final model = TaskModel.fromEntity(task);
    return await _dataSource.updateTask(model, idToken);
  }

  @override
  Future<void> deleteTask(
      String taskId, String userId, String idToken) async {
    await _dataSource.deleteTask(taskId, userId, idToken);
  }
}
