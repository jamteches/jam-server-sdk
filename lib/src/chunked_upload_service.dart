import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'jam_client.dart';

/// Chunked Upload Service
/// 
/// Handles large file uploads by splitting into chunks to bypass
/// Cloudflare timeout (100 seconds).
/// 
/// Features:
/// - Automatic chunking (5MB default)
/// - Resumable uploads
/// - Progress tracking
/// - Checksum verification
class ChunkedUploadService {
  final JamClient _client;
  
  /// Default chunk size: 5MB (safe for Cloudflare)
  static const int defaultChunkSize = 5 * 1024 * 1024;
  
  ChunkedUploadService(this._client);
  
  /// Upload a large file using chunked upload
  /// 
  /// [filePath] - Path to the file to upload
  /// [projectId] - Target project ID
  /// [onProgress] - Optional callback for progress updates (0.0 to 1.0)
  /// [chunkSize] - Size of each chunk in bytes (default: 5MB)
  /// [verifyChecksum] - Whether to verify file checksum after upload
  /// 
  /// Returns upload result with file URL
  Future<Map<String, dynamic>> upload(
    String filePath, {
    required String projectId,
    void Function(double progress, int uploadedChunks, int totalChunks)? onProgress,
    int chunkSize = defaultChunkSize,
    bool verifyChecksum = true,
  }) async {
    final file = File(filePath);
    if (!await file.exists()) {
      throw JamException(statusCode: 404, message: 'File not found: $filePath');
    }
    
    final fileSize = await file.length();
    final filename = file.uri.pathSegments.last;
    
    // Calculate checksum if verification enabled
    String? checksum;
    if (verifyChecksum) {
      checksum = await _calculateChecksum(file);
    }
    
    // Step 1: Initialize upload session
    final session = await initUpload(
      filename: filename,
      totalSize: fileSize,
      projectId: projectId,
      chunkSize: chunkSize,
      checksum: checksum,
    );
    
    final sessionId = session['session_id'] as String;
    final totalChunks = session['total_chunks'] as int;
    
    try {
      // Step 2: Upload chunks
      final raf = await file.open();
      
      for (int i = 0; i < totalChunks; i++) {
        final offset = i * chunkSize;
        await raf.setPosition(offset);
        
        final remainingBytes = fileSize - offset;
        final bytesToRead = remainingBytes < chunkSize ? remainingBytes : chunkSize;
        
        final chunkData = await raf.read(bytesToRead.toInt());
        
        await uploadChunk(sessionId, i, chunkData);
        
        // Report progress
        onProgress?.call((i + 1) / totalChunks, i + 1, totalChunks);
      }
      
      await raf.close();
      
      // Step 3: Complete upload
      final result = await completeUpload(sessionId);
      
      return result;
    } catch (e) {
      // Don't cancel on error - allow resume
      rethrow;
    }
  }
  
  /// Upload file from bytes
  Future<Map<String, dynamic>> uploadBytes(
    Uint8List bytes,
    String filename, {
    required String projectId,
    void Function(double progress, int uploadedChunks, int totalChunks)? onProgress,
    int chunkSize = defaultChunkSize,
    bool verifyChecksum = true,
  }) async {
    // Calculate checksum
    String? checksum;
    if (verifyChecksum) {
      checksum = sha256.convert(bytes).toString();
    }
    
    // Initialize session
    final session = await initUpload(
      filename: filename,
      totalSize: bytes.length,
      projectId: projectId,
      chunkSize: chunkSize,
      checksum: checksum,
    );
    
    final sessionId = session['session_id'] as String;
    final totalChunks = session['total_chunks'] as int;
    
    try {
      // Upload chunks
      for (int i = 0; i < totalChunks; i++) {
        final start = i * chunkSize;
        final end = (start + chunkSize > bytes.length) ? bytes.length : start + chunkSize;
        
        final chunkData = bytes.sublist(start, end);
        
        await uploadChunk(sessionId, i, Uint8List.fromList(chunkData));
        
        onProgress?.call((i + 1) / totalChunks, i + 1, totalChunks);
      }
      
      // Complete
      return await completeUpload(sessionId);
    } catch (e) {
      rethrow;
    }
  }
  
  /// Resume an interrupted upload
  Future<Map<String, dynamic>> resume(
    String sessionId,
    String filePath, {
    void Function(double progress, int uploadedChunks, int totalChunks)? onProgress,
  }) async {
    // Get current status
    final status = await getUploadStatus(sessionId);
    
    if (status['status'] == 'completed') {
      throw JamException(statusCode: 400, message: 'Upload already completed');
    }
    
    final uploadedChunks = List<int>.from(status['uploaded_chunks'] ?? []);
    final missingChunks = List<int>.from(status['missing_chunks'] ?? []);
    final totalChunks = status['total_chunks'] as int;
    final chunkSize = status['chunk_size'] as int;
    
    if (missingChunks.isEmpty) {
      // All chunks uploaded, just complete
      return await completeUpload(sessionId);
    }
    
    final file = File(filePath);
    if (!await file.exists()) {
      throw JamException(statusCode: 404, message: 'File not found: $filePath');
    }
    
    final fileSize = await file.length();
    
    // Verify file size matches
    if (fileSize != status['total_size']) {
      throw JamException(statusCode: 400, message: 'File size mismatch. Cannot resume with different file.');
    }
    
    final raf = await file.open();
    
    try {
      for (final chunkIndex in missingChunks) {
        final offset = chunkIndex * chunkSize;
        await raf.setPosition(offset);
        
        final remainingBytes = fileSize - offset;
        final bytesToRead = remainingBytes < chunkSize ? remainingBytes : chunkSize;
        
        final chunkData = await raf.read(bytesToRead.toInt());
        
        await uploadChunk(sessionId, chunkIndex, chunkData);
        
        uploadedChunks.add(chunkIndex);
        onProgress?.call(uploadedChunks.length / totalChunks, uploadedChunks.length, totalChunks);
      }
      
      await raf.close();
      
      return await completeUpload(sessionId);
    } catch (e) {
      await raf.close();
      rethrow;
    }
  }
  
  /// Initialize a new upload session
  Future<Map<String, dynamic>> initUpload({
    required String filename,
    required int totalSize,
    required String projectId,
    int chunkSize = defaultChunkSize,
    String? contentType,
    String? checksum,
  }) async {
    return await _client.post('/api/upload/init', body: {
      'filename': filename,
      'total_size': totalSize,
      'chunk_size': chunkSize,
      'project_id': projectId,
      if (contentType != null) 'content_type': contentType,
      if (checksum != null) 'checksum': checksum,
    });
  }
  
  /// Upload a single chunk
  /// 
  /// [useMultipart] - Use multipart form-data (default: true for Flutter Web compatibility)
  /// Flutter Web has issues with raw binary upload via XMLHttpRequest
  /// 
  /// [usePost] - Use POST instead of PUT (only applies when useMultipart is false)
  Future<Map<String, dynamic>> uploadChunk(
    String sessionId,
    int chunkIndex,
    Uint8List chunkData, {
    bool useMultipart = true,
    bool usePost = true,
  }) async {
    final path = '/api/upload/$sessionId/chunk/$chunkIndex';
    
    if (useMultipart) {
      // Use multipart form-data (Flutter Web compatible)
      return await _client.postMultipartBytes(
        path,
        chunkData,
        'chunk_$chunkIndex.bin',
        fileFieldName: 'chunk',
      );
    } else if (usePost) {
      // Use POST with raw binary
      return await _client.postBytes(path, chunkData);
    } else {
      // Use PUT with raw binary (original method)
      return await _client.putBytes(path, chunkData);
    }
  }
  
  /// Complete the upload (merge chunks)
  Future<Map<String, dynamic>> completeUpload(String sessionId) async {
    return await _client.post('/api/upload/$sessionId/complete', body: {});
  }
  
  /// Get upload status
  Future<Map<String, dynamic>> getUploadStatus(String sessionId) async {
    return await _client.get('/api/upload/$sessionId/status');
  }
  
  /// Cancel and cleanup upload session
  Future<void> cancelUpload(String sessionId) async {
    await _client.delete('/api/upload/$sessionId');
  }
  
  /// Calculate SHA256 checksum of a file
  Future<String> _calculateChecksum(File file) async {
    final digest = await sha256.bind(file.openRead()).first;
    return digest.toString();
  }
}

/// Upload progress information
class UploadProgress {
  final String sessionId;
  final int uploadedChunks;
  final int totalChunks;
  final double progress;
  final String status;
  
  UploadProgress({
    required this.sessionId,
    required this.uploadedChunks,
    required this.totalChunks,
    required this.progress,
    required this.status,
  });
  
  bool get isComplete => uploadedChunks == totalChunks;
  
  @override
  String toString() => 'UploadProgress($uploadedChunks/$totalChunks, ${(progress * 100).toStringAsFixed(1)}%)';
}
