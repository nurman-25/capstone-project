import 'package:flutter/material.dart';

import '../core/app_colors.dart';

/// A flat green button with simple press animation and loading state.
class GradientButton extends StatefulWidget {
  const GradientButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.loading = false,
    this.height = 54,
    this.gradient,
    this.borderRadius = 14.0,
    this.fullWidth = true,
    this.fontSize = 14,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool loading;
  final double height;
  final Gradient? gradient;
  final double borderRadius;
  final bool fullWidth;
  final double fontSize;

  @override
  State<GradientButton> createState() => _GradientButtonState();
}

class _GradientButtonState extends State<GradientButton> {
  bool _pressed = false;

  bool get _enabled => widget.onPressed != null && !widget.loading;

  @override
  Widget build(BuildContext context) {
    final gradient = widget.gradient ?? AppColors.primaryGradient;
    final disabledGradient = LinearGradient(
      colors: [AppColors.surfaceBright, AppColors.surfaceLight],
    );

    return GestureDetector(
      onTapDown: _enabled ? (_) => setState(() => _pressed = true) : null,
      onTapUp: _enabled
          ? (_) {
              setState(() => _pressed = false);
              widget.onPressed?.call();
            }
          : null,
      onTapCancel: _enabled ? () => setState(() => _pressed = false) : null,
      child: AnimatedScale(
        scale: _pressed ? 0.98 : 1.0,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOutCubic,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          height: widget.height,
          width: widget.fullWidth ? double.infinity : null,
          decoration: BoxDecoration(
            gradient: _enabled ? gradient : disabledGradient,
            borderRadius: BorderRadius.circular(widget.borderRadius),
            boxShadow: _enabled
                ? [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(_pressed ? 0.08 : 0.18),
                      blurRadius: _pressed ? 6 : 10,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          padding: EdgeInsets.symmetric(horizontal: widget.icon != null ? 20 : 28),
          child: Center(
            child: widget.loading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: AppColors.textOnPrimary,
                    ),
                  )
                : Row(
                    mainAxisSize: widget.fullWidth ? MainAxisSize.max : MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (widget.icon != null) ...[
                        Icon(
                          widget.icon,
                          size: 20,
                          color: _enabled ? AppColors.textOnPrimary : AppColors.textMuted,
                        ),
                        const SizedBox(width: 10),
                      ],
                      Text(
                        widget.label,
                        style: TextStyle(
                          fontSize: widget.fontSize,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.2,
                          color: _enabled ? AppColors.textOnPrimary : AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
