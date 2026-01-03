import 'jam_client.dart';

/// AI service for chat, knowledge base, and intelligent features
/// 
/// Provides AI-powered chat with RAG (Retrieval Augmented Generation),
/// knowledge base management, and AI settings.
/// 
/// Example:
/// ```dart
/// final jam = Jam('https://api.jamteches.com');
/// await jam.auth.login(username: 'john', password: 'pass');
/// 
/// // Chat with AI
/// final response = await jam.ai.chat(
///   projectId: 'my-project',
///   message: 'What is the capital of Thailand?',
/// );
/// print(response['response']);
/// 
/// // Add knowledge to AI
/// await jam.ai.addKnowledge(
///   projectId: 'my-project',
///   sourceType: 'text',
///   text: 'Bangkok is the capital of Thailand.',
///   title: 'Thailand Facts',
/// );
/// ```
class AiService {
  final JamClient _client;

  AiService(this._client);

  // ==================== Health Check ====================

  /// Check AI service health status
  Future<Map<String, dynamic>> health() async {
    return await _client.get('/api/ai/health');
  }

  /// Get GPU queue status (Admin only)
  /// 
  /// Returns information about the GPU task queue including:
  /// - Queue length
  /// - Current task type (transcription/chat)
  /// - Processing status
  /// 
  /// Note: Requires admin role to access.
  Future<Map<String, dynamic>> getGpuQueueStatus() async {
    return await _client.get('/api/ai/gpu-queue/status');
  }

  // ==================== Chat ====================

  /// Send a chat message with optional conversation history
  Future<Map<String, dynamic>> chat({
    required String projectId,
    required String message,
    List<Map<String, String>>? history,
    bool stream = false,
  }) async {
    return await _client.post('/api/ai/chat', body: {
      'project_id': projectId,
      'message': message,
      if (history != null) 'history': history,
      'stream': stream,
    });
  }

  /// Simple chat without project context
  Future<Map<String, dynamic>> simpleChat({required String message}) async {
    return await _client.post('/api/ai/chat/simple', body: {
      'message': message,
    });
  }

  // ==================== Knowledge Base ====================

  /// Add knowledge from text or URL
  Future<Map<String, dynamic>> addKnowledge({
    required String projectId,
    required String sourceType,
    String? url,
    String? text,
    String? title,
  }) async {
    return await _client.post('/api/ai/knowledge', body: {
      'project_id': projectId,
      'source_type': sourceType,
      if (url != null) 'url': url,
      if (text != null) 'text': text,
      if (title != null) 'title': title,
    });
  }

  /// Add knowledge from file
  Future<Map<String, dynamic>> addKnowledgeFile(
    String filePath, {
    required String projectId,
  }) async {
    return await _client.postMultipart(
      '/api/ai/knowledge/file',
      filePath,
      fields: {'project_id': projectId},
    );
  }

  /// List knowledge documents in a project
  Future<Map<String, dynamic>> listKnowledge(
    String projectId, {
    int limit = 20,
    int offset = 0,
  }) async {
    return await _client.get('/api/ai/knowledge/$projectId', queryParams: {
      'limit': limit.toString(),
      'offset': offset.toString(),
    });
  }

  /// Delete a knowledge document
  Future<Map<String, dynamic>> deleteKnowledge(
    String projectId,
    String documentId,
  ) async {
    return await _client.delete('/api/ai/knowledge/$projectId/$documentId');
  }

  /// Clear all knowledge for a project
  Future<Map<String, dynamic>> clearKnowledge(String projectId) async {
    return await _client.delete('/api/ai/knowledge/$projectId');
  }

  /// Get knowledge base statistics
  Future<Map<String, dynamic>> getKnowledgeStats(String projectId) async {
    return await _client.get('/api/ai/knowledge/$projectId/stats');
  }

  // ==================== AI Settings ====================

  /// Get AI settings for a project
  Future<Map<String, dynamic>> getSettings(String projectId) async {
    return await _client.get('/api/ai/settings/$projectId');
  }

  /// Save AI settings for a project
  Future<Map<String, dynamic>> saveSettings(
    String projectId, {
    String? systemInstruction,
    String? botName,
    String? botPersonality,
    String? language,
    double? temperature,
    int? maxTokens,
    bool? useRag,
    int? nContext,
  }) async {
    final body = <String, dynamic>{};
    if (systemInstruction != null) body['system_instruction'] = systemInstruction;
    if (botName != null) body['bot_name'] = botName;
    if (botPersonality != null) body['bot_personality'] = botPersonality;
    if (language != null) body['language'] = language;
    if (temperature != null) body['temperature'] = temperature;
    if (maxTokens != null) body['max_tokens'] = maxTokens;
    if (useRag != null) body['use_rag'] = useRag;
    if (nContext != null) body['n_context'] = nContext;
    
    return await _client.post('/api/ai/settings/$projectId', body: body);
  }

  // ==================== Sync Sources ====================

  /// Get sync sources for a project
  Future<List<dynamic>> getSyncSources(String projectId) async {
    final response = await _client.get('/api/ai/sync/$projectId/sources');
    if (response is List) return response;
    return response['data'] ?? [];
  }

  /// Add a sync source
  Future<Map<String, dynamic>> addSyncSource(
    String projectId, {
    required String sourceType,
    required String url,
    String? name,
    bool autoSync = false,
    int syncIntervalHours = 24,
  }) async {
    return await _client.post('/api/ai/sync/$projectId/sources', body: {
      'source_type': sourceType,
      'url': url,
      if (name != null) 'name': name,
      'auto_sync': autoSync,
      'sync_interval_hours': syncIntervalHours,
    });
  }

  /// Remove a sync source
  Future<Map<String, dynamic>> removeSyncSource(String projectId, String sourceId) async {
    return await _client.delete('/api/ai/sync/$projectId/sources/$sourceId');
  }

  /// Run sync for a specific source
  Future<Map<String, dynamic>> runSyncSource(
    String projectId,
    String sourceId, {
    int maxItems = 5,
  }) async {
    return await _client.post(
      '/api/ai/sync/$projectId/run/$sourceId',
      body: {'max_items': maxItems},
    );
  }

  /// Run sync for all sources in a project
  Future<Map<String, dynamic>> runSyncAll(
    String projectId, {
    int maxPerSource = 3,
  }) async {
    return await _client.post('/api/ai/sync/$projectId/run-all', body: {
      'max_per_source': maxPerSource,
    });
  }

  /// Get synced items for a project
  Future<List<dynamic>> getSyncedItems(String projectId) async {
    final response = await _client.get('/api/ai/sync/$projectId/synced');
    if (response is List) return response;
    return response['data'] ?? [];
  }

  // ==================== AI Models ====================

  /// List available AI models
  Future<List<dynamic>> listModels() async {
    final response = await _client.get('/api/ai/models');
    if (response is List) return response;
    return response['models'] ?? [];
  }

  // ==================== Scheduler (Admin) ====================

  /// Get scheduler status (Admin only)
  Future<Map<String, dynamic>> getSchedulerStatus() async {
    return await _client.get('/api/ai/scheduler/status');
  }

  /// Run scheduler now (Admin only)
  Future<Map<String, dynamic>> runSchedulerNow() async {
    return await _client.post('/api/ai/scheduler/run-now');
  }

  // ==================== Facebook Integration ====================

  /// Get Facebook integration status
  Future<Map<String, dynamic>> getFacebookStatus() async {
    return await _client.get('/api/ai/facebook/status');
  }

  /// Set Facebook cookies (Admin only)
  Future<Map<String, dynamic>> setFacebookCookies({
    required String cUser,
    required String xs,
    String? datr,
  }) async {
    return await _client.post('/api/ai/facebook/cookies', body: {
      'c_user': cUser,
      'xs': xs,
      if (datr != null) 'datr': datr,
    });
  }

  /// Clear Facebook cookies (Admin only)
  Future<Map<String, dynamic>> clearFacebookCookies() async {
    return await _client.delete('/api/ai/facebook/cookies');
  }
}
