/// Jam SDK Transcription Flow Test
/// Tests: Chunked Upload -> Transcribe -> Get Result
/// 
/// Usage: dart run test_transcription_flow.dart

import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:crypto/crypto.dart';

const baseUrl = 'http://localhost:8000';
const aiUrl = 'http://localhost:8001';
const adminUser = 'jam_admin';
const adminPass = 'Admin@2024!';
const projectId = '692d79007214ae6e80e63d7a';
const chunkSize = 5 * 1024 * 1024; // 5MB

String? token;

void main() async {
  print('╔══════════════════════════════════════════════════════════════╗');
  print('║   🎤 JAM SDK TRANSCRIPTION FLOW TEST                        ║');
  print('╚══════════════════════════════════════════════════════════════╝');
  print('');
  print('📅 Test Date: ${DateTime.now()}');
  print('🔗 Base URL: $baseUrl');
  print('');

  try {
    // Step 1: Login
    await step1Login();

    // Step 2: Check audio file
    final audioFile = await step2CheckAudioFile();
    if (audioFile == null) return;

    // Step 3: Chunked Upload
    final uploadResult = await step3ChunkedUpload(audioFile);
    if (uploadResult == null) return;

    // Step 4: Start Transcription
    final jobId = await step4StartTranscription(uploadResult);
    if (jobId == null) return;

    // Step 5: Wait for completion
    final result = await step5WaitForCompletion(jobId);
    if (result == null) return;

    // Step 6: Display results
    await step6DisplayResults(result);

    print('');
    print('╔══════════════════════════════════════════════════════════════╗');
    print('║   🎉 ALL STEPS COMPLETED SUCCESSFULLY!                       ║');
    print('╚══════════════════════════════════════════════════════════════╝');
  } catch (e) {
    print('');
    print('❌ ERROR: $e');
    exit(1);
  }
}

// ============================================
// STEP 1: LOGIN
// ============================================
Future<void> step1Login() async {
  print('');
  print('═══════════════════════════════════════════════════════════════');
  print('  STEP 1: LOGIN');
  print('═══════════════════════════════════════════════════════════════');

  final response = await http.post(
    Uri.parse('$baseUrl/api/login'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({'username': adminUser, 'password': adminPass}),
  );

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    token = data['token'];
    print('  ✓ Login successful');
    print('    Username: ${data['username']}');
    print('    Role: ${data['role']}');
    print('    Token: ${token!.substring(0, 30)}...');
  } else {
    throw Exception('Login failed: ${response.body}');
  }
}

// ============================================
// STEP 2: CHECK AUDIO FILE
// ============================================
Future<File?> step2CheckAudioFile() async {
  print('');
  print('═══════════════════════════════════════════════════════════════');
  print('  STEP 2: CHECK AUDIO FILE');
  print('═══════════════════════════════════════════════════════════════');

  // Try multiple locations
  final possiblePaths = [
    '/home/sleepassin/Desktop/Jam-Server/backend/python/test_audio.wav',
    '/home/sleepassin/Desktop/Jam-Server/test_audio.wav',
    'test_audio.wav',
  ];

  File? audioFile;
  for (final path in possiblePaths) {
    final file = File(path);
    if (await file.exists()) {
      audioFile = file;
      break;
    }
  }

  if (audioFile == null) {
    print('  ❌ No audio file found');
    print('  Please provide a test audio file at one of:');
    for (final path in possiblePaths) {
      print('    - $path');
    }
    return null;
  }

  final size = await audioFile.length();
  print('  ✓ Audio file found');
  print('    Path: ${audioFile.path}');
  print('    Size: ${(size / 1024).toStringAsFixed(2)} KB');

  return audioFile;
}

// ============================================
// STEP 3: CHUNKED UPLOAD
// ============================================
Future<Map<String, dynamic>?> step3ChunkedUpload(File file) async {
  print('');
  print('═══════════════════════════════════════════════════════════════');
  print('  STEP 3: CHUNKED UPLOAD');
  print('═══════════════════════════════════════════════════════════════');

  final fileSize = await file.length();
  final filename = file.path.split('/').last;
  final totalChunks = (fileSize / chunkSize).ceil();

  print('  📤 Starting upload...');
  print('    Filename: $filename');
  print('    Size: ${(fileSize / 1024).toStringAsFixed(2)} KB');
  print('    Chunks: $totalChunks');

  // Step 3.1: Init upload
  print('');
  print('  ▶ Init upload session...');
  
  final initResponse = await http.post(
    Uri.parse('$baseUrl/api/upload/init'),
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    },
    body: jsonEncode({
      'filename': filename,
      'total_size': fileSize,
      'chunk_size': chunkSize,
      'project_id': projectId,
    }),
  );

  if (initResponse.statusCode != 200 && initResponse.statusCode != 201) {
    print('  ❌ Init failed (${initResponse.statusCode}): ${initResponse.body}');
    return null;
  }

  final initData = jsonDecode(initResponse.body);
  final sessionId = initData['session_id'];
  print('  ✓ Session created: ${sessionId.substring(0, 16)}...');

  // Step 3.2: Upload chunks
  print('');
  print('  ▶ Uploading chunks...');
  
  final bytes = await file.readAsBytes();
  for (int i = 0; i < totalChunks; i++) {
    final start = i * chunkSize;
    final end = (start + chunkSize > fileSize) ? fileSize : start + chunkSize;
    final chunkBytes = bytes.sublist(start, end);

    // Use multipart for chunk upload
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/api/upload/$sessionId/chunk/$i'),
    );
    request.headers['Authorization'] = 'Bearer $token';
    request.files.add(http.MultipartFile.fromBytes(
      'chunk',
      chunkBytes,
      filename: 'chunk_$i.bin',
    ));

    final chunkResponse = await request.send();
    if (chunkResponse.statusCode != 200) {
      final body = await chunkResponse.stream.bytesToString();
      print('  ❌ Chunk $i failed: $body');
      return null;
    }

    final progress = ((i + 1) / totalChunks * 100).toStringAsFixed(0);
    stdout.write('\r    Chunk ${i + 1}/$totalChunks ($progress%)');
  }
  print('');
  print('  ✓ All chunks uploaded');

  // Step 3.3: Complete upload
  print('');
  print('  ▶ Completing upload...');
  
  final completeResponse = await http.post(
    Uri.parse('$baseUrl/api/upload/$sessionId/complete'),
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    },
    body: '{}',
  );

  if (completeResponse.statusCode != 200) {
    print('  ❌ Complete failed: ${completeResponse.body}');
    return null;
  }

  final result = jsonDecode(completeResponse.body);
  print('  ✓ Upload completed');
  print('    File URL: ${result['url'] ?? result['file_url'] ?? result['path']}');

  return result;
}

// ============================================
// STEP 4: START TRANSCRIPTION
// ============================================
Future<String?> step4StartTranscription(Map<String, dynamic> uploadResult) async {
  print('');
  print('═══════════════════════════════════════════════════════════════');
  print('  STEP 4: START TRANSCRIPTION');
  print('═══════════════════════════════════════════════════════════════');

  // Get file URL from upload result
  final fileUrl = uploadResult['url'] ?? uploadResult['file_url'] ?? uploadResult['path'];
  
  // Fix path - remove /storage prefix if present
  String storagePath = fileUrl.toString();
  if (storagePath.startsWith('/storage/')) {
    storagePath = storagePath.substring('/storage/'.length);
  }
  
  print('  🎤 Starting async transcription...');
  print('    Storage Path: $storagePath');
  print('    Language: th (Thai)');
  print('    Diarize: true');

  final response = await http.post(
    Uri.parse('$baseUrl/api/ai/transcribe-url'),
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    },
    body: jsonEncode({
      'project_id': projectId,
      'storage_path': storagePath,  // Use fixed path
      'language': 'th',
      'diarize': true,
      'async': true,
    }),
  );

  if (response.statusCode != 200) {
    print('  ❌ Transcription start failed: ${response.body}');
    // Fallback: try direct file upload
    print('');
    print('  ▶ Trying direct file upload transcription...');
    return await step4DirectFileTranscription();
  }

  final data = jsonDecode(response.body);
  final jobId = data['job_id'] ?? data['id'];
  
  print('  ✓ Transcription job created');
  print('    Job ID: $jobId');
  print('    Status: ${data['status'] ?? 'pending'}');

  return jobId;
}

Future<String?> step4DirectFileTranscription() async {
  // Find audio file again
  final file = File('/home/sleepassin/Desktop/Jam-Server/backend/python/test_audio.wav');
  if (!await file.exists()) {
    print('  ❌ Audio file not found for direct upload');
    return null;
  }

  final request = http.MultipartRequest(
    'POST',
    Uri.parse('$baseUrl/api/ai/transcribe-async'),
  );
  request.headers['Authorization'] = 'Bearer $token';
  request.fields['project_id'] = projectId;
  request.fields['language'] = 'th';
  request.fields['diarize'] = 'true';
  request.files.add(await http.MultipartFile.fromPath('file', file.path));

  final response = await request.send();
  final body = await response.stream.bytesToString();

  if (response.statusCode != 200) {
    print('  ❌ Direct transcription failed: $body');
    return null;
  }

  final data = jsonDecode(body);
  final jobId = data['job_id'] ?? data['id'];
  
  print('  ✓ Direct transcription job created');
  print('    Job ID: $jobId');

  return jobId;
}

// ============================================
// STEP 5: WAIT FOR COMPLETION
// ============================================
Future<Map<String, dynamic>?> step5WaitForCompletion(String jobId) async {
  print('');
  print('═══════════════════════════════════════════════════════════════');
  print('  STEP 5: WAIT FOR COMPLETION');
  print('═══════════════════════════════════════════════════════════════');

  print('  ⏳ Waiting for transcription to complete...');
  
  const maxAttempts = 60; // 5 minutes max
  const pollInterval = Duration(seconds: 5);

  for (int attempt = 0; attempt < maxAttempts; attempt++) {
    final response = await http.get(
      Uri.parse('$baseUrl/api/jobs/$jobId'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode != 200) {
      print('  ⚠ Status check failed: ${response.body}');
      await Future.delayed(pollInterval);
      continue;
    }

    final data = jsonDecode(response.body);
    final status = data['status'];
    final progress = data['progress'] ?? 0;

    stdout.write('\r    Status: $status, Progress: $progress%    ');

    if (status == 'completed') {
      print('');
      print('  ✓ Transcription completed!');
      return data;
    }

    if (status == 'failed') {
      print('');
      print('  ❌ Transcription failed: ${data['error']}');
      return null;
    }

    await Future.delayed(pollInterval);
  }

  print('');
  print('  ❌ Timeout waiting for transcription');
  return null;
}

// ============================================
// STEP 6: DISPLAY RESULTS
// ============================================
Future<void> step6DisplayResults(Map<String, dynamic> jobData) async {
  print('');
  print('═══════════════════════════════════════════════════════════════');
  print('  STEP 6: TRANSCRIPTION RESULTS');
  print('═══════════════════════════════════════════════════════════════');

  final result = jobData['result'] ?? jobData;
  
  // Get segments
  final segments = result['segments'] as List<dynamic>? ?? [];
  final language = result['language'] ?? 'unknown';
  final duration = result['duration'] ?? 0;

  print('');
  print('  📊 Summary:');
  print('    Language: $language');
  print('    Duration: ${duration.toStringAsFixed(2)} seconds');
  print('    Segments: ${segments.length}');
  
  // Get speakers if diarization was enabled
  final speakers = <String>{};
  for (final seg in segments) {
    final speaker = seg['speaker'];
    if (speaker != null) {
      speakers.add(speaker.toString());
    }
  }
  if (speakers.isNotEmpty) {
    print('    Speakers: ${speakers.join(', ')}');
  }

  print('');
  print('  📝 Transcript:');
  print('  ─────────────────────────────────────────────────────────────');
  
  for (final seg in segments.take(10)) {
    final start = (seg['start'] ?? 0).toStringAsFixed(2);
    final end = (seg['end'] ?? 0).toStringAsFixed(2);
    final text = seg['text'] ?? '';
    final speaker = seg['speaker'];
    
    if (speaker != null) {
      print('    [$start - $end] ($speaker) $text');
    } else {
      print('    [$start - $end] $text');
    }
  }

  if (segments.length > 10) {
    print('    ... and ${segments.length - 10} more segments');
  }

  print('  ─────────────────────────────────────────────────────────────');
  
  // Full text
  final fullText = segments.map((s) => s['text']).join(' ');
  print('');
  print('  📄 Full Text:');
  print('    ${fullText.substring(0, fullText.length > 200 ? 200 : fullText.length)}${fullText.length > 200 ? '...' : ''}');
}
