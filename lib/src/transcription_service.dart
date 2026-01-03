import 'dart:async';
import 'models.dart';
import 'jam_client.dart';

/// Transcription service for audio/video transcription
/// 
/// Supports sync and async transcription with speaker diarization.
/// Optimized for Thai language but supports all languages.
/// 
/// Key Features:
/// - **5x realtime speed** on GPU
/// - **Anti-hallucination** text cleanup
/// - **Automatic duplicate removal**
/// - **SRT/VTT subtitle generation**
/// 
/// Example:
/// ```dart
/// final jam = Jam('https://api.jamteches.com');
/// await jam.auth.login(username: 'john', password: 'pass');
/// 
/// // Sync transcription (for small files < 5 min)
/// final result = await jam.transcription.transcribe(
///   '/path/to/audio.mp3',
///   projectId: 'my-project',
///   language: 'th',
/// );
/// print('Segments: ${result['segments'].length}');
/// 
/// // Async transcription for large files (recommended)
/// final job = await jam.transcription.transcribeAsync(
///   '/path/to/video.mp4',
///   projectId: 'my-project',
///   language: 'th',
/// );
/// 
/// // Wait for completion with polling
/// final transcription = await jam.transcription.waitForCompletion(
///   job['job_id'],
///   onProgress: (progress) => print('Progress: $progress%'),
/// );
/// print('Done! ${transcription.segments.length} segments');
/// ```
class TranscriptionService {
  final JamClient _client;

  TranscriptionService(this._client);

  // ==================== Sync Transcription ====================

  /// Transcribe audio/video file synchronously
  /// 
  /// **For small files (< 5 min).** For larger files, use [transcribeAsync].
  /// 
  /// Parameters:
  /// - [filePath]: Local path to audio/video file
  /// - [projectId]: Project ID for organization
  /// - [language]: Language code (e.g., 'th', 'en', 'ja'). Auto-detect if null.
  /// - [diarize]: Enable speaker diarization
  /// - [subtitleFormat]: Generate subtitles ('srt' or 'vtt')
  Future<Map<String, dynamic>> transcribe(
    String filePath, {
    String? projectId,
    String? language,
    bool diarize = false,
    String? subtitleFormat,
  }) async {
    final fields = <String, String>{};
    if (projectId != null) fields['project_id'] = projectId;
    if (language != null) fields['language'] = language;
    fields['diarize'] = diarize.toString();
    if (subtitleFormat != null) fields['subtitle_format'] = subtitleFormat;
    
    return await _client.postMultipart('/api/ai/transcribe', filePath, fields: fields);
  }

  // ==================== Async Transcription ====================

  /// Queue audio/video file for async transcription
  /// 
  /// **Recommended for all files.** Returns immediately with job ID.
  /// 
  /// Returns job info including:
  /// - `job_id`: Use with [getJobStatus] or [waitForCompletion]
  /// - `status`: Initial status ('pending')
  /// 
  /// Example:
  /// ```dart
  /// final job = await jam.transcription.transcribeAsync(
  ///   '/path/to/meeting.mp4',
  ///   projectId: 'my-project',
  ///   language: 'th',  // Thai
  /// );
  /// 
  /// // Then wait for completion
  /// final result = await jam.transcription.waitForCompletion(job['job_id']);
  /// ```
  Future<Map<String, dynamic>> transcribeAsync(
    String filePath, {
    required String projectId,
    String? language,
    bool diarize = false,
    String? subtitleFormat,
  }) async {
    final fields = <String, String>{
      'project_id': projectId,
    };
    if (language != null) fields['language'] = language;
    fields['diarize'] = diarize.toString();
    if (subtitleFormat != null) fields['subtitle_format'] = subtitleFormat;
    
    return await _client.postMultipart('/api/ai/transcribe-async', filePath, fields: fields);
  }

  /// Transcribe from file URL or storage path (no re-upload needed)
  /// 
  /// Use this for files already uploaded to storage via chunked upload.
  /// 
  /// Example:
  /// ```dart
  /// // After chunked upload
  /// final uploadResult = await jam.chunkedUpload.uploadBytes(...);
  /// 
  /// // Transcribe without re-uploading
  /// final job = await jam.transcription.transcribeByUrl(
  ///   projectId: 'my-project',
  ///   fileUrl: uploadResult['url'],  // e.g., '/storage/project_id/file.wav'
  ///   language: 'th',
  ///   async: true,  // Recommended for large files
  /// );
  /// ```
  Future<Map<String, dynamic>> transcribeByUrl({
    required String projectId,
    String? fileUrl,
    String? storagePath,
    String? language,
    bool async = true,
  }) async {
    if (fileUrl == null && storagePath == null) {
      throw JamException(
        statusCode: 400,
        message: 'Either fileUrl or storagePath is required',
      );
    }
    
    return await _client.post('/api/ai/transcribe-url', body: {
      'project_id': projectId,
      if (fileUrl != null) 'file_url': fileUrl,
      if (storagePath != null) 'storage_path': storagePath,
      if (language != null) 'language': language,
      'async': async,
    });
  }

  // ==================== Job Queue ====================

  /// Get transcription job status
  /// 
  /// Returns job info including:
  /// - `status`: 'pending', 'processing', 'completed', 'failed'
  /// - `progress`: 0-100
  /// - `result`: Transcription result when completed
  /// - `error`: Error message if failed
  Future<Map<String, dynamic>> getJobStatus(String jobId) async {
    return await _client.get('/api/jobs/$jobId');
  }

  /// Wait for transcription to complete with polling
  /// 
  /// Polls job status every [pollInterval] until completed or failed.
  /// 
  /// Parameters:
  /// - [jobId]: Job ID from [transcribeAsync]
  /// - [pollInterval]: Seconds between polls (default 5)
  /// - [timeout]: Max wait time in seconds (default 30 min)
  /// - [onProgress]: Callback for progress updates
  /// 
  /// Returns [TranscriptionResult] on success.
  /// Throws [JamException] on failure or timeout.
  /// 
  /// Example:
  /// ```dart
  /// final result = await jam.transcription.waitForCompletion(
  ///   jobId,
  ///   onProgress: (progress) => print('Progress: $progress%'),
  /// );
  /// 
  /// for (final segment in result.segments) {
  ///   print('[${segment.start}s] ${segment.text}');
  /// }
  /// ```
  Future<TranscriptionResult> waitForCompletion(
    String jobId, {
    int pollInterval = 5,
    int timeout = 1800, // 30 minutes
    void Function(int progress)? onProgress,
  }) async {
    final startTime = DateTime.now();
    
    while (true) {
      // Check timeout
      if (DateTime.now().difference(startTime).inSeconds > timeout) {
        throw JamException(
          statusCode: 408,
          message: 'Transcription timed out after $timeout seconds',
        );
      }
      
      // Get status
      final status = await getJobStatus(jobId);
      final jobStatus = status['status'] as String?;
      final progress = status['progress'] as int? ?? 0;
      
      // Report progress
      if (onProgress != null) {
        onProgress(progress);
      }
      
      // Check status
      if (jobStatus == 'completed') {
        final result = status['result'] as Map<String, dynamic>?;
        if (result == null) {
          throw JamException(
            statusCode: 500,
            message: 'Transcription completed but no result returned',
          );
        }
        return TranscriptionResult.fromJson(result);
      }
      
      if (jobStatus == 'failed') {
        final error = status['error'] as String? ?? 'Unknown error';
        throw JamException(
          statusCode: 500,
          message: 'Transcription failed: $error',
        );
      }
      
      // Wait before next poll
      await Future.delayed(Duration(seconds: pollInterval));
    }
  }

  /// List all transcription jobs
  Future<Map<String, dynamic>> listJobs({
    String? projectId,
    int limit = 20,
  }) async {
    final params = <String, String>{
      'limit': limit.toString(),
    };
    if (projectId != null) params['project_id'] = projectId;
    
    return await _client.get('/api/jobs', queryParams: params);
  }

  /// Delete a transcription job
  Future<Map<String, dynamic>> deleteJob(String jobId) async {
    return await _client.delete('/api/jobs/$jobId');
  }

  // ==================== Transcription Records ====================

  /// Create a transcription record
  Future<Map<String, dynamic>> create({
    required String projectId,
    required String filename,
    required String language,
    required double duration,
    required List<JamTranscriptSegment> segments,
    String? subtitle,
    String? subtitleFormat,
    bool diarizationEnabled = false,
    List<String>? speakers,
    bool isVideo = false,
  }) async {
    return await _client.post('/api/transcriptions', body: {
      'project_id': projectId,
      'filename': filename,
      'language': language,
      'duration': duration,
      'segments': segments.map((s) => s.toJson()).toList(),
      if (subtitle != null) 'subtitle': subtitle,
      if (subtitleFormat != null) 'subtitle_format': subtitleFormat,
      'diarization_enabled': diarizationEnabled,
      if (speakers != null) 'speakers': speakers,
      'is_video': isVideo,
    });
  }

  /// List transcriptions
  Future<Map<String, dynamic>> list({
    String? projectId,
    int page = 1,
    int limit = 20,
  }) async {
    final params = <String, String>{
      'page': page.toString(),
      'limit': limit.toString(),
    };
    if (projectId != null) params['project_id'] = projectId;
    
    return await _client.get('/api/transcriptions', queryParams: params);
  }

  /// Get a transcription by ID
  Future<Map<String, dynamic>> get(String id) async {
    return await _client.get('/api/transcriptions/$id');
  }

  /// Delete a transcription
  Future<Map<String, dynamic>> delete(String id) async {
    return await _client.delete('/api/transcriptions/$id');
  }

  /// Search transcriptions
  Future<List<dynamic>> search({
    String? query,
    String? language,
    String? projectId,
  }) async {
    final params = <String, String>{};
    if (query != null) params['q'] = query;
    if (language != null) params['language'] = language;
    if (projectId != null) params['project_id'] = projectId;
    
    final response = await _client.get('/api/transcriptions/search', queryParams: params);
    if (response is List) return response;
    return response['data'] ?? [];
  }

  // ==================== Speaker Name Mapping ====================

  /// Get full job details including result with segments
  /// 
  /// Returns a TranscriptionResult with all segments for a completed job.
  Future<TranscriptionResult> getJob(String jobId) async {
    final status = await getJobStatus(jobId);
    final result = status['result'] as Map<String, dynamic>?;
    if (result == null) {
      throw JamException(
        statusCode: 404,
        message: 'Job result not found or job not completed',
      );
    }
    return TranscriptionResult.fromJson(result);
  }

  /// Update speaker names in a completed transcription job
  /// 
  /// Maps generic speaker IDs (SPEAKER_00, SPEAKER_01, etc.) to real names.
  /// This is useful after diarization to identify who said what.
  /// 
  /// **Parameters:**
  /// - `jobId`: The transcription job ID
  /// - `speakerMapping`: Map of speaker IDs to real names
  ///   Example: {'SPEAKER_00': 'John', 'SPEAKER_01': 'Jane'}
  /// 
  /// **Returns:** Updated job data with mapped speaker names
  /// 
  /// **Example:**
  /// ```dart
  /// // 1. Transcribe with diarization
  /// final job = await jam.transcription.transcribeAsync(
  ///   audioFile,
  ///   projectId: 'my-project',
  ///   diarize: true,
  /// );
  /// 
  /// // 2. Wait for completion
  /// final result = await jam.transcription.waitForCompletion(job['job_id']);
  /// 
  /// // 3. Check who spoke
  /// final speakers = result.segments
  ///   .map((s) => s.speaker)
  ///   .where((s) => s != null)
  ///   .toSet();
  /// print('Detected speakers: $speakers');
  /// // Output: {SPEAKER_00, SPEAKER_01, SPEAKER_02}
  /// 
  /// // 4. Map to real names
  /// await jam.transcription.updateSpeakerNames(
  ///   job['job_id'],
  ///   {
  ///     'SPEAKER_00': 'CEO',
  ///     'SPEAKER_01': 'Manager',
  ///     'SPEAKER_02': 'Employee',
  ///   },
  /// );
  /// 
  /// // 5. Get updated result
  /// final updated = await jam.transcription.getJob(job['job_id']);
  /// print(updated.segments[0].speaker); // "CEO" instead of "SPEAKER_00"
  /// ```
  Future<Map<String, dynamic>> updateSpeakerNames(
    String jobId,
    Map<String, String> speakerMapping,
  ) async {
    return await _client.post(
      '/api/jobs/$jobId/speakers',
      body: {
        'speaker_mapping': speakerMapping,
      },
    );
  }

  /// Update speaker names in a saved transcription
  /// 
  /// Maps generic speaker IDs to real names for a permanent transcription record.
  /// 
  /// **Parameters:**
  /// - [id]: Transcription ID (not Job ID)
  /// - [speakerMapping]: Map of "SPEAKER_XX" -> "Real Name"
  Future<Map<String, dynamic>> updateTranscriptionSpeakers(
    String id,
    Map<String, String> speakerMapping,
  ) async {
    return await _client.patch('/api/transcriptions/$id/speakers', body: {
      'speaker_mapping': speakerMapping,
    });
  }

  /// Get speaker statistics for a transcription job
  /// 
  /// Returns the number of segments per speaker, useful for understanding
  /// who spoke the most before mapping names.
  /// 
  /// **Returns:** Map of speaker IDs to segment counts
  /// 
  /// **Example:**
  /// ```dart
  /// final stats = await jam.transcription.getSpeakerStats(jobId);
  /// print(stats);
  /// // Output: {'SPEAKER_00': 45, 'SPEAKER_01': 23, 'SPEAKER_02': 12}
  /// 
  /// // Find the main speaker
  /// final entries = stats.entries.toList()
  ///   ..sort((a, b) => b.value.compareTo(a.value));
  /// print('Main speaker: ${entries.first.key} (${entries.first.value} segments)');
  /// ```
  Future<Map<String, int>> getSpeakerStats(String jobId) async {
    final job = await getJob(jobId);
    final stats = <String, int>{};
    
    for (final segment in job.segments) {
      if (segment.speaker != null) {
        stats[segment.speaker!] = (stats[segment.speaker!] ?? 0) + 1;
      }
    }
    
    return stats;
  }
}

// ==================== Models ====================

/// Complete transcription result
class TranscriptionResult {
  final String language;
  final double languageProbability;
  final double duration;
  final List<JamTranscriptSegment> segments;
  final bool isVideo;
  final String? subtitle;
  final String? subtitleFormat;
  
  TranscriptionResult({
    required this.language,
    required this.languageProbability,
    required this.duration,
    required this.segments,
    this.isVideo = false,
    this.subtitle,
    this.subtitleFormat,
  });
  
  /// Duration in minutes
  double get durationMinutes => duration / 60;
  
  /// Full transcript text
  String get fullText => segments.map((s) => s.text).join(' ');
  
  factory TranscriptionResult.fromJson(Map<String, dynamic> json) {
    final segmentsList = json['segments'] as List<dynamic>? ?? [];
    return TranscriptionResult(
      language: json['language'] as String? ?? 'unknown',
      languageProbability: (json['language_probability'] as num?)?.toDouble() ?? 0.0,
      duration: (json['duration'] as num?)?.toDouble() ?? 0.0,
      segments: segmentsList.map((s) => JamTranscriptSegment.fromJson(s)).toList(),
      isVideo: json['is_video'] as bool? ?? false,
      subtitle: json['subtitle'] as String?,
      subtitleFormat: json['subtitle_format'] as String?,
    );
  }
  
  Map<String, dynamic> toJson() => {
    'language': language,
    'language_probability': languageProbability,
    'duration': duration,
    'segments': segments.map((s) => s.toJson()).toList(),
    'is_video': isVideo,
    if (subtitle != null) 'subtitle': subtitle,
    if (subtitleFormat != null) 'subtitle_format': subtitleFormat,
  };
}

