import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/io.dart';
import '../models/message.dart';
import '../models/connection_state.dart';
import '../models/tool_call.dart';
import '../utils/logger.dart';

/// OpenClaw Gateway service using WebSocket with protocol v3 handshake.
///
/// Handles the complete handshake sequence:
/// 1. Connect to WebSocket endpoint
/// 2. Wait for connect.challenge event
/// 3. Send connect request with auth token
/// 4. Wait for hello-ok response
/// 5. Mark connection as established
class WebSocketService {
  static const String _defaultServerUrl = 'ws://192.168.92.79:18789';
  static const int _maxReconnectAttempts = 5;
  static const Duration _reconnectDelay = Duration(seconds: 3);
  
  WebSocketChannel? _channel;
  final _messageController = StreamController<ChatMessage>.broadcast();
  final _connectionController = StreamController<ConnectionInfo>.broadcast();
  final _streamChunkController = StreamController<Map<String, dynamic>>.broadcast();
  
  Stream<ChatMessage> get messageStream => _messageController.stream;
  Stream<ConnectionInfo> get connectionStream => _connectionController.stream;
  Stream<Map<String, dynamic>> get streamChunkStream => _streamChunkController.stream;
  
  int _reconnectAttempts = 0;
  Timer? _reconnectTimer;
  bool _isDisposed = false;
  String _serverUrl = _defaultServerUrl;
  String _chatId = 'flutter:main';
  String _senderName = 'Flutter User';
  String _authToken = '';
  bool _handshakeComplete = false;
  String? _lastError;

  // Setters for configuration
  set serverUrl(String url) => _serverUrl = url;
  set chatId(String id) => _chatId = id;
  set senderName(String name) => _senderName = name;
  set authToken(String token) => _authToken = token;

  /// Get the current auth token
  String get authToken => _authToken;

  Future<void> connect() async {
    if (_isDisposed) return;
    if (_channel != null) {
      await disconnect();
    }

    _handshakeComplete = false;

    _connectionController.add(ConnectionInfo(
      state: ConnectionState.connecting,
      serverUrl: _serverUrl,
    ));

    try {
      _channel = IOWebSocketChannel.connect(
        Uri.parse(_serverUrl),
        pingInterval: const Duration(seconds: 30),
      );

      _channel!.stream.listen(
        _onMessage,
        onError: _onError,
        onDone: _onDone,
      );

      _reconnectAttempts = 0;
    } catch (e) {
      _connectionController.add(ConnectionInfo(
        state: ConnectionState.error,
        serverUrl: _serverUrl,
        errorMessage: e.toString(),
      ));
      _scheduleReconnect();
    }
  }

  void _onMessage(dynamic data) {
    try {
      final json = jsonDecode(data as String);
      final msgType = json['type'] as String?;

      // Handle gateway handshake challenge
      if (msgType == 'event' && json['event'] == 'connect.challenge') {
        try {
          final payload = json['payload'] as Map<String, dynamic>?;
          final nonce = payload?['nonce'] as String?;
          if (nonce != null && _channel != null) {
            _sendConnectRequest(nonce);
          } else {
            _connectionController.add(ConnectionInfo(
              state: ConnectionState.error,
              serverUrl: _serverUrl,
              errorMessage: nonce == null ? 'No nonce in challenge' : 'Channel not ready',
            ));
          }
        } catch (e) {
          _connectionController.add(ConnectionInfo(
            state: ConnectionState.error,
            serverUrl: _serverUrl,
            errorMessage: 'Challenge handling error: $e',
          ));
        }
        return;
      }

      // Handle hello-ok response (handshake complete)
      if (msgType == 'res') {
        final payload = json['payload'] as Map<String, dynamic>?;
        final payloadType = payload?['type'] as String?;
        
        if (payloadType == 'hello-ok') {
          _handshakeComplete = true;
          _connectionController.add(ConnectionInfo(
            state: ConnectionState.connected,
            serverUrl: _serverUrl,
            lastConnectedAt: DateTime.now(),
          ));
          return;
        }
        
        // If it's a successful response but not hello-ok, just acknowledge
        if (json['ok'] == true) {
          return;
        }
        
        // Handle errors
        if (json['ok'] == false) {
          final error = json['error']?['message'] ?? json['error']?.toString() ?? 'Unknown error';
          _connectionController.add(ConnectionInfo(
            state: ConnectionState.error,
            serverUrl: _serverUrl,
            errorMessage: 'Gateway error: $error',
          ));
          return;
        }
      }

      // Handle hello-ok response (handshake complete)
      if (msgType == 'res' && json['payload']?['type'] == 'hello-ok') {
        _handshakeComplete = true;
        _connectionController.add(ConnectionInfo(
          state: ConnectionState.connected,
          serverUrl: _serverUrl,
          lastConnectedAt: DateTime.now(),
        ));
        return;
      }

      // Handle errors from gateway
      if (msgType == 'res' && json['ok'] == false) {
        final error = json['error']?['message'] ?? json['error']?.toString() ?? 'Unknown error';
        _connectionController.add(ConnectionInfo(
          state: ConnectionState.error,
          serverUrl: _serverUrl,
          errorMessage: error,
        ));
        return;
      }

      // Handle streaming chunks
      if (msgType == 'stream_chunk') {
        _streamChunkController.add({
          'messageId': json['messageId'] as String,
          'chunk': json['chunk'] as String? ?? '',
          'thinking': json['thinking'] as String?,
          'toolUsages': json['toolUsages'] != null
              ? (json['toolUsages'] as List).map((u) => ToolUsage(
                  id: u['id'] as String,
                  timestamp: DateTime.parse(u['timestamp'] as String),
                  calls: (u['calls'] as List).map((c) => ToolCall(
                    id: c['id'] as String,
                    name: c['name'] as String,
                    description: c['description'] as String?,
                    status: ToolStatus.values.byName(c['status'] as String),
                    timestamp: DateTime.parse(c['timestamp'] as String),
                    duration: c['duration'] != null
                        ? Duration(milliseconds: c['duration'] as int)
                        : null,
                    result: c['result'] as String?,
                    error: c['error'] as String?,
                    parameters: c['parameters'] as Map<String, dynamic>?,
                  )).toList(),
                )).toList()
              : null,
          'isComplete': json['isComplete'] as bool? ?? false,
        });
        return;
      }
      
      // Handle regular messages
      final message = ChatMessage.fromJson(json);
      _messageController.add(message);
    } catch (e) {
      // Handle non-JSON messages or system messages
      final systemMessage = ChatMessage(
        role: MessageRole.system,
        content: data.toString(),
        metadata: {'raw': true},
      );
      _messageController.add(systemMessage);
    }
  }

  void _sendConnectRequest(String nonce) {
    if (_channel == null) return;
    
    final requestId = _generateRequestId();
    final connectPayload = {
      'type': 'req',
      'id': requestId,
      'method': 'connect',
      'params': {
        'minProtocol': 3,
        'maxProtocol': 3,
        'client': {
          'id': 'cli',
          'version': '0.3.7',
          'platform': 'android',
          'mode': 'operator',
        },
        'role': 'operator',
        'scopes': ['operator.read', 'operator.write'],
        'caps': [],
        'commands': [],
        'permissions': {},
        'auth': {'token': _authToken},
        'locale': 'en-US',
        'userAgent': 'Flutterclaw/0.3.7',
        'device': {
          'id': 'flutterclaw_device_${DateTime.now().millisecondsSinceEpoch}',
          'nonce': nonce,
        },
      },
    };
    
    _channel!.sink.add(jsonEncode(connectPayload));
  }

  String _generateRequestId() {
    final random = Random();
    final chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    return List.generate(16, (_) => chars[random.nextInt(chars.length)]).join();
  }

  void _onError(dynamic error) {
    _connectionController.add(ConnectionInfo(
      state: ConnectionState.error,
      serverUrl: _serverUrl,
      errorMessage: error.toString(),
    ));
    _scheduleReconnect();
  }

  void _onDone() {
    if (!_isDisposed && _channel != null) {
      _connectionController.add(ConnectionInfo(
        state: ConnectionState.disconnected,
        serverUrl: _serverUrl,
      ));
      _scheduleReconnect();
    }
  }

  void _scheduleReconnect() {
    if (_reconnectAttempts >= _maxReconnectAttempts) {
      _connectionController.add(ConnectionInfo(
        state: ConnectionState.error,
        serverUrl: _serverUrl,
        errorMessage: 'Max reconnection attempts reached',
      ));
      return;
    }

    _reconnectAttempts++;
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(_reconnectDelay * _reconnectAttempts, () {
      if (!_isDisposed) {
        connect();
      }
    });
  }

  Future<void> sendMessage(String content, {Map<String, dynamic>? metadata}) async {
    if (_channel == null) {
      throw StateError('WebSocket not connected');
    }

    // If handshake isn't complete, we can't send messages yet
    if (!_handshakeComplete) {
      throw StateError('WebSocket handshake not complete');
    }

    final message = ChatMessage(
      role: MessageRole.user,
      content: content,
      metadata: metadata,
    );

    final payload = {
      'type': 'chat',
      'chatId': _chatId,
      'message': message.toJson(),
    };

    _channel!.sink.add(jsonEncode(payload));
  }

  Future<void> disconnect() async {
    _reconnectTimer?.cancel();
    _handshakeComplete = false;
    await _channel?.sink.close();
    _channel = null;
    _connectionController.add(ConnectionInfo(
      state: ConnectionState.disconnected,
      serverUrl: _serverUrl,
    ));
  }

  void dispose() {
    _isDisposed = true;
    _reconnectTimer?.cancel();
    _channel?.sink.close();
    _messageController.close();
    _connectionController.close();
    _streamChunkController.close();
  }
}
