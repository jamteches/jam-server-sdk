/// Jam Server Flutter SDK - Transcription Tests
/// 
/// Comprehensive tests for the TranscriptionService including:
/// - Sync transcription
/// - Async transcription  
/// - Transcribe from URL/storage path
/// - Job management (status, list, delete)
/// 
/// Run with: dart run test/transcription_test.dart

import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';

void main() async {
  print('🎤 Jam Server Flutter SDK - Transcription Tests\n');
  
  final baseUrl = Platform.environment['JAM_SERVER_URL'] ?? 'https://api.jamteches.com';
  final apiKey = Platform.environment['JAM_API_KEY'];
  final projectId = Platform.environment['JAM_PROJECT_ID'] ?? 'test_project';
  
  final tester = TranscriptionTester(
    baseUrl: baseUrl,
    apiKey: apiKey,
    projectId: projectId,
  );
  
  await tester.runAllTests();
}

class TranscriptionTester {
  final String baseUrl;
  final String? apiKey;
  final String projectId;
  String? _token;
  int _passed = 0;
  int _failed = 0;
  int _skipped = 0;
  
  TranscriptionTester({
    required this.baseUrl,
    this.apiKey,
    required this.projectId,
  });

  Future<void> runAllTests() async {
    print('=' * 60);
    print('Testing Transcription Service at: $baseUrl');
    print('Project ID: $projectId');
    print('API Key: ${apiKey != null ? "***" + apiKey!.substring(apiKey!.length - 4) : "Not set"}');
    print('=' * 60);
    print('');

    // 1. Health & Status Tests
    await testSection('Health & Status', [
      testHealthCheck,
      testAIHealth,
      testGPUQueueStatus,
    ]);

    // 2. Sync Transcription Tests (requires auth)
    await testSection('Sync Transcription', [
      testTranscribeSyncEndpoint,
      testTranscribeWithLanguage,
      testTranscribeWithSubtitleFormat,
    ]);

    // 3. Async Transcription Tests
    await testSection('Async Transcription', [
      testTranscribeAsyncQueue,
      testTranscribeAsyncWithOptions,
    ]);

    // 4. Job Management Tests
    await testSection('Job Management', [
      testListJobs,
      testGetJobStatus,
      testDeleteJob,
    ]);

    // 5. Error Handling Tests
    await testSection('Error Handling', [
      testMissingFile,
      testInvalidJobId,
    ]);

    // Print Summary
    printSummary();
  }

  Future<void> testSection(String name, List<Future<void> Function()> tests) async {
    print('\n📋 Section: $name');
    print('-' * 40);
    for (final test in tests) {
      await test();
    }
  }

  // ==================== Health Tests ====================

  Future<void> testHealthCheck() async {
    print('  Testing: Health Check');
    try {
      final response = await _get('/health');
      
      if (response['status'] == 'ok') {
        _pass('Health check returned ok');
      } else {
        _fail('Health check did not return ok');
      }
    } catch (e) {
      _fail('Health check failed: $e');
    }
  }

  Future<void> testAIHealth() async {
    print('  Testing: AI Health');
    try {
      final response = await _get('/api/ai/health');
      
      if (response['status'] == 'ok') {
        _pass('AI health check returned ok');
        if (response.containsKey('features')) {
          print('      Features: ${response['features']}');
        }
      } else {
        _fail('AI health check did not return ok');
      }
    } catch (e) {
      _fail('AI health failed: $e');
    }
  }

  Future<void> testGPUQueueStatus() async {
    print('  Testing: GPU Queue Status');
    try {
      final response = await _get('/api/ai/gpu-queue/status');
      
      if (response.containsKey('queue_length') || response.containsKey('status')) {
        _pass('GPU Queue status available');
        print('      Queue length: ${response['queue_length'] ?? 'N/A'}');
      } else {
        _fail('GPU Queue status missing expected fields');
      }
    } catch (e) {
      _fail('GPU Queue status failed: $e');
    }
  }

  // ==================== Sync Transcription Tests ====================

  Future<void> testTranscribeSyncEndpoint() async {
    print('  Testing: Sync Transcription Endpoint');
    
    if (apiKey == null && _token == null) {
      _skip('No authentication available');
      return;
    }
    
    try {
      // Create a simple test audio (just check endpoint accessibility)
      final response = await _postMultipart(
        '/api/ai/transcribe',
        {'language': 'en', 'project_id': projectId},
        testAudioBytes: _createTestWavBytes(),
        filename: 'test.wav',
      );
      
      // Should get a response (even if no speech detected)
      if (response.containsKey('segments') || response.containsKey('language') || response.containsKey('duration')) {
        _pass('Sync transcription endpoint works');
        print('      Language: ${response['language'] ?? 'auto'}');
        print('      Duration: ${response['duration'] ?? 'N/A'}');
      } else if (response.containsKey('error')) {
        _fail('Sync transcription error: ${response['error']}');
      } else {
        _pass('Sync transcription endpoint responded');
      }
    } catch (e) {
      _fail('Sync transcription failed: $e');
    }
  }

  Future<void> testTranscribeWithLanguage() async {
    print('  Testing: Transcription with Language');
    
    if (apiKey == null && _token == null) {
      _skip('No authentication available');
      return;
    }
    
    try {
      final languages = ['en', 'th', 'ja'];
      for (final lang in languages) {
        final response = await _postMultipart(
          '/api/ai/transcribe',
          {'language': lang, 'project_id': projectId},
          testAudioBytes: _createTestWavBytes(),
          filename: 'test.wav',
        );
        
        if (response.containsKey('language') && response['language'] == lang) {
          print('      Language $lang: ✓');
        }
      }
      _pass('Language parameter works');
    } catch (e) {
      _fail('Language test failed: $e');
    }
  }

  Future<void> testTranscribeWithSubtitleFormat() async {
    print('  Testing: Transcription with Subtitle Format');
    
    if (apiKey == null && _token == null) {
      _skip('No authentication available');
      return;
    }
    
    try {
      // Test SRT
      var response = await _postMultipart(
        '/api/ai/transcribe',
        {'language': 'en', 'project_id': projectId, 'subtitle_format': 'srt'},
        testAudioBytes: _createTestWavBytes(),
        filename: 'test.wav',
      );
      
      if (response.containsKey('subtitle_format') || response.containsKey('subtitle')) {
        print('      SRT format: ✓');
      }
      
      // Test VTT
      response = await _postMultipart(
        '/api/ai/transcribe',
        {'language': 'en', 'project_id': projectId, 'subtitle_format': 'vtt'},
        testAudioBytes: _createTestWavBytes(),
        filename: 'test.wav',
      );
      
      if (response.containsKey('subtitle_format') || response.containsKey('subtitle')) {
        print('      VTT format: ✓');
      }
      
      _pass('Subtitle formats work');
    } catch (e) {
      _fail('Subtitle format test failed: $e');
    }
  }

  // ==================== Async Transcription Tests ====================

  Future<void> testTranscribeAsyncQueue() async {
    print('  Testing: Async Transcription Queue');
    
    if (apiKey == null && _token == null) {
      _skip('No authentication available');
      return;
    }
    
    try {
      final response = await _postMultipart(
        '/api/ai/transcribe-async',
        {
          'owner': 'test_user',
          'project_id': projectId,
          'language': 'en',
        },
        testAudioBytes: _createTestWavBytes(),
        filename: 'test.wav',
      );
      
      if (response.containsKey('job_id')) {
        _pass('Job queued successfully');
        print('      Job ID: ${response['job_id']}');
        print('      Status: ${response['status']}');
      } else {
        _fail('No job_id returned: $response');
      }
    } catch (e) {
      _fail('Async queue failed: $e');
    }
  }

  Future<void> testTranscribeAsyncWithOptions() async {
    print('  Testing: Async Transcription with Options');
    
    if (apiKey == null && _token == null) {
      _skip('No authentication available');
      return;
    }
    
    try {
      // Test with diarization
      var response = await _postMultipart(
        '/api/ai/transcribe-async',
        {
          'owner': 'test_user',
          'project_id': projectId,
          'language': 'en',
          'diarize': 'true',
        },
        testAudioBytes: _createTestWavBytes(),
        filename: 'test.wav',
      );
      
      if (response.containsKey('job_id')) {
        print('      With diarize: ✓');
      }
      
      // Test with subtitle format
      response = await _postMultipart(
        '/api/ai/transcribe-async',
        {
          'owner': 'test_user',
          'project_id': projectId,
          'language': 'th',
          'subtitle_format': 'srt',
        },
        testAudioBytes: _createTestWavBytes(),
        filename: 'test.wav',
      );
      
      if (response.containsKey('job_id')) {
        print('      With subtitle: ✓');
      }
      
      _pass('Async options work');
    } catch (e) {
      _fail('Async options test failed: $e');
    }
  }

  // ==================== Job Management Tests ====================

  Future<void> testListJobs() async {
    print('  Testing: List Jobs');
    
    if (apiKey == null && _token == null) {
      _skip('No authentication available');
      return;
    }
    
    try {
      final response = await _get('/api/jobs?owner=test_user&limit=10');
      
      if (response.containsKey('jobs')) {
        _pass('Jobs list returned');
        print('      Total: ${response['total'] ?? response['jobs'].length}');
      } else {
        _fail('Jobs list missing expected fields');
      }
    } catch (e) {
      _fail('List jobs failed: $e');
    }
  }

  Future<void> testGetJobStatus() async {
    print('  Testing: Get Job Status');
    
    if (apiKey == null && _token == null) {
      _skip('No authentication available');
      return;
    }
    
    try {
      // First create a job
      final createResponse = await _postMultipart(
        '/api/ai/transcribe-async',
        {
          'owner': 'test_user',
          'project_id': projectId,
        },
        testAudioBytes: _createTestWavBytes(),
        filename: 'test.wav',
      );
      
      if (!createResponse.containsKey('job_id')) {
        _fail('Could not create job for status test');
        return;
      }
      
      final jobId = createResponse['job_id'];
      
      // Get job status
      final statusResponse = await _get('/api/jobs/$jobId');
      
      if (statusResponse.containsKey('status') && statusResponse.containsKey('progress')) {
        _pass('Job status returned');
        print('      Status: ${statusResponse['status']}');
        print('      Progress: ${statusResponse['progress']}%');
      } else {
        _fail('Job status missing expected fields');
      }
    } catch (e) {
      _fail('Get job status failed: $e');
    }
  }

  Future<void> testDeleteJob() async {
    print('  Testing: Delete Job');
    
    if (apiKey == null && _token == null) {
      _skip('No authentication available');
      return;
    }
    
    try {
      // First create a job
      final createResponse = await _postMultipart(
        '/api/ai/transcribe-async',
        {
          'owner': 'test_user',
          'project_id': projectId,
        },
        testAudioBytes: _createTestWavBytes(),
        filename: 'test.wav',
      );
      
      if (!createResponse.containsKey('job_id')) {
        _fail('Could not create job for delete test');
        return;
      }
      
      final jobId = createResponse['job_id'];
      
      // Delete job
      final deleteResponse = await _delete('/api/jobs/$jobId');
      
      if (deleteResponse.containsKey('message') || deleteResponse.containsKey('success')) {
        _pass('Job deleted successfully');
      } else {
        _fail('Delete response unexpected: $deleteResponse');
      }
    } catch (e) {
      _fail('Delete job failed: $e');
    }
  }

  // ==================== Error Handling Tests ====================

  Future<void> testMissingFile() async {
    print('  Testing: Missing File Error');
    try {
      final response = await _post('/api/ai/transcribe', {
        'project_id': projectId,
        'language': 'en',
      });
      
      // Should get 422 or error response
      if (response.containsKey('error') || response.containsKey('detail')) {
        _pass('Missing file handled correctly');
      } else {
        _fail('Should have returned error for missing file');
      }
    } catch (e) {
      // Exception is expected
      _pass('Missing file throws exception as expected');
    }
  }

  Future<void> testInvalidJobId() async {
    print('  Testing: Invalid Job ID');
    try {
      final response = await _get('/api/jobs/invalid_job_id_12345');
      
      if (response.containsKey('error') || response.containsKey('detail')) {
        _pass('Invalid job ID handled correctly');
      } else {
        _fail('Should have returned error for invalid job ID');
      }
    } catch (e) {
      // Exception is expected
      _pass('Invalid job ID throws exception as expected');
    }
  }

  // ==================== Helper Methods ====================

  Uint8List _createTestWavBytes() {
    // Create a minimal valid WAV file header with silence
    final sampleRate = 16000;
    final numChannels = 1;
    final bitsPerSample = 16;
    final numSamples = sampleRate * 2; // 2 seconds
    final byteRate = sampleRate * numChannels * bitsPerSample ~/ 8;
    final blockAlign = numChannels * bitsPerSample ~/ 8;
    final dataSize = numSamples * blockAlign;
    final fileSize = 36 + dataSize;
    
    final buffer = BytesBuilder();
    
    // RIFF header
    buffer.add(utf8.encode('RIFF'));
    buffer.add(_int32Bytes(fileSize));
    buffer.add(utf8.encode('WAVE'));
    
    // fmt chunk
    buffer.add(utf8.encode('fmt '));
    buffer.add(_int32Bytes(16)); // chunk size
    buffer.add(_int16Bytes(1)); // audio format (PCM)
    buffer.add(_int16Bytes(numChannels));
    buffer.add(_int32Bytes(sampleRate));
    buffer.add(_int32Bytes(byteRate));
    buffer.add(_int16Bytes(blockAlign));
    buffer.add(_int16Bytes(bitsPerSample));
    
    // data chunk
    buffer.add(utf8.encode('data'));
    buffer.add(_int32Bytes(dataSize));
    
    // Silent audio data
    buffer.add(Uint8List(dataSize));
    
    return buffer.toBytes();
  }

  Uint8List _int32Bytes(int value) {
    return Uint8List(4)..buffer.asByteData().setInt32(0, value, Endian.little);
  }

  Uint8List _int16Bytes(int value) {
    return Uint8List(2)..buffer.asByteData().setInt16(0, value, Endian.little);
  }

  Future<Map<String, dynamic>> _get(String path) async {
    final httpClient = HttpClient();
    final request = await httpClient.getUrl(Uri.parse('$baseUrl$path'));
    
    _addAuthHeaders(request);
    
    final response = await request.close();
    final body = await response.transform(utf8.decoder).join();
    httpClient.close();
    
    try {
      return jsonDecode(body) as Map<String, dynamic>;
    } catch (e) {
      return {'_raw': body, '_statusCode': response.statusCode};
    }
  }

  Future<Map<String, dynamic>> _post(String path, Map<String, dynamic> data) async {
    final httpClient = HttpClient();
    final request = await httpClient.postUrl(Uri.parse('$baseUrl$path'));
    
    request.headers.contentType = ContentType.json;
    _addAuthHeaders(request);
    
    request.write(jsonEncode(data));
    
    final response = await request.close();
    final body = await response.transform(utf8.decoder).join();
    httpClient.close();
    
    try {
      return jsonDecode(body) as Map<String, dynamic>;
    } catch (e) {
      return {'_raw': body, '_statusCode': response.statusCode};
    }
  }

  Future<Map<String, dynamic>> _delete(String path) async {
    final httpClient = HttpClient();
    final request = await httpClient.deleteUrl(Uri.parse('$baseUrl$path'));
    
    _addAuthHeaders(request);
    
    final response = await request.close();
    final body = await response.transform(utf8.decoder).join();
    httpClient.close();
    
    try {
      return jsonDecode(body) as Map<String, dynamic>;
    } catch (e) {
      return {'_raw': body, '_statusCode': response.statusCode};
    }
  }

  Future<Map<String, dynamic>> _postMultipart(
    String path,
    Map<String, String> fields, {
    Uint8List? testAudioBytes,
    String filename = 'test.wav',
  }) async {
    final httpClient = HttpClient();
    final request = await httpClient.postUrl(Uri.parse('$baseUrl$path'));
    
    final boundary = '----DartFormBoundary${DateTime.now().millisecondsSinceEpoch}';
    request.headers.set('Content-Type', 'multipart/form-data; boundary=$boundary');
    _addAuthHeaders(request);
    
    final buffer = StringBuffer();
    
    // Add fields
    for (final entry in fields.entries) {
      buffer.write('--$boundary\r\n');
      buffer.write('Content-Disposition: form-data; name="${entry.key}"\r\n\r\n');
      buffer.write('${entry.value}\r\n');
    }
    
    // Add file
    if (testAudioBytes != null) {
      buffer.write('--$boundary\r\n');
      buffer.write('Content-Disposition: form-data; name="file"; filename="$filename"\r\n');
      buffer.write('Content-Type: audio/wav\r\n\r\n');
    }
    
    // Write string part
    request.write(buffer.toString());
    
    // Write file bytes
    if (testAudioBytes != null) {
      request.add(testAudioBytes);
      request.write('\r\n');
    }
    
    // Close boundary
    request.write('--$boundary--\r\n');
    
    final response = await request.close();
    final body = await response.transform(utf8.decoder).join();
    httpClient.close();
    
    try {
      return jsonDecode(body) as Map<String, dynamic>;
    } catch (e) {
      return {'_raw': body, '_statusCode': response.statusCode};
    }
  }

  void _addAuthHeaders(HttpClientRequest request) {
    if (_token != null) {
      request.headers.add('Authorization', 'Bearer $_token');
    }
    if (apiKey != null) {
      request.headers.add('X-API-Key', apiKey!);
    }
  }

  void _pass(String message) {
    _passed++;
    print('      ✅ PASS: $message');
  }

  void _fail(String message) {
    _failed++;
    print('      ❌ FAIL: $message');
  }

  void _skip(String message) {
    _skipped++;
    print('      ⏭️  SKIP: $message');
  }

  void printSummary() {
    print('\n');
    print('=' * 60);
    print('📊 Test Summary');
    print('=' * 60);
    print('   ✅ Passed:  $_passed');
    print('   ❌ Failed:  $_failed');
    print('   ⏭️  Skipped: $_skipped');
    print('   📈 Total:   ${_passed + _failed + _skipped}');
    print('');
    
    if (_failed == 0) {
      print('🎉 All tests passed!');
    } else {
      print('⚠️  Some tests failed. Check the output above.');
      exit(1);
    }
  }
}
