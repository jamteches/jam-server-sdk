/// Jam Server SDK for Flutter
/// 
/// A comprehensive SDK for interacting with Jam Server.
/// Provides authentication, database, storage, AI, real-time updates, and more.
/// 
/// ## Getting Started
/// 
/// ```dart
/// import 'package:jam_server_sdk/jam.dart';
/// 
/// void main() async {
///   // Initialize SDK
///   final jam = Jam('https://api.jamteches.com');
///   
///   // Login
///   await jam.auth.login(username: 'john', password: 'password');
///   
///   // Set project context
///   jam.setProject('my-project-id');
///   
///   // Use database
///   final users = jam.db.collection('users');
///   await users.add({'name': 'John', 'age': 30});
///   final allUsers = await users.list();
///   
///   // Use storage
///   await jam.storage.upload('/path/to/file.pdf', projectId: 'my-project');
///   
///   // Use AI
///   final response = await jam.ai.chat(
///     projectId: 'my-project',
///     message: 'Hello!',
///   );
///   
///   // Real-time updates
///   jam.realtime.connect();
///   jam.realtime.subscribe('messages');
///   jam.realtime.stream.listen((event) => print(event));
/// }
/// ```
library jam_server_sdk;

import 'src/jam_client.dart';
import 'src/auth_service.dart';
import 'src/db_service.dart';
import 'src/storage_service.dart';
import 'src/project_service.dart';
import 'src/task_service.dart';
import 'src/user_service.dart';
import 'src/ai_service.dart';
import 'src/transcription_service.dart';
import 'src/media_service.dart';
import 'src/realtime_service.dart';
import 'src/admin_service.dart';
import 'src/chunked_upload_service.dart';
import 'src/project_auth_service.dart';
import 'src/project_settings_service.dart';

// Export exceptions and models
export 'src/jam_client.dart' show JamException;
export 'src/task_service.dart' show TaskStatus, TaskPriority;
export 'src/transcription_service.dart' show TranscriptSegment;
export 'src/realtime_service.dart' show RealtimeEventType;
export 'src/chunked_upload_service.dart' show UploadProgress;
export 'src/project_auth_service.dart' show ProjectAuthService, ProjectUser, ProjectAuthResponse;
export 'src/project_settings_service.dart' show ProjectSettingsService, ProjectSettings, ProjectSettingsUpdate;
export 'src/models.dart';

/// Main Jam SDK class
/// 
/// Entry point for all Jam Server operations.
/// 
/// Example:
/// ```dart
/// final jam = Jam('https://api.jamteches.com');
/// 
/// // With API Key (for client apps)
/// final jam = Jam('https://api.jamteches.com', apiKey: 'jam_pk_...');
/// 
/// // With existing token
/// final jam = Jam('https://api.jamteches.com', token: 'existing_jwt_token');
/// ```
class Jam {
  late final JamClient _client;
  
  /// Authentication service
  late final AuthService auth;
  
  /// Database service
  late final DbService db;
  
  /// File storage service
  late final StorageService storage;
  
  /// Project management service
  late final ProjectService projects;
  
  /// Task management service
  late final TaskService tasks;
  
  /// User management service (Admin)
  late final UserService users;
  
  /// AI service (chat, knowledge base, etc.)
  late final AiService ai;
  
  /// Transcription service
  late final TranscriptionService transcription;
  
  /// Media conversion service
  late final MediaService media;
  
  /// Real-time WebSocket service
  late final RealtimeService realtime;
  
  /// Admin service (backup, logs, metrics)
  late final AdminService admin;
  
  /// Chunked upload service (for large files)
  late final ChunkedUploadService chunkedUpload;

  /// Create a new Jam SDK instance
  /// 
  /// [baseUrl]: The base URL of your Jam Server (e.g., 'https://api.jamteches.com')
  /// [apiKey]: Optional API key for authentication
  /// [token]: Optional JWT token for authentication
  /// [projectId]: Optional default project ID
  Jam(
    String baseUrl, {
    String? apiKey,
    String? token,
    String? projectId,
  }) {
    _client = JamClient(baseUrl: baseUrl);
    
    if (apiKey != null) {
      _client.setApiKey(apiKey);
    }
    if (token != null) {
      _client.setToken(token);
    }
    if (projectId != null) {
      _client.setProject(projectId);
    }
    
    // Initialize services
    auth = AuthService(_client);
    db = DbService(_client);
    storage = StorageService(_client);
    projects = ProjectService(_client);
    tasks = TaskService(_client);
    users = UserService(_client);
    ai = AiService(_client);
    transcription = TranscriptionService(_client);
    media = MediaService(_client);
    realtime = RealtimeService(_client);
    admin = AdminService(_client);
    chunkedUpload = ChunkedUploadService(_client);
  }

  // ==================== Token Management ====================

  /// Set JWT token manually
  void setToken(String token) {
    _client.setToken(token);
  }

  /// Get current JWT token
  String? get token => _client.token;

  /// Clear JWT token
  void clearToken() {
    _client.clearToken();
  }

  // ==================== API Key Management ====================

  /// Set API Key for authentication
  void setApiKey(String apiKey) {
    _client.setApiKey(apiKey);
  }

  /// Get current API Key
  String? get apiKey => _client.apiKey;

  /// Clear API Key
  void clearApiKey() {
    _client.clearApiKey();
  }

  // ==================== Project Context ====================

  /// Set current project context
  /// 
  /// This affects all subsequent API calls.
  void setProject(String projectId) {
    _client.setProject(projectId);
  }

  /// Get current project ID
  String? get currentProjectId => _client.currentProjectId;

  /// Clear project context
  void clearProject() {
    _client.clearProject();
  }

  // ==================== Utilities ====================

  /// Check if user is authenticated
  bool get isAuthenticated => _client.token != null || _client.apiKey != null;

  /// Get base URL
  String get baseUrl => _client.baseUrl;

  // ==================== Project Auth ====================

  /// Create a project-scoped authentication service
  /// 
  /// Each project can have its own users separate from server admins.
  /// 
  /// Example:
  /// ```dart
  /// final auth = jam.projectAuth('my-project-id');
  /// 
  /// // Register user in this project
  /// await auth.register(email: 'user@example.com', password: 'pass123');
  /// 
  /// // Login
  /// await auth.login(email: 'user@example.com', password: 'pass123');
  /// 
  /// // Get current user
  /// final user = await auth.me();
  /// ```
  ProjectAuthService projectAuth(String projectId) {
    return ProjectAuthService(_client, projectId);
  }

  /// Get project settings service
  /// 
  /// Manage project configuration including permissions, registration settings, etc.
  /// 
  /// Example:
  /// ```dart
  /// final settings = jam.projectSettings('my-project-id');
  /// 
  /// // Get current settings
  /// final current = await settings.get();
  /// 
  /// // Disable registration
  /// await settings.disableRegistration();
  /// 
  /// // Limit to specific email domains
  /// await settings.setAllowedDomains(['@company.com']);
  /// ```
  ProjectSettingsService projectSettings(String projectId) {
    return ProjectSettingsService(_client, projectId);
  }

  /// Dispose all resources
  void dispose() {
    realtime.dispose();
    _client.dispose();
  }
}
