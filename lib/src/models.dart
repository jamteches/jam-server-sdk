/// Data models for Jam Server SDK

/// User model
class JamUser {
  final String id;
  final String username;
  final String? email;
  final String role;
  final bool emailVerified;
  final DateTime? createdAt;

  JamUser({
    required this.id,
    required this.username,
    this.email,
    required this.role,
    this.emailVerified = false,
    this.createdAt,
  });

  factory JamUser.fromJson(Map<String, dynamic> json) {
    return JamUser(
      id: json['id'] ?? '',
      username: json['username'] ?? '',
      email: json['email'],
      role: json['role'] ?? 'user',
      emailVerified: json['email_verified'] ?? false,
      createdAt: json['created_at'] != null 
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'username': username,
    if (email != null) 'email': email,
    'role': role,
    'email_verified': emailVerified,
    if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
  };

  bool get isAdmin => role == 'admin';
}

/// Project model
class JamProject {
  final String id;
  final String name;
  final String? description;
  final String owner;
  final List<String> members;
  final String status;
  final int createdAt;
  final int updatedAt;

  JamProject({
    required this.id,
    required this.name,
    this.description,
    required this.owner,
    required this.members,
    this.status = 'active',
    required this.createdAt,
    required this.updatedAt,
  });

  factory JamProject.fromJson(Map<String, dynamic> json) {
    return JamProject(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'],
      owner: json['owner'] ?? '',
      members: (json['members'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList() ?? [],
      status: json['status'] ?? 'active',
      createdAt: json['created_at'] ?? 0,
      updatedAt: json['updated_at'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    if (description != null) 'description': description,
    'owner': owner,
    'members': members,
    'status': status,
    'created_at': createdAt,
    'updated_at': updatedAt,
  };

  bool get isActive => status == 'active';
  bool get isArchived => status == 'archived';
}

/// Document model
class JamDocument {
  final String id;
  final String collection;
  final String? projectId;
  final Map<String, dynamic> data;
  final int updatedAt;
  final String owner;

  JamDocument({
    required this.id,
    required this.collection,
    this.projectId,
    required this.data,
    required this.updatedAt,
    required this.owner,
  });

  factory JamDocument.fromJson(Map<String, dynamic> json) {
    return JamDocument(
      id: json['id'] ?? '',
      collection: json['collection'] ?? '',
      projectId: json['project_id'],
      data: json['data'] ?? json,
      updatedAt: json['updated_at'] ?? json['_updated_at'] ?? 0,
      owner: json['owner'] ?? json['_owner'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'collection': collection,
    if (projectId != null) 'project_id': projectId,
    'data': data,
    'updated_at': updatedAt,
    'owner': owner,
  };

  /// Get a value from data by key
  T? getValue<T>(String key) => data[key] as T?;
}

/// File metadata model
class JamFile {
  final String id;
  final String filename;
  final String originalName;
  final String projectId;
  final String owner;
  final int size;
  final String mimeType;
  final int uploadedAt;
  final String url;

  JamFile({
    required this.id,
    required this.filename,
    required this.originalName,
    required this.projectId,
    required this.owner,
    required this.size,
    required this.mimeType,
    required this.uploadedAt,
    required this.url,
  });

  factory JamFile.fromJson(Map<String, dynamic> json) {
    return JamFile(
      id: json['id']?.toString() ?? '',
      filename: json['filename'] ?? '',
      originalName: json['original_name'] ?? json['filename'] ?? '',
      projectId: json['project_id'] ?? '',
      owner: json['owner'] ?? '',
      size: json['size'] ?? 0,
      mimeType: json['mime_type'] ?? '',
      uploadedAt: json['uploaded_at'] ?? 0,
      url: json['url'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'filename': filename,
    'original_name': originalName,
    'project_id': projectId,
    'owner': owner,
    'size': size,
    'mime_type': mimeType,
    'uploaded_at': uploadedAt,
    'url': url,
  };

  /// Get human-readable file size
  String get readableSize {
    if (size < 1024) return '$size B';
    if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(1)} KB';
    if (size < 1024 * 1024 * 1024) return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(size / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}

/// Task model
class JamTask {
  final String id;
  final String projectId;
  final String title;
  final String? description;
  final String? assignedTo;
  final String status;
  final String priority;
  final int? dueDate;
  final List<String> tags;
  final String createdBy;
  final int createdAt;
  final int updatedAt;

  JamTask({
    required this.id,
    required this.projectId,
    required this.title,
    this.description,
    this.assignedTo,
    this.status = 'todo',
    this.priority = 'medium',
    this.dueDate,
    this.tags = const [],
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
  });

  factory JamTask.fromJson(Map<String, dynamic> json) {
    return JamTask(
      id: json['id'] ?? '',
      projectId: json['project_id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'],
      assignedTo: json['assigned_to'],
      status: json['status'] ?? 'todo',
      priority: json['priority'] ?? 'medium',
      dueDate: json['due_date'],
      tags: (json['tags'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList() ?? [],
      createdBy: json['created_by'] ?? '',
      createdAt: json['created_at'] ?? 0,
      updatedAt: json['updated_at'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'project_id': projectId,
    'title': title,
    if (description != null) 'description': description,
    if (assignedTo != null) 'assigned_to': assignedTo,
    'status': status,
    'priority': priority,
    if (dueDate != null) 'due_date': dueDate,
    'tags': tags,
    'created_by': createdBy,
    'created_at': createdAt,
    'updated_at': updatedAt,
  };

  bool get isTodo => status == 'todo';
  bool get isInProgress => status == 'in_progress';
  bool get isDone => status == 'done';
  bool get isHighPriority => priority == 'high';
}

/// Webhook model
class JamWebhook {
  final String id;
  final String projectId;
  final String collection;
  final List<String> events;
  final String url;
  final String? secret;
  final int createdAt;
  final int? lastTriggered;
  final int failures;

  JamWebhook({
    required this.id,
    required this.projectId,
    this.collection = '*',
    required this.events,
    required this.url,
    this.secret,
    required this.createdAt,
    this.lastTriggered,
    this.failures = 0,
  });

  factory JamWebhook.fromJson(Map<String, dynamic> json) {
    return JamWebhook(
      id: json['id']?.toString() ?? '',
      projectId: json['project_id'] ?? '',
      collection: json['collection'] ?? '*',
      events: (json['events'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList() ?? ['create', 'update', 'delete'],
      url: json['url'] ?? '',
      secret: json['secret'],
      createdAt: json['created_at'] ?? 0,
      lastTriggered: json['last_triggered'],
      failures: json['failures'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'project_id': projectId,
    'collection': collection,
    'events': events,
    'url': url,
    if (secret != null) 'secret': secret,
    'created_at': createdAt,
    if (lastTriggered != null) 'last_triggered': lastTriggered,
    'failures': failures,
  };
}

/// API Key model
class JamApiKey {
  final String id;
  final String projectId;
  final String name;
  final String prefix;
  final String createdBy;
  final DateTime createdAt;
  final DateTime? lastUsedAt;
  final DateTime? expiresAt;
  final bool isActive;
  final List<String> permissions;

  JamApiKey({
    required this.id,
    required this.projectId,
    required this.name,
    required this.prefix,
    required this.createdBy,
    required this.createdAt,
    this.lastUsedAt,
    this.expiresAt,
    this.isActive = true,
    required this.permissions,
  });

  factory JamApiKey.fromJson(Map<String, dynamic> json) {
    return JamApiKey(
      id: json['id']?.toString() ?? '',
      projectId: json['project_id'] ?? '',
      name: json['name'] ?? '',
      prefix: json['prefix'] ?? '',
      createdBy: json['created_by'] ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      lastUsedAt: json['last_used_at'] != null
          ? DateTime.parse(json['last_used_at'])
          : null,
      expiresAt: json['expires_at'] != null
          ? DateTime.parse(json['expires_at'])
          : null,
      isActive: json['is_active'] ?? true,
      permissions: (json['permissions'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList() ?? ['read', 'write'],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'project_id': projectId,
    'name': name,
    'prefix': prefix,
    'created_by': createdBy,
    'created_at': createdAt.toIso8601String(),
    if (lastUsedAt != null) 'last_used_at': lastUsedAt!.toIso8601String(),
    if (expiresAt != null) 'expires_at': expiresAt!.toIso8601String(),
    'is_active': isActive,
    'permissions': permissions,
  };

  bool get isExpired => expiresAt != null && DateTime.now().isAfter(expiresAt!);
  bool get canRead => permissions.contains('read');
  bool get canWrite => permissions.contains('write');
  bool get canDelete => permissions.contains('delete');
}

/// Transcription model
class JamTranscription {
  final String id;
  final String projectId;
  final String owner;
  final String filename;
  final String language;
  final double duration;
  final List<JamTranscriptSegment> segments;
  final String? subtitle;
  final String? subtitleFormat;
  final bool diarizationEnabled;
  final List<String> speakers;
  final bool isVideo;
  final DateTime createdAt;
  final DateTime updatedAt;

  JamTranscription({
    required this.id,
    required this.projectId,
    required this.owner,
    required this.filename,
    required this.language,
    required this.duration,
    required this.segments,
    this.subtitle,
    this.subtitleFormat,
    this.diarizationEnabled = false,
    this.speakers = const [],
    this.isVideo = false,
    required this.createdAt,
    required this.updatedAt,
  });

  factory JamTranscription.fromJson(Map<String, dynamic> json) {
    return JamTranscription(
      id: json['id']?.toString() ?? '',
      projectId: json['project_id'] ?? '',
      owner: json['owner'] ?? '',
      filename: json['filename'] ?? '',
      language: json['language'] ?? '',
      duration: (json['duration'] as num?)?.toDouble() ?? 0.0,
      segments: (json['segments'] as List<dynamic>?)
          ?.map((e) => JamTranscriptSegment.fromJson(e))
          .toList() ?? [],
      subtitle: json['subtitle'],
      subtitleFormat: json['subtitle_format'],
      diarizationEnabled: json['diarization_enabled'] ?? false,
      speakers: (json['speakers'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList() ?? [],
      isVideo: json['is_video'] ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : DateTime.now(),
    );
  }

  /// Get full text from all segments
  String get fullText => segments.map((s) => s.text).join(' ');
}

/// Transcript segment model
class JamTranscriptSegment {
  final double start;
  final double end;
  final String text;
  final String? speaker;

  JamTranscriptSegment({
    required this.start,
    required this.end,
    required this.text,
    this.speaker,
  });

  factory JamTranscriptSegment.fromJson(Map<String, dynamic> json) {
    return JamTranscriptSegment(
      start: (json['start'] as num).toDouble(),
      end: (json['end'] as num).toDouble(),
      text: json['text'] ?? '',
      speaker: json['speaker'],
    );
  }

  Map<String, dynamic> toJson() => {
    'start': start,
    'end': end,
    'text': text,
    if (speaker != null) 'speaker': speaker,
  };

  /// Duration of segment in seconds
  double get duration => end - start;

  /// Format start time as string (MM:SS)
  String get startFormatted => _formatTime(start);

  /// Format end time as string (MM:SS)
  String get endFormatted => _formatTime(end);

  String _formatTime(double seconds) {
    final mins = (seconds / 60).floor();
    final secs = (seconds % 60).floor();
    return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }
}
