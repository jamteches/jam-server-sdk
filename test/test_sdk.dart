/// Jam Server SDK Test Script
/// Run with: dart run test_sdk.dart

import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;

const baseUrl = 'http://localhost:8000';
const adminUser = 'jam_admin';
const adminPass = 'Admin@2024!';

String? authToken;
String? projectId;

Future<void> main() async {
  print('='.padRight(60, '='));
  print('🔬 JAM SERVER SDK TEST');
  print('='.padRight(60, '='));
  print('');
  
  int passed = 0;
  int failed = 0;
  
  // Test 1: Login
  print('📌 TEST 1: Authentication');
  print('-'.padRight(40, '-'));
  try {
    final loginResult = await login(adminUser, adminPass);
    if (loginResult['token'] != null) {
      authToken = loginResult['token'];
      passed++;
      print('✅ Login successful');
    } else {
      failed++;
      print('❌ Login failed');
    }
  } catch (e) {
    failed++;
    print('❌ Login error: $e');
  }
  
  // Test 2: Verify Token
  try {
    final verify = await verifyToken();
    if (verify['status'] == 'valid') {
      passed++;
      print('✅ Token verification');
    } else {
      failed++;
      print('❌ Token verification failed');
    }
  } catch (e) {
    failed++;
    print('❌ Token verify error: $e');
  }
  
  print('');
  
  // Test 3: Projects
  print('📌 TEST 2: Project Management');
  print('-'.padRight(40, '-'));
  try {
    final projects = await listProjects();
    if (projects is List && projects.isNotEmpty) {
      projectId = projects[0]['id'];
      passed++;
      print('✅ List projects (${projects.length} found)');
    } else {
      failed++;
      print('❌ List projects failed');
    }
  } catch (e) {
    failed++;
    print('❌ List projects error: $e');
  }
  
  if (projectId != null) {
    try {
      final project = await getProject(projectId!);
      if (project['id'] != null) {
        passed++;
        print('✅ Get project detail');
      } else {
        failed++;
        print('❌ Get project failed');
      }
    } catch (e) {
      failed++;
      print('❌ Get project error: $e');
    }
  }
  
  print('');
  
  // Test 4: Storage
  print('📌 TEST 3: Storage Service');
  print('-'.padRight(40, '-'));
  try {
    final quota = await getStorageQuota();
    if (quota['used_bytes'] != null) {
      passed++;
      print('✅ Storage quota (${quota['used_bytes']} bytes used)');
    } else {
      failed++;
      print('❌ Storage quota failed');
    }
  } catch (e) {
    failed++;
    print('❌ Storage quota error: $e');
  }
  
  if (projectId != null) {
    try {
      final files = await listFiles(projectId!);
      passed++;
      print('✅ List files (${files is List ? files.length : 0} found)');
    } catch (e) {
      failed++;
      print('❌ List files error: $e');
    }
  }
  
  print('');
  
  // Test 5: Project Users
  print('📌 TEST 4: Project Users');
  print('-'.padRight(40, '-'));
  if (projectId != null) {
    try {
      final users = await listProjectUsers(projectId!);
      if (users is List) {
        passed++;
        print('✅ List project users (${users.length} found)');
      } else {
        failed++;
        print('❌ List project users failed');
      }
    } catch (e) {
      failed++;
      print('❌ List project users error: $e');
    }
  }
  
  print('');
  
  // Test 6: API Keys
  print('📌 TEST 5: API Key Management');
  print('-'.padRight(40, '-'));
  if (projectId != null) {
    try {
      final keys = await listApiKeys(projectId!);
      if (keys is List) {
        passed++;
        print('✅ List API keys (${keys.length} found)');
      } else {
        failed++;
        print('❌ List API keys failed');
      }
    } catch (e) {
      failed++;
      print('❌ List API keys error: $e');
    }
  }
  
  print('');
  
  // Test 7: Transcription Jobs
  print('📌 TEST 6: Transcription Service');
  print('-'.padRight(40, '-'));
  try {
    final jobs = await listJobs();
    passed++;
    final jobCount = jobs['jobs']?.length ?? 0;
    print('✅ List transcription jobs ($jobCount found)');
  } catch (e) {
    failed++;
    print('❌ List jobs error: $e');
  }
  
  try {
    final transcriptions = await listTranscriptions();
    passed++;
    print('✅ List transcriptions');
  } catch (e) {
    failed++;
    print('❌ List transcriptions error: $e');
  }
  
  print('');
  
  // Test 8: Admin Features
  print('📌 TEST 7: Admin Features');
  print('-'.padRight(40, '-'));
  try {
    final metrics = await getMetrics();
    passed++;
    print('✅ Get metrics');
  } catch (e) {
    failed++;
    print('❌ Get metrics error: $e');
  }
  
  try {
    final emailLogs = await getEmailLogs();
    passed++;
    final count = emailLogs is List ? emailLogs.length : 0;
    print('✅ Get email logs ($count entries)');
  } catch (e) {
    failed++;
    print('❌ Get email logs error: $e');
  }
  
  try {
    final backups = await getBackups();
    passed++;
    final count = backups is List ? backups.length : 0;
    print('✅ Get backups ($count found)');
  } catch (e) {
    failed++;
    print('❌ Get backups error: $e');
  }
  
  print('');
  
  // Test 9: Webhooks
  print('📌 TEST 8: Webhooks');
  print('-'.padRight(40, '-'));
  if (projectId != null) {
    try {
      final webhooks = await listWebhooks(projectId!);
      passed++;
      final count = webhooks is List ? webhooks.length : 0;
      print('✅ List webhooks ($count found)');
    } catch (e) {
      failed++;
      print('❌ List webhooks error: $e');
    }
  }
  
  print('');
  
  // Summary
  print('='.padRight(60, '='));
  print('📊 TEST SUMMARY');
  print('='.padRight(60, '='));
  print('✅ Passed: $passed');
  print('❌ Failed: $failed');
  print('');
  
  if (failed == 0) {
    print('🎉 ALL TESTS PASSED!');
    exit(0);
  } else {
    print('⚠️ Some tests failed.');
    exit(1);
  }
}

// ==================== API Functions ====================

Future<Map<String, dynamic>> login(String username, String password) async {
  final response = await http.post(
    Uri.parse('$baseUrl/api/login'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({'username': username, 'password': password}),
  );
  return jsonDecode(response.body);
}

Future<Map<String, dynamic>> verifyToken() async {
  final response = await http.get(
    Uri.parse('$baseUrl/api/auth/verify'),
    headers: {'Authorization': 'Bearer $authToken'},
  );
  return jsonDecode(response.body);
}

Future<List> listProjects() async {
  final response = await http.get(
    Uri.parse('$baseUrl/api/projects'),
    headers: {'Authorization': 'Bearer $authToken'},
  );
  return jsonDecode(response.body);
}

Future<Map<String, dynamic>> getProject(String id) async {
  final response = await http.get(
    Uri.parse('$baseUrl/api/projects/$id'),
    headers: {'Authorization': 'Bearer $authToken'},
  );
  return jsonDecode(response.body);
}

Future<Map<String, dynamic>> getStorageQuota() async {
  final response = await http.get(
    Uri.parse('$baseUrl/api/storage/quota'),
    headers: {'Authorization': 'Bearer $authToken'},
  );
  return jsonDecode(response.body);
}

Future<dynamic> listFiles(String projectId) async {
  final response = await http.get(
    Uri.parse('$baseUrl/api/storage/list?project_id=$projectId'),
    headers: {'Authorization': 'Bearer $authToken'},
  );
  return jsonDecode(response.body);
}

Future<List> listProjectUsers(String projectId) async {
  final response = await http.get(
    Uri.parse('$baseUrl/api/projects/$projectId/users'),
    headers: {'Authorization': 'Bearer $authToken'},
  );
  return jsonDecode(response.body);
}

Future<List> listApiKeys(String projectId) async {
  final response = await http.get(
    Uri.parse('$baseUrl/api/projects/$projectId/keys'),
    headers: {'Authorization': 'Bearer $authToken'},
  );
  return jsonDecode(response.body);
}

Future<Map<String, dynamic>> listJobs() async {
  final response = await http.get(
    Uri.parse('$baseUrl/api/jobs?limit=10'),
    headers: {'Authorization': 'Bearer $authToken'},
  );
  return jsonDecode(response.body);
}

Future<dynamic> listTranscriptions() async {
  final response = await http.get(
    Uri.parse('$baseUrl/api/transcriptions?limit=10'),
    headers: {'Authorization': 'Bearer $authToken'},
  );
  return jsonDecode(response.body);
}

Future<dynamic> getMetrics() async {
  final response = await http.get(
    Uri.parse('$baseUrl/api/metrics'),
    headers: {'Authorization': 'Bearer $authToken'},
  );
  return jsonDecode(response.body);
}

Future<dynamic> getEmailLogs() async {
  final response = await http.get(
    Uri.parse('$baseUrl/api/admin/email-logs'),
    headers: {'Authorization': 'Bearer $authToken'},
  );
  return jsonDecode(response.body);
}

Future<dynamic> getBackups() async {
  final response = await http.get(
    Uri.parse('$baseUrl/api/admin/backups'),
    headers: {'Authorization': 'Bearer $authToken'},
  );
  return jsonDecode(response.body);
}

Future<dynamic> listWebhooks(String projectId) async {
  final response = await http.get(
    Uri.parse('$baseUrl/api/projects/$projectId/webhooks'),
    headers: {'Authorization': 'Bearer $authToken'},
  );
  return jsonDecode(response.body);
}
