import 'dart:convert';
import 'package:http/http.dart' as http;
import 'jam_client.dart';

/// Project User model
class ProjectUser {
  final String id;
  final String projectId;
  final String username;
  final String email;
  final String role;
  final bool emailVerified;
  final Map<String, dynamic>? metadata;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? lastLoginAt;

  ProjectUser({
    required this.id,
    required this.projectId,
    required this.username,
    required this.email,
    required this.role,
    required this.emailVerified,
    this.metadata,
    required this.createdAt,
    required this.updatedAt,
    this.lastLoginAt,
  });

  factory ProjectUser.fromJson(Map<String, dynamic> json) {
    return ProjectUser(
      id: json['id'] ?? '',
      projectId: json['project_id'] ?? '',
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      role: json['role'] ?? 'user',
      emailVerified: json['email_verified'] ?? false,
      metadata: json['metadata'],
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updated_at'] ?? '') ?? DateTime.now(),
      lastLoginAt: json['last_login_at'] != null
          ? DateTime.tryParse(json['last_login_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'project_id': projectId,
        'username': username,
        'email': email,
        'role': role,
        'email_verified': emailVerified,
        'metadata': metadata,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
        'last_login_at': lastLoginAt?.toIso8601String(),
      };
}

/// Auth response model
class ProjectAuthResponse {
  final String status;
  final String? token;
  final ProjectUser? user;
  final String? message;

  ProjectAuthResponse({
    required this.status,
    this.token,
    this.user,
    this.message,
  });

  factory ProjectAuthResponse.fromJson(Map<String, dynamic> json) {
    return ProjectAuthResponse(
      status: json['status'] ?? '',
      token: json['token'],
      user: json['user'] != null ? ProjectUser.fromJson(json['user']) : null,
      message: json['message'],
    );
  }

  bool get isSuccess => status == 'ok';
}

/// Project-Scoped Authentication Service
/// 
/// Provides authentication for project-specific users.
/// Each project can have its own user base separate from server admins.
/// 
/// Example:
/// ```dart
/// final auth = ProjectAuthService(client, 'my-project-id');
/// 
/// // Register new user
/// final response = await auth.register(
///   email: 'user@example.com',
///   password: 'password123',
/// );
/// 
/// // Login
/// final loginResponse = await auth.login(
///   email: 'user@example.com',
///   password: 'password123',
/// );
/// 
/// // Set token for authenticated requests
/// auth.setToken(loginResponse.token!);
/// 
/// // Get current user
/// final user = await auth.me();
/// ```
class ProjectAuthService {
  final JamClient _client;
  final String projectId;
  String? _projectToken;

  ProjectAuthService(this._client, this.projectId);

  /// Set the project authentication token
  void setToken(String token) {
    _projectToken = token;
  }

  /// Get the current project token
  String? get token => _projectToken;

  /// Clear the project token (logout locally)
  void clearToken() {
    _projectToken = null;
  }

  /// Check if user is authenticated
  bool get isAuthenticated => _projectToken != null;

  /// Make authenticated request to project auth endpoint
  Future<http.Response> _authRequest(
    String method,
    String endpoint, {
    Map<String, dynamic>? body,
    bool requireAuth = false,
  }) async {
    final url = Uri.parse('${_client.baseUrl}/api/projects/$projectId/auth$endpoint');
    final headers = <String, String>{
      'Content-Type': 'application/json',
    };

    if (requireAuth && _projectToken != null) {
      headers['Authorization'] = 'Bearer $_projectToken';
    }

    http.Response response;
    switch (method) {
      case 'GET':
        response = await http.get(url, headers: headers);
        break;
      case 'POST':
        response = await http.post(url, headers: headers, body: json.encode(body));
        break;
      case 'PATCH':
        response = await http.patch(url, headers: headers, body: json.encode(body));
        break;
      case 'DELETE':
        response = await http.delete(url, headers: headers);
        break;
      default:
        throw JamException(statusCode: 400, message: 'Invalid HTTP method: $method');
    }

    if (response.statusCode >= 400) {
      final error = json.decode(response.body);
      throw JamException(statusCode: response.statusCode, message: error['error'] ?? 'Request failed');
    }

    return response;
  }

  // ===========================================
  // Public Auth Methods (No Token Required)
  // ===========================================

  /// Register a new user in this project
  /// 
  /// Returns auth response with token and user info on success.
  /// 
  /// Example:
  /// ```dart
  /// final response = await auth.register(
  ///   email: 'user@example.com',
  ///   password: 'password123',
  ///   username: 'johndoe', // optional
  ///   metadata: {'name': 'John Doe'}, // optional
  /// );
  /// auth.setToken(response.token!);
  /// ```
  Future<ProjectAuthResponse> register({
    required String email,
    required String password,
    String? username,
    Map<String, dynamic>? metadata,
  }) async {
    final response = await _authRequest('POST', '/register', body: {
      'email': email,
      'password': password,
      if (username != null) 'username': username,
      if (metadata != null) 'metadata': metadata,
    });

    final data = json.decode(response.body);
    final authResponse = ProjectAuthResponse.fromJson(data);
    
    // Auto-set token if available
    if (authResponse.token != null) {
      _projectToken = authResponse.token;
    }
    
    return authResponse;
  }

  /// Login with email/username and password
  /// 
  /// Returns auth response with token and user info on success.
  /// 
  /// Example:
  /// ```dart
  /// final response = await auth.login(
  ///   email: 'user@example.com',
  ///   password: 'password123',
  /// );
  /// // Token is automatically set
  /// ```
  Future<ProjectAuthResponse> login({
    required String email,
    required String password,
  }) async {
    final response = await _authRequest('POST', '/login', body: {
      'email': email,
      'password': password,
    });

    final data = json.decode(response.body);
    final authResponse = ProjectAuthResponse.fromJson(data);
    
    // Auto-set token if available
    if (authResponse.token != null) {
      _projectToken = authResponse.token;
    }
    
    return authResponse;
  }

  /// Request password reset OTP
  /// 
  /// Sends an OTP to the user's email for password reset.
  /// 
  /// Example:
  /// ```dart
  /// await auth.forgotPassword('user@example.com');
  /// // User receives OTP via email
  /// ```
  Future<void> forgotPassword(String email) async {
    await _authRequest('POST', '/forgot-password', body: {
      'email': email,
    });
  }

  /// Reset password using OTP
  /// 
  /// Example:
  /// ```dart
  /// await auth.resetPassword(
  ///   email: 'user@example.com',
  ///   otp: '123456',
  ///   newPassword: 'newpassword123',
  /// );
  /// ```
  Future<void> resetPassword({
    required String email,
    required String otp,
    required String newPassword,
  }) async {
    await _authRequest('POST', '/reset-password', body: {
      'email': email,
      'otp': otp,
      'new_password': newPassword,
    });
  }

  // ===========================================
  // Protected Auth Methods (Token Required)
  // ===========================================

  /// Get current authenticated user info
  /// 
  /// Requires authentication token.
  /// 
  /// Example:
  /// ```dart
  /// final user = await auth.me();
  /// print('Hello, ${user.email}');
  /// ```
  Future<ProjectUser> me() async {
    final response = await _authRequest('GET', '/me', requireAuth: true);
    final data = json.decode(response.body);
    return ProjectUser.fromJson(data);
  }

  /// Update user profile
  /// 
  /// Requires authentication token.
  /// 
  /// Example:
  /// ```dart
  /// await auth.updateProfile(
  ///   username: 'newusername',
  ///   metadata: {'avatar': 'https://...'},
  /// );
  /// ```
  Future<void> updateProfile({
    String? username,
    Map<String, dynamic>? metadata,
  }) async {
    await _authRequest('PATCH', '/profile', 
      requireAuth: true,
      body: {
        if (username != null) 'username': username,
        if (metadata != null) 'metadata': metadata,
      },
    );
  }

  /// Change password
  /// 
  /// Requires current password for verification.
  /// 
  /// Example:
  /// ```dart
  /// await auth.changePassword(
  ///   currentPassword: 'oldpassword',
  ///   newPassword: 'newpassword123',
  /// );
  /// ```
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    await _authRequest('POST', '/change-password',
      requireAuth: true,
      body: {
        'current_password': currentPassword,
        'new_password': newPassword,
      },
    );
  }

  /// Send email verification OTP
  /// 
  /// Sends an OTP to verify the user's email address.
  /// 
  /// Example:
  /// ```dart
  /// await auth.sendVerification();
  /// // User receives OTP via email
  /// ```
  Future<void> sendVerification() async {
    await _authRequest('POST', '/send-verification', requireAuth: true);
  }

  /// Verify email with OTP
  /// 
  /// Example:
  /// ```dart
  /// await auth.verifyEmail('123456');
  /// ```
  Future<void> verifyEmail(String otp) async {
    await _authRequest('POST', '/verify-email',
      requireAuth: true,
      body: {'otp': otp},
    );
  }

  /// Logout and revoke token
  /// 
  /// Invalidates the current token on the server.
  /// 
  /// Example:
  /// ```dart
  /// await auth.logout();
  /// // Token is no longer valid
  /// ```
  Future<void> logout() async {
    await _authRequest('POST', '/logout', requireAuth: true);
    _projectToken = null;
  }

  /// Refresh authentication token
  /// 
  /// Gets a new token with extended expiry.
  /// 
  /// Example:
  /// ```dart
  /// final newToken = await auth.refreshToken();
  /// ```
  Future<String> refreshToken() async {
    final response = await _authRequest('POST', '/refresh', requireAuth: true);
    final data = json.decode(response.body);
    final newToken = data['token'] as String;
    _projectToken = newToken;
    return newToken;
  }

  // ===========================================
  // URL Helpers (For Web Pages)
  // ===========================================

  /// Get the forgot password page URL for this project
  /// 
  /// Returns a URL that can be opened in a browser for password reset.
  /// 
  /// Example:
  /// ```dart
  /// final url = auth.forgotPasswordUrl;
  /// // Open in browser: https://api.jamteches.com/project-forgot-password.html?project_id=xxx
  /// ```
  String get forgotPasswordUrl {
    return '${_client.baseUrl}/project-forgot-password.html?project_id=$projectId';
  }

  /// Get the reset password page URL for this project
  /// 
  /// Returns a URL that can be opened in a browser for password reset with OTP.
  /// 
  /// Example:
  /// ```dart
  /// final url = auth.resetPasswordUrl;
  /// // Open in browser: https://api.jamteches.com/project-reset-password.html?project_id=xxx
  /// ```
  String get resetPasswordUrl {
    return '${_client.baseUrl}/project-reset-password.html?project_id=$projectId';
  }

  /// Get the base URL for all project auth endpoints
  String get authBaseUrl => '${_client.baseUrl}/api/projects/$projectId/auth';
}
