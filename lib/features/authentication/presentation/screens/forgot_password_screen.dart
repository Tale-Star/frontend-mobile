import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radii.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/utils/validators.dart';
import '../../../../shared/widgets/ts_button.dart';
import '../../../../shared/widgets/ts_snackbar.dart';
import '../../../../shared/widgets/ts_text_field.dart';
import '../cubit/auth_cubit.dart';
import '../cubit/auth_state.dart';

/// Pantalla asistida de recuperación de contraseña (US04 - Simulación en cliente).
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _onSubmit() {
    if (_formKey.currentState?.validate() ?? false) {
      context.read<AuthCubit>().requestPasswordReset(
            email: _emailController.text.trim(),
          );
    }
  }

  void _showConfirmationDialog(String email) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        shape: const RoundedRectangleBorder(borderRadius: AppRadii.md),
        title: Row(
          children: [
            const Icon(Icons.mark_email_read_outlined, color: AppColors.success, size: 28),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Solicitud Enviada',
                style: AppTypography.titleLarge(),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hemos registrado tu solicitud para el correo:',
              style: AppTypography.bodyMedium(),
            ),
            const SizedBox(height: 4),
            Text(
              email,
              style: AppTypography.bodyMedium(color: AppColors.primary900)
                  .copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppSpacing.md),
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: const BoxDecoration(
                color: AppColors.surface2Light,
                borderRadius: AppRadii.sm,
              ),
              child: Text(
                'Nota de prueba MVP: El servicio de correo está simulado en cliente. Tu cuenta permanece protegida.',
                style: AppTypography.caption(color: AppColors.textSecondaryLight),
              ),
            ),
          ],
        ),
        actions: [
          TsButton(
            key: const Key('forgot_password_dialog_back_button'),
            label: 'Volver a Iniciar Sesión',
            onPressed: () {
              Navigator.of(dialogContext).pop();
              context.go(RouteNames.loginPath);
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgLight,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.textPrimaryLight, size: 20),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: BlocConsumer<AuthCubit, AuthState>(
          listener: (context, state) {
            if (state is AuthError) {
              TsSnackBar.showError(context, state.message);
            } else if (state is PasswordResetSent) {
              _showConfirmationDialog(state.email);
            }
          },
          builder: (context, state) {
            final isLoading = state is AuthLoading;

            return Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.xl,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Center(
                          child: Container(
                            width: 64,
                            height: 64,
                            decoration: const BoxDecoration(
                              color: AppColors.primary100,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.lock_reset_rounded,
                              size: 34,
                              color: AppColors.primary900,
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          'Recuperar Contraseña',
                          style: AppTypography.displayLarge(),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          'Ingresa tu correo para recibir instrucciones de recuperación',
                          style: AppTypography.bodyMedium(
                            color: AppColors.textSecondaryLight,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: AppSpacing.xl),

                        TsTextField(
                          key: const Key('forgot_password_email_field'),
                          label: 'Correo electrónico',
                          hint: 'ejemplo@correo.com',
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.done,
                          prefixIcon: const Icon(
                            Icons.mail_outline,
                            size: 20,
                            color: AppColors.textTertiaryLight,
                          ),
                          validator: Validators.validateEmail,
                          enabled: !isLoading,
                          onFieldSubmitted: (_) => _onSubmit(),
                        ),
                        const SizedBox(height: AppSpacing.lg),

                        TsButton(
                          key: const Key('forgot_password_submit_button'),
                          label: 'Enviar Instrucciones',
                          isLoading: isLoading,
                          onPressed: _onSubmit,
                        ),
                        const SizedBox(height: AppSpacing.lg),

                        TextButton(
                          key: const Key('forgot_password_back_button'),
                          onPressed: isLoading ? null : () => context.pop(),
                          child: Text(
                            'Regresar al inicio de sesión',
                            style: AppTypography.bodyMedium(
                              color: AppColors.primary900,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
