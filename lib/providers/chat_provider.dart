import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/message.dart';
import '../models/connection_state.dart';
import '../services/websocket_service.dart';

class ChatProvider extends ChangeNotifier {
  final WebSocketService _webSocketService;
  final List<ChatMessage> _messages = [];
  ConnectionInfo _connectionInfo = const ConnectionInfo();
  bool _isTyping = false;
  String? _error;
  String _searchQuery = '';

  List<ChatMessage> get messages => List.unmodifiable(_messages);
  List<ChatMessage> get filteredMessages {
    if (_searchQuery.isEmpty) return messages;
    final lower = _searchQuery.toLowerCase();
    return _messages
        .where((m) => m.content.toLowerCase().contains(lower))
        .toList();
  }

  ConnectionInfo get connectionInfo => _connectionInfo;
  bool get isTyping => _isTyping;
  String? get error => _error;
  String get searchQuery => _searchQuery;

  StreamSubscription<ChatMessage>? _messageSubscription;
  StreamSubscription<ConnectionInfo>? _connectionSubscription;

  ChatProvider({WebSocketService? webSocketService})
      : _webSocketService = webSocketService ?? WebSocketService();

  void initialize() {
    _messageSubscription = _webSocketService.messageStream.listen(
      _onMessageReceived,
      onError: _onError,
    );

    _connectionSubscription = _webSocketService.connectionStream.listen(
      _onConnectionChanged,
      onError: _onError,
    );

    _webSocketService.connect();
  }

  void _onMessageReceived(ChatMessage message) {
    if (message.role == MessageRole.assistant) {
      _isTyping = false;
    }
    
    _messages.add(message);
    notifyListeners();
  }

  void _onConnectionChanged(ConnectionInfo info) {
    _connectionInfo = info;
    if (info.state == ConnectionState.error) {
      _error = info.errorMessage;
    } else {
      _error = null;
    }
    notifyListeners();
  }

  void _onError(Object error) {
    _error = error.toString();
    notifyListeners();
  }

  void sendMessage(String content, {Map<String, dynamic>? metadata}) {
    try {
      final message = ChatMessage(
        role: MessageRole.user,
        content: content,
        status: MessageStatus.sending,
      );
      
      _messages.add(message);
      _isTyping = true;
      notifyListeners();

      _webSocketService.sendMessage(content, metadata: metadata);
      
      // Update message status
      final index = _messages.indexOf(message);
      if (index != -1) {
        _messages[index] = message.copyWith(status: MessageStatus.sent);
        notifyListeners();
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Retry a previously-failed or any user message.
  void retryMessage(ChatMessage message) {
    final index = _messages.indexWhere((m) => m.id == message.id);
    if (index == -1) return;

    // Remove the old message and its assistant response (if any)
    _messages.removeAt(index);
    // Also remove any consecutive assistant/tool messages that followed
    while (index < _messages.length &&
        (_messages[index].role == MessageRole.assistant ||
         _messages[index].role == MessageRole.tool)) {
      _messages.removeAt(index);
    }

    notifyListeners();

    // Re-send
    sendMessage(message.content, metadata: message.metadata);
  }

  /// Delete a message by ID.
  void deleteMessage(String id) {
    _messages.removeWhere((m) => m.id == id);
    notifyListeners();
  }

  /// Filter messages by search query.
  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void clearMessages() {
    _messages.clear();
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  Future<void> reconnect() async {
    await _webSocketService.disconnect();
    await _webSocketService.connect();
  }

  void setServerUrl(String url) {
    _webSocketService.serverUrl = url;
    reconnect();
  }

  void setChatId(String chatId) {
    _webSocketService.chatId = chatId;
    reconnect();
  }

  void setSenderName(String name) {
    _webSocketService.senderName = name;
  }

  @override
  void dispose() {
    _messageSubscription?.cancel();
    _connectionSubscription?.cancel();
    _webSocketService.dispose();
    super.dispose();
  }
}
