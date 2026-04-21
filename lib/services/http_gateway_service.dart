import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/message.dart';
import '../models/connection_state.dart';
import '../utils/logger.dart';

/// OpenClaw Gateway HTTP API client (OpenAI-compatible).
///
/// Uses the REST endpoints instead of WebSocket for simpler connectivity.
/// Endpoints:
/// - POST /v1/chat/completions  - Chat messages
/// - POST /v1/responses        - Response API
class HttpGatewayService {
  static const String _defaultServerUrl = 'http://192.168.92.79:18789';
  static const Duration _timeout = Duration(seconds: 30);

  String _serverUrl = _defaultServerUrl;
  String _authToken = '';
  String _chatId = 'flutter:main';
  String? _lastError;

  final _connectionController = StreamController<ConnectionInfo>.broadcast();
  Stream<ConnectionInfo> get connectionStream => _connectionController.stream;

  String? get lastError => _lastError;

  set serverUrl(String url) {
    // Normalize URL - remove ws:// prefix and replace with http://
    if (url.startsWith('ws://')) {
      url = 'http://' + url.substring(5);
    } else if (url.startsWith('wss://')) {
      url = 'https://' + url.substring(6);
    }
    _serverUrl = url;
  }

  set authToken(String token) => _authToken = token;
  set chatId(String id) => _chatId = id;

  String get serverUrl => _serverUrl;

  Future<bool> checkHealth() async {
    AppLogger.info('Checking health at $_serverUrl/v1/models', tag: 'HTTP');
    try {
      final uri = Uri.parse('$_serverUrl/v1/models');
      final response = await http.get(
        uri,
        headers: _buildHeaders(),
      ).timeout(_timeout);

      final isOk = response.statusCode == 200;
      _lastError = isOk ? null : 'HTTP ${response.statusCode}: ${response.body}';
      AppLogger.info('Health check result: ${isOk ? "OK" : "FAIL ($_lastError)"}', tag: 'HTTP');
      
      _connectionController.add(ConnectionInfo(
        state: isOk ? ConnectionState.connected : ConnectionState.error,
        serverUrl: _serverUrl,
        errorMessage: _lastError,
      ));
      return isOk;
    } catch (e, stackTrace) {
      _lastError = 'Health check failed: $e';
      AppLogger.error('Health check exception', tag: 'HTTP', error: e, stackTrace: stackTrace);
      _connectionController.add(ConnectionInfo(
        state: ConnectionState.error,
        serverUrl: _serverUrl,
        errorMessage: _lastError,
      ));
      return false;
    }
  }

  Future<ChatMessage?> sendMessage(
    String content, {
    List<ChatMessage> history = const [],
  }) async {
    AppLogger.info('Sending message to $_serverUrl/v1/chat/completions', tag: 'HTTP');
    try {
      _connectionController.add(ConnectionInfo(
        state: ConnectionState.connecting,
        serverUrl: _serverUrl,
      ));

      final messages = _buildMessages(content, history);
      AppLogger.debug('Request body: ${jsonEncode({"model": "openclaw/default", "messages": messages, "stream": false})}', tag: 'HTTP');
      
      final response = await http.post(
        Uri.parse('$_serverUrl/v1/chat/completions'),
        headers: _buildHeaders(),
        body: jsonEncode({
          'model': 'openclaw/default',
          'messages': messages,
          'stream': false,
        }),
      ).timeout(const Duration(minutes: 2));

      AppLogger.info('Response status: ${response.statusCode}', tag: 'HTTP');
      AppLogger.debug('Response body: ${response.body}', tag: 'HTTP');

      if (response.statusCode != 200) {
        _lastError = 'HTTP ${response.statusCode}: ${response.body}';
        AppLogger.error('Request failed: $_lastError', tag: 'HTTP');
        _connectionController.add(ConnectionInfo(
          state: ConnectionState.error,
          serverUrl: _serverUrl,
          errorMessage: _lastError,
        ));
        return null;
      }

      final json = jsonDecode(response.body);
      final choices = json['choices'] as List?;
      if (choices == null || choices.isEmpty) {
        _lastError = 'No choices in response';
        AppLogger.error(_lastError!, tag: 'HTTP');
        return null;
      }

      final choice = choices[0];
      final message = choice['message'] as Map<String, dynamic>?;
      if (message == null) {
        _lastError = 'No message in choice';
        AppLogger.error(_lastError!, tag: 'HTTP');
        return null;
      }

      _lastError = null;
      _connectionController.add(ConnectionInfo(
        state: ConnectionState.connected,
        serverUrl: _serverUrl,
        lastConnectedAt: DateTime.now(),
      ));

      return ChatMessage(
        role: MessageRole.assistant,
        content: message['content'] as String? ?? '',
        metadata: {
          'finish_reason': choice['finish_reason'],
        },
      );
    } catch (e, stackTrace) {
      _lastError = 'Request exception: $e';
      AppLogger.error('Request exception', tag: 'HTTP', error: e, stackTrace: stackTrace);
      _connectionController.add(ConnectionInfo(
        state: ConnectionState.error,
        serverUrl: _serverUrl,
        errorMessage: _lastError,
      ));
      return null;
    }
  }

  /// Send a streaming chat request
  Stream<String> sendStreamingMessage(
    String content, {
    List<ChatMessage> history = const [],
  }) async* {
    try {
      _connectionController.add(ConnectionInfo(
        state: ConnectionState.connecting,
        serverUrl: _serverUrl,
      ));

      final messages = _buildMessages(content, history);
      final request = http.Request(
        'POST',
        Uri.parse('$_serverUrl/v1/chat/completions'),
      );
      request.headers.addAll(_buildHeaders());
      request.body = jsonEncode({
        'model': 'openclaw/default',
        'messages': messages,
        'stream': true,
      });

      final response = await request.send().timeout(const Duration(minutes: 2));

      if (response.statusCode != 200) {
        final body = await response.stream.bytesToString();
        _connectionController.add(ConnectionInfo(
          state: ConnectionState.error,
          serverUrl: _serverUrl,
          errorMessage: 'HTTP ${response.statusCode}: $body',
        ));
        return;
      }

      _connectionController.add(ConnectionInfo(
        state: ConnectionState.connected,
        serverUrl: _serverUrl,
        lastConnectedAt: DateTime.now(),
      ));

      // Read SSE stream
      final stream = response.stream
          .transform(utf8.decoder)
          .transform(const LineSplitter());

      await for (final line in stream) {
        if (line.startsWith('data: ')) {
          final data = line.substring(6);
          if (data == '[DONE]') {
            return;
          }
          try {
            final json = jsonDecode(data);
            final choices = json['choices'] as List?;
            if (choices != null && choices.isNotEmpty) {
              final delta = choices[0]['delta'] as Map<String, dynamic>?;
              if (delta != null && delta['content'] != null) {
                yield delta['content'] as String;
              }
            }
          } catch (_) {
            // Skip malformed chunks
          }
        }
      }
    } catch (e) {
      _connectionController.add(ConnectionInfo(
        state: ConnectionState.error,
        serverUrl: _serverUrl,
        errorMessage: e.toString(),
      ));
    }
  }

  Map<String, String> _buildHeaders() {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (_authToken.isNotEmpty) {
      headers['Authorization'] = 'Bearer $_authToken';
    }

    return headers;
  }

  List<Map<String, dynamic>> _buildMessages(
    String content,
    List<ChatMessage> history,
  ) {
    final messages = <Map<String, dynamic>>[];

    for (final msg in history) {
      if (msg.role == MessageRole.system) continue;
      messages.add({
        'role': msg.role == MessageRole.user ? 'user' : 'assistant',
        'content': msg.content,
      });
    }

    messages.add({
      'role': 'user',
      'content': content,
    });

    return messages;
  }

  void dispose() {
    _connectionController.close();
  }
}
