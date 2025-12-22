# Jam Server Flutter SDK - Changelog

## v2.2.1 (2025-12-21)

### 🐛 Bug Fixes

- **JamException Constructor**: Fixed incorrect positional arguments to use named parameters (`statusCode:`, `message:`)
- **chunked_upload_service.dart**: Fixed all JamException calls and `_client.post()` calls to use named `body:` parameter
- **project_auth_service.dart**: Fixed JamException calls to use correct named parameters
- **transcription_service.dart**: Moved `updateSpeakerNames()` and `getSpeakerStats()` methods inside `TranscriptionService` class
- **getJob() method**: Added missing `getJob()` method to `TranscriptionService` for fetching completed job results
- **API endpoints**: Fixed `/jobs/$jobId/speakers` to use correct `/api/jobs/$jobId/speakers` path

---

## v2.2.0 (2025-12-21)

### 🎉 New Features

#### Enhanced Transcription
- **Improved Diarization Accuracy**: Optimized speaker detection for meeting scenarios
- **Better Thai Language Support**: Enhanced transcription accuracy for Thai audio
- **Progress Callbacks**: Real-time progress updates during transcription

#### API Improvements
- **Bulk Operations**: Support for bulk delete operations
- **Better Error Handling**: More descriptive error messages
- **Timeout Configuration**: Configurable request timeouts

### 🔧 Improvements

- Optimized network requests for large file uploads
- Improved WebSocket reconnection logic
- Better memory management for chunked uploads
- Enhanced logging for debugging

### 📚 Documentation

- Complete API documentation at https://api.jamteches.com/docs
- Updated examples for all SDK features
- Added troubleshooting guide

---

## v1.3.0 (2025-12-18)

### 🎉 New Features

#### Speaker Diarization & Name Mapping
- **Speaker Diarization**: Automatically detect and separate different speakers in audio/video
- **Speaker Name Mapping**: Map generic speaker IDs (SPEAKER_00, SPEAKER_01) to real names
- **Speaker Statistics**: Get analytics on who spoke how much

#### New Methods in `TranscriptionService`:

**`updateSpeakerNames(jobId, speakerMapping)`**
- Update speaker IDs with real names after transcription
- Example:
  ```dart
  await jam.transcription.updateSpeakerNames(
    jobId,
    {'SPEAKER_00': 'John', 'SPEAKER_01': 'Jane'},
  );
  ```

**`getSpeakerStats(jobId)`**
- Get statistics about speakers (segment count per speaker)
- Useful for determining who the main speaker is
- Returns: `Map<String, int>` with speaker IDs and counts

### 🔧 Improvements

- Enhanced transcription documentation with diarization examples
- Added complete workflow examples for speaker identification
- Improved inline documentation for all diarization methods

### 📚 Documentation

- Added comprehensive diarization guide in README
- Examples for complete speaker identification workflow
- Speaker stats and mapping usage patterns

### 🐛 Bug Fixes

- Fixed speaker field handling in `TranscriptSegment`
- Improved null safety for speaker data

---

## v1.2.0 (Previous)

### Features
- Chunked file upload support
- Transcription async/sync modes
- Real-time updates via WebSocket
- Project user authentication
- Storage operations

---

## Usage Example

```dart
// Full diarization workflow
final job = await jam.transcription.transcribeAsync(
  audioFile,
  projectId: 'my-project',
  diarize: true,
);

final result = await jam.transcription.waitForCompletion(job['job_id']);

// Get speaker stats
final stats = await jam.transcription.getSpeakerStats(job['job_id']);
print(stats); // {SPEAKER_00: 45, SPEAKER_01: 23}

// Map to real names
await jam.transcription.updateSpeakerNames(
  job['job_id'],
  {'SPEAKER_00': 'CEO', 'SPEAKER_01': 'Manager'},
);

// Use updated result
final updated = await jam.transcription.getJob(job['job_id']);
print(updated.segments[0].speaker); // "CEO"
```

---

**For full documentation, see [README.md](README.md)**
