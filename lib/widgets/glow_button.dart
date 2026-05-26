import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class GlowButton extends StatefulWidget {
  const GlowButton({
    required this.onPressed,
    this.icon,
    this.label,
    this.size = 56,
    this.circular = false,
    this.enabled = true,
    super.key,
  }) : assert(icon != null || label != null);

  final VoidCallback? onPressed;
  final IconData? icon;
  final String? label;
  final double size;
  final bool circular;
  final bool enabled;

  @override
  State<GlowButton> createState() => _GlowButtonState();
}

class _GlowButtonState extends State<GlowButton> {
  bool _pressed = false;

  bool get _enabled => widget.enabled && widget.onPressed != null;

  @override
  Widget build(BuildContext context) {
    final glowAlpha = _pressed ? 0.72 : 0.42;
    final blur = _pressed ? 36.0 : 24.0;

    return GestureDetector(
      onTapDown: _enabled ? (_) => setState(() => _pressed = true) : null,
      onTapCancel: _enabled ? () => setState(() => _pressed = false) : null,
      onTapUp: _enabled
          ? (_) {
              setState(() => _pressed = false);
              widget.onPressed?.call();
            }
          : null,
      child: AnimatedScale(
        scale: _pressed ? 0.96 : 1,
        duration: const Duration(milliseconds: 110),
        curve: Curves.easeOutCubic,
        child: AnimatedOpacity(
          opacity: _enabled ? 1 : 0.48,
          duration: const Duration(milliseconds: 160),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            height: widget.circular ? widget.size : null,
            width: widget.circular ? widget.size : null,
            padding: widget.circular
                ? EdgeInsets.zero
                : const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
            decoration: BoxDecoration(
              color: neonPink,
              shape: widget.circular ? BoxShape.circle : BoxShape.rectangle,
              borderRadius: widget.circular ? null : BorderRadius.circular(22),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.72),
                width: widget.circular ? 6 : 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: neonPink.withValues(alpha: glowAlpha),
                  blurRadius: blur,
                  spreadRadius: _pressed ? 4 : 1,
                ),
                BoxShadow(
                  color: softPink.withValues(alpha: 0.24),
                  blurRadius: 48,
                  offset: const Offset(0, 18),
                ),
              ],
            ),
            child: Center(
              child: widget.label == null
                  ? Icon(
                      widget.icon,
                      color: Colors.white,
                      size: widget.size * 0.36,
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (widget.icon != null) ...[
                          Icon(widget.icon, color: Colors.white, size: 20),
                          const SizedBox(width: 10),
                        ],
                        Flexible(
                          child: Text(
                            widget.label!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.labelLarge
                                ?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                ),
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
