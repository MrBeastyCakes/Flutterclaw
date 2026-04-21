import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/message.dart';
import '../providers/chat_provider.dart';
import 'message_bubble.dart';
import 'typing_indicator.dart';
import '../utils/animations.dart';

class MessageList extends StatefulWidget {
  final List<ChatMessage> messages;
  final bool isTyping;

  const MessageList({
    super.key,
    required this.messages,
    this.isTyping = false,
  });

  @override
  State<MessageList> createState() => _MessageListState();
}

class _MessageListState extends State<MessageList> {
  final ScrollController _scrollController = ScrollController();
  final Map<String, bool> _seenIds = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  @override
  void didUpdateWidget(covariant MessageList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.messages.length > oldWidget.messages.length) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ChatProvider>();
    final displayMessages = provider.filteredMessages;

    if (displayMessages.isEmpty && provider.searchQuery.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.4),
            ),
            const SizedBox(height: 16),
            Text(
              'No messages match "${provider.searchQuery}"',
              style: TextStyle(
                fontSize: 16,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        // Simulate refresh — in production this would fetch history
        await Future.delayed(const Duration(milliseconds: 800));
      },
      displacement: 40,
      color: Theme.of(context).colorScheme.primary,
      backgroundColor: Theme.of(context).colorScheme.surface,
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: displayMessages.length + (widget.isTyping ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == displayMessages.length && widget.isTyping) {
            return const Align(
              alignment: Alignment.centerLeft,
              child: TypingIndicator(),
            );
          }

          final message = displayMessages[index];
          final showTimestamp = _shouldShowTimestamp(displayMessages, index);
          final isFirstInGroup = _isFirstInGroup(displayMessages, index);

          return MessageBubble(
            message: message,
            showTimestamp: showTimestamp,
            onRetry: () => _retryMessage(context, message),
            onDelete: () => _deleteMessage(context, message.id),
          );
        },
      ),
    );
  }

  bool _shouldShowTimestamp(List<ChatMessage> msgs, int index) {
    if (index == 0) return true;
    final current = msgs[index].timestamp;
    final previous = msgs[index - 1].timestamp;
    return current.difference(previous).inMinutes >= 5;
  }

  bool _isFirstInGroup(List<ChatMessage> msgs, int index) {
    if (index == 0) return true;
    return msgs[index].role != msgs[index - 1].role;
  }

  void _retryMessage(BuildContext context, ChatMessage message) {
    if (mounted) {
      context.read<ChatProvider>().retryMessage(message);
    }
  }

  void _deleteMessage(BuildContext context, String messageId) {
    if (mounted) {
      context.read<ChatProvider>().deleteMessage(messageId);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}
