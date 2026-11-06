import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radii.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_typography.dart';

/// Campo de texto oficial de Tale Star con soporte para validación y visibilidad de contraseña.
class TsTextField extends StatefulWidget {
  final String label;
  final String? hint;
  final TextEditingController? controller;
  final String? Function(String?)? validator;
  final bool isPassword;
  final TextInputType keyboardType;
  final TextInputAction textInputAction;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onFieldSubmitted;
  final bool enabled;
  final int maxLines;
  final FocusNode? focusNode;

  const TsTextField({
    super.key,
    required this.label,
    this.hint,
    this.controller,
    this.validator,
    this.isPassword = false,
    this.keyboardType = TextInputType.text,
    this.textInputAction = TextInputAction.next,
    this.prefixIcon,
    this.suffixIcon,
    this.onChanged,
    this.onFieldSubmitted,
    this.enabled = true,
    this.maxLines = 1,
    this.focusNode,
  });

  @override
  State<TsTextField> createState() => _TsTextFieldState();
}

class _TsTextFieldState extends State<TsTextField> {
  bool _obscureText = true;

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    final labelColor = widget.enabled
        ? (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight)
        : (isDark ? AppColors.textTertiaryDark : AppColors.textTertiaryLight);
    final inputStyle = AppTypography.bodyMedium(
      color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
    );
    final fillColor = widget.enabled
        ? (isDark ? AppColors.surface2Dark : AppColors.surface2Light)
        : (isDark ? AppColors.surface3Dark : AppColors.surface3Light);
    final borderColor = isDark ? AppColors.surface3Dark : AppColors.surface3Light;
    final iconColor = isDark ? AppColors.textTertiaryDark : AppColors.textTertiaryLight;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: AppTypography.label(color: labelColor),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: widget.controller,
          validator: widget.validator,
          obscureText: widget.isPassword && _obscureText,
          keyboardType: widget.keyboardType,
          textInputAction: widget.textInputAction,
          onChanged: widget.onChanged,
          onFieldSubmitted: widget.onFieldSubmitted,
          enabled: widget.enabled,
          maxLines: widget.isPassword ? 1 : widget.maxLines,
          focusNode: widget.focusNode,
          style: inputStyle,
          decoration: InputDecoration(
            hintText: widget.hint,
            hintStyle: AppTypography.bodyMedium(color: iconColor),
            prefixIcon: widget.prefixIcon,
            suffixIcon: widget.isPassword
                ? IconButton(
                    icon: Icon(
                      _obscureText ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                      color: iconColor,
                      size: 20,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscureText = !_obscureText;
                      });
                    },
                  )
                : widget.suffixIcon,
            filled: true,
            fillColor: fillColor,
            border: OutlineInputBorder(
              borderRadius: AppRadii.sm,
              borderSide: BorderSide(color: borderColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: AppRadii.sm,
              borderSide: BorderSide(color: borderColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: AppRadii.sm,
              borderSide: BorderSide(
                color: isDark ? AppColors.primary500 : AppColors.primary900,
                width: 1.5,
              ),
            ),
            errorBorder: const OutlineInputBorder(
              borderRadius: AppRadii.sm,
              borderSide: BorderSide(color: AppColors.danger),
            ),
            focusedErrorBorder: const OutlineInputBorder(
              borderRadius: AppRadii.sm,
              borderSide: BorderSide(color: AppColors.danger, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}
