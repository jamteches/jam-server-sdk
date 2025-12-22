import 'jam_client.dart';

/// Task management service for project task tracking
/// 
/// Example:
/// ```dart
/// final jam = Jam('https://api.jamteches.com');
/// await jam.auth.login(username: 'john', password: 'pass');
/// 
/// // Create a task
/// final task = await jam.tasks.create(
///   projectId: 'my-project',
///   title: 'Implement login',
///   description: 'Add login functionality',
///   priority: TaskPriority.high,
/// );
/// 
/// // Update task status
/// await jam.tasks.update(task['id'], status: TaskStatus.inProgress);
/// ```
class TaskService {
  final JamClient _client;

  TaskService(this._client);

  /// Create a new task
  Future<Map<String, dynamic>> create({
    required String projectId,
    required String title,
    String? description,
    String? assignedTo,
    TaskPriority priority = TaskPriority.medium,
    int? dueDate,
    List<String>? tags,
  }) async {
    return await _client.post('/api/tasks', body: {
      'project_id': projectId,
      'title': title,
      if (description != null) 'description': description,
      if (assignedTo != null) 'assigned_to': assignedTo,
      'priority': priority.value,
      if (dueDate != null) 'due_date': dueDate,
      if (tags != null) 'tags': tags,
    });
  }

  /// List tasks for a project
  Future<List<dynamic>> list({required String projectId}) async {
    final response = await _client.get('/api/tasks', queryParams: {
      'project_id': projectId,
    });
    if (response is List) return response;
    return response['data'] ?? [];
  }

  /// Update a task
  Future<Map<String, dynamic>> update(
    String taskId, {
    String? title,
    String? description,
    String? assignedTo,
    TaskStatus? status,
    TaskPriority? priority,
    int? dueDate,
    List<String>? tags,
  }) async {
    final body = <String, dynamic>{};
    if (title != null) body['title'] = title;
    if (description != null) body['description'] = description;
    if (assignedTo != null) body['assigned_to'] = assignedTo;
    if (status != null) body['status'] = status.value;
    if (priority != null) body['priority'] = priority.value;
    if (dueDate != null) body['due_date'] = dueDate;
    if (tags != null) body['tags'] = tags;
    
    return await _client.patch('/api/tasks/$taskId', body: body);
  }

  /// Delete a task
  Future<Map<String, dynamic>> delete(String taskId) async {
    return await _client.delete('/api/tasks/$taskId');
  }
}

/// Task status enum
enum TaskStatus {
  todo('todo'),
  inProgress('in_progress'),
  done('done');

  final String value;
  const TaskStatus(this.value);
}

/// Task priority enum
enum TaskPriority {
  low('low'),
  medium('medium'),
  high('high');

  final String value;
  const TaskPriority(this.value);
}
