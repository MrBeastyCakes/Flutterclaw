import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/chat_provider.dart';
import '../models/connection_state.dart';

class ConnectionStatusBar extends StatelessWidget {
  const ConnectionStatusBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ChatProvider>(
      builder: (context, provider, child) {
        final info = provider.connectionInfo;
        
        if (info.state == ConnectionState.connected) {
          return const SizedBox.shrink();
        }

        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          color: _getBackgroundColor(info.state),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: SafeArea(
            top: false,
            child: Row(
              children: [
                _getIcon(info.state),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _getMessage(info),
                    style: TextStyle(
                      color: _getTextColor(info.state),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                if (info.state == ConnectionState.error ||
                    info.state == ConnectionState.disconnected)
                  TextButton(
                    onPressed: () => provider.reconnect(),
                    style: TextButton.styleFrom(
                      foregroundColor: _getTextColor(info.state),
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

  Color _getBackgroundColor(ConnectionState state) {
    switch (state) {
      case ConnectionState.connecting:
      case ConnectionState.reconnecting:
        return Colors.orange.shade100;
      case ConnectionState.error:
      case ConnectionState.disconnected:
        return Colors.red.shade100;
      case ConnectionState.connected:
        return Colors.transparent;
    }
  }

  Color _getTextColor(ConnectionState state) {
    switch (state) {
      case ConnectionState.connecting:
      case ConnectionState.reconnecting:
        return Colors.orange.shade900;
      case ConnectionState.error:
      case ConnectionState.disconnected:
        return Colors.red.shade900;
      case ConnectionState.connected:
        return Colors.transparent;
    }
  }

  Widget _getIcon(ConnectionState state) {
    switch (state) {
      case ConnectionState.connecting:
      case ConnectionState.reconnecting:
        return SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation(Colors.orange.shade900),
          ),
        );
      case ConnectionState.error:
      case ConnectionState.disconnected:
        return Icon(Icons.error_outline, size: 18, color: Colors.red.shade900);
      case ConnectionState.connected:
        return const SizedBox.shrink();
    }
  }

  String _getMessage(ConnectionInfo info) {
    switch (info.state) {
      case ConnectionState.connecting:
        return 'Connecting to OpenClaw...';
      case ConnectionState.reconnecting:
        return 'Reconnecting (attempt ${info.reconnectAttempts})...';
      case ConnectionState.error:
        return info.errorMessage ?? 'Connection error';
      case ConnectionState.disconnected:
        return 'Disconnected from OpenClaw';
      case ConnectionState.connected:
        return '';
    }
  }
}
