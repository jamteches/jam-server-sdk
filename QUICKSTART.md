# Jam Server SDK - Quick Start

Get started in 5 minutes! 🚀

## 1. Installation

```yaml
# pubspec.yaml
dependencies:
  jam_server_sdk:
    path: ./sdk/flutter
```

```bash
flutter pub get
```

## 2. Initialize with API Key (Recommended)

```dart
import 'package:jam_server_sdk/jam.dart';

// Get your API Key from Admin Console > API Keys
final jam = Jam(
  'https://api.jamteches.com',
  apiKey: 'jam_pk_xxx...',  // Your API Key
);
```

**That's it!** Project is auto-detected from API Key.

## 3. Basic Operations

### Database

```dart
// Create
await jam.db.collection('tasks').add({
  'title': 'Buy groceries',
  'done': false,
});

// Read
final tasks = await jam.db.collection('tasks').list();

// Update
await jam.db.collection('tasks').update('doc-id', {
  'done': true,
});

// Delete
await jam.db.collection('tasks').delete('doc-id');
```

### Storage

```dart
// Upload
await jam.storage.upload('/path/to/file.pdf');

// List files
final files = await jam.storage.listFiles();

// Download
final bytes = await jam.storage.downloadBytes('filename.pdf');
```

### Project User Auth (Multi-tenant)

```dart
final auth = jam.projectAuth('project-id');

// Register
await auth.register(email: 'user@test.com', password: 'pass123');

// Login
await auth.login(email: 'user@test.com', password: 'pass123');

// Get current user
final me = await auth.me();
```

## 4. Error Handling

```dart
try {
  await jam.db.collection('users').get('invalid');
} on JamException catch (e) {
  print('Error: ${e.message}');
  if (e.isNotFound) print('Document not found');
}
```

## 5. Full Example

```dart
import 'package:jam_server_sdk/jam.dart';

void main() async {
  final jam = Jam(
    'https://api.jamteches.com',
    apiKey: 'jam_pk_xxx',
  );

  // Add a task
  final task = await jam.db.collection('tasks').add({
    'title': 'Learn Jam SDK',
    'created': DateTime.now().toIso8601String(),
  });
  print('Created: ${task['id']}');

  // List all tasks
  final tasks = await jam.db.collection('tasks').list();
  print('Total tasks: ${tasks.length}');

  // Clean up
  jam.dispose();
}
```

---

📚 For full documentation, see [README.md](README.md)
