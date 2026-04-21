import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/message.dart';
import '../providers/chat_provider.dart';
import '../utils/clipboard.dart';

/// Bottom sheet shown on long-press of a message bubble.
class MessageActionsSheet extends StatelessWidget {
  final ChatMessage message;

  const MessageActionsSheet({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == MessageRole.user;
    final isError = message.status == MessageStatus.error;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            _ActionTile(
              icon: Icons.copy,
              label: 'Copy text',
              onTap: () {
                Navigator.pop(context);
                copyToClipboard(context, message.content);
              },
            ),
            if (isUser)
              _ActionTile(
                icon: Icons.refresh,
                label: 'Retry',
                onTap: () {
                  Navigator.pop(context);
                  context.read<ChatProvider>().retryMessage(message);
                },
              ),
            if (isError && isUser)
              _ActionTile(
                icon: Icons.error_outline,
                label: 'View error',
                onTap: () {
                  Navigator.pop(context);
                  _showErrorDialog(context);
                },
              ),
            _ActionTile(
              icon: Icons.share_outlined,
              label: 'Share',
              onTap: () {
                Navigator.pop(context);
                // Share via platform share sheet (could use share_plus)
                showAppSnackBar(context, 'Share: coming soon');
              },
            ),
            const Divider(height: 32),
            _ActionTile(
              icon: Icons.delete_outline,
              label: 'Delete',
              color: Theme.of(context).colorScheme.error,
              onTap: () {
                Navigator.pop(context);
                context.read<ChatProvider>().deleteMessage(message.id);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showErrorDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Message Error'),
        content: Text(message.metadata?['error']?.toString() ?? 'Unknown error'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  const _ActionTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: color ?? Theme.of(context).colorScheme.onSurface),
      title: Text(
        label,
        style: TextStyle(
          color: color ?? Theme.of(context).colorScheme.onSurface,
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: onTap,
      dense: true,
      minLeadingWidth: 24,
      contentPadding: const EdgeInsets.symmetric(horizontal: 24),
    );
  }
}
