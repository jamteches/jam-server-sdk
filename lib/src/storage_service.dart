import 'dart:typed_data';
import 'jam_client.dart';

/// File storage service for uploading, listing, and deleting files
/// 
/// All operations require project context.
/// 
/// Example:
/// ```dart
/// final jam = Jam('https://api.jamteches.com');
/// await jam.auth.login(username: 'john', password: 'pass');
/// 
/// // Upload a file
/// final result = await jam.storage.upload(
///   '/path/to/file.pdf',
///   projectId: 'my-project',
/// );
/// print('File URL: ${result['url']}');
/// 
/// // List files
/// final files = await jam.storage.list(projectId: 'my-project');
/// 
/// // Delete a file
/// await jam.storage.delete('filename.pdf');
/// ```
class StorageService {
  final JamClient _client;

  StorageService(this._client);

  /// Upload a file from file path
  /// 
  /// Returns file metadata with URL.
  Future<Map<String, dynamic>> upload(
    String filePath, {
    required String projectId,
  }) async {
    return await _client.postMultipart(
      '/api/storage',
      filePath,
      fields: {'project_id': projectId},
    );
  }

  /// Upload a file from bytes
  Future<Map<String, dynamic>> uploadBytes(
    Uint8List fileBytes,
    String filename, {
    required String projectId,
  }) async {
    return await _client.postMultipartBytes(
      '/api/storage',
      fileBytes,
      filename,
      fields: {'project_id': projectId},
    );
  }

  /// List all files in a project
  /// 
  /// Returns list of file metadata with URLs.
  Future<List<dynamic>> list({required String projectId}) async {
    final response = await _client.get(
      '/api/storage/list',
      queryParams: {'project_id': projectId},
    );
    
    if (response is List) {
      return response;
    }
    return response['files'] ?? response['data'] ?? [];
  }

  /// Delete a file by filename
  Future<Map<String, dynamic>> delete(String filename) async {
    return await _client.delete('/api/storage/$filename');
  }

  /// Get download URL for a file
  /// 
  /// Returns the full URL to download/access the file.
  String getDownloadUrl(String projectId, String filename) {
    return '${_client.baseUrl}/storage/$projectId/$filename';
  }

  /// Download file as bytes
  Future<Uint8List> downloadBytes(String projectId, String filename) async {
    return await _client.downloadBytes('/storage/$projectId/$filename');
  }

  // ==================== Storage Quota ====================

  /// Get current user's storage quota information
  /// 
  /// Returns:
  /// - `used_bytes`: Current storage usage in bytes
  /// - `quota_bytes`: Maximum allowed storage (-1 for unlimited)
  /// - `remaining_bytes`: Remaining storage space
  /// - `usage_percentage`: Percentage of quota used
  /// - `unlimited`: Whether user has unlimited storage
  Future<Map<String, dynamic>> getQuota() async {
    return await _client.get('/api/storage/quota');
  }

  /// Get storage quota tier configuration
  /// 
  /// Returns quota limits for each user tier (user, premium, admin)
  Future<Map<String, dynamic>> getQuotaConfig() async {
    return await _client.get('/api/storage/quota/config');
  }

  /// Get all users' storage usage (Admin only)
  Future<List<dynamic>> getAllUsersUsage() async {
    final response = await _client.get('/api/admin/storage/usage');
    if (response is List) return response;
    return response['data'] ?? [];
  }

  /// Get specific user's storage quota (Admin only)
  Future<Map<String, dynamic>> getUserQuota(String username) async {
    return await _client.get('/api/admin/storage/quota/$username');
  }

  /// Recalculate user's storage usage from files (Admin only)
  Future<Map<String, dynamic>> recalculateUserQuota(String username) async {
    return await _client.post('/api/admin/storage/quota/$username/recalculate');
  }
}
