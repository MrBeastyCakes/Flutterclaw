import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

enum ThinkingState {
  thinking,
  completed,
  collapsed,
}

class ThinkingBubble extends StatefulWidget {
  final String? thinking;
  final ThinkingState state;
  final VoidCallback? onToggle;

  const ThinkingBubble({
    super.key,
    this.thinking,
    this.state = ThinkingState.thinking,
    this.onToggle,
  });

  @override
  State<ThinkingBubble> createState() => _ThinkingBubbleState();
}

class _ThinkingBubbleState extends State<ThinkingBubble>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isThinking = widget.state == ThinkingState.thinking;
    
    return GestureDetector(
      onTap: () {
        if (!isThinking && widget.thinking != null) {
          setState(() => _isExpanded = !_isExpanded);
          if (_isExpanded) {
            _animationController.forward();
          } else {
            _animationController.reverse();
          }
          widget.onToggle?.call();
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        margin: const EdgeInsets.only(left: 16, right: 64, bottom: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isThinking
                ? Theme.of(context).colorScheme.primary.withOpacity(0.3)
                : Theme.of(context).colorScheme.outlineVariant.withOpacity(0.3),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isThinking)
                  SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation(
                        Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  )
                else
                  Icon(
                    Icons.psychology,
                    size: 16,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                const SizedBox(width: 8),
                Text(
                  isThinking ? 'Thinking...' : 'Reasoning',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(width: 8),
                if (!isThinking && widget.thinking != null)
                  AnimatedBuilder(
                    animation: _animationController,
                    builder: (context, child) {
                      return Transform.rotate(
                        angle: _animationController.value * 3.14159,
                        child: Icon(
                          Icons.keyboard_arrow_down,
                          size: 18,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      );
                    },
                  ),
              ],
            ),
            if (_isExpanded && widget.thinking != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: MarkdownBody(
                  data: widget.thinking!,
                  styleSheet: MarkdownStyleSheet(
                    p: TextStyle(
                      fontSize: 13,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      height: 1.5,
                    ),
                    code: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
