import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/io.dart';
import '../models/message.dart';
import '../models/connection_state.dart';
import '../models/tool_call.dart';

/// Callback for streaming message chunks
typedef StreamChunkCallback = void Function(String messageId, String chunk, {String? thinking, List<ToolUsage>? toolUsages});

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

  // Setters for configuration
  set serverUrl(String url) => _serverUrl = url;
  set chatId(String id) => _chatId = id;
  set senderName(String name) => _senderName = name;

  Future<void> connect() async {
    if (_isDisposed) return;
    if (_channel != null) {
      await disconnect();
    }

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
      _connectionController.add(ConnectionInfo(
        state: ConnectionState.connected,
        serverUrl: _serverUrl,
        lastConnectedAt: DateTime.now(),
      ));
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
      
      // Handle streaming chunks
      if (json['type'] == 'stream_chunk') {
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

  void _onError(Object error) {
    _connectionController.add(ConnectionInfo(
      state: ConnectionState.error,
      serverUrl: _serverUrl,
      errorMessage: error.toString(),
      reconnectAttempts: _reconnectAttempts,
    ));
    _scheduleReconnect();
  }

  void _onDone() {
    if (_isDisposed) return;
    _connectionController.add(ConnectionInfo(
      state: ConnectionState.disconnected,
      serverUrl: _serverUrl,
      reconnectAttempts: _reconnectAttempts,
    ));
    _scheduleReconnect();
  }

  void _scheduleReconnect() {
    if (_reconnectAttempts >= _maxReconnectAttempts || _isDisposed) return;
    
    _reconnectAttempts++;
    _connectionController.add(ConnectionInfo(
      state: ConnectionState.reconnecting,
      serverUrl: _serverUrl,
      reconnectAttempts: _reconnectAttempts,
    ));

    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(_reconnectDelay, () {
      if (!_isDisposed) connect();
    });
  }

  void sendMessage(String content, {Map<String, dynamic>? metadata}) {
    if (_channel == null || _channel!.closeCode != null) {
      throw StateError('WebSocket is not connected');
    }

    final payload = {
      'type': 'message',
      'chatJid': _chatId,
      'senderName': _senderName,
      'content': content,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'metadata': metadata,
    };

    _channel!.sink.add(jsonEncode(payload));
  }

  Future<void> disconnect() async {
    _reconnectTimer?.cancel();
    _reconnectAttempts = 0;
    
    if (_channel != null) {
      await _channel!.sink.close();
      _channel = null;
    }
    
    _connectionController.add(const ConnectionInfo(
      state: ConnectionState.disconnected,
    ));
  }

  void dispose() {
    _isDisposed = true;
    _reconnectTimer?.cancel();
    disconnect();
    _messageController.close();
    _connectionController.close();
    _streamChunkController.close();
  }
}
