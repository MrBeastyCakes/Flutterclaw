import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/message.dart';
import '../providers/chat_provider.dart';
import 'message_bubble.dart';
import 'typing_indicator.dart';
import 'package:provider/provider.dart';

class MessageList extends StatefulWidget {
  final List<ChatMessage> messages;

  const MessageList({
    super.key,
    required this.messages,
  });

  @override
  State<MessageList> createState() => _MessageListState();
}

class _MessageListState extends State<MessageList> {
  final ScrollController _scrollController = ScrollController();

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
    final isTyping = context.watch<ChatProvider>().isTyping;
    
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: widget.messages.length + (isTyping ? 1 : 0),
      itemBuilder: (context, index) {
        if (isTyping && index == widget.messages.length) {
          return const TypingIndicator();
        }
        
        final message = widget.messages[index];
        final showTimestamp = _shouldShowTimestamp(index);
        
        return MessageBubble(
          message: message,
          showTimestamp: showTimestamp,
          onRetry: () => _retryMessage(context, message),
          onDelete: () => _deleteMessage(context, index),
        );
      },
    );
  }

  bool _shouldShowTimestamp(int index) {
    if (index == 0) return true;
    
    final current = widget.messages[index].timestamp;
    final previous = widget.messages[index - 1].timestamp;
    
    return current.difference(previous).inMinutes >= 5;
  }

  void _retryMessage(BuildContext context, ChatMessage message) {
    context.read<ChatProvider>().sendMessage(message.content);
  }

  void _deleteMessage(BuildContext context, int index) {
    final message = widget.messages[index];
    context.read<ChatProvider>().removeMessage(message.id);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}
