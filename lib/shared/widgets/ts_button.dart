import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radii.dart';
import '../../core/theme/app_typography.dart';

enum TsButtonVariant { primary, secondary, danger, outline, text }

/// Botón estándar oficial de Tale Star con soporte para variantes, iconos y estado de carga.
class TsButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final TsButtonVariant variant;
  final bool isLoading;
  final IconData? icon;
  final double? width;
  final double height;

  const TsButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = TsButtonVariant.primary,
    this.isLoading = false,
    this.icon,
    this.width,
    this.height = 48.0,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final effectiveOnPressed = isLoading ? null : onPressed;

    Widget childContent;
    if (isLoading) {
      childContent = SizedBox(
        height: 20,
        width: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2.2,
          valueColor: AlwaysStoppedAnimation<Color>(_getLoadingColor()),
        ),
      );
    } else if (icon != null) {
      childContent = Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 18),
          const SizedBox(width: 8),
          Text(label, style: AppTypography.button()),
        ],
      );
    } else {
      childContent = Text(label, style: AppTypography.button());
    }

    Widget button;
    switch (variant) {
      case TsButtonVariant.primary:
        button = ElevatedButton(
          onPressed: effectiveOnPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary900,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: const RoundedRectangleBorder(borderRadius: AppRadii.sm),
          ),
          child: childContent,
        );
        break;

      case TsButtonVariant.secondary:
        button = ElevatedButton(
          onPressed: effectiveOnPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: isDark ? AppColors.surface2Dark : AppColors.surface2Light,
            foregroundColor: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
            elevation: 0,
            shape: const RoundedRectangleBorder(borderRadius: AppRadii.sm),
          ),
          child: childContent,
        );
        break;

      case TsButtonVariant.danger:
        button = ElevatedButton(
          onPressed: effectiveOnPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.danger,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: const RoundedRectangleBorder(borderRadius: AppRadii.sm),
          ),
          child: childContent,
        );
        break;

      case TsButtonVariant.outline:
        button = OutlinedButton(
          onPressed: effectiveOnPressed,
          style: OutlinedButton.styleFrom(
            foregroundColor: isDark ? AppColors.primary300 : AppColors.primary900,
            side: BorderSide(
              color: isDark ? AppColors.primary500 : AppColors.primary900,
              width: 1.5,
            ),
            shape: const RoundedRectangleBorder(borderRadius: AppRadii.sm),
          ),
          child: childContent,
        );
        break;

      case TsButtonVariant.text:
        button = TextButton(
          onPressed: effectiveOnPressed,
          style: TextButton.styleFrom(
            foregroundColor: isDark ? AppColors.primary300 : AppColors.primary900,
            shape: const RoundedRectangleBorder(borderRadius: AppRadii.sm),
          ),
          child: childContent,
        );
        break;
    }

    if (width != null) {
      return SizedBox(width: width, height: height, child: button);
    }

    return SizedBox(height: height, width: double.infinity, child: button);
  }

  Color _getLoadingColor() {
    switch (variant) {
      case TsButtonVariant.primary:
      case TsButtonVariant.danger:
        return Colors.white;
      case TsButtonVariant.secondary:
      case TsButtonVariant.outline:
      case TsButtonVariant.text:
        return AppColors.primary900;
    }
  }
}
