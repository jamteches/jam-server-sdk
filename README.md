# 📱 Jam Server Flutter SDK

A comprehensive Flutter client for interacting with **Jam Server**. Seamlessly integrate Authentication, AI Transcription, Chunked Uploads, and Admin management into your apps.

---

## 📦 Installation

Add this package to your `pubspec.yaml`:

```yaml
dependencies:
  jam_server_sdk:
    git:
      url: https://github.com/jamteches/jam-server.git
      path: sdk/flutter
```

---

## 🚀 Quick Start

Initialize the client with your efficient Jam Server URL:

```dart
import 'package:jam_server_sdk/jam.dart';

void main() async {
  // 1. Initialize
  final jam = Jam('https://api.yourdomain.com');
  
  // 2. Authenticate (Admin or Project User)
  await jam.auth.login(username: 'admin', password: 'password');
  
  print('Ready to jam! Token: ${jam.token}');
}
```

---

## 🛠️ Core Features

### 1. 🔐 Authentication

Handle global system authentication.

```dart
// Login as Admin
await jam.auth.login(username: 'admin', password: 'password');

// Register new Admin
await jam.auth.register(email: 'new@admin.com', username: 'admin2', password: 'pass');

// Verify Session
final isValid = await jam.auth.verifyToken();

// Logout
await jam.auth.logout();
```

### 2. 👥 Project-Scoped Auth (Multi-tenancy)

Authenticate end-users specifically for a project.

```dart
final project = jam.projectAuth('proj_123');

// Register user for this project
await project.register(email: 'user@client.com', password: 'secure_pass');

// Login user
await project.login(email: 'user@client.com', password: 'secure_pass');

// Get profile
final me = await project.me();
```

### 3. 💾 Storage & Uploads

Smart file handling that automatically switches to chunked upload for large files.

#### Chunked Upload (Recommended) ✨
Robust upload for unreliable networks and huge files (>2GB).

```dart
final result = await jam.chunkedUpload.uploadFile(
  projectId: 'proj_123',
  file: File('huge_recording.wav'),
  onProgress: (progress) {
    print('Uploading: ${(progress * 100).toStringAsFixed(1)}%');
  }
);
// Returns: { "url": "/storage/...", "filename": "..." }
```

### 4. 🎙️ Transcription Flow

**Correct Pattern**: 1. Upload File -> 2. Create Job -> 3. Wait for results.

```dart
// 1. Upload
final upload = await jam.chunkedUpload.uploadFile(projectId: 'pid', file: myFile);

// 2. Create Job (using URL from upload)
final job = await jam.transcription.transcribeByUrl(
  projectId: 'pid',
  fileUrl: upload['url'],
  language: 'th', // 'th', 'en', or null (auto)
  diarize: true,  // Enable speaker separation
  async: true     // Return job ID immediately
);

// 3. Monitor
jam.transcription.waitForCompletion(job['job_id'], onProgress: (p) {
  print('Processing: $p%');
});

// 4. Update Speaker Names (Optional)
await jam.transcription.updateTranscriptionSpeakers(
  transcriptionId,
  {'SPEAKER_00': 'Somchai', 'SPEAKER_01': 'John'}
);
```

### 5. 🎞️ Media Tools

```dart
// Check supported formats
final formats = await jam.media.getSupportedFormats();

// Convert Video
await jam.media.convertVideo(
  projectId: 'pid',
  fileUrl: '/storage/.../vid.mov',
  outputFormat: 'mp4'
);
```

### 6. 👑 Admin Tools

Manage the server instance (Requires Admin Login).

```dart
// Get all users
final users = await jam.admin.getUnifiedUsers();

// Check Storage Usage
final summary = await jam.admin.getStorageUsageSummary();

// Manage Backups
await jam.admin.createBackup();
```

---

## 🧩 Integration Example

```dart
class TranscriptionService {
  final Jam jam;
  TranscriptionService(this.jam);

  Future<void> processRecording(String projectId, File file) async {
    try {
      print('1. Uploading...');
      final upload = await jam.chunkedUpload.uploadFile(
        projectId: projectId, 
        file: file
      );

      print('2. Queuing Job...');
      final job = await jam.transcription.transcribeByUrl(
        projectId: projectId,
        fileUrl: upload['url'],
        language: 'th',
        diarize: true
      );

      print('3. Waiting for AI...');
      final result = await jam.transcription.waitForCompletion(
        job['job_id'],
        onProgress: (p) => print('Processing: $p%')
      );

      print('✅ Done! Text: ${result.fullText}');
      
    } catch (e) {
      print('❌ Failed: $e');
    }
  }
}
```

## ⚠️ Error Handling

```dart
try {
  await jam.auth.login(...);
} on JamException catch (e) {
  if (e.isRateLimit) {
     print('Too many requests! Wait ${e.retryAfter} seconds.');
  } else {
     print('Error: ${e.message} (Code: ${e.statusCode})');
  }
}
```

---

## 📄 License

MIT License. See LICENSE for details.
