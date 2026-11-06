import 'package:flutter/material.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';

/// Indicador visual enmascarado de 4 dígitos para ingreso de PIN parental.
class PinDotsIndicator extends StatelessWidget {
  final int length;
  final int totalDigits;
  final bool hasError;

  const PinDotsIndicator({
    super.key,
    required this.length,
    this.totalDigits = AppConstants.pinLength,
    this.hasError = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(totalDigits, (index) {
        final isFilled = index < length;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          margin: const EdgeInsets.symmetric(horizontal: 10),
          width: isFilled ? 18 : 14,
          height: isFilled ? 18 : 14,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: hasError
                ? AppColors.danger
                : isFilled
                    ? AppColors.primary700
                    : Colors.transparent,
            border: Border.all(
              color: hasError
                  ? AppColors.danger
                  : isFilled
                      ? AppColors.primary700
                      : (Theme.of(context).brightness == Brightness.dark
                          ? AppColors.surface3Dark
                          : AppColors.surface3Light),
              width: 2,
            ),
            boxShadow: isFilled
                ? [
                    BoxShadow(
                      color: (hasError ? AppColors.danger : AppColors.primary700)
                          .withValues(alpha: 0.35),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
        );
      }),
    );
  }
}
