import 'dart:ui';

import 'package:flutter/material.dart';

//可复用的液态玻璃效果
class GlassContainer extends StatelessWidget {
  final Widget child;
  final double blur;
  final double opacity;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Border? border;
  const GlassContainer({
    super.key,
    required this.child,
    this.blur = 25, //
    this.opacity = 0.08,
    this.borderRadius = 35,
    this.padding,
    this.margin,
    this.border,
    required Color color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 20, offset: Offset(0, 8))],
      ),
      child: RepaintBoundary(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(borderRadius),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
            child: Container(
              padding: padding,
              decoration: BoxDecoration(
                // 液态玻璃核心：半透明白 + 细微边框
                color: Colors.white70.withValues(alpha: 1),
                borderRadius: BorderRadius.circular(borderRadius),
                border: border ?? Border.all(color: Colors.white.withValues(alpha: 0.4), width: 1.5),
              ),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}
