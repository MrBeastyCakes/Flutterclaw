import 'dart:async';
import 'package:flutter/material.dart';

class StreamingText extends StatefulWidget {
  final String text;
  final TextStyle? style;
  final Duration chunkDuration;
  final int charsPerChunk;

  const StreamingText({
    super.key,
    required this.text,
    this.style,
    this.chunkDuration = const Duration(milliseconds: 16),
    this.charsPerChunk = 2,
  });

  @override
  State<StreamingText> createState() => _StreamingTextState();
}

class _StreamingTextState extends State<StreamingText> {
  String _displayedText = '';
  int _currentIndex = 0;
  bool _isComplete = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startStreaming();
  }

  @override
  void didUpdateWidget(covariant StreamingText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.text != oldWidget.text) {
      _timer?.cancel();
      _currentIndex = 0;
      _displayedText = '';
      _isComplete = false;
      _startStreaming();
    }
  }

  void _startStreaming() {
    _timer?.cancel();
    void tick() {
      if (!mounted) return;
      final endIndex = (_currentIndex + widget.charsPerChunk).clamp(
        0,
        widget.text.length,
      );
      setState(() {
        _displayedText = widget.text.substring(0, endIndex);
        _currentIndex = endIndex;
      });
      if (_currentIndex < widget.text.length) {
        _timer = Timer(widget.chunkDuration, tick);
      } else {
        setState(() => _isComplete = true);
      }
    }
    tick();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: _displayedText,
            style: widget.style,
          ),
          if (!_isComplete)
            WidgetSpan(
              child: _Cursor(
                color: widget.style?.color ?? Theme.of(context).colorScheme.onSurface,
              ),
            ),
        ],
      ),
    );
  }
}

class _Cursor extends StatefulWidget {
  final Color color;

  const _Cursor({required this.color});

  @override
  State<_Cursor> createState() => _CursorState();
}

class _CursorState extends State<_Cursor> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 530),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Opacity(
          opacity: _controller.value,
          child: Container(
            width: 2,
            height: 18,
            color: widget.color,
          ),
        );
      },
    );
  }
}

