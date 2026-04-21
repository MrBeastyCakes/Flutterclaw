import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/chat_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        elevation: 0,
      ),
      body: ListView(
        children: [
          _SectionHeader(title: 'Connection'),
          _SettingTile(
            icon: Icons.dns,
            title: 'Server URL',
            subtitle: 'WebSocket endpoint for OpenClaw',
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showServerUrlDialog(context),
          ),
          _SettingTile(
            icon: Icons.badge,
            title: 'Chat ID',
            subtitle: 'Identifier for this chat session',
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showChatIdDialog(context),
          ),
          _SettingTile(
            icon: Icons.person,
            title: 'Display Name',
            subtitle: 'Your name in conversations',
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showNameDialog(context),
          ),
          const Divider(),
          _SectionHeader(title: 'Appearance'),
          _SettingTile(
            icon: Icons.dark_mode,
            title: 'Theme',
            subtitle: 'System default',
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // TODO: Theme selector
            },
          ),
          const Divider(),
          _SectionHeader(title: 'Data'),
          _SettingTile(
            icon: Icons.delete_forever,
            title: 'Clear All Messages',
            subtitle: 'Permanently delete chat history',
            iconColor: Theme.of(context).colorScheme.error,
            textColor: Theme.of(context).colorScheme.error,
            onTap: () => _showClearConfirmation(context),
          ),
        ],
      ),
    );
  }

  void _showServerUrlDialog(BuildContext context) {
    final controller = TextEditingController(
      text: 'ws://localhost:8765',
    );
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Server URL'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'ws://localhost:8765',
            labelText: 'WebSocket URL',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              context.read<ChatProvider>().setServerUrl(controller.text);
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showChatIdDialog(BuildContext context) {
    final controller = TextEditingController(text: 'flutter:main');
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Chat ID'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'flutter:main',
            labelText: 'Chat Identifier',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              context.read<ChatProvider>().setChatId(controller.text);
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showNameDialog(BuildContext context) {
    final controller = TextEditingController(text: 'Flutter User');
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Display Name'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Flutter User',
            labelText: 'Your Name',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              context.read<ChatProvider>().setSenderName(controller.text);
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showClearConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Messages?'),
        content: const Text(
          'This will permanently delete all messages. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              context.read<ChatProvider>().clearMessages();
              Navigator.pop(context);
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Theme.of(context).colorScheme.primary,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _SettingTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final Color? iconColor;
  final Color? textColor;

  const _SettingTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.trailing,
    this.onTap,
    this.iconColor,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: iconColor ?? Theme.of(context).colorScheme.onSurfaceVariant),
      title: Text(
        title,
        style: TextStyle(color: textColor),
      ),
      subtitle: Text(subtitle),
      trailing: trailing,
      onTap: onTap,
    );
  }
}
