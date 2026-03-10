import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/constants/app_constants.dart';
import '../models/task_model.dart';

class FirebaseTaskDataSource {
  final http.Client _client;

  FirebaseTaskDataSource({http.Client? client})
    : _client = client ?? http.Client();

  String _buildUrl(String path, String idToken) {
    return '${AppConstants.firebaseDbUrl}/$path.json?auth=$idToken';
  }

  Future<List<TaskModel>> getTasks(String userId, String idToken) async {
    final url = _buildUrl('${AppConstants.tasksEndpoint}/$userId', idToken);
    final response = await _client.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data == null) return [];

      final tasksMap = data as Map<dynamic, dynamic>;
      return tasksMap.entries
          .map((e) => TaskModel.fromJson(e.key as String, e.value))
          .toList();
    }
    throw Exception('Failed to fetch tasks: ${response.statusCode}');
  }

  Future<TaskModel> addTask(TaskModel task, String idToken) async {
    final url = _buildUrl(
      '${AppConstants.tasksEndpoint}/${task.userId}/${task.id}',
      idToken,
    );
    final response = await _client.put(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(task.toJson()),
    );

    if (response.statusCode == 200) {
      return task;
    }
    throw Exception('Failed to add task: ${response.statusCode}');
  }

  Future<TaskModel> updateTask(TaskModel task, String idToken) async {
    final url = _buildUrl(
      '${AppConstants.tasksEndpoint}/${task.userId}/${task.id}',
      idToken,
    );
    final response = await _client.patch(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(task.toJson()),
    );

    if (response.statusCode == 200) {
      return task;
    }
    throw Exception('Failed to update task: ${response.statusCode}');
  }

  Future<void> deleteTask(String taskId, String userId, String idToken) async {
    final url = _buildUrl(
      '${AppConstants.tasksEndpoint}/$userId/$taskId',
      idToken,
    );
    final response = await _client.delete(Uri.parse(url));

    if (response.statusCode != 200) {
      throw Exception('Failed to delete task: ${response.statusCode}');
    }
  }
}
