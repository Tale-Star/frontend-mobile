import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radii.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/ts_button.dart';

/// Diálogo informativo y constructivo para dispositivos no certificados por Google ARCore.
class ArUnsupportedDialog extends StatelessWidget {
  final String? deviceModel;
  final String? reasonMessage;
  final VoidCallback onDismiss;

  const ArUnsupportedDialog({
    super.key,
    this.deviceModel,
    this.reasonMessage,
    required this.onDismiss,
  });

  static Future<void> show(
    BuildContext context, {
    String? deviceModel,
    String? reasonMessage,
    VoidCallback? onDismiss,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => ArUnsupportedDialog(
        deviceModel: deviceModel,
        reasonMessage: reasonMessage,
        onDismiss: () {
          Navigator.of(ctx).pop();
          if (onDismiss != null) onDismiss();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AlertDialog(
      backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
      shape: const RoundedRectangleBorder(borderRadius: AppRadii.md),
      contentPadding: const EdgeInsets.all(AppSpacing.lg),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.warning.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.view_in_ar_rounded,
              color: AppColors.warning,
              size: 28,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              'Realidad Aumentada no disponible',
              style: AppTypography.titleMedium(
                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
              ),
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            reasonMessage ??
                'Tu dispositivo no cuenta con la certificación oficial de Google ARCore para rastreo de superficies tridimensionales.',
            style: AppTypography.bodyMedium(
              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surface2Dark : AppColors.surface2Light,
              borderRadius: AppRadii.sm,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.menu_book_rounded,
                  size: 20,
                  color: isDark ? AppColors.primary300 : AppColors.primary900,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '¡No te preocupes! Puedes disfrutar este cuento con la experiencia completa del lector tradicional 2D.',
                    style: AppTypography.bodySmall(
                      color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        TsButton(
          key: const Key('ar_unsupported_dismiss_button'),
          label: 'Continuar en Lector 2D',
          onPressed: onDismiss,
        ),
      ],
    );
  }
}

