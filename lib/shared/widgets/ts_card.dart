import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radii.dart';

/// Tarjeta base oficial de Tale Star con bordes redondeados y soporte interactivo.
class TsCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color? backgroundColor;
  final Color? borderColor;

  const TsCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16.0),
    this.onTap,
    this.backgroundColor,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final effectiveBg = backgroundColor ?? (isDark ? AppColors.surfaceDark : AppColors.surfaceLight);
    final effectiveBorder = borderColor ?? (isDark ? AppColors.surface3Dark : AppColors.surface3Light);

    return Material(
      color: effectiveBg,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadii.md,
        side: BorderSide(color: effectiveBorder, width: 1.0),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadii.md,
        child: Padding(
          padding: padding,
          child: child,
        ),
      ),
    );
  }
}
