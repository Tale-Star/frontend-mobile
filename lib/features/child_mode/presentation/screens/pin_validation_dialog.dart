import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radii.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_typography.dart';
import '../cubit/child_mode_cubit.dart';
import '../cubit/child_mode_state.dart';
import '../widgets/pin_dots_indicator.dart';
import '../widgets/pin_keypad.dart';

/// Modal oficial accesible de validación de PIN parental para autorizar la salida de Modo Niño (US84).
class PinValidationDialog extends StatefulWidget {
  final ChildModeCubit cubit;

  const PinValidationDialog({
    super.key,
    required this.cubit,
  });

  /// Muestra el diálogo modal de validación de PIN parental.
  static Future<bool> show(BuildContext context, {required ChildModeCubit cubit}) async {
    cubit.requestExit();
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => PinValidationDialog(cubit: cubit),
    );
    if (result != true) {
      cubit.cancelExit();
    }
    return result ?? false;
  }

  @override
  State<PinValidationDialog> createState() => _PinValidationDialogState();
}

class _PinValidationDialogState extends State<PinValidationDialog> {
  String _pin = '';

  void _onDigitPressed(String digit) {
    if (_pin.length >= AppConstants.pinLength) return;
    setState(() {
      _pin += digit;
    });

    if (_pin.length == AppConstants.pinLength) {
      _submitPin();
    }
  }

  void _onBackspacePressed() {
    if (_pin.isNotEmpty) {
      setState(() {
        _pin = _pin.substring(0, _pin.length - 1);
      });
    }
  }

  void _onClearPressed() {
    setState(() {
      _pin = '';
    });
  }

  Future<void> _submitPin() async {
    final entered = _pin;
    final success = await widget.cubit.validatePinAndExit(entered);
    if (!mounted) return;

    if (success) {
      Navigator.of(context).pop(true);
    } else {
      setState(() {
        _pin = '';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ChildModeCubit, ChildModeState>(
      bloc: widget.cubit,
      listener: (context, state) {
        if (state is ChildModeInactive) {
          if (Navigator.of(context).canPop()) {
            Navigator.of(context).pop(true);
          }
        }
      },
      builder: (context, state) {
        final isValidating = state is ChildModeUnlocking && state.isValidating;
        final isLockedOut = state is ChildModeValidationError && state.isLockedOut;
        final hasError = state is ChildModeValidationError;
        final errorMessage = hasError ? state.errorMessage : null;

        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, result) {
            if (!didPop) {
              widget.cubit.cancelExit();
              Navigator.of(context).pop(false);
            }
          },
          child: Dialog(
            backgroundColor: context.surfaceColor,
            shape: const RoundedRectangleBorder(borderRadius: AppRadii.lg),
            insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 360),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Icono y Cabecera
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const SizedBox(width: 40),
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: context.isDarkMode
                                ? AppColors.primary900.withValues(alpha: 0.3)
                                : AppColors.primary100,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.lock_rounded,
                            color: AppColors.primary700,
                            size: 26,
                          ),
                        ),
                        // Botón cerrar modal -> cancela salida
                        IconButton(
                          key: const Key('pin_validation_cancel_button'),
                          icon: const Icon(Icons.close_rounded),
                          color: context.textSecondaryColor,
                          onPressed: () {
                            widget.cubit.cancelExit();
                            Navigator.of(context).pop(false);
                          },
                        ),
                      ],
                    ),

                    const SizedBox(height: AppSpacing.sm),

                    Text(
                      'PIN Parental',
                      style: AppTypography.titleLarge(color: context.textPrimaryColor),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Ingresa el PIN de 4 dígitos para salir de Modo Niño.',
                      style: AppTypography.bodySmall(color: context.textSecondaryColor),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: AppSpacing.md),

                    // Mensaje de error / intentos restantes
                    if (errorMessage != null) ...[
                      Container(
                        key: const Key('pin_validation_error_banner'),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        margin: const EdgeInsets.only(bottom: AppSpacing.md),
                        decoration: BoxDecoration(
                          color: AppColors.danger.withValues(alpha: 0.12),
                          borderRadius: AppRadii.sm,
                          border: Border.all(color: AppColors.danger.withValues(alpha: 0.3)),
                        ),
                        child: Text(
                          errorMessage,
                          style: AppTypography.caption(color: AppColors.danger),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],

                    // Indicador de Puntos
                    PinDotsIndicator(
                      length: _pin.length,
                      hasError: hasError,
                    ),

                    const SizedBox(height: AppSpacing.md),

                    // Indicador de validación o Teclado
                    if (isValidating) ...[
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 40),
                        child: Column(
                          children: [
                            CircularProgressIndicator(color: AppColors.primary700),
                            SizedBox(height: 16),
                            Text(
                              'Verificando PIN parental...',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                color: AppColors.textSecondaryLight,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ] else ...[
                      PinKeypad(
                        enabled: !isLockedOut,
                        onDigitPressed: _onDigitPressed,
                        onBackspacePressed: _onBackspacePressed,
                        onClearPressed: _onClearPressed,
                      ),
                    ],

                    const SizedBox(height: AppSpacing.sm),

                    // Botón para volver al contenido protegido
                    TextButton(
                      key: const Key('pin_validation_back_to_child_mode'),
                      onPressed: () {
                        widget.cubit.cancelExit();
                        Navigator.of(context).pop(false);
                      },
                      child: Text(
                        'Continuar en Modo Niño',
                        style: AppTypography.button(color: AppColors.primary700),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
