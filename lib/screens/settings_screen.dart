import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/chat_provider.dart';
import '../models/connection_state.dart' as model;

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
            icon: Icons.edit,
            title: 'Server URL',
            subtitle: 'WebSocket endpoint for OpenClaw',
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Consumer<ChatProvider>(
                  builder: (context, provider, child) {
                    return Text(
                      provider.connectionInfo.serverUrl ?? 'ws://192.168.92.79:18789',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontSize: 12,
                      ),
                    );
                  },
                ),
                const SizedBox(width: 8),
                const Icon(Icons.chevron_right, size: 20),
              ],
            ),
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
          _SectionHeader(title: 'Connection Control'),
          Consumer<ChatProvider>(
            builder: (context, provider, child) {
              final isConnected = provider.connectionInfo.state == model.ConnectionState.connected;
              final isConnecting = provider.connectionInfo.state == model.ConnectionState.connecting ||
                  provider.connectionInfo.state == model.ConnectionState.reconnecting;
              
              return Column(
                children: [
                  _SettingTile(
                    icon: isConnected ? Icons.cloud_done : Icons.cloud_off,
                    title: isConnected ? 'Connected' : isConnecting ? 'Connecting...' : 'Disconnected',
                    subtitle: provider.connectionInfo.serverUrl ?? 'Not configured',
                    iconColor: isConnected 
                        ? Theme.of(context).colorScheme.primary 
                        : isConnecting 
                            ? Theme.of(context).colorScheme.secondary 
                            : Theme.of(context).colorScheme.error,
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isConnecting)
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Theme.of(context).colorScheme.secondary,
                            ),
                          )
                        else
                          IconButton(
                            onPressed: () => isConnected 
                                ? provider.disconnect() 
                                : provider.reconnect(),
                            icon: Icon(isConnected ? Icons.stop : Icons.play_arrow),
                            color: isConnected 
                                ? Theme.of(context).colorScheme.error 
                                : Theme.of(context).colorScheme.primary,
                          ),
                        const SizedBox(width: 8),
                        IconButton(
                          onPressed: () => provider.reconnect(),
                          icon: const Icon(Icons.refresh),
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ],
                    ),
                  ),
                  if (provider.connectionInfo.errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Text(
                        provider.connectionInfo.errorMessage!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                          fontSize: 12,
                        ),
                      ),
                    ),
                ],
              );
            },
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
    final provider = context.read<ChatProvider>();
    final controller = TextEditingController(
      text: provider.connectionInfo.serverUrl ?? 'ws://192.168.92.79:18789',
    );
    String? errorText;
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Server URL'),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.url,
            decoration: InputDecoration(
              hintText: 'ws://192.168.92.79:18789',
              labelText: 'WebSocket URL',
              errorText: errorText,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final url = controller.text.trim();
                if (!url.startsWith('ws://') && !url.startsWith('wss://')) {
                  setState(() => errorText = 'Must start with ws:// or wss://');
                  return;
                }
                provider.setServerUrl(url);
                Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
          ],
        ),
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
