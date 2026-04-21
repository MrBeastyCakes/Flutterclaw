import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/chat_provider.dart';
import '../models/connection_state.dart' as model;

class ConnectionStatusBar extends StatelessWidget {
  const ConnectionStatusBar({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Consumer<ChatProvider>(
      builder: (context, provider, child) {
        final info = provider.connectionInfo;
        
        if (info.state == model.ConnectionState.connected) {
          return const SizedBox.shrink();
        }

        final colors = _themeColors(info.state, cs);

        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          color: colors.background,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: SafeArea(
            top: false,
            child: Row(
              children: [
                colors.icon,
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _statusText(info),
                    style: TextStyle(
                      color: colors.text,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                if (info.state == model.ConnectionState.error ||
                    info.state == model.ConnectionState.disconnected)
                  TextButton(
                    onPressed: () => provider.reconnect(),
                    style: TextButton.styleFrom(
                      foregroundColor: colors.text,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text('RECONNECT'),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  _StatusColors _themeColors(model.ConnectionState state, ColorScheme cs) {
    switch (state) {
      case model.ConnectionState.connecting:
      case model.ConnectionState.reconnecting:
        return _StatusColors(
          background: cs.primaryContainer.withValues(alpha: 0.7),
          text: cs.onPrimaryContainer,
          icon: SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation(cs.onPrimaryContainer),
            ),
          ),
        );
      case model.ConnectionState.error:
      case model.ConnectionState.disconnected:
        return _StatusColors(
          background: cs.errorContainer.withValues(alpha: 0.7),
          text: cs.onErrorContainer,
          icon: Icon(
            Icons.error_outline,
            size: 18,
            color: cs.onErrorContainer,
          ),
        );
      case model.ConnectionState.connected:
        return _StatusColors(
          background: Colors.transparent,
          text: Colors.transparent,
          icon: const SizedBox.shrink(),
        );
    }
  }

  String _statusText(model.ConnectionInfo info) {
    switch (info.state) {
      case model.ConnectionState.connecting:
        return 'Connecting to OpenClaw...';
      case model.ConnectionState.reconnecting:
        return 'Reconnecting (attempt ${info.reconnectAttempts})...';
      case model.ConnectionState.error:
        return info.errorMessage ?? 'Connection error';
      case model.ConnectionState.disconnected:
        return 'Disconnected from OpenClaw';
      case model.ConnectionState.connected:
        return '';
    }
  }
}

class _StatusColors {
  final Color background;
  final Color text;
  final Widget icon;

  const _StatusColors({
    required this.background,
    required this.text,
    required this.icon,
  });
}
