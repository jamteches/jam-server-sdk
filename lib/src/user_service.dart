import 'jam_client.dart';

/// User management service (Admin only)
/// 
/// Manage users, roles, and statistics.
/// 
/// Example:
/// ```dart
/// final jam = Jam('https://api.jamteches.com');
/// await jam.auth.login(username: 'admin', password: 'pass');
/// 
/// // List all users
/// final users = await jam.users.list();
/// 
/// // Update user role
/// await jam.users.update('john', role: 'admin');
/// 
/// // Get user statistics
/// final stats = await jam.users.getStats();
/// ```
class UserService {
  final JamClient _client;

  UserService(this._client);

  /// List all users (Admin only)
  Future<List<dynamic>> list() async {
    final response = await _client.get('/api/users');
    if (response is List) return response;
    return response['data'] ?? [];
  }

  /// Get user details
  Future<Map<String, dynamic>> get(String username) async {
    return await _client.get('/api/users/$username');
  }

  /// Update user (Admin only)
  Future<Map<String, dynamic>> update(
    String username, {
    String? email,
    String? role,
    String? password,
  }) async {
    final body = <String, dynamic>{};
    if (email != null) body['email'] = email;
    if (role != null) body['role'] = role;
    if (password != null) body['password'] = password;
    
    return await _client.patch('/api/users/$username', body: body);
  }

  /// Delete user (Admin only)
  Future<Map<String, dynamic>> delete(String username) async {
    return await _client.delete('/api/users/$username');
  }

  /// Get user statistics (Admin only)
  Future<Map<String, dynamic>> getStats() async {
    return await _client.get('/api/users/stats');
  }

  /// Change user password
  Future<Map<String, dynamic>> changePassword(
    String username, {
    required String oldPassword,
    required String newPassword,
  }) async {
    return await _client.post('/api/users/$username/password', body: {
      'old_password': oldPassword,
      'new_password': newPassword,
    });
  }
}
