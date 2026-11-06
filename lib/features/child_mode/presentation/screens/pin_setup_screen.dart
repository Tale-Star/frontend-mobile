import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radii.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../injection.dart';
import '../../../../shared/widgets/ts_app_bar.dart';
import '../../../../shared/widgets/ts_button.dart';
import '../../../../shared/widgets/ts_pin_field.dart';
import '../../../../shared/widgets/ts_snackbar.dart';
import '../../../../shared/widgets/ts_text_field.dart';
import '../../../authentication/presentation/cubit/auth_cubit.dart';
import '../../../authentication/presentation/cubit/auth_state.dart';
import '../../domain/repositories/parental_pin_repository.dart';

/// Pantalla oficial de configuración y cambio de PIN parental (US78).
class PinSetupScreen extends StatefulWidget {
  final ParentalPinRepository? repository;

  const PinSetupScreen({
    super.key,
    this.repository,
  });

  @override
  State<PinSetupScreen> createState() => _PinSetupScreenState();
}

class _PinSetupScreenState extends State<PinSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();

  String _newPin = '';
  String _confirmPin = '';

  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  ParentalPinRepository get _repository => widget.repository ?? sl<ParentalPinRepository>();

  Future<void> _submit() async {
    setState(() {
      _errorMessage = null;
    });

    final password = _passwordController.text.trim();
    if (password.isEmpty) {
      setState(() {
        _errorMessage = 'Por favor ingresa la contraseña actual de tu cuenta.';
      });
      return;
    }

    if (_newPin.length != AppConstants.pinLength) {
      setState(() {
        _errorMessage = 'El PIN debe contener exactamente 4 dígitos.';
      });
      return;
    }

    if (_confirmPin.length != AppConstants.pinLength) {
      setState(() {
        _errorMessage = 'Por favor confirma el PIN de 4 dígitos.';
      });
      return;
    }

    if (_newPin != _confirmPin) {
      setState(() {
        _errorMessage = 'Los números del PIN no coinciden. Verifícalos con calma.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final updatedUser = await _repository.setParentalPin(
        currentPassword: password,
        pin: _newPin,
      );

      if (mounted) {
        // Actualiza el estado reactivo del usuario en AuthCubit
        context.read<AuthCubit>().updateUserPinConfigured(updatedUser.pinConfigured);
        TsSnackBar.showSuccess(
          context,
          '¡PIN parental guardado con éxito! Ahora puedes activar el Modo Niño.',
        );
        Navigator.of(context).pop(true);
      }
    } on Failure catch (f) {
      if (mounted) {
        setState(() {
          _errorMessage = f.message;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _errorMessage = 'No fue posible guardar el PIN. Por favor intenta de nuevo.';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthCubit>().state;
    final isAlreadyConfigured = authState is Authenticated && authState.user.pinConfigured;
    final isDark = context.isDarkMode;

    return Scaffold(
      backgroundColor: context.scaffoldBg,
      appBar: TsAppBar(
        title: isAlreadyConfigured ? 'Modificar PIN Parental' : 'Configurar PIN Parental',
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Cabecera explicativa
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: context.surfaceColor,
                    borderRadius: AppRadii.md,
                    border: Border.all(color: context.surface3Color),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.02),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppColors.primary900.withValues(alpha: 0.3)
                              : AppColors.primary100,
                          borderRadius: AppRadii.sm,
                        ),
                        child: const Icon(
                          Icons.security_rounded,
                          color: AppColors.primary700,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isAlreadyConfigured
                                  ? 'Actualiza tu clave de salida'
                                  : 'Protección para los pequeños',
                              style: AppTypography.titleSmall(color: context.textPrimaryColor),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'El PIN de 4 dígitos asegura que solo un adulto pueda salir del Modo Niño y volver a la administración.',
                              style: AppTypography.bodySmall(
                                color: context.textSecondaryColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppSpacing.lg),

                // Mensaje de error si ocurre alguno
                if (_errorMessage != null) ...[
                  Container(
                    key: const Key('pin_setup_error_banner'),
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: AppColors.danger.withValues(alpha: 0.1),
                      borderRadius: AppRadii.sm,
                      border: Border.all(color: AppColors.danger.withValues(alpha: 0.4)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline, color: AppColors.danger, size: 20),
                        const SizedBox(width: AppSpacing.xs),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: AppTypography.bodySmall(color: AppColors.danger),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],

                // Campo: Contraseña actual
                TsTextField(
                  key: const Key('pin_setup_password_field'),
                  controller: _passwordController,
                  label: 'Contraseña actual de tu cuenta',
                  hint: 'Ingresa tu contraseña para confirmar tu identidad',
                  isPassword: true,
                  prefixIcon: const Icon(Icons.lock_outline_rounded),
                  enabled: !_isLoading,
                ),

                const SizedBox(height: AppSpacing.lg),

                // Campo: Nuevo PIN
                Text(
                  'Nuevo PIN de 4 dígitos',
                  style: AppTypography.titleSmall(color: context.textPrimaryColor),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Elige 4 números fáciles de recordar para ti.',
                  style: AppTypography.bodySmall(color: context.textSecondaryColor),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.sm),
                TsPinField(
                  key: const Key('pin_setup_new_pin_field'),
                  enabled: !_isLoading,
                  onChanged: (val) {
                    setState(() {
                      _newPin = val;
                    });
                  },
                  onCompleted: (val) {
                    setState(() {
                      _newPin = val;
                    });
                  },
                ),

                const SizedBox(height: AppSpacing.lg),

                // Campo: Confirmar PIN
                Text(
                  'Confirma el nuevo PIN',
                  style: AppTypography.titleSmall(color: context.textPrimaryColor),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Ingresa nuevamente los 4 números.',
                  style: AppTypography.bodySmall(color: context.textSecondaryColor),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.sm),
                TsPinField(
                  key: const Key('pin_setup_confirm_pin_field'),
                  enabled: !_isLoading,
                  onChanged: (val) {
                    setState(() {
                      _confirmPin = val;
                    });
                  },
                  onCompleted: (val) {
                    setState(() {
                      _confirmPin = val;
                    });
                  },
                ),

                const SizedBox(height: AppSpacing.xl),

                // Botón Guardar
                TsButton(
                  key: const Key('pin_setup_submit_button'),
                  label: _isLoading ? 'Guardando PIN...' : 'Guardar PIN Parental',
                  isLoading: _isLoading,
                  icon: Icons.check_circle_outline_rounded,
                  onPressed: _isLoading ? null : _submit,
                ),

                const SizedBox(height: AppSpacing.sm),

                // Botón Cancelar
                TextButton(
                  key: const Key('pin_setup_cancel_button'),
                  onPressed: _isLoading ? null : () => Navigator.of(context).pop(false),
                  child: Text(
                    'Cancelar',
                    style: AppTypography.button(color: AppColors.textSecondaryLight),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
