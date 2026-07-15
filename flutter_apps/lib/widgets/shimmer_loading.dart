import 'package:flutter/material.dart';

import '../core/app_colors.dart';

/// A shimmer loading skeleton widget for premium loading states.
/// Displays an animated gradient sweep effect over placeholder shapes.
class ShimmerLoading extends StatefulWidget {
  const ShimmerLoading({
    super.key,
    this.width = double.infinity,
    this.height = 80,
    this.borderRadius = 16.0,
    this.count = 3,
    this.spacing = 12.0,
  });

  final double width;
  final double height;
  final double borderRadius;
  final int count;
  final double spacing;

  @override
  State<ShimmerLoading> createState() => _ShimmerLoadingState();
}

class _ShimmerLoadingState extends State<ShimmerLoading>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(widget.count, (i) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: i < widget.count - 1 ? widget.spacing : 0,
          ),
          child: AnimatedBuilder(
            animation: _ctrl,
            builder: (_, __) {
              return Container(
                width: widget.width,
                height: widget.height,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(widget.borderRadius),
                  gradient: LinearGradient(
                    begin: Alignment(-1.0 + 2.0 * _ctrl.value, 0),
                    end: Alignment(1.0 + 2.0 * _ctrl.value, 0),
                    colors: const [
                      AppColors.surfaceLight,
                      AppColors.surfaceBright,
                      AppColors.surfaceLight,
                    ],
                    stops: const [0.0, 0.5, 1.0],
                  ),
                ),
              );
            },
          ),
        );
      }),
    );
  }
}
