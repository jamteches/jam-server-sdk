import 'jam_client.dart';

/// A collection reference for performing CRUD operations on documents.
/// 
/// Provides a fluent API for database operations.
/// 
/// Example usage:
/// ```dart
/// final jam = Jam('https://api.jamteches.com');
/// await jam.auth.login(username: 'john', password: 'pass');
/// jam.setProject('my-project');
/// 
/// final products = jam.db.collection('products');
/// 
/// // Create a document
/// await products.add({'name': 'iPhone', 'price': 999});
/// 
/// // List documents with filters
/// final items = await products.list(
///   filters: {'price_gt': 500},
///   sort: 'price:desc',
///   limit: 10,
/// );
/// 
/// // Get a document
/// final product = await products.get('product_id');
/// 
/// // Update a document
/// await products.update('product_id', {'price': 899});
/// 
/// // Delete a document
/// await products.delete('product_id');
/// ```
class Collection {
  final JamClient _client;
  final String name;

  Collection(this._client, this.name);

  String get _projectId {
    final projectId = _client.currentProjectId;
    if (projectId == null) {
      throw JamException(
        statusCode: 400,
        message: 'Project ID is required. Call jam.setProject() first.',
      );
    }
    return projectId;
  }

  /// Add a new document to the collection.
  /// 
  /// Returns the created document with its generated ID.
  Future<Map<String, dynamic>> add(Map<String, dynamic> data) async {
    final body = Map<String, dynamic>.from(data);
    body['project_id'] = _projectId;
    
    try {
      return await _client.post('/api/db/$name', body: body);
    } on JamException {
      rethrow;
    } catch (e) {
      throw JamException(statusCode: 500, message: 'Failed to add document: $e');
    }
  }

  /// List documents in the collection with optional filtering.
  /// 
  /// [filters] supports various operators:
  /// - `price_lt`: Less than
  /// - `price_gt`: Greater than
  /// - `price_lte`: Less than or equal
  /// - `price_gte`: Greater than or equal
  /// - `name_like`: Contains (case-insensitive)
  /// - `status_ne`: Not equal
  /// 
  /// [sort]: Sort field with direction (e.g., 'price:asc' or 'created_at:desc')
  /// [limit]: Maximum number of results (default: 20)
  /// [page]: Page number for pagination (default: 1)
  /// [mine]: Only show documents owned by current user
  Future<Map<String, dynamic>> list({
    Map<String, dynamic>? filters,
    String? sort,
    int limit = 20,
    int page = 1,
    bool? mine,
  }) async {
    final params = <String, String>{
      'project_id': _projectId,
      'limit': limit.toString(),
      'page': page.toString(),
    };
    
    if (sort != null) params['_sort'] = sort;
    if (mine == true) params['mine'] = 'true';
    
    if (filters != null) {
      filters.forEach((key, value) {
        params[key] = value.toString();
      });
    }
    
    try {
      return await _client.get('/api/db/$name', queryParams: params);
    } on JamException {
      rethrow;
    } catch (e) {
      throw JamException(statusCode: 500, message: 'Failed to list documents: $e');
    }
  }

  /// Get a specific document by its ID.
  Future<Map<String, dynamic>> get(String id) async {
    try {
      return await _client.get('/api/db/$name/$id', queryParams: {
        'project_id': _projectId,
      });
    } on JamException {
      rethrow;
    } catch (e) {
      throw JamException(statusCode: 500, message: 'Failed to get document: $e');
    }
  }

  /// Update an existing document (partial update).
  /// 
  /// Only the fields specified in [data] will be updated.
  Future<Map<String, dynamic>> update(String id, Map<String, dynamic> data) async {
    try {
      return await _client.patch(
        '/api/db/$name/$id?project_id=$_projectId',
        body: data,
      );
    } on JamException {
      rethrow;
    } catch (e) {
      throw JamException(statusCode: 500, message: 'Failed to update document: $e');
    }
  }

  /// Delete a document by its ID.
  Future<Map<String, dynamic>> delete(String id) async {
    try {
      return await _client.delete('/api/db/$name/$id', queryParams: {
        'project_id': _projectId,
      });
    } on JamException {
      rethrow;
    } catch (e) {
      throw JamException(statusCode: 500, message: 'Failed to delete document: $e');
    }
  }

  /// Get nested value from document using path
  /// 
  /// Example: `getDeep('user123', 'profile/settings/theme')`
  Future<dynamic> getDeep(String id, String path) async {
    try {
      return await _client.get('/api/db/$name/$id/$path');
    } on JamException {
      rethrow;
    } catch (e) {
      throw JamException(statusCode: 500, message: 'Failed to get nested value: $e');
    }
  }

  /// Update nested value in document using path
  Future<dynamic> updateDeep(String id, String path, dynamic value) async {
    try {
      return await _client.patch('/api/db/$name/$id/$path', body: value);
    } on JamException {
      rethrow;
    } catch (e) {
      throw JamException(statusCode: 500, message: 'Failed to update nested value: $e');
    }
  }
}
