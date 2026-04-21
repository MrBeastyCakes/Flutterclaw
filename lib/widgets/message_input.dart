import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/chat_provider.dart';

class MessageInput extends StatefulWidget {
  const MessageInput({super.key});

  @override
  State<MessageInput> createState() => _MessageInputState();
}

class _MessageInputState extends State<MessageInput>
    with SingleTickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _hasText = false;
  late AnimationController _sendAnim;
  late Animation<double> _sendScale;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onTextChanged);
    _sendAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
      reverseDuration: const Duration(milliseconds: 100),
    );
    _sendScale = Tween<double>(begin: 0.8, end: 1).animate(
      CurvedAnimation(parent: _sendAnim, curve: Curves.easeOutBack),
    );
  }

  void _onTextChanged() {
    final hasText = _controller.text.trim().isNotEmpty;
    if (hasText != _hasText) {
      setState(() {
        _hasText = hasText;
      });
      if (hasText) {
        _sendAnim.forward();
      } else {
        _sendAnim.reverse();
      }
    }
  }

  void _sendMessage() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    context.read<ChatProvider>().sendMessage(text);
    _controller.clear();
    _focusNode.requestFocus();
    _sendAnim.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return SafeArea(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: cs.surface,
          border: Border(
            top: BorderSide(color: cs.outlineVariant.withOpacity(0.5)),
          ),
          boxShadow: [
            BoxShadow(
              color: cs.shadow.withOpacity(0.03),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Attachment button with micro-interaction
            _IconButtonScale(
              icon: Icons.add_circle_outline,
              onTap: () {
                // TODO: Show attachment options
              },
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _controller,
                focusNode: _focusNode,
                decoration: InputDecoration(
                  hintText: 'Type a message...',
                  filled: true,
                  fillColor: cs.surfaceContainerHighest,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 14,
                  ),
                ),
                textCapitalization: TextCapitalization.sentences,
                keyboardType: TextInputType.multiline,
                maxLines: null,
                onSubmitted: (_) => _sendMessage(),
                style: TextStyle(color: cs.onSurface),
              ),
            ),
            const SizedBox(width: 8),
            // Send / Mic button with animated transition
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              transitionBuilder: (child, animation) {
                return ScaleTransition(
                  scale: animation,
                  child: FadeTransition(
                    opacity: animation,
                    child: child,
                  ),
                );
              },
              child: _hasText
                  ? ScaleTransition(
                      scale: _sendScale,
                      child: IconButton.filled(
                        key: const ValueKey('send'),
                        onPressed: _sendMessage,
                        icon: const Icon(Icons.send),
                        style: IconButton.styleFrom(
                          backgroundColor: cs.primary,
                          foregroundColor: cs.onPrimary,
                        ),
                      ),
                    )
                  : _IconButtonScale(
                      key: const ValueKey('mic'),
                      icon: Icons.mic_none,
                      onTap: () {
                        // TODO: Voice input
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    _sendAnim.dispose();
    super.dispose();
  }
}

class _IconButtonScale extends StatefulWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _IconButtonScale({required this.icon, required this.onTap});

  @override
  State<_IconButtonScale> createState() => _IconButtonScaleState();
}

class _IconButtonScaleState extends State<_IconButtonScale>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) {
        _ctrl.reverse();
        widget.onTap();
      },
      onTapCancel: () => _ctrl.reverse(),
      child: ScaleTransition(
        scale: Tween<double>(begin: 1, end: 0.85).animate(_ctrl),
        child: IconButton(
          icon: Icon(widget.icon),
          onPressed: () {}, // handled by GestureDetector
        ),
      ),
    );
  }
}
