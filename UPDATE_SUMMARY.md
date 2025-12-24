# Flutter SDK Update Summary

## 📦 Updated Package Ready!

**File**: `flutter-sdk.zip` (45 KB)  
**Location**: `/home/sleepassin/Desktop/Jam-Server/sdk/flutter/flutter-sdk.zip`

---

## 🆕 What's New in v1.3.0

### Speaker Diarization & Name Mapping

1. **New Method**: `updateSpeakerNames(jobId, speakerMapping)`
   - Map speaker IDs to real names
   - Example: `SPEAKER_00` → `"CEO"`

2. **New Method**: `getSpeakerStats(jobId)`
   - Get speaker statistics
   - Returns: `{SPEAKER_00: 45, SPEAKER_01: 23}`

3. **Enhanced Diarization Support**
   - `diarize: true` parameter in transcribeAsync
   - `speaker` field in TranscriptSegment
   - Full workflow examples

---

## 📋 Updated Files

| File | Changes |
|------|---------|
| `lib/src/transcription_service.dart` | +98 lines - Added speaker mapping methods |
| `README.md` | +107 lines - Added diarization documentation |
| `CHANGELOG.md` | New file - Version history |

---

## 🚀 Quick Usage Guide for Flutter Team

### 1. Add to Project

```yaml
# pubspec.yaml
dependencies:
  jam_server_sdk:
    path: ./sdk/flutter  # or extract zip
```

### 2. Basic Diarization

```dart
import 'package:jam_server_sdk/jam.dart';

// Initialize
final jam = Jam('https://api.jamteches.com');

// Transcribe with diarization
final job = await jam.transcription.transcribeAsync(
  audioFilePath,
  projectId: 'my-project',
  language: 'th',
  diarize: true,  // ← Enable speaker detection
);

// Wait for completion
final result = await jam.transcription.waitForCompletion(
  job['job_id'],
  onProgress: (progress) => print('$progress%'),
);

// Check speakers
print('Speakers: ${result.segments.map((s) => s.speaker).toSet()}');
// Output: {SPEAKER_00, SPEAKER_01, SPEAKER_02}
```

### 3. Map Speaker Names

```dart
// Get speaker statistics
final stats = await jam.transcription.getSpeakerStats(job['job_id']);
print(stats);
// {SPEAKER_00: 45, SPEAKER_01: 23, SPEAKER_02: 12}

// Update with real names
await jam.transcription.updateSpeakerNames(
  job['job_id'],
  {
    'SPEAKER_00': 'CEO',
    'SPEAKER_01': 'Manager',
    'SPEAKER_02': 'Employee',
  },
);

// Get updated result
final updated = await jam.transcription.getJob(job['job_id']);

// Display with names
for (final segment in updated.segments) {
  print('[${segment.start}s] ${segment.speaker}: ${segment.text}');
}
// Output:
// [0.0s] CEO: Let's discuss the quarterly results
// [5.2s] Manager: Sales increased by 15%
```

---

## 📊 Recommended UI Flow

```
1. User uploads audio/video
   └─> Show: "Processing..."

2. Transcription completes
   └─> Detect speakers: SPEAKER_00, SPEAKER_01, ...
   
3. Show dialog/form:
   "We detected 3 speakers. Please identify them:"
   - SPEAKER_00 (45 segments): [____] 
   - SPEAKER_01 (23 segments): [____]
   - SPEAKER_02 (12 segments): [____]
   
4. User enters names:
   - SPEAKER_00: "John"
   - SPEAKER_01: "Jane"
   - SPEAKER_02: "Bob"
   
5. Call updateSpeakerNames()
   └─> Transcript now shows real names
```

---

## 🎯 Key Points for Flutter Team

1. **Diarization is Optional**
   - Set `diarize: false` (default) for normal transcription
   - Set `diarize: true` for speaker detection

2. **Performance**
   - Without diarization: ~7x realtime
   - With diarization: ~5-6x realtime
   - 20-minute audio ≈ 3-4 minutes processing

3. **Speaker Mapping is Manual**
   - System only detects "someone spoke" (SPEAKER_XX)
   - User must provide real names
   - Use `getSpeakerStats()` to help user decide

4. **API Support Required**
   - Backend needs `/jobs/{id}/speakers` endpoint
   - I'll implement if needed

---

## 📚 Documentation

All examples are in:
- `README.md` - Complete guide
- `CHANGELOG.md` - Version history
- `lib/src/transcription_service.dart` - Inline docs

---

## 🔄 Next Steps for Backend

If Flutter team needs the API endpoint, I need to add:

```go
// In backend/go/jobs.go
func updateSpeakerNamesHandler(w http.ResponseWriter, r *http.Request) {
    // Call Python speaker_mapping.py
}
```

**Need this? Let me know!**

---

## ✅ Ready to Deploy

The SDK is ready for the Flutter team to integrate. Package contains:
- Updated Dart code
- Complete documentation
- Usage examples
- Changelog

**Send them**: `flutter-sdk.zip` (45 KB)
