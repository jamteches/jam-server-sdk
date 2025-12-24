/// Jam Server SDK - Usage Example
/// 
/// This example demonstrates how to use the Jam Server Flutter SDK
/// in a real Flutter application.

import 'package:flutter/material.dart';
// import 'package:jam_server_sdk/jam.dart';

void main() {
  runApp(const JamExampleApp());
}

class JamExampleApp extends StatelessWidget {
  const JamExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Jam SDK Example',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const JamExampleHome(),
    );
  }
}

class JamExampleHome extends StatefulWidget {
  const JamExampleHome({super.key});

  @override
  State<JamExampleHome> createState() => _JamExampleHomeState();
}

class _JamExampleHomeState extends State<JamExampleHome> {
  // TODO: Uncomment when using the actual SDK
  // late final Jam jam;
  
  bool _isLoggedIn = false;
  String _status = 'Not connected';
  List<String> _logs = [];

  @override
  void initState() {
    super.initState();
    _initializeSDK();
  }

  void _initializeSDK() {
    // Initialize the Jam SDK
    // jam = Jam('https://api.jamteches.com');
    _addLog('SDK initialized with base URL: https://api.jamteches.com');
  }

  void _addLog(String message) {
    setState(() {
      _logs.insert(0, '[${DateTime.now().toString().substring(11, 19)}] $message');
      if (_logs.length > 50) _logs.removeLast();
    });
  }

  Future<void> _testHealthCheck() async {
    _addLog('Testing health check...');
    try {
      // final health = await jam.admin.healthCheck();
      // _addLog('Health: ${health['status']}');
      _addLog('✅ Health check: OK (simulated)');
    } catch (e) {
      _addLog('❌ Health check failed: $e');
    }
  }

  Future<void> _testLogin() async {
    _addLog('Attempting login...');
    try {
      // await jam.auth.login(username: 'user', password: 'pass');
      // _addLog('Logged in as: ${jam.auth.currentUser}');
      setState(() => _isLoggedIn = true);
      _addLog('✅ Login successful (simulated)');
    } catch (e) {
      _addLog('❌ Login failed: $e');
    }
  }

  Future<void> _testDatabase() async {
    _addLog('Testing database operations...');
    try {
      // jam.setProject('my-project');
      // final users = jam.db.collection('users');
      // 
      // // Create
      // final doc = await users.add({'name': 'Test', 'age': 25});
      // _addLog('Created: ${doc['id']}');
      // 
      // // Read
      // final list = await users.list(limit: 5);
      // _addLog('Found ${list['total']} documents');
      
      _addLog('✅ Database operations: OK (simulated)');
    } catch (e) {
      _addLog('❌ Database test failed: $e');
    }
  }

  Future<void> _testAIChat() async {
    _addLog('Testing AI chat...');
    try {
      // final response = await jam.ai.chat(
      //   projectId: 'my-project',
      //   message: 'Hello!',
      // );
      // _addLog('AI: ${response['response']}');
      
      _addLog('✅ AI Chat: OK (simulated)');
    } catch (e) {
      _addLog('❌ AI chat failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Jam SDK Example'),
        actions: [
          IconButton(
            icon: Icon(_isLoggedIn ? Icons.logout : Icons.login),
            onPressed: _testLogin,
          ),
        ],
      ),
      body: Column(
        children: [
          // Status bar
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: _isLoggedIn ? Colors.green.shade100 : Colors.orange.shade100,
            child: Text(
              _isLoggedIn ? '✅ Logged In' : '⚠️ Not Logged In',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          
          // Action buttons
          Padding(
            padding: const EdgeInsets.all(16),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ElevatedButton.icon(
                  onPressed: _testHealthCheck,
                  icon: const Icon(Icons.health_and_safety),
                  label: const Text('Health'),
                ),
                ElevatedButton.icon(
                  onPressed: _testLogin,
                  icon: const Icon(Icons.login),
                  label: const Text('Login'),
                ),
                ElevatedButton.icon(
                  onPressed: _testDatabase,
                  icon: const Icon(Icons.storage),
                  label: const Text('Database'),
                ),
                ElevatedButton.icon(
                  onPressed: _testAIChat,
                  icon: const Icon(Icons.chat),
                  label: const Text('AI Chat'),
                ),
              ],
            ),
          ),
          
          const Divider(),
          
          // Logs
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _logs.length,
              itemBuilder: (context, index) {
                final log = _logs[index];
                Color? color;
                if (log.contains('✅')) color = Colors.green.shade700;
                if (log.contains('❌')) color = Colors.red.shade700;
                
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Text(
                    log,
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                      color: color,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          setState(() => _logs.clear());
          _addLog('Logs cleared');
        },
        child: const Icon(Icons.delete),
      ),
    );
  }
}
