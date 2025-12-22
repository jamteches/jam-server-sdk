import 'jam_client.dart';

/// Project Settings model
class ProjectSettings {
  final String projectId;
  final bool allowRegistration;
  final bool requireEmailVerification;
  final List<String> allowedEmailDomains;
  final int maxUsers;
  final String defaultRole;
  final bool userCanRead;
  final bool userCanWrite;
  final bool userCanDelete;
  final bool moderatorCanDelete;
  final int rateLimitPerMinute;
  final DateTime createdAt;
  final DateTime updatedAt;

  ProjectSettings({
    required this.projectId,
    required this.allowRegistration,
    required this.requireEmailVerification,
    required this.allowedEmailDomains,
    required this.maxUsers,
    required this.defaultRole,
    required this.userCanRead,
    required this.userCanWrite,
    required this.userCanDelete,
    required this.moderatorCanDelete,
    required this.rateLimitPerMinute,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ProjectSettings.fromJson(Map<String, dynamic> json) {
    return ProjectSettings(
      projectId: json['project_id'] ?? '',
      allowRegistration: json['allow_registration'] ?? true,
      requireEmailVerification: json['require_email_verification'] ?? false,
      allowedEmailDomains: (json['allowed_email_domains'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      maxUsers: json['max_users'] ?? 0,
      defaultRole: json['default_role'] ?? 'user',
      userCanRead: json['user_can_read'] ?? true,
      userCanWrite: json['user_can_write'] ?? true,
      userCanDelete: json['user_can_delete'] ?? false,
      moderatorCanDelete: json['moderator_can_delete'] ?? true,
      rateLimitPerMinute: json['rate_limit_per_minute'] ?? 0,
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updated_at'] ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'project_id': projectId,
        'allow_registration': allowRegistration,
        'require_email_verification': requireEmailVerification,
        'allowed_email_domains': allowedEmailDomains,
        'max_users': maxUsers,
        'default_role': defaultRole,
        'user_can_read': userCanRead,
        'user_can_write': userCanWrite,
        'user_can_delete': userCanDelete,
        'moderator_can_delete': moderatorCanDelete,
        'rate_limit_per_minute': rateLimitPerMinute,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };
}

/// Project Settings Update Request
class ProjectSettingsUpdate {
  final bool? allowRegistration;
  final bool? requireEmailVerification;
  final List<String>? allowedEmailDomains;
  final int? maxUsers;
  final String? defaultRole;
  final bool? userCanRead;
  final bool? userCanWrite;
  final bool? userCanDelete;
  final bool? moderatorCanDelete;
  final int? rateLimitPerMinute;

  ProjectSettingsUpdate({
    this.allowRegistration,
    this.requireEmailVerification,
    this.allowedEmailDomains,
    this.maxUsers,
    this.defaultRole,
    this.userCanRead,
    this.userCanWrite,
    this.userCanDelete,
    this.moderatorCanDelete,
    this.rateLimitPerMinute,
  });

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (allowRegistration != null) map['allow_registration'] = allowRegistration;
    if (requireEmailVerification != null) map['require_email_verification'] = requireEmailVerification;
    if (allowedEmailDomains != null) map['allowed_email_domains'] = allowedEmailDomains;
    if (maxUsers != null) map['max_users'] = maxUsers;
    if (defaultRole != null) map['default_role'] = defaultRole;
    if (userCanRead != null) map['user_can_read'] = userCanRead;
    if (userCanWrite != null) map['user_can_write'] = userCanWrite;
    if (userCanDelete != null) map['user_can_delete'] = userCanDelete;
    if (moderatorCanDelete != null) map['moderator_can_delete'] = moderatorCanDelete;
    if (rateLimitPerMinute != null) map['rate_limit_per_minute'] = rateLimitPerMinute;
    return map;
  }
}

/// Project Settings Service
/// 
/// Manage project configuration including:
/// - Registration settings
/// - Email verification requirements
/// - User permissions
/// - Rate limiting
/// 
/// Example:
/// ```dart
/// final settings = ProjectSettingsService(client, 'my-project-id');
/// 
/// // Get current settings
/// final current = await settings.get();
/// print('Allow registration: ${current.allowRegistration}');
/// 
/// // Update settings
/// await settings.update(ProjectSettingsUpdate(
///   allowRegistration: false,
///   maxUsers: 100,
/// ));
/// ```
class ProjectSettingsService {
  final JamClient _client;
  final String projectId;

  ProjectSettingsService(this._client, this.projectId);

  /// Get current project settings
  /// 
  /// Requires server admin or project owner authentication.
  /// 
  /// Example:
  /// ```dart
  /// final settings = await service.get();
  /// print('Max users: ${settings.maxUsers}');
  /// print('User can delete: ${settings.userCanDelete}');
  /// ```
  Future<ProjectSettings> get() async {
    final response = await _client.get('/api/projects/$projectId/settings');
    return ProjectSettings.fromJson(response);
  }

  /// Update project settings
  /// 
  /// Only include fields you want to update.
  /// 
  /// Example:
  /// ```dart
  /// await service.update(ProjectSettingsUpdate(
  ///   allowRegistration: false,
  ///   requireEmailVerification: true,
  ///   allowedEmailDomains: ['@mycompany.com'],
  ///   maxUsers: 50,
  ///   userCanDelete: true,
  /// ));
  /// ```
  Future<ProjectSettings> update(ProjectSettingsUpdate updates) async {
    final response = await _client.patch(
      '/api/projects/$projectId/settings',
      body: updates.toJson(),
    );
    return ProjectSettings.fromJson(response['settings']);
  }

  /// Enable user registration
  Future<void> enableRegistration() async {
    await update(ProjectSettingsUpdate(allowRegistration: true));
  }

  /// Disable user registration
  Future<void> disableRegistration() async {
    await update(ProjectSettingsUpdate(allowRegistration: false));
  }

  /// Require email verification for new users
  Future<void> requireEmailVerification() async {
    await update(ProjectSettingsUpdate(requireEmailVerification: true));
  }

  /// Don't require email verification
  Future<void> skipEmailVerification() async {
    await update(ProjectSettingsUpdate(requireEmailVerification: false));
  }

  /// Set allowed email domains
  /// 
  /// Example:
  /// ```dart
  /// await service.setAllowedDomains(['@company.com', '@partner.com']);
  /// ```
  Future<void> setAllowedDomains(List<String> domains) async {
    await update(ProjectSettingsUpdate(allowedEmailDomains: domains));
  }

  /// Remove email domain restrictions
  Future<void> allowAllDomains() async {
    await update(ProjectSettingsUpdate(allowedEmailDomains: []));
  }

  /// Set maximum number of users
  /// 
  /// 0 = unlimited
  Future<void> setMaxUsers(int maxUsers) async {
    await update(ProjectSettingsUpdate(maxUsers: maxUsers));
  }

  /// Set user permissions
  /// 
  /// Example:
  /// ```dart
  /// await service.setUserPermissions(
  ///   canRead: true,
  ///   canWrite: true,
  ///   canDelete: false,
  /// );
  /// ```
  Future<void> setUserPermissions({
    bool? canRead,
    bool? canWrite,
    bool? canDelete,
  }) async {
    await update(ProjectSettingsUpdate(
      userCanRead: canRead,
      userCanWrite: canWrite,
      userCanDelete: canDelete,
    ));
  }

  /// Set moderator permissions
  Future<void> setModeratorPermissions({
    bool? canDelete,
  }) async {
    await update(ProjectSettingsUpdate(
      moderatorCanDelete: canDelete,
    ));
  }
}
