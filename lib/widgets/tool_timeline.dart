import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/tool_call.dart';

class ToolTimeline extends StatelessWidget {
  final List<ToolUsage> toolUsages;

  const ToolTimeline({
    super.key,
    required this.toolUsages,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(left: 48, right: 16, top: 4, bottom: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.build_circle_outlined,
                size: 16,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 8),
              Text(
                'Tool Usage',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const Spacer(),
              if (toolUsages.any((u) => u.isRunning))
                SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation(
                      Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          ...toolUsages.expand((usage) => usage.calls).map((call) => 
            _ToolCallChip(call: call),
          ),
        ],
      ),
    );
  }
}

class _ToolCallChip extends StatelessWidget {
  final ToolCall call;

  const _ToolCallChip({required this.call});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline line
          Container(
            width: 2,
            height: 28,
            margin: const EdgeInsets.only(right: 12, left: 6),
            decoration: BoxDecoration(
              color: _getStatusColor(context, call.status).withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(1),
            ),
          ),
          // Icon
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: _getStatusColor(context, call.status).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: _getStatusIcon(context, call.status),
            ),
          ),
          const SizedBox(width: 12),
          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  call.displayName,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                if (call.description != null)
                  Text(
                    call.description!,
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                if (call.duration != null)
                  Text(
                    '${call.duration!.inMilliseconds}ms',
                    style: TextStyle(
                      fontSize: 11,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),
          // Status badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: _getStatusColor(context, call.status).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              _getStatusText(call.status),
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: _getStatusColor(context, call.status),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(BuildContext context, ToolStatus status) {
    switch (status) {
      case ToolStatus.pending:
        return Theme.of(context).colorScheme.outline;
      case ToolStatus.running:
        return Theme.of(context).colorScheme.primary;
      case ToolStatus.completed:
        return Colors.green.shade600;
      case ToolStatus.error:
        return Theme.of(context).colorScheme.error;
    }
  }

  Widget _getStatusIcon(BuildContext context, ToolStatus status) {
    switch (status) {
      case ToolStatus.pending:
        return Icon(Icons.hourglass_empty, size: 14, color: _getStatusColor(context, status));
      case ToolStatus.running:
        return SizedBox(
          width: 12,
          height: 12,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation(_getStatusColor(context, status)),
          ),
        );
      case ToolStatus.completed:
        return Icon(Icons.check, size: 14, color: _getStatusColor(context, status));
      case ToolStatus.error:
        return Icon(Icons.error_outline, size: 14, color: _getStatusColor(context, status));
    }
  }

  String _getStatusText(ToolStatus status) {
    switch (status) {
      case ToolStatus.pending:
        return 'Pending';
      case ToolStatus.running:
        return 'Running';
      case ToolStatus.completed:
        return 'Done';
      case ToolStatus.error:
        return 'Error';
    }
  }
}

