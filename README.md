# Jam Server Flutter SDK

A comprehensive Flutter SDK for interacting with Jam Server (v2.0). Support for authentication, storage, transcription AI, and admin management.

## Installation

Add this to your package's `pubspec.yaml` file:

```yaml
dependencies:
  jam_flutter_sdk:
    path: ./sdk/flutter  # Local path or git url
```

## Usage

### 1. Initialization

```dart
import 'package:jam_flutter_sdk/jam.dart';

// Initialize with your server URL
final jam = Jam('https://api.jamteches.com');
```

### 2. Authentication

The SDK supports both **System Users** (global) and **Project Users** (scoped).

#### System Login (For Admins & Global Users)
```dart
// Login
final result = await jam.auth.login(
  username: 'my_user', 
  password: 'my_password'
);

// Register
await jam.auth.register(
  username: 'new_user',
  email: 'new@example.com',
  password: 'secure_password',
  inviteCode: 'OPTIONAL_CODE'
);

// Verify Email
await jam.auth.verifyEmail('TOKEN_FROM_EMAIL');
```

#### Project Login (End-Users)
```dart
// Login to specific project
final auth = jam.projectAuth('project_id');
final result = await auth.login(
  email: 'end_user@example.com',
  password: 'user_password'
);

print('Project Token: ${auth.token}');
```

### 3. File Storage & Quota

Manage files with automatic chunked uploading for large files.

```dart
// Check Quota
final quota = await jam.storage.getQuota();
print('Used: ${quota['used_bytes']} / ${quota['quota_bytes']}');

// Upload File (Auto-chunked)
final uploadResult = await jam.chunkedUpload.uploadFile(
  '/path/to/video.mp4',
  projectId: 'my_project_id',
  onProgress: (progress) => print('Upload: ${progress * 100}%'),
);

print('File URL: ${uploadResult['url']}');

// List Files
final files = await jam.storage.list(projectId: 'my_project_id');

// Delete File
await jam.storage.delete('filename.mp4');
```

### 4. Transcription AI

Transcribe audio/video with speaker diarization.

```dart
// Async Transcription (Recommended)
final job = await jam.transcription.transcribeAsync(
  '/path/to/interview.mp3',
  projectId: 'my_project_id',
  language: 'th', // Thai
  diarize: true,  // Detect speakers
);

// Wait for completion
final result = await jam.transcription.waitForCompletion(
  job['job_id'],
  onProgress: (p) => print('Processing: $p%'),
);

// Print Segments
for (var segment in result.segments) {
  print('[${segment.startFormatted} - ${segment.endFormatted}] ${segment.speaker}: ${segment.text}');
}
```

### 5. Admin Management

Administrative tools for managing users and system health.

```dart
// Ensure you are logged in as Admin
await jam.auth.login(username: 'admin', password: '...');

// === User Management ===

// Get all users (System + Project)
final users = await jam.admin.getUnifiedUsers();

for (var user in users) {
  print('${user.username} (${user.tier}) - Source: ${user.source}');
}

// Update User Tier
await jam.admin.updateUserTier('USER_ID', 'vip'); // free, pro, premium, vip

// Delete User
await jam.admin.deleteUser('USER_ID');

// === Storage Admin ===

// Get overall storage usage
final summary = await jam.admin.getStorageUsageSummary();
print('Total Used: ${summary['total_size_formatted']}');

// List files in a project
final files = await jam.admin.getProjectFiles('PROJECT_ID');

// Force delete a file
await jam.admin.deleteFile('FILE_ID');
```

### 6. Projects

Manage projects and settings.

```dart
// List My Projects
final projects = await jam.projects.list();

// Create Project
final newProject = await jam.projects.create(
  name: 'New Project',
  description: 'My awesome project'
);

// Update Settings
await jam.projectSettings.update(
  projectId: 'PROJECT_ID',
  settings: {
    'transcription_language': 'th',
    'max_users': 10
  }
);
```

## Error Handling

All API calls throw `JamException` on error.

```dart
try {
  await jam.auth.login(...);
} on JamException catch (e) {
  print('Error ${e.statusCode}: ${e.message}');
} catch (e) {
  print('Network error: $e');
}
```

## Features Checklist

- [x] Authentication (System & Project)
- [x] Chunked File Upload (Resume support)
- [x] Storage Management & Quota
- [x] AI Transcription (Async, Diarization)
- [x] Admin Tools (Users, Tier, Storage, Backups)
- [x] Project Management
- [x] Collections (NoSQL DB)
- [x] Realtime (WebSocket)

---
© 2025 Jam Server. All rights reserved.
