import 'models.dart';
import 'jam_client.dart';

/// Admin service for system administration
/// 
/// Includes backup, logs, metrics, user management, and storage management.
/// 
/// Example:
/// ```dart
/// final jam = Jam('https://api.jamteches.com');
/// await jam.auth.login(username: 'admin', password: 'pass');
/// 
/// // Manage Users
/// final users = await jam.admin.getUnifiedUsers();
/// await jam.admin.updateUserTier(users.first.id, 'vip');
/// 
/// // Manage Storage
/// final usage = await jam.admin.getStorageUsageSummary();
/// ```
class AdminService {
  final JamClient _client;

  AdminService(this._client);

  // ==================== User Management ====================

  /// Get unified users (Admin only)
  Future<List<UnifiedUser>> getUnifiedUsers() async {
    final response = await _client.get('/api/admin/users');
    if (response is List) {
      return response.map((json) => UnifiedUser.fromJson(json)).toList();
    }
    return [];
  }

  /// Update user tier (Admin only)
  Future<void> updateUserTier(String userId, String tier, {int customQuota = 0}) async {
    await _client.patch(
      '/api/admin/users/$userId/tier',
      body: {
        'tier': tier,
        if (customQuota > 0) 'custom_quota': customQuota,
      },
    );
  }

  /// Delete user (Admin only)
  Future<void> deleteUser(String userId) async {
    await _client.delete('/api/admin/users/$userId');
  }

  // ==================== Storage Administration ====================

  /// Get storage usage summary (Admin only)
  Future<Map<String, dynamic>> getStorageUsageSummary() async {
    return await _client.get('/api/admin/storage/summary');
  }

  /// Get files for a project (Admin only)
  Future<List<JamFile>> getProjectFiles(String projectId) async {
    final response = await _client.get('/api/admin/storage/projects/$projectId/files');
    if (response is List) {
      return response.map((e) => JamFile.fromJson(e)).toList();
    }
    return [];
  }

  /// Delete file (Admin only)
  Future<void> deleteFile(String fileId) async {
    await _client.delete('/api/admin/storage/files/$fileId');
  }

  // ==================== Backup ====================

  /// Trigger a manual backup (Admin only)
  Future<Map<String, dynamic>> triggerBackup() async {
    return await _client.post('/api/admin/backups');
  }

  /// List available backups (Admin only)
  Future<List<dynamic>> listBackups() async {
    final response = await _client.get('/api/admin/backups');
    if (response is List) return response;
    return response['data'] ?? [];
  }

  /// Get backup download URL
  String getBackupDownloadUrl(String filename) {
    return '${_client.baseUrl}/api/admin/backups/$filename';
  }

  // ==================== Logs ====================

  /// Get system logs (Admin only)
  Future<Map<String, dynamic>> getLogs({
    int? limit,
    String? level,
  }) async {
    final params = <String, String>{};
    if (limit != null) params['limit'] = limit.toString();
    if (level != null) params['level'] = level;
    
    return await _client.get('/api/logs', queryParams: params.isNotEmpty ? params : null);
  }

  /// Clear system logs (Admin only)
  Future<Map<String, dynamic>> clearLogs() async {
    return await _client.delete('/api/logs');
  }

  // ==================== Metrics ====================

  /// Get system metrics (Admin only)
  Future<Map<String, dynamic>> getMetrics() async {
    return await _client.get('/api/metrics');
  }

  // ==================== Health Check ====================

  /// Check server health
  Future<Map<String, dynamic>> healthCheck() async {
    return await _client.get('/health');
  }
}
