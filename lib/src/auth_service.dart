import 'jam_client.dart';

/// Authentication and user session management
/// 
/// Handles login, registration, password recovery, and email verification.
/// 
/// Example:
/// ```dart
/// final jam = Jam('https://api.jamteches.com');
/// 
/// // Register with email verification
/// await jam.auth.sendOTP(email: 'user@example.com');
/// await jam.auth.register(
///   username: 'john',
///   email: 'user@example.com',
///   password: 'SecurePass123!',
///   otp: '123456',
/// );
/// 
/// // Login
/// final result = await jam.auth.login(username: 'john', password: 'SecurePass123!');
/// print('Logged in as: ${result['username']}');
/// ```
class AuthService {
  final JamClient _client;

  AuthService(this._client);

  // ==================== Registration ====================

  /// Send OTP to email for registration
  Future<Map<String, dynamic>> sendOTP({required String email}) async {
    return await _client.post('/api/send-otp', body: {'email': email});
  }

  /// Register a new user with email verification
  /// 
  /// Requires OTP sent via [sendOTP] method.
  Future<Map<String, dynamic>> register({
    required String username,
    required String password,
    required String email,
    required String otp,
  }) async {
    return await _client.post('/api/register', body: {
      'username': username,
      'password': password,
      'email': email,
      'otp': otp,
    });
  }

  // ==================== Login ====================

  /// Login with username and password
  /// 
  /// Returns user info with token. Token is automatically set in client.
  Future<Map<String, dynamic>> login({
    required String username,
    required String password,
  }) async {
    final response = await _client.post('/api/login', body: {
      'username': username,
      'password': password,
    });

    if (response['token'] != null) {
      _client.setToken(response['token']);
    }

    return response;
  }

  /// Verify JWT token is still valid
  Future<Map<String, dynamic>> verifyToken() async {
    return await _client.get('/api/auth/verify');
  }

  /// Logout and clear session
  void logout() {
    _client.clearToken();
    _client.clearProject();
  }

  // ==================== Email Verification ====================

  /// Verify email address with token
  Future<void> verifyEmail(String token) async {
    await _client.get('/api/verify-email', queryParams: {'token': token});
  }

  /// Resend email verification
  Future<Map<String, dynamic>> resendVerification({required String email}) async {
    return await _client.post('/api/resend-verification', body: {'email': email});
  }

  // ==================== Password Recovery ====================

  /// Request password reset email
  Future<Map<String, dynamic>> forgotPassword({required String email}) async {
    return await _client.post('/api/forgot-password', body: {'email': email});
  }

  /// Reset password with token
  Future<Map<String, dynamic>> resetPassword({
    required String token,
    required String newPassword,
  }) async {
    return await _client.post('/api/reset-password', body: {
      'token': token,
      'new_password': newPassword,
    });
  }

  /// Change password (for logged-in user)
  Future<Map<String, dynamic>> changePassword({
    required String username,
    required String oldPassword,
    required String newPassword,
  }) async {
    return await _client.post('/api/users/$username/password', body: {
      'old_password': oldPassword,
      'new_password': newPassword,
    });
  }

  // ==================== OAuth ====================

  /// Get Google OAuth login URL
  String getGoogleLoginUrl() {
    return '${_client.baseUrl}/api/auth/google/login';
  }

  // ==================== Session State ====================

  /// Check if user is logged in
  bool get isLoggedIn => _client.token != null;

  /// Get current token
  String? get token => _client.token;
}
