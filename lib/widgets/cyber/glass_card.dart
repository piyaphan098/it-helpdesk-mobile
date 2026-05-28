import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final BorderRadius? borderRadius;
  final bool highlight;
  final double? width;
  final double? height;
  final VoidCallback? onTap;

  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.borderRadius,
    this.highlight = true,
    this.width,
    this.height,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final br = borderRadius ?? BorderRadius.circular(16);

    Widget card = Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer.withOpacity(0.7),
        borderRadius: br,
        border: Border(
          top: BorderSide(
            color: highlight
                ? Colors.white.withOpacity(0.15)
                : Colors.white.withOpacity(0.1),
            width: 1,
          ),
          left: BorderSide(
            color: highlight
                ? Colors.white.withOpacity(0.15)
                : Colors.white.withOpacity(0.1),
            width: 1,
          ),
          right: BorderSide(color: Colors.white.withOpacity(0.1), width: 1),
          bottom: BorderSide(color: Colors.white.withOpacity(0.1), width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF22D3EE).withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: br,
        child:
            padding != null ? Padding(padding: padding!, child: child) : child,
      ),
    );

    if (onTap != null) {
      return GestureDetector(onTap: onTap, child: card);
    }
    return card;
  }
}

class CyanGlow extends StatelessWidget {
  final Widget child;
  const CyanGlow({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2fd9f4).withOpacity(0.4),
            blurRadius: 15,
            spreadRadius: 0,
          ),
        ],
      ),
      child: child,
    );
  }
}


