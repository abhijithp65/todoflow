import '../entities/task_entity.dart';

abstract class TaskRepository {
  Future<List<TaskEntity>> getTasks(String userId, String idToken);
  Future<TaskEntity> addTask(TaskEntity task, String idToken);
  Future<TaskEntity> updateTask(TaskEntity task, String idToken);
  Future<void> deleteTask(String taskId, String userId, String idToken);
}
