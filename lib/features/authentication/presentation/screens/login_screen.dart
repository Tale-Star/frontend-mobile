import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/storage/preferences_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../injection.dart';
import '../../../../shared/utils/validators.dart';
import '../../../../shared/widgets/ts_button.dart';
import '../../../../shared/widgets/ts_snackbar.dart';
import '../../../../shared/widgets/ts_text_field.dart';
import '../cubit/auth_cubit.dart';
import '../cubit/auth_state.dart';

/// Pantalla oficial de inicio de sesión de Tale Star para padres y educadores.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _rememberMe = true;

  @override
  void initState() {
    super.initState();
    // Recupera la preferencia previa de recordar sesión si existe
    if (sl.isRegistered<PreferencesService>()) {
      _rememberMe = sl<PreferencesService>().rememberMe;
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _onLoginPressed() {
    if (_formKey.currentState?.validate() ?? false) {
      context.read<AuthCubit>().login(
            email: _emailController.text.trim(),
            password: _passwordController.text,
            rememberMe: _rememberMe,
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.scaffoldBg,
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
                  vertical: AppSpacing.xl,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Cabecera e identidad de marca Tale Star
                        Center(
                          child: Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              color: context.isDarkMode
                                  ? AppColors.primary900.withValues(alpha: 0.3)
                                  : AppColors.primary100,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.auto_stories_rounded,
                              size: 34,
                              color: AppColors.primary700,
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          'Tale Star',
                          style: AppTypography.displayLarge(color: context.textPrimaryColor),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          'Bienvenido a tu espacio de cuentos y lectura guiada',
                          style: AppTypography.bodyMedium(
                            color: context.textSecondaryColor,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: AppSpacing.xl),

                        // Campo de correo electrónico
                        TsTextField(
                          key: const Key('login_email_field'),
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
                          key: const Key('login_password_field'),
                          label: 'Contraseña',
                          hint: 'Ingresa tu contraseña',
                          controller: _passwordController,
                          isPassword: true,
                          textInputAction: TextInputAction.done,
                          prefixIcon: const Icon(
                            Icons.lock_outline,
                            size: 20,
                            color: AppColors.textTertiaryLight,
                          ),
                          validator: Validators.validatePassword,
                          enabled: !isLoading,
                          onFieldSubmitted: (_) => _onLoginPressed(),
                        ),
                        const SizedBox(height: AppSpacing.sm),

                        // Fila con "Recordarme" (US03) y "Olvidé mi contraseña" (US04)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Flexible(
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  SizedBox(
                                    height: 44,
                                    width: 44,
                                    child: Checkbox(
                                      key: const Key('login_remember_me_checkbox'),
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
                                  Flexible(
                                    child: GestureDetector(
                                      onTap: isLoading
                                          ? null
                                          : () {
                                              setState(() {
                                                _rememberMe = !_rememberMe;
                                              });
                                            },
                                      child: Text(
                                        'Recordarme',
                                        style: AppTypography.bodySmall(
                                          color: context.textPrimaryColor,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            TextButton(
                              key: const Key('login_forgot_password_button'),
                              onPressed: isLoading
                                  ? null
                                  : () => context.push(RouteNames.forgotPasswordPath),
                              child: Text(
                                '¿Olvidaste tu contraseña?',
                                style: AppTypography.bodySmall(
                                  color: AppColors.primary900,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.lg),

                        // Botón principal de inicio de sesión
                        TsButton(
                          key: const Key('login_submit_button'),
                          label: 'Iniciar Sesión',
                          isLoading: isLoading,
                          onPressed: _onLoginPressed,
                        ),
                        const SizedBox(height: AppSpacing.xl),

                        // Enlace hacia pantalla de registro
                        Wrap(
                          alignment: WrapAlignment.center,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text(
                              '¿Aún no tienes una cuenta? ',
                              style: AppTypography.bodyMedium(
                                color: context.textSecondaryColor,
                              ),
                            ),
                            GestureDetector(
                              key: const Key('login_go_to_register_button'),
                              onTap: isLoading
                                  ? null
                                  : () => context.push(RouteNames.registerPath),
                              child: Text(
                                'Regístrate aquí',
                                style: AppTypography.bodyMedium(
                                  color: context.isDarkMode ? AppColors.primary300 : AppColors.primary900,
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
