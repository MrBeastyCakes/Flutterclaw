import 'package:flutter_test/flutter_test.dart';
import 'package:flutterclaw/models/message.dart';
import 'package:flutterclaw/models/tool_call.dart';

void main() {
  group('ChatMessage serialization', () {
    test('round-trip JSON with toolUsages', () {
      final original = ChatMessage(
        role: MessageRole.assistant,
        content: 'Hello',
        toolUsages: [
          ToolUsage(
            id: 'tu-1',
            timestamp: DateTime.now(),
            calls: [
              ToolCall(
                id: 'tc-1',
                name: 'exec',
                status: ToolStatus.completed,
                timestamp: DateTime.now(),
                result: 'done',
              ),
            ],
          ),
        ],
      );

      final json = original.toJson();
      final restored = ChatMessage.fromJson(json);

      expect(restored.id, original.id);
      expect(restored.role, original.role);
      expect(restored.content, original.content);
      expect(restored.toolUsages?.length, 1);
      expect(restored.toolUsages?.first.calls.first.name, 'exec');
      expect(restored.toolUsages?.first.calls.first.status, ToolStatus.completed);
    });

    test('round-trip JSON without toolUsages', () {
      final original = ChatMessage(
        role: MessageRole.user,
        content: 'Test',
        status: MessageStatus.sending,
      );

      final json = original.toJson();
      final restored = ChatMessage.fromJson(json);

      expect(restored.id, original.id);
      expect(restored.role, MessageRole.user);
      expect(restored.toolUsages, isNull);
    });

    test('copyWith preserves id', () {
      final msg = ChatMessage(role: MessageRole.user, content: 'A');
      final copy = msg.copyWith(content: 'B');
      expect(copy.id, msg.id);
      expect(copy.content, 'B');
    });
  });
}
