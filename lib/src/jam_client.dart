import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;

/// Base HTTP client for Jam Server SDK
/// 
/// Handles authentication, request formatting, and response parsing.
/// Supports both JWT token and API Key authentication.
class JamClient {
  final String baseUrl;
  String? _token;
  String? _apiKey;
  String? _currentProjectId;
  final http.Client _httpClient = http.Client();

  JamClient({required this.baseUrl});

  /// Set JWT token for authentication
  void setToken(String token) {
    _token = token;
  }

  /// Clear JWT token
  void clearToken() {
    _token = null;
  }

  /// Get current JWT token
  String? get token => _token;

  /// Set API Key for authentication
  void setApiKey(String apiKey) {
    _apiKey = apiKey;
  }

  /// Clear API Key
  void clearApiKey() {
    _apiKey = null;
  }

  /// Get current API Key
  String? get apiKey => _apiKey;

  /// Set current project context
  void setProject(String projectId) {
    _currentProjectId = projectId;
  }

  /// Get current project ID
  String? get currentProjectId => _currentProjectId;

  /// Clear project context
  void clearProject() {
    _currentProjectId = null;
  }

  /// Build headers for API requests
  Map<String, String> get _headers {
    final headers = <String, String>{
      'Content-Type': 'application/json',
    };
    
    if (_apiKey != null) {
      headers['X-API-Key'] = _apiKey!;
    } else if (_token != null) {
      headers['Authorization'] = 'Bearer $_token';
    }
    
    if (_currentProjectId != null) {
      headers['X-Project-ID'] = _currentProjectId!;
    }
    
    return headers;
  }

  /// Build headers for multipart requests (no Content-Type)
  Map<String, String> get _multipartHeaders {
    final headers = <String, String>{};
    
    if (_apiKey != null) {
      headers['X-API-Key'] = _apiKey!;
    } else if (_token != null) {
      headers['Authorization'] = 'Bearer $_token';
    }
    
    if (_currentProjectId != null) {
      headers['X-Project-ID'] = _currentProjectId!;
    }
    
    return headers;
  }

  /// GET request
  Future<dynamic> get(String path, {Map<String, String>? queryParams}) async {
    var uri = Uri.parse('$baseUrl$path');
    if (queryParams != null && queryParams.isNotEmpty) {
      uri = uri.replace(queryParameters: queryParams);
    }
    final response = await _httpClient.get(uri, headers: _headers);
    return _handleResponse(response);
  }

  /// POST request with JSON body
  Future<dynamic> post(String path, {dynamic body}) async {
    final uri = Uri.parse('$baseUrl$path');
    final response = await _httpClient.post(
      uri,
      headers: _headers,
      body: body != null ? jsonEncode(body) : null,
    );
    return _handleResponse(response);
  }

  /// PATCH request with JSON body
  Future<dynamic> patch(String path, {dynamic body}) async {
    final uri = Uri.parse('$baseUrl$path');
    final response = await _httpClient.patch(
      uri,
      headers: _headers,
      body: body != null ? jsonEncode(body) : null,
    );
    return _handleResponse(response);
  }

  /// DELETE request
  Future<dynamic> delete(String path, {Map<String, String>? queryParams}) async {
    var uri = Uri.parse('$baseUrl$path');
    if (queryParams != null && queryParams.isNotEmpty) {
      uri = uri.replace(queryParameters: queryParams);
    }
    final response = await _httpClient.delete(uri, headers: _headers);
    return _handleResponse(response);
  }

  /// PUT request with JSON body
  Future<dynamic> put(String path, {dynamic body}) async {
    final uri = Uri.parse('$baseUrl$path');
    final response = await _httpClient.put(
      uri,
      headers: _headers,
      body: body != null ? jsonEncode(body) : null,
    );
    return _handleResponse(response);
  }

  /// PUT request with raw bytes (for chunk upload)
  Future<dynamic> putBytes(String path, Uint8List bytes) async {
    final uri = Uri.parse('$baseUrl$path');
    final headers = Map<String, String>.from(_headers);
    headers['Content-Type'] = 'application/octet-stream';
    
    final response = await _httpClient.put(
      uri,
      headers: headers,
      body: bytes,
    );
    return _handleResponse(response);
  }

  /// POST request with raw bytes (for chunk upload - Flutter Web compatible)
  /// Use this instead of putBytes on Flutter Web to avoid CORS/XMLHttpRequest issues
  Future<dynamic> postBytes(String path, Uint8List bytes) async {
    final uri = Uri.parse('$baseUrl$path');
    final headers = Map<String, String>.from(_headers);
    headers['Content-Type'] = 'application/octet-stream';
    
    final response = await _httpClient.post(
      uri,
      headers: headers,
      body: bytes,
    );
    return _handleResponse(response);
  }

  /// POST multipart request with file path
  Future<dynamic> postMultipart(
    String path,
    String filePath, {
    Map<String, String>? fields,
    String fileFieldName = 'file',
  }) async {
    final uri = Uri.parse('$baseUrl$path');
    final request = http.MultipartRequest('POST', uri);

    request.headers.addAll(_multipartHeaders);
    request.files.add(await http.MultipartFile.fromPath(fileFieldName, filePath));

    if (fields != null) {
      request.fields.addAll(fields);
    }

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    return _handleResponse(response);
  }

  /// POST multipart request with file bytes
  Future<dynamic> postMultipartBytes(
    String path,
    Uint8List fileBytes,
    String filename, {
    Map<String, String>? fields,
    String fileFieldName = 'file',
    String? contentType,
  }) async {
    final uri = Uri.parse('$baseUrl$path');
    final request = http.MultipartRequest('POST', uri);

    request.headers.addAll(_multipartHeaders);
    request.files.add(http.MultipartFile.fromBytes(
      fileFieldName,
      fileBytes,
      filename: filename,
    ));

    if (fields != null) {
      request.fields.addAll(fields);
    }

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    return _handleResponse(response);
  }

  /// Download file as bytes
  Future<Uint8List> downloadBytes(String path) async {
    final uri = Uri.parse('$baseUrl$path');
    final response = await _httpClient.get(uri, headers: _headers);
    
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return response.bodyBytes;
    } else {
      throw JamException(
        statusCode: response.statusCode,
        message: response.body,
      );
    }
  }

  /// Handle HTTP response
  dynamic _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return null;
      try {
        return jsonDecode(response.body);
      } catch (e) {
        return response.body;
      }
    } else {
      String message;
      try {
        final decoded = jsonDecode(response.body);
        message = decoded['error'] ?? decoded['message'] ?? response.body;
      } catch (e) {
        message = response.body;
      }
      throw JamException(
        statusCode: response.statusCode,
        message: message,
      );
    }
  }

  /// Dispose HTTP client
  void dispose() {
    _httpClient.close();
  }
}

/// Exception thrown by Jam SDK
class JamException implements Exception {
  final int statusCode;
  final String message;

  JamException({required this.statusCode, required this.message});

  @override
  String toString() => 'JamException(statusCode: $statusCode, message: $message)';

  bool get isUnauthorized => statusCode == 401;
  bool get isForbidden => statusCode == 403;
  bool get isNotFound => statusCode == 404;
  bool get isServerError => statusCode >= 500;
}
