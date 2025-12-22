# Jam Server Flutter SDK

A comprehensive Flutter SDK for **Jam Server** - a Firebase alternative with AI capabilities including speech-to-text transcription with speaker diarization.

## Features

- 🔐 **Authentication** - JWT & API Key authentication
- 📁 **Storage** - File upload, download, chunked upload support
- 📝 **Database** - NoSQL document storage with real-time sync
- 🎙️ **Transcription** - Speech-to-text with speaker diarization
- 👥 **Project Auth** - Multi-tenant user management
- 🔔 **Webhooks** - Event-driven integrations

## Installation

Add to your `pubspec.yaml`:

```yaml
dependencies:
  jam_server_sdk:
    git:
      url: https://github.com/jamteches/jam-server-sdk.git
      ref: v2.2.2
```

Then run:
```bash
flutter pub get
```

## Quick Start

```dart
import 'package:jam_server_sdk/jam_server_sdk.dart';

void main() async {
  // Initialize
  final jam = Jam('https://api.jamteches.com');
  
  // Login
  await jam.auth.login(username: 'user', password: 'pass');
  
  // Upload and transcribe audio
  final file = await jam.storage.upload('/path/to/audio.mp3', projectId: 'my-project');
  final job = await jam.transcription.transcribe(file['url'], diarize: true);
  
  // Wait for result
  final result = await jam.transcription.waitForCompletion(job['job_id']);
  print(result['segments']);
}
```

## Documentation

See [API Documentation](https://api.jamteches.com/docs) for complete reference.

## Project Authentication

For apps with their own user system:

```dart
final projectAuth = jam.projectAuth('your-project-id');

// Register user
await projectAuth.register(
  email: 'user@example.com',
  password: 'SecurePass123!',
);

// Login
await projectAuth.login(
  email: 'user@example.com', 
  password: 'SecurePass123!',
);

// Password Reset
await projectAuth.forgotPassword('user@example.com');
await projectAuth.resetPassword(
  email: 'user@example.com',
  otp: '123456',
  newPassword: 'NewSecurePass123!',
);
```

## Chunked Upload (Large Files)

```dart
final chunkedUpload = jam.chunkedUpload;

await chunkedUpload.uploadFile(
  '/path/to/large-video.mp4',
  projectId: 'my-project',
  chunkSize: 5 * 1024 * 1024, // 5MB chunks
  onProgress: (sent, total) {
    print('Progress: ${(sent / total * 100).toStringAsFixed(1)}%');
  },
);
```

## Version

Current version: **2.2.2**

## License

MIT License - see [LICENSE](LICENSE) for details.

## Support

- GitHub Issues: [Report a bug](https://github.com/jamteches/jam-server-sdk/issues)
- Documentation: [api.jamteches.com/docs](https://api.jamteches.com/docs)
