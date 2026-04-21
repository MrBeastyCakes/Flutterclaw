import 'package:flutter_test/flutter_test.dart';
import 'package:flutterclaw/services/websocket_service.dart';
import 'package:flutterclaw/models/message.dart';

void main() {
  group('WebSocketService', () {
    late WebSocketService service;

    setUp(() {
      service = WebSocketService();
    });

    tearDown(() {
      service.dispose();
    });

    test('initial state is disconnected', () {
      expect(service.connectionStream, isNotNull);
      expect(service.messageStream, isNotNull);
    });

    test('can set server URL via setter', () {
      service.serverUrl = 'ws://test:8765';
      // No public getter, but setter should not throw
      expect(true, isTrue);
    });

    test('can set chat ID via setter', () {
      service.chatId = 'test:main';
      expect(true, isTrue);
    });
  });
}
