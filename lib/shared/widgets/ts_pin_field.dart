import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radii.dart';
import '../../core/theme/app_typography.dart';

/// Campo visual para ingreso de PIN parental de 4 dígitos.
class TsPinField extends StatefulWidget {
  final ValueChanged<String> onCompleted;
  final ValueChanged<String>? onChanged;
  final bool hasError;
  final bool obscureText;
  final bool enabled;

  const TsPinField({
    super.key,
    required this.onCompleted,
    this.onChanged,
    this.hasError = false,
    this.obscureText = true,
    this.enabled = true,
  });

  @override
  State<TsPinField> createState() => _TsPinFieldState();
}

class _TsPinFieldState extends State<TsPinField> {
  late final List<TextEditingController> _controllers;
  late final List<FocusNode> _focusNodes;
  late final List<FocusNode> _keyboardFocusNodes;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(
      AppConstants.pinLength,
      (_) => TextEditingController(),
    );
    _focusNodes = List.generate(
      AppConstants.pinLength,
      (_) => FocusNode(),
    );
    _keyboardFocusNodes = List.generate(
      AppConstants.pinLength,
      (_) => FocusNode(),
    );
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    for (final k in _keyboardFocusNodes) {
      k.dispose();
    }
    super.dispose();
  }

  @override
  void didUpdateWidget(TsPinField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.hasError && !oldWidget.hasError) {
      _clear();
    }
  }

  void _clear() {
    for (final c in _controllers) {
      c.clear();
    }
    if (_focusNodes.isNotEmpty) {
      _focusNodes.first.requestFocus();
    }
  }

  String _currentPin() {
    return _controllers.map((c) => c.text).join();
  }

  void _onDigitChanged(int index, String value) {
    if (value.isNotEmpty) {
      if (index < AppConstants.pinLength - 1) {
        _focusNodes[index + 1].requestFocus();
      } else {
        _focusNodes[index].unfocus();
      }
    }
    final pin = _currentPin();
    widget.onChanged?.call(pin);
    if (pin.length == AppConstants.pinLength) {
      widget.onCompleted(pin);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final defaultBg = isDark ? AppColors.surface2Dark : AppColors.surfaceLight;
    final defaultBorder = isDark ? AppColors.surface3Dark : AppColors.surface3Light;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(AppConstants.pinLength, (index) {
        return Container(
          width: 56,
          height: 64,
          margin: const EdgeInsets.symmetric(horizontal: 6),
          child: KeyboardListener(
            focusNode: _keyboardFocusNodes[index],
            onKeyEvent: (event) {
              if (event is KeyDownEvent &&
                  event.logicalKey == LogicalKeyboardKey.backspace &&
                  _controllers[index].text.isEmpty &&
                  index > 0) {
                _focusNodes[index - 1].requestFocus();
              }
            },
            child: TextField(
              controller: _controllers[index],
              focusNode: _focusNodes[index],
              enabled: widget.enabled,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              obscureText: widget.obscureText,
              obscuringCharacter: '●',
              maxLength: 1,
              style: AppTypography.displayMedium(
                color: widget.hasError
                    ? AppColors.danger
                    : (isDark ? AppColors.primary300 : AppColors.primary900),
              ),
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(
                counterText: '',
                contentPadding: EdgeInsets.zero,
                filled: true,
                fillColor: widget.hasError
                    ? AppColors.danger.withValues(alpha: 0.08)
                    : defaultBg,
                border: OutlineInputBorder(
                  borderRadius: AppRadii.md,
                  borderSide: BorderSide(
                    color: widget.hasError ? AppColors.danger : defaultBorder,
                    width: 1.5,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: AppRadii.md,
                  borderSide: BorderSide(
                    color: widget.hasError ? AppColors.danger : defaultBorder,
                    width: 1.5,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: AppRadii.md,
                  borderSide: BorderSide(
                    color: widget.hasError ? AppColors.danger : AppColors.primary700,
                    width: 2.0,
                  ),
                ),
              ),
              onChanged: (value) => _onDigitChanged(index, value),
            ),
          ),
        );
      }),
    );
  }
}
