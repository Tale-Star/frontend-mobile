import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_typography.dart';

/// Teclado numérico accesible diseñado para ingreso rápido y seguro de PIN parental.
class PinKeypad extends StatelessWidget {
  final ValueChanged<String> onDigitPressed;
  final VoidCallback onBackspacePressed;
  final VoidCallback? onClearPressed;
  final bool enabled;

  const PinKeypad({
    super.key,
    required this.onDigitPressed,
    required this.onBackspacePressed,
    this.onClearPressed,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildRow(context, ['1', '2', '3']),
        const SizedBox(height: 8),
        _buildRow(context, ['4', '5', '6']),
        const SizedBox(height: 8),
        _buildRow(context, ['7', '8', '9']),
        const SizedBox(height: 8),
        _buildBottomRow(context),
      ],
    );
  }

  Widget _buildRow(BuildContext context, List<String> digits) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: digits.map((d) => _buildDigitButton(context, d)).toList(),
    );
  }

  Widget _buildDigitButton(BuildContext context, String digit) {
    final isDark = context.isDarkMode;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Semantics(
        button: true,
        label: 'Dígito $digit',
        enabled: enabled,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            key: Key('pin_keypad_$digit'),
            borderRadius: BorderRadius.circular(30),
            onTap: enabled ? () => onDigitPressed(digit) : null,
            child: Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isDark ? AppColors.surface2Dark : AppColors.surfaceLight,
                border: Border.all(
                  color: isDark ? AppColors.surface3Dark : AppColors.surface3Light,
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  digit,
                  style: AppTypography.titleMedium(
                    color: enabled
                        ? (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight)
                        : (isDark ? AppColors.textTertiaryDark : AppColors.textTertiaryLight),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomRow(BuildContext context) {
    final isDark = context.isDarkMode;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Botón Limpiar (C)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: SizedBox(
            width: 58,
            height: 58,
            child: onClearPressed != null
                ? Semantics(
                    button: true,
                    label: 'Limpiar código PIN',
                    enabled: enabled,
                    child: InkWell(
                      key: const Key('pin_keypad_clear'),
                      borderRadius: BorderRadius.circular(30),
                      onTap: enabled ? onClearPressed : null,
                      child: Center(
                        child: Text(
                          'C',
                          style: AppTypography.titleSmall(
                            color: enabled
                                ? (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight)
                                : (isDark ? AppColors.textTertiaryDark : AppColors.textTertiaryLight),
                          ),
                        ),
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ),

        // Dígito 0
        _buildDigitButton(context, '0'),

        // Botón Borrar (Backspace)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Semantics(
            button: true,
            label: 'Borrar último dígito',
            enabled: enabled,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                key: const Key('pin_keypad_backspace'),
                borderRadius: BorderRadius.circular(30),
                onTap: enabled ? onBackspacePressed : null,
                child: SizedBox(
                  width: 58,
                  height: 58,
                  child: Center(
                    child: Icon(
                      Icons.backspace_outlined,
                      size: 22,
                      color: enabled
                          ? (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight)
                          : (isDark ? AppColors.textTertiaryDark : AppColors.textTertiaryLight),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
