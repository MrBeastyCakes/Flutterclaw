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

    test('can set server URL', () {
      service.serverUrl = 'ws://test:8765';
      expect(service.serverUrl, 'ws://test:8765');
    });

    test('can set chat ID', () {
      service.chatId = 'test:main';
      expect(service.chatId, 'test:main');
    });
  });
}
