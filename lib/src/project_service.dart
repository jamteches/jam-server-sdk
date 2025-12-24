import 'jam_client.dart';

/// Project management service
/// 
/// Create, update, and manage projects and their members.
/// 
/// Example:
/// ```dart
/// final jam = Jam('https://api.jamteches.com');
/// await jam.auth.login(username: 'john', password: 'pass');
/// 
/// // Create a project
/// final project = await jam.projects.create(
///   name: 'My App',
///   description: 'Mobile application project',
///   members: ['alice', 'bob'],
/// );
/// 
/// // Set as current project
/// jam.setProject(project['id']);
/// 
/// // List all projects
/// final projects = await jam.projects.list();
/// ```
class ProjectService {
  final JamClient _client;

  ProjectService(this._client);

  /// Create a new project
  Future<Map<String, dynamic>> create({
    required String name,
    String? description,
    List<String>? members,
  }) async {
    return await _client.post('/api/projects', body: {
      'name': name,
      if (description != null) 'description': description,
      if (members != null) 'members': members,
    });
  }

  /// List all projects (user's projects or all for admin)
  Future<List<dynamic>> list() async {
    final response = await _client.get('/api/projects');
    if (response is List) return response;
    return response['data'] ?? [];
  }

  /// Get project details
  Future<Map<String, dynamic>> get(String projectId) async {
    return await _client.get('/api/projects/$projectId');
  }

  /// Update project
  Future<Map<String, dynamic>> update(
    String projectId, {
    String? name,
    String? description,
    List<String>? members,
    String? status,
  }) async {
    final body = <String, dynamic>{};
    if (name != null) body['name'] = name;
    if (description != null) body['description'] = description;
    if (members != null) body['members'] = members;
    if (status != null) body['status'] = status;
    
    return await _client.patch('/api/projects/$projectId', body: body);
  }

  /// Delete project and all its data
  Future<Map<String, dynamic>> delete(String projectId) async {
    return await _client.delete('/api/projects/$projectId');
  }

  // ==================== API Keys ====================

  /// Generate a new API key for a project
  /// 
  /// ⚠️ The full key is only returned once!
  Future<Map<String, dynamic>> generateApiKey(
    String projectId, {
    required String name,
    List<String>? permissions,
    int expiresInDays = 0,
  }) async {
    return await _client.post('/api/projects/$projectId/keys', body: {
      'name': name,
      'permissions': permissions ?? ['read', 'write'],
      'expires_in': expiresInDays,
    });
  }

  /// List all API keys for a project (keys are hidden)
  Future<List<dynamic>> listApiKeys(String projectId) async {
    final response = await _client.get('/api/projects/$projectId/keys');
    if (response is List) return response;
    return response['data'] ?? [];
  }

  /// Revoke (delete) an API key
  Future<Map<String, dynamic>> revokeApiKey(String projectId, String keyId) async {
    return await _client.delete('/api/projects/$projectId/keys/$keyId');
  }

  /// Toggle API key active status
  Future<Map<String, dynamic>> toggleApiKey(
    String projectId,
    String keyId, {
    required bool isActive,
  }) async {
    return await _client.patch('/api/projects/$projectId/keys/$keyId/toggle', body: {
      'is_active': isActive,
    });
  }

  // ==================== Webhooks ====================

  /// Create a webhook for project events
  Future<Map<String, dynamic>> createWebhook(
    String projectId, {
    required String url,
    String? collection,
    List<String>? events,
    String? secret,
  }) async {
    return await _client.post('/api/projects/$projectId/webhooks', body: {
      'url': url,
      if (collection != null) 'collection': collection,
      'events': events ?? ['create', 'update', 'delete'],
      if (secret != null) 'secret': secret,
    });
  }

  /// List webhooks for a project
  Future<List<dynamic>> listWebhooks(String projectId) async {
    final response = await _client.get('/api/projects/$projectId/webhooks');
    if (response is List) return response;
    return response['data'] ?? [];
  }

  /// Delete a webhook
  Future<Map<String, dynamic>> deleteWebhook(String projectId, String webhookId) async {
    return await _client.delete('/api/projects/$projectId/webhooks/$webhookId');
  }
}
