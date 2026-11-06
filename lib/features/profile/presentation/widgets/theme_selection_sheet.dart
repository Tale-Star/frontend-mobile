import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radii.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/theme_cubit.dart';

/// Modal inferior para seleccionar y persistir el tema visual de Tale Star (Fase 7).
class ThemeSelectionSheet extends StatelessWidget {
  const ThemeSelectionSheet({super.key});

  /// Abre la hoja de selección modal.
  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider.value(
        value: context.read<ThemeCubit>(),
        child: const ThemeSelectionSheet(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    final currentTheme = context.watch<ThemeCubit>().state;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(
          top: BorderSide(
            color: isDark ? AppColors.surface3Dark : AppColors.surface3Light,
          ),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.xl,
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Indicador de arrastre superior
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: AppSpacing.md),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.surface3Dark : AppColors.surface3Light,
                  borderRadius: AppRadii.pill,
                ),
              ),
            ),

            // Título
            Row(
              children: [
                const Icon(
                  Icons.palette_outlined,
                  color: AppColors.primary700,
                  size: 26,
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  'Apariencia y Tema',
                  style: AppTypography.titleMedium(
                    color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Personaliza los tonos visuales de Tale Star para mayor comodidad de lectura.',
              style: AppTypography.bodySmall(
                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
              ),
            ),

            const SizedBox(height: AppSpacing.lg),

            // Opción: Claro
            _buildThemeOption(
              context: context,
              mode: AppThemeMode.light,
              title: 'Tema Claro',
              subtitle: 'Superficies luminosas de alta legibilidad para el día.',
              icon: Icons.light_mode_rounded,
              isSelected: currentTheme == AppThemeMode.light,
              isDark: isDark,
            ),

            const SizedBox(height: AppSpacing.sm),

            // Opción: Oscuro
            _buildThemeOption(
              context: context,
              mode: AppThemeMode.dark,
              title: 'Tema Oscuro',
              subtitle: 'Colores nocturnos para descansar la vista antes de dormir.',
              icon: Icons.dark_mode_rounded,
              isSelected: currentTheme == AppThemeMode.dark,
              isDark: isDark,
            ),

            const SizedBox(height: AppSpacing.sm),

            // Opción: Sistema
            _buildThemeOption(
              context: context,
              mode: AppThemeMode.system,
              title: 'Automático (Sistema)',
              subtitle: 'Se sincroniza automáticamente con el modo de tu teléfono.',
              icon: Icons.brightness_auto_rounded,
              isSelected: currentTheme == AppThemeMode.system,
              isDark: isDark,
            ),

            const SizedBox(height: AppSpacing.md),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeOption({
    required BuildContext context,
    required AppThemeMode mode,
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isSelected,
    required bool isDark,
  }) {
    final borderColor = isSelected
        ? AppColors.primary700
        : (isDark ? AppColors.surface3Dark : AppColors.surface3Light);
    final cardBg = isSelected
        ? (isDark ? AppColors.primary900.withValues(alpha: 0.15) : AppColors.primary100.withValues(alpha: 0.35))
        : (isDark ? AppColors.surface2Dark : AppColors.surface2Light);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: Key('theme_option_${mode.name}'),
        onTap: () {
          context.read<ThemeCubit>().setThemeMode(mode);
          Navigator.of(context).pop();
        },
        borderRadius: AppRadii.md,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.md,
          ),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: AppRadii.md,
            border: Border.all(
              color: borderColor,
              width: isSelected ? 1.6 : 1.0,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primary700
                      : (isDark ? AppColors.surface3Dark : AppColors.surfaceLight),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 20,
                  color: isSelected
                      ? Colors.white
                      : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTypography.button(
                        color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: AppTypography.bodySmall(
                        color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                      ),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                const Icon(
                  Icons.check_circle_rounded,
                  color: AppColors.primary700,
                  size: 22,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

