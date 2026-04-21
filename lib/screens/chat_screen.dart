import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/chat_provider.dart';
import '../widgets/message_list.dart';
import '../widgets/message_input.dart';
import '../widgets/connection_status_bar.dart';
import '../widgets/message_search_bar.dart';
import '../utils/animations.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  bool _searchOpen = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: AnimatedSwitcher(
          duration: AppAnimations.normal,
          child: _searchOpen
              ? MessageSearchBar(
                  key: const ValueKey('search'),
                  onClose: () => setState(() => _searchOpen = false),
                )
              : const Text('Flutterclaw', key: ValueKey('title')),
        ),
        centerTitle: !_searchOpen,
        elevation: 0,
        scrolledUnderElevation: 1,
        actions: _searchOpen
            ? null
            : [
                ScaleBounce(
                  child: IconButton(
                    icon: const Icon(Icons.search),
                    onPressed: () => setState(() => _searchOpen = true),
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'clear') {
                      context.read<ChatProvider>().clearMessages();
                    } else if (value == 'reconnect') {
                      context.read<ChatProvider>().reconnect();
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'clear',
                      child: Row(
                        children: [
                          Icon(Icons.clear_all),
                          SizedBox(width: 8),
                          Text('Clear chat'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'reconnect',
                      child: Row(
                        children: [
                          Icon(Icons.refresh),
                          SizedBox(width: 8),
                          Text('Reconnect'),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
      ),
      body: Column(
        children: [
          const ConnectionStatusBar(),
          Expanded(
            child: Consumer<ChatProvider>(
              builder: (context, provider, child) {
                if (provider.messages.isEmpty) {
                  return _buildEmptyState(context);
                }
                return MessageList(
                  messages: provider.messages,
                  isTyping: provider.isTyping,
                );
              },
            ),
          ),
          const MessageInput(),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedContainer(
            duration: AppAnimations.slow,
            curve: AppAnimations.bounce,
            child: Icon(
              Icons.chat_bubble_outline,
              size: 80,
              color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.3),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Start a conversation',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your OpenClaw assistant is ready',
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }
}
