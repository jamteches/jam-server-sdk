import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'jam_client.dart';

/// Real-time service for WebSocket connections
/// 
/// Subscribe to collection updates and receive real-time notifications.
/// 
/// Example:
/// ```dart
/// final jam = Jam('https://api.jamteches.com');
/// await jam.auth.login(username: 'john', password: 'pass');
/// 
/// // Connect to realtime
/// jam.realtime.connect();
/// 
/// // Subscribe to a collection
/// jam.realtime.subscribe('messages');
/// 
/// // Listen for updates
/// jam.realtime.stream.listen((event) {
///   print('Event: ${event['type']} on ${event['collection']}');
///   print('Data: ${event['data']}');
/// });
/// 
/// // When done
/// jam.realtime.disconnect();
/// ```
class RealtimeService {
  final JamClient _client;
  WebSocketChannel? _channel;
  final _streamController = StreamController<Map<String, dynamic>>.broadcast();
  final Set<String> _subscriptions = {};
  bool _isConnected = false;
  Timer? _reconnectTimer;
  Timer? _pingTimer;

  RealtimeService(this._client);

  /// Stream of real-time events
  Stream<Map<String, dynamic>> get stream => _streamController.stream;

  /// Check if connected to WebSocket
  bool get isConnected => _isConnected;

  /// Get list of active subscriptions
  Set<String> get subscriptions => Set.unmodifiable(_subscriptions);

  /// Connect to WebSocket server
  void connect({String? projectId}) {
    if (_isConnected) return;

    final token = _client.token;
    final apiKey = _client.apiKey;
    
    if (token == null && apiKey == null) {
      throw Exception('Authentication required for realtime connection');
    }

    // Build WebSocket URL
    final wsBase = _client.baseUrl.replaceFirst('http', 'ws');
    final authParam = apiKey != null ? 'api_key=$apiKey' : 'token=$token';
    var wsUrl = '$wsBase/api/ws?$authParam';
    
    final effectiveProjectId = projectId ?? _client.currentProjectId;
    if (effectiveProjectId != null) {
      wsUrl += '&project_id=$effectiveProjectId';
    }

    _channel = WebSocketChannel.connect(Uri.parse(wsUrl));

    _channel!.stream.listen(
      (message) {
        _isConnected = true;
        try {
          final data = jsonDecode(message);
          _streamController.add(data);
        } catch (e) {
          print('[Jam Realtime] Error parsing message: $e');
        }
      },
      onError: (error) {
        print('[Jam Realtime] WebSocket error: $error');
        _isConnected = false;
        _streamController.addError(error);
        _scheduleReconnect();
      },
      onDone: () {
        print('[Jam Realtime] WebSocket connection closed');
        _isConnected = false;
        _scheduleReconnect();
      },
    );

    _isConnected = true;
    
    // Re-subscribe to collections after connect
    for (final collection in _subscriptions) {
      _sendSubscribe(collection);
    }

    // Start ping timer
    _startPingTimer();
  }

  /// Disconnect from WebSocket server
  void disconnect() {
    _isConnected = false;
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _pingTimer?.cancel();
    _pingTimer = null;
    _channel?.sink.close();
    _channel = null;
  }

  /// Subscribe to updates for a collection
  void subscribe(String collection) {
    _subscriptions.add(collection);
    if (_isConnected) {
      _sendSubscribe(collection);
    }
  }

  /// Unsubscribe from updates for a collection
  void unsubscribe(String collection) {
    _subscriptions.remove(collection);
    if (_isConnected) {
      _send({'type': 'unsubscribe', 'collection': collection});
    }
  }

  /// Send a message through WebSocket
  void send(Map<String, dynamic> data) {
    _send(data);
  }

  void _sendSubscribe(String collection) {
    _send({'type': 'subscribe', 'collection': collection});
  }

  void _send(Map<String, dynamic> data) {
    if (_channel != null && _isConnected) {
      _channel!.sink.add(jsonEncode(data));
    } else {
      throw Exception('WebSocket not connected');
    }
  }

  void _scheduleReconnect() {
    if (_reconnectTimer != null) return;
    
    print('[Jam Realtime] Reconnecting in 5 seconds...');
    _reconnectTimer = Timer(const Duration(seconds: 5), () {
      _reconnectTimer = null;
      try {
        connect();
      } catch (e) {
        print('[Jam Realtime] Reconnect failed: $e');
        _scheduleReconnect();
      }
    });
  }

  void _startPingTimer() {
    _pingTimer?.cancel();
    _pingTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (_isConnected) {
        try {
          _send({'type': 'ping'});
        } catch (e) {
          // Ignore ping errors
        }
      }
    });
  }

  /// Dispose resources
  void dispose() {
    disconnect();
    _streamController.close();
  }
}

/// Real-time event types
class RealtimeEventType {
  static const String create = 'create';
  static const String update = 'update';
  static const String delete = 'delete';
  static const String ping = 'ping';
  static const String pong = 'pong';
}
