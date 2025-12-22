import 'jam_client.dart';
import 'collection.dart';

/// Database service for document CRUD operations
/// 
/// Provides both direct methods and fluent Collection API.
/// 
/// Example:
/// ```dart
/// final jam = Jam('https://api.jamteches.com');
/// await jam.auth.login(username: 'john', password: 'pass');
/// jam.setProject('my-project-id');
/// 
/// // Using Collection API (recommended)
/// final users = jam.db.collection('users');
/// await users.add({'name': 'John', 'age': 30});
/// final allUsers = await users.list();
/// 
/// // Using direct methods
/// await jam.db.create('users', {'name': 'Jane', 'age': 25}, projectId: 'my-project');
/// ```
class DbService {
  final JamClient _client;

  DbService(this._client);

  /// Get a collection reference for fluent API
  Collection collection(String name) => Collection(_client, name);

  // ==================== Document Operations ====================

  /// List documents in a collection
  /// 
  /// Supports filtering, sorting, and pagination:
  /// - `page`: Page number (default: 1)
  /// - `limit`: Items per page (default: 20)
  /// - `sort`: Sort field with direction (e.g., 'created_at:desc')
  /// - `mine`: Only show documents owned by current user
  /// - Filter operators: `_gt`, `_lt`, `_gte`, `_lte`, `_like`, `_ne`
  Future<Map<String, dynamic>> list(
    String collection, {
    required String projectId,
    int page = 1,
    int limit = 20,
    String? sort,
    bool? mine,
    Map<String, dynamic>? filters,
  }) async {
    final params = <String, String>{
      'project_id': projectId,
      'page': page.toString(),
      'limit': limit.toString(),
    };
    
    if (sort != null) params['_sort'] = sort;
    if (mine == true) params['mine'] = 'true';
    
    if (filters != null) {
      filters.forEach((key, value) {
        params[key] = value.toString();
      });
    }
    
    return await _client.get('/api/db/$collection', queryParams: params);
  }

  /// Get a single document by ID
  Future<Map<String, dynamic>> get(
    String collection,
    String id, {
    String? projectId,
  }) async {
    final params = <String, String>{};
    if (projectId != null) params['project_id'] = projectId;
    
    return await _client.get('/api/db/$collection/$id', queryParams: params.isNotEmpty ? params : null);
  }

  /// Create a new document
  /// 
  /// The `project_id` is required in the data body.
  Future<Map<String, dynamic>> create(
    String collection,
    Map<String, dynamic> data, {
    required String projectId,
  }) async {
    final body = Map<String, dynamic>.from(data);
    body['project_id'] = projectId;
    return await _client.post('/api/db/$collection', body: body);
  }

  /// Update an existing document (partial update)
  Future<Map<String, dynamic>> update(
    String collection,
    String id,
    Map<String, dynamic> data, {
    String? projectId,
  }) async {
    final params = <String, String>{};
    if (projectId != null) params['project_id'] = projectId;
    
    String path = '/api/db/$collection/$id';
    if (params.isNotEmpty) {
      path += '?${params.entries.map((e) => '${e.key}=${e.value}').join('&')}';
    }
    
    return await _client.patch(path, body: data);
  }

  /// Delete a document
  Future<Map<String, dynamic>> delete(
    String collection,
    String id, {
    String? projectId,
  }) async {
    final params = <String, String>{};
    if (projectId != null) params['project_id'] = projectId;
    
    return await _client.delete('/api/db/$collection/$id', queryParams: params.isNotEmpty ? params : null);
  }

  // ==================== Deep Path Access ====================

  /// Get nested value from document using dot notation path
  /// 
  /// Example: `getDeep('users', 'user123', 'profile/settings/theme')`
  Future<dynamic> getDeep(String collection, String id, String path) async {
    return await _client.get('/api/db/$collection/$id/$path');
  }

  /// Update nested value in document using dot notation path
  Future<dynamic> updateDeep(
    String collection,
    String id,
    String path,
    dynamic value,
  ) async {
    return await _client.patch('/api/db/$collection/$id/$path', body: value);
  }
}
