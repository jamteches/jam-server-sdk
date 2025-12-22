import 'jam_client.dart';

/// Admin service for system administration
/// 
/// Includes backup, logs, and metrics management.
/// 
/// Example:
/// ```dart
/// final jam = Jam('https://api.jamteches.com');
/// await jam.auth.login(username: 'admin', password: 'pass');
/// 
/// // Create a backup
/// await jam.admin.triggerBackup();
/// 
/// // List backups
/// final backups = await jam.admin.listBackups();
/// 
/// // Get system metrics
/// final metrics = await jam.admin.getMetrics();
/// ```
class AdminService {
  final JamClient _client;

  AdminService(this._client);

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
