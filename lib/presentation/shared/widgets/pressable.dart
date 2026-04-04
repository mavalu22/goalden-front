import 'package:flutter/material.dart';

/// A wrapper that adds hover (desktop) and press (all platforms) visual feedback
/// to any child widget.
///
/// - [hoverColor]: background color shown on hover. Null = no hover background.
/// - [borderRadius]: applied to the hover background clip.
/// - [scaleFactor]: how far to scale down on press (default 0.96).
/// - [onTap]: tapped callback; also sets `SystemMouseCursors.click` when non-null.
class Pressable extends StatefulWidget {
  const Pressable({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.hoverColor,
    this.borderRadius = BorderRadius.zero,
    this.scaleFactor = 0.96,
    this.behavior = HitTestBehavior.opaque,
  });

  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final Color? hoverColor;
  final BorderRadius borderRadius;
  final double scaleFactor;
  final HitTestBehavior behavior;

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _hovered = false;
  bool _pressed = false;

  void _onEnter(PointerEvent _) => setState(() => _hovered = true);
  void _onExit(PointerEvent _) => setState(() => _hovered = false);
  void _onTapDown(TapDownDetails _) => setState(() => _pressed = true);
  void _onTapUp(TapUpDetails _) => setState(() => _pressed = false);
  void _onTapCancel() => setState(() => _pressed = false);

  @override
  Widget build(BuildContext context) {
    final canInteract = widget.onTap != null || widget.onLongPress != null;

    Widget child = widget.child;

    // Hover background
    if (widget.hoverColor != null) {
      child = AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: (_hovered && !_pressed) ? widget.hoverColor : Colors.transparent,
          borderRadius: widget.borderRadius,
        ),
        child: child,
      );
    }

    // Press scale
    child = AnimatedScale(
      scale: _pressed ? widget.scaleFactor : 1.0,
      duration: const Duration(milliseconds: 100),
      curve: Curves.easeOut,
      child: child,
    );

    return MouseRegion(
      cursor: canInteract ? SystemMouseCursors.click : MouseCursor.defer,
      onEnter: _onEnter,
      onExit: _onExit,
      child: GestureDetector(
        onTap: widget.onTap,
        onLongPress: widget.onLongPress,
        onTapDown: _onTapDown,
        onTapUp: _onTapUp,
        onTapCancel: _onTapCancel,
        behavior: widget.behavior,
        child: child,
      ),
    );
  }
}
