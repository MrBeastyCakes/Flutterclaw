import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/message.dart';

enum ToolStatus {
  pending,
  running,
  completed,
  error,
}

class ToolCall {
  final String id;
  final String name;
  final String? description;
  final ToolStatus status;
  final DateTime timestamp;
  final Duration? duration;
  final String? result;
  final String? error;
  final Map<String, dynamic>? parameters;

  const ToolCall({
    required this.id,
    required this.name,
    this.description,
    this.status = ToolStatus.pending,
    required this.timestamp,
    this.duration,
    this.result,
    this.error,
    this.parameters,
  });

  ToolCall copyWith({
    ToolStatus? status,
    Duration? duration,
    String? result,
    String? error,
  }) {
    return ToolCall(
      id: id,
      name: name,
      description: description,
      status: status ?? this.status,
      timestamp: timestamp,
      duration: duration ?? this.duration,
      result: result ?? this.result,
      error: error ?? this.error,
      parameters: parameters,
    );
  }

  String get displayName {
    switch (name) {
      case 'exec':
        return 'Run command';
      case 'read':
        return 'Read file';
      case 'write':
        return 'Write file';
      case 'edit':
        return 'Edit file';
      case 'web_fetch':
        return 'Fetch webpage';
      case 'memory_search':
        return 'Search memory';
      case 'image':
        return 'Analyze image';
      default:
        return name.replaceAll('_', ' ').split(' ').map((w) => 
          w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : ''
        ).join(' ');
    }
  }

  IconData get icon {
    switch (name) {
      case 'exec':
        return Icons.terminal;
      case 'read':
      case 'write':
      case 'edit':
        return Icons.description;
      case 'web_fetch':
        return Icons.language;
      case 'memory_search':
        return Icons.memory;
      case 'image':
        return Icons.image;
      default:
        return Icons.build;
    }
  }
}

class ToolUsage {
  final String id;
  final DateTime timestamp;
  final List<ToolCall> calls;

  const ToolUsage({
    required this.id,
    required this.timestamp,
    required this.calls,
  });

  bool get isComplete => calls.every((c) => 
    c.status == ToolStatus.completed || c.status == ToolStatus.error);
  bool get hasErrors => calls.any((c) => c.status == ToolStatus.error);
  bool get isRunning => calls.any((c) => c.status == ToolStatus.running);
}

