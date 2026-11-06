import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/utils/validators.dart';
import '../../../../shared/widgets/ts_button.dart';
import '../../../../shared/widgets/ts_snackbar.dart';
import '../../../../shared/widgets/ts_text_field.dart';
import '../cubit/auth_cubit.dart';
import '../cubit/auth_state.dart';

/// Pantalla oficial de registro para tutores y docentes en Tale Star.
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _displayNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _pinController = TextEditingController();
  bool _rememberMe = true;
  bool _showPinField = false;

  @override
  void dispose() {
    _displayNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _pinController.dispose();
    super.dispose();
  }

  void _onRegisterPressed() {
    if (_formKey.currentState?.validate() ?? false) {
      final pin = _showPinField && _pinController.text.trim().isNotEmpty
          ? _pinController.text.trim()
          : null;

      context.read<AuthCubit>().register(
            email: _emailController.text.trim(),
            displayName: _displayNameController.text.trim(),
            password: _passwordController.text,
            parentalPin: pin,
            rememberMe: _rememberMe,
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.scaffoldBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: context.textPrimaryColor, size: 20),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: BlocConsumer<AuthCubit, AuthState>(
          listener: (context, state) {
            if (state is AuthError) {
              TsSnackBar.showError(context, state.message);
            } else if (state is Authenticated) {
              context.go(RouteNames.libraryPath);
            }
          },
          builder: (context, state) {
            final isLoading = state is AuthLoading;

            return Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.md,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Crear tu cuenta',
                          style: AppTypography.displayLarge(),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          'Empieza a compartir cuentos y melodías con tus niños',
                          style: AppTypography.bodyMedium(
                            color: AppColors.textSecondaryLight,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: AppSpacing.xl),

                        // Campo de nombre visible
                        TsTextField(
                          key: const Key('register_display_name_field'),
                          label: 'Nombre o alias',
                          hint: 'Ej: Mamá Laura o Profe Carlos',
                          controller: _displayNameController,
                          textInputAction: TextInputAction.next,
                          prefixIcon: const Icon(
                            Icons.person_outline,
                            size: 20,
                            color: AppColors.textTertiaryLight,
                          ),
                          validator: Validators.validateDisplayName,
                          enabled: !isLoading,
                        ),
                        const SizedBox(height: AppSpacing.md),

                        // Campo de correo electrónico
                        TsTextField(
                          key: const Key('register_email_field'),
                          label: 'Correo electrónico',
                          hint: 'ejemplo@correo.com',
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          prefixIcon: const Icon(
                            Icons.mail_outline,
                            size: 20,
                            color: AppColors.textTertiaryLight,
                          ),
                          validator: Validators.validateEmail,
                          enabled: !isLoading,
                        ),
                        const SizedBox(height: AppSpacing.md),

                        // Campo de contraseña
                        TsTextField(
                          key: const Key('register_password_field'),
                          label: 'Contraseña',
                          hint: 'Mínimo 6 caracteres',
                          controller: _passwordController,
                          isPassword: true,
                          textInputAction: TextInputAction.next,
                          prefixIcon: const Icon(
                            Icons.lock_outline,
                            size: 20,
                            color: AppColors.textTertiaryLight,
                          ),
                          validator: Validators.validatePassword,
                          enabled: !isLoading,
                        ),
                        const SizedBox(height: AppSpacing.md),

                        // Confirmación de contraseña
                        TsTextField(
                          key: const Key('register_confirm_password_field'),
                          label: 'Confirmar contraseña',
                          hint: 'Repite tu contraseña',
                          controller: _confirmPasswordController,
                          isPassword: true,
                          textInputAction: _showPinField ? TextInputAction.next : TextInputAction.done,
                          prefixIcon: const Icon(
                            Icons.lock_outline,
                            size: 20,
                            color: AppColors.textTertiaryLight,
                          ),
                          validator: (val) => Validators.validateConfirmPassword(
                            _passwordController.text,
                            val,
                          ),
                          enabled: !isLoading,
                          onFieldSubmitted: _showPinField ? null : (_) => _onRegisterPressed(),
                        ),
                        const SizedBox(height: AppSpacing.md),

                        // Configuración opcional de PIN parental
                        InkWell(
                          onTap: () {
                            setState(() {
                              _showPinField = !_showPinField;
                            });
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                            child: Row(
                              children: [
                                Icon(
                                  _showPinField
                                      ? Icons.keyboard_arrow_down
                                      : Icons.keyboard_arrow_right,
                                  color: AppColors.primary900,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Configurar PIN parental ahora (opcional)',
                                    style: AppTypography.bodySmall(
                                      color: AppColors.primary900,
                                    ).copyWith(fontWeight: FontWeight.w600),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        if (_showPinField) ...[
                          const SizedBox(height: AppSpacing.xs),
                          TsTextField(
                            key: const Key('register_pin_field'),
                            label: 'PIN parental (4 dígitos)',
                            hint: 'Ej: 1234',
                            controller: _pinController,
                            keyboardType: TextInputType.number,
                            textInputAction: TextInputAction.done,
                            prefixIcon: const Icon(
                              Icons.pin_outlined,
                              size: 20,
                              color: AppColors.textTertiaryLight,
                            ),
                            validator: (val) {
                              if (val != null && val.trim().isNotEmpty) {
                                return Validators.validatePin(val.trim());
                              }
                              return null;
                            },
                            enabled: !isLoading,
                            onFieldSubmitted: (_) => _onRegisterPressed(),
                          ),
                        ],
                        const SizedBox(height: AppSpacing.sm),

                        // Opción "Recordarme"
                        Row(
                          children: [
                            SizedBox(
                              height: 44,
                              width: 44,
                              child: Checkbox(
                                key: const Key('register_remember_me_checkbox'),
                                value: _rememberMe,
                                activeColor: AppColors.primary900,
                                onChanged: isLoading
                                    ? null
                                    : (val) {
                                        setState(() {
                                          _rememberMe = val ?? false;
                                        });
                                      },
                              ),
                            ),
                            Expanded(
                              child: GestureDetector(
                                onTap: isLoading
                                    ? null
                                    : () {
                                        setState(() {
                                          _rememberMe = !_rememberMe;
                                        });
                                      },
                                child: Text(
                                  'Recordar mi sesión en este dispositivo',
                                  style: AppTypography.bodySmall(
                                    color: AppColors.textPrimaryLight,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.lg),

                        // Botón de registro
                        TsButton(
                          key: const Key('register_submit_button'),
                          label: 'Crear Cuenta',
                          isLoading: isLoading,
                          onPressed: _onRegisterPressed,
                        ),
                        const SizedBox(height: AppSpacing.xl),

                        // Enlace hacia login
                        Wrap(
                          alignment: WrapAlignment.center,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text(
                              '¿Ya tienes una cuenta? ',
                              style: AppTypography.bodyMedium(
                                color: AppColors.textSecondaryLight,
                              ),
                            ),
                            GestureDetector(
                              key: const Key('register_go_to_login_button'),
                              onTap: isLoading ? null : () => context.pop(),
                              child: Text(
                                'Inicia sesión',
                                style: AppTypography.bodyMedium(
                                  color: AppColors.primary900,
                                ).copyWith(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
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
