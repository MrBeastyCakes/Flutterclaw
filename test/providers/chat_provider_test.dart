import 'package:flutter_test/flutter_test.dart';
import 'package:flutterclaw/providers/chat_provider.dart';
import 'package:flutterclaw/models/message.dart';
import 'package:flutterclaw/services/websocket_service.dart';

class _FakeWebSocketService extends Fake implements WebSocketService {
  @override
  void sendMessage(String content, {Map<String, dynamic>? metadata}) {}

  @override
  void dispose() {}

  @override
  Future<void> connect() async {}

  @override
  Future<void> disconnect() async {}
}

void main() {
  group('ChatProvider search', () {
    late ChatProvider provider;

    setUp(() {
      provider = ChatProvider(webSocketService: _FakeWebSocketService());
    });

    tearDown(() {
      provider.dispose();
    });

    test('search filters messages', () {
      provider.sendMessage('hello world');
      provider.sendMessage('goodbye moon');
      
      provider.setSearchQuery('hello');
      expect(provider.filteredMessages.length, 1);
      expect(provider.filteredMessages.first.content, 'hello world');

      provider.setSearchQuery('');
      expect(provider.filteredMessages.length, 2);
    });

    test('deleteMessage removes message', () {
      provider.sendMessage('temp');
      final id = provider.messages.first.id;
      provider.deleteMessage(id);
      expect(provider.messages.isEmpty, true);
    });

    test('retryMessage resends content', () {
      provider.sendMessage('retry me');
      final id = provider.messages.first.id;
      provider.retryMessage(provider.messages.first);
      expect(provider.messages.any((m) => m.id == id), false);
    });
  });
}
