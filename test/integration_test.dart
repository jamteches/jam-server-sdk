/// Jam Server SDK Integration Test
/// Tests the actual SDK classes, not raw HTTP calls

import '../lib/jam.dart';

const baseUrl = 'http://localhost:8000';
const adminUser = 'jam_admin';
const adminPass = 'Admin@2024!';

Future<void> main() async {
  print('='.padRight(60, '='));
  print('🔬 JAM SERVER SDK INTEGRATION TEST');
  print('='.padRight(60, '='));
  print('');
  
  int passed = 0;
  int failed = 0;
  
  // Initialize SDK
  final jam = Jam(baseUrl);
  print('📌 SDK Initialized: $baseUrl');
  print('');
  
  // Test 1: Authentication
  print('📌 TEST 1: AuthService');
  print('-'.padRight(40, '-'));
  try {
    final result = await jam.auth.login(username: adminUser, password: adminPass);
    if (result['token'] != null) {
      passed++;
      print('✅ jam.auth.login() - Token received');
    } else {
      failed++;
      print('❌ jam.auth.login() failed');
    }
  } catch (e) {
    failed++;
    print('❌ jam.auth.login() error: $e');
  }
  
  try {
    final verify = await jam.auth.verifyToken();
    if (verify['status'] == 'valid') {
      passed++;
      print('✅ jam.auth.verifyToken()');
    } else {
      failed++;
      print('❌ jam.auth.verifyToken() failed');
    }
  } catch (e) {
    failed++;
    print('❌ jam.auth.verifyToken() error: $e');
  }
  
  print('');
  
  // Test 2: Project Management
  print('📌 TEST 2: ProjectService');
  print('-'.padRight(40, '-'));
  String? projectId;
  try {
    final projects = await jam.projects.list();
    if (projects.isNotEmpty) {
      projectId = projects[0]['id'];
      passed++;
      print('✅ jam.projects.list() - ${projects.length} projects');
    } else {
      failed++;
      print('❌ jam.projects.list() - no projects');
    }
  } catch (e) {
    failed++;
    print('❌ jam.projects.list() error: $e');
  }
  
  if (projectId != null) {
    try {
      final project = await jam.projects.get(projectId);
      if (project['id'] != null) {
        passed++;
        print('✅ jam.projects.get("$projectId")');
        print('   Project: ${project['name']}');
      } else {
        failed++;
        print('❌ jam.projects.get() failed');
      }
    } catch (e) {
      failed++;
      print('❌ jam.projects.get() error: $e');
    }
  }
  
  print('');
  
  // Test 3: Storage
  print('📌 TEST 3: StorageService');
  print('-'.padRight(40, '-'));
  try {
    final quota = await jam.storage.getQuota();
    if (quota['used_bytes'] != null) {
      passed++;
      final usedMB = (quota['used_bytes'] / 1024 / 1024).toStringAsFixed(2);
      print('✅ jam.storage.getQuota() - ${usedMB}MB used');
    } else {
      failed++;
      print('❌ jam.storage.getQuota() failed');
    }
  } catch (e) {
    failed++;
    print('❌ jam.storage.getQuota() error: $e');
  }
  
  if (projectId != null) {
    try {
      final files = await jam.storage.list(projectId: projectId);
      passed++;
      print('✅ jam.storage.list() - ${files.length} files');
    } catch (e) {
      failed++;
      print('❌ jam.storage.list() error: $e');
    }
  }
  
  print('');
  
  // Test 4: Project Auth (Multi-tenant)
  print('📌 TEST 4: ProjectAuthService');
  print('-'.padRight(40, '-'));
  if (projectId != null) {
    final projectAuth = jam.projectAuth(projectId);
    print('   Created jam.projectAuth("$projectId")');
    
    // Check URLs
    print('   forgotPasswordUrl: ${projectAuth.forgotPasswordUrl}');
    print('   resetPasswordUrl: ${projectAuth.resetPasswordUrl}');
    passed++;
    print('✅ ProjectAuthService URLs generated');
  }
  
  print('');
  
  // Test 5: Project Settings
  print('📌 TEST 5: ProjectSettingsService');
  print('-'.padRight(40, '-'));
  if (projectId != null) {
    try {
      final settings = jam.projectSettings(projectId);
      final config = await settings.get();
      if (config.projectId.isNotEmpty) {
        passed++;
        print('✅ jam.projectSettings().get()');
        print('   Registration: ${config.allowRegistration}');
      } else {
        failed++;
        print('❌ jam.projectSettings().get() failed');
      }
    } catch (e) {
      failed++;
      print('❌ jam.projectSettings().get() error: $e');
    }
  }
  
  print('');
  
  // Test 6: Transcription Service
  print('📌 TEST 6: TranscriptionService');
  print('-'.padRight(40, '-'));
  try {
    final jobs = await jam.transcription.listJobs();
    passed++;
    final count = jobs['jobs']?.length ?? jobs['total'] ?? 0;
    print('✅ jam.transcription.listJobs() - $count jobs');
  } catch (e) {
    failed++;
    print('❌ jam.transcription.listJobs() error: $e');
  }
  
  try {
    final transcriptions = await jam.transcription.list();
    passed++;
    print('✅ jam.transcription.list()');
  } catch (e) {
    failed++;
    print('❌ jam.transcription.list() error: $e');
  }
  
  print('');
  
  // Test 7: Admin Service
  print('📌 TEST 7: AdminService');
  print('-'.padRight(40, '-'));
  try {
    final metrics = await jam.admin.getMetrics();
    passed++;
    print('✅ jam.admin.getMetrics()');
  } catch (e) {
    failed++;
    print('❌ jam.admin.getMetrics() error: $e');
  }
  
  try {
    final backups = await jam.admin.listBackups();
    passed++;
    print('✅ jam.admin.listBackups() - ${backups.length} backups');
  } catch (e) {
    failed++;
    print('❌ jam.admin.listBackups() error: $e');
  }
  
  print('');
  
  // Test 8: User Service
  print('📌 TEST 8: UserService');
  print('-'.padRight(40, '-'));
  try {
    final users = await jam.users.list();
    if (users.isNotEmpty) {
      passed++;
      print('✅ jam.users.list() - ${users.length} users');
    } else {
      failed++;
      print('❌ jam.users.list() - empty');
    }
  } catch (e) {
    failed++;
    print('❌ jam.users.list() error: $e');
  }
  
  print('');
  
  // Summary
  print('='.padRight(60, '='));
  print('📊 SDK INTEGRATION TEST SUMMARY');
  print('='.padRight(60, '='));
  print('✅ Passed: $passed');
  print('❌ Failed: $failed');
  print('');
  
  if (failed == 0) {
    print('🎉 ALL SDK TESTS PASSED!');
  } else {
    print('⚠️ Some SDK tests failed.');
  }
  
  // Cleanup
  jam.dispose();
}
