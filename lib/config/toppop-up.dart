// 顶部液态玻璃提示（无关闭按钮，2 秒后自动消失）
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

class ToastUtil {
  ToastUtil._();

  static const double _barHeight = 70;
  static const Duration _visibleDuration = Duration(seconds: 2);
  static const Duration _animDuration = Duration(milliseconds: 280);

  /// 错误提示（红色调液态玻璃）
  static void showRedError(BuildContext context, String title, String message) {
    _show(context, title: title, message: message, isError: true);
  }

  /// 成功提示（绿色调液态玻璃）
  static void showGreenSuccess(BuildContext context, String title, String message) {
    _show(context, title: title, message: message, isError: false);
  }

  static void _show(BuildContext context, {required String title, required String message, required bool isError}) {
    final overlay = Overlay.maybeOf(context);
    if (overlay == null) return;

    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (ctx) => _GlassTopToast(
        title: title,
        message: message,
        isError: isError,
        barHeight: _barHeight,
        visibleDuration: _visibleDuration,
        animDuration: _animDuration,
        onRemove: () {
          entry.remove();
        },
      ),
    );
    overlay.insert(entry);
  }
}

class _GlassTopToast extends StatefulWidget {
  const _GlassTopToast({required this.title, required this.message, required this.isError, required this.barHeight, required this.visibleDuration, required this.animDuration, required this.onRemove});

  final String title;
  final String message;
  final bool isError;
  final double barHeight;
  final Duration visibleDuration;
  final Duration animDuration;
  final VoidCallback onRemove;

  @override
  State<_GlassTopToast> createState() => _GlassTopToastState();
}

class _GlassTopToastState extends State<_GlassTopToast> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Offset> _slide;
  Timer? _dismissTimer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.animDuration);
    _slide = Tween<Offset>(begin: const Offset(0, -1), end: Offset.zero).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic, reverseCurve: Curves.easeInCubic));
    _controller.forward();
    _dismissTimer = Timer(widget.visibleDuration, () async {
      if (!mounted) return;
      await _controller.reverse();
      if (mounted) widget.onRemove();
    });
  }

  @override
  void dispose() {
    _dismissTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top + 8;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titleColor = isDark ? Colors.white : const Color(0xFF1A1A1A);
    final subtitleColor = isDark ? Colors.white70 : Colors.black.withValues(alpha: 0.65);
    final accent = widget.isError ? const Color(0xFFE53935) : const Color(0xFF43A047);
    final settings = LiquidGlassSettings(blur: 14, thickness: 22, glassColor: accent.withValues(alpha: 0.14));

    return Positioned(
      top: top,
      left: 16,
      right: 16,
      height: widget.barHeight,
      child: SlideTransition(
        position: _slide,
        child: Material(
          type: MaterialType.transparency,
          child: GlassCard(
            width: double.infinity,
            height: widget.barHeight,
            useOwnLayer: true,
            quality: GlassQuality.standard,
            settings: settings,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            clipBehavior: Clip.antiAlias,
            child: Row(
              children: [
                Icon(widget.isError ? Icons.error_outline_rounded : Icons.check_circle_outline_rounded, color: accent, size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: titleColor),
                      ),
                      if (widget.message.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          widget.message,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 12, color: subtitleColor),
                        ),
                      ],
                    ],
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
