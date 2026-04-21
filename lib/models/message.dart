import 'package:uuid/uuid.dart';
import 'tool_call.dart';

enum MessageRole {
  user,
  assistant,
  system,
  tool,
}

enum MessageStatus {
  sending,
  sent,
  delivered,
  error,
}

class ChatMessage {
  final String id;
  final MessageRole role;
  final String content;
  final String? thinking;
  final bool isStreaming;
  final DateTime timestamp;
  final MessageStatus status;
  final Map<String, dynamic>? metadata;
  final List<ToolUsage>? toolUsages;

  ChatMessage({
    String? id,
    required this.role,
    required this.content,
    this.thinking,
    this.isStreaming = false,
    DateTime? timestamp,
    this.status = MessageStatus.sent,
    this.metadata,
    this.toolUsages,
  })  : id = id ?? const Uuid().v4(),
        timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toJson() => {
    'id': id,
    'role': role.name,
    'content': content,
    'thinking': thinking,
    'isStreaming': isStreaming,
    'timestamp': timestamp.toIso8601String(),
    'status': status.name,
    'metadata': metadata,
    'toolUsages': toolUsages?.map((u) => {
      'id': u.id,
      'timestamp': u.timestamp.toIso8601String(),
      'calls': u.calls.map((c) => {
        'id': c.id,
        'name': c.name,
        'description': c.description,
        'status': c.status.name,
        'timestamp': c.timestamp.toIso8601String(),
        'duration': c.duration?.inMilliseconds,
        'result': c.result,
        'error': c.error,
        'parameters': c.parameters,
      }).toList(),
    }).toList(),
  };

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    List<ToolUsage>? usages;
    if (json['toolUsages'] != null) {
      usages = (json['toolUsages'] as List).map((u) => ToolUsage(
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
      )).toList();
    }

    return ChatMessage(
      id: json['id'] as String,
      role: MessageRole.values.byName(json['role'] as String),
      content: json['content'] as String,
      thinking: json['thinking'] as String?,
      isStreaming: json['isStreaming'] as bool? ?? false,
      timestamp: DateTime.parse(json['timestamp'] as String),
      status: MessageStatus.values.byName(json['status'] as String),
      metadata: json['metadata'] as Map<String, dynamic>?,
      toolUsages: usages,
    );
  }

  ChatMessage copyWith({
    MessageRole? role,
    String? content,
    String? thinking,
    bool? isStreaming,
    MessageStatus? status,
    Map<String, dynamic>? metadata,
    List<ToolUsage>? toolUsages,
  }) {
    return ChatMessage(
      id: id,
      role: role ?? this.role,
      content: content ?? this.content,
      thinking: thinking ?? this.thinking,
      isStreaming: isStreaming ?? this.isStreaming,
      timestamp: timestamp,
      status: status ?? this.status,
      metadata: metadata ?? this.metadata,
      toolUsages: toolUsages ?? this.toolUsages,
    );
  }
}

