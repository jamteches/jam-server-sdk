import 'jam_client.dart';

/// Media conversion service for audio/video processing
/// 
/// Supports video/audio conversion, compression, trimming, and more.
/// 
/// Example:
/// ```dart
/// final jam = Jam('https://api.jamteches.com');
/// await jam.auth.login(username: 'john', password: 'pass');
/// 
/// // Convert video to MP4
/// final result = await jam.media.convertVideo(
///   '/path/to/video.avi',
///   outputFormat: 'mp4',
///   resolution: '1280x720',
/// );
/// 
/// // Extract audio from video
/// final audio = await jam.media.extractAudio(
///   '/path/to/video.mp4',
///   audioFormat: 'mp3',
/// );
/// 
/// // Generate thumbnail
/// final thumbnail = await jam.media.generateThumbnail(
///   '/path/to/video.mp4',
///   timeOffset: '00:00:05',
/// );
/// ```
class MediaService {
  final JamClient _client;

  MediaService(this._client);

  /// Get supported formats and codecs
  Future<Map<String, dynamic>> getSupportedFormats() async {
    return await _client.get('/api/ai/convert/supported');
  }

  /// Get media file information
  Future<Map<String, dynamic>> getMediaInfo(String filePath) async {
    return await _client.postMultipart('/api/ai/convert/info', filePath);
  }

  // ==================== Video Conversion ====================

  /// Convert video to another format
  Future<dynamic> convertVideo(
    String filePath, {
    String outputFormat = 'mp4',
    String? resolution,
    String videoCodec = 'libx264',
    String audioCodec = 'aac',
    int crf = 23,
    String preset = 'medium',
  }) async {
    return await _client.postMultipart('/api/ai/convert/video', filePath, fields: {
      'output_format': outputFormat,
      if (resolution != null) 'resolution': resolution,
      'video_codec': videoCodec,
      'audio_codec': audioCodec,
      'crf': crf.toString(),
      'preset': preset,
    });
  }

  // ==================== Audio Conversion ====================

  /// Convert audio to another format
  Future<dynamic> convertAudio(
    String filePath, {
    String outputFormat = 'mp3',
    String bitrate = '192k',
    int sampleRate = 44100,
  }) async {
    return await _client.postMultipart('/api/ai/convert/audio', filePath, fields: {
      'output_format': outputFormat,
      'bitrate': bitrate,
      'sample_rate': sampleRate.toString(),
    });
  }

  /// Extract audio from video
  Future<dynamic> extractAudio(
    String filePath, {
    String audioFormat = 'mp3',
    String bitrate = '192k',
  }) async {
    return await _client.postMultipart('/api/ai/convert/extract-audio', filePath, fields: {
      'audio_format': audioFormat,
      'bitrate': bitrate,
    });
  }

  // ==================== Compression ====================

  /// Compress video file
  Future<dynamic> compress(
    String filePath, {
    int crf = 28,
    String preset = 'medium',
  }) async {
    return await _client.postMultipart('/api/ai/convert/compress', filePath, fields: {
      'crf': crf.toString(),
      'preset': preset,
    });
  }

  // ==================== Trimming ====================

  /// Trim video/audio file
  Future<dynamic> trim(
    String filePath, {
    required String startTime,
    required String endTime,
  }) async {
    return await _client.postMultipart('/api/ai/convert/trim', filePath, fields: {
      'start_time': startTime,
      'end_time': endTime,
    });
  }

  // ==================== Thumbnail ====================

  /// Generate thumbnail from video
  Future<dynamic> generateThumbnail(
    String filePath, {
    String timeOffset = '00:00:01',
    int width = 320,
  }) async {
    return await _client.postMultipart('/api/ai/convert/thumbnail', filePath, fields: {
      'time_offset': timeOffset,
      'width': width.toString(),
    });
  }

  // ==================== HLS Streaming ====================

  /// Convert video to HLS format for streaming
  Future<dynamic> convertToHLS(
    String filePath, {
    int segmentTime = 10,
  }) async {
    return await _client.postMultipart('/api/ai/convert/hls', filePath, fields: {
      'segment_time': segmentTime.toString(),
    });
  }

  // ==================== Generic Convert ====================

  /// Generic media conversion
  Future<dynamic> convert(
    String filePath, {
    required String outputFormat,
    Map<String, String>? options,
  }) async {
    final fields = {
      'output_format': outputFormat,
      ...?options,
    };
    return await _client.postMultipart('/api/ai/convert', filePath, fields: fields);
  }
}
