import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radii.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/theme_cubit.dart';
import '../../../../injection.dart';
import '../../../../shared/widgets/ts_app_bar.dart';
import '../../../../shared/widgets/ts_button.dart';
import '../../../authentication/domain/entities/user_entity.dart';
import '../../../authentication/presentation/cubit/auth_cubit.dart';
import '../../../authentication/presentation/cubit/auth_state.dart';
import '../../../augmented_reality/presentation/cubit/ar_cubit.dart';
import '../../../child_mode/presentation/cubit/child_mode_cubit.dart';
import '../../../child_mode/presentation/screens/pin_setup_screen.dart';
import '../../../library/presentation/cubit/library_cubit.dart';
import '../../../music/presentation/cubit/music_player_cubit.dart';
import '../cubit/profile_cubit.dart';
import '../cubit/profile_state.dart';
import '../widgets/subscription_plans_sheet.dart';
import '../widgets/theme_selection_sheet.dart';

/// Pestaña 5 oficial: Perfil, Apariencia y Ajustes del Tutor / Educador (Fase 7).
class ProfileTabScreen extends StatelessWidget {
  const ProfileTabScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Si ya existe ProfileCubit en el árbol lo utiliza; de lo contrario instancia uno con GetIt
    return BlocProvider<ProfileCubit>(
      create: (ctx) {
        final authState = ctx.read<AuthCubit>().state;
        UserEntity? initialUser;
        if (authState is Authenticated) {
          initialUser = authState.user;
        }
        final cubit = sl<ProfileCubit>();
        cubit.loadProfile(initialUser: initialUser);
        return cubit;
      },
      child: const _ProfileTabView(),
    );
  }
}

class _ProfileTabView extends StatelessWidget {
  const _ProfileTabView();

  String _formatRegistrationDate(DateTime date) {
    const months = [
      'enero',
      'febrero',
      'marzo',
      'abril',
      'mayo',
      'junio',
      'julio',
      'agosto',
      'septiembre',
      'octubre',
      'noviembre',
      'diciembre',
    ];
    final monthName = (date.month >= 1 && date.month <= 12)
        ? months[date.month - 1]
        : 'enero';
    return '${date.day} de $monthName de ${date.year}';
  }

  Future<void> _performLogout(BuildContext context) async {
    // 1. Detener y liberar reproducción musical
    if (sl.isRegistered<MusicPlayerCubit>()) {
      await sl<MusicPlayerCubit>().clearSession();
    }
    // 2. Liberar recursos de Realidad Aumentada si estuvieran activos
    if (sl.isRegistered<ArCubit>()) {
      await sl<ArCubit>().exitAr();
    }
    // 3. Restablecer la memoria de la biblioteca
    if (sl.isRegistered<LibraryCubit>()) {
      sl<LibraryCubit>().clearSession();
    }
    // 4. Limpiar sesión protegida de Modo Niño
    if (sl.isRegistered<ChildModeCubit>()) {
      await sl<ChildModeCubit>().clearSession();
    }
    // 5. Cerrar sesión en AuthCubit (purga tokens, preferencias y cachés locales)
    if (context.mounted) {
      await context.read<AuthCubit>().logout();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    final isMock = AppConfig.instance.useMockData;

    return Scaffold(
      backgroundColor: context.scaffoldBg,
      appBar: const TsAppBar(title: 'Perfil'),
      body: SafeArea(
        child: BlocConsumer<ProfileCubit, ProfileState>(
          listener: (context, state) {
            // Sincroniza el estado del PIN en AuthCubit
            if (state is ProfileLoaded) {
              context.read<AuthCubit>().updateUserPinConfigured(state.user.pinConfigured);
            }
          },
          builder: (context, state) {
            if (state is ProfileLoading && state is! ProfileLoaded) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(color: AppColors.primary700),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      'Cargando perfil...',
                      style: AppTypography.bodyMedium(
                        color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                      ),
                    ),
                  ],
                ),
              );
            }

            if (state is ProfileError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        state.isNetworkError
                            ? Icons.wifi_off_rounded
                            : Icons.error_outline_rounded,
                        size: 56,
                        color: AppColors.danger,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        'No pudimos cargar tu perfil',
                        style: AppTypography.titleMedium(
                          color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        state.message,
                        style: AppTypography.bodySmall(
                          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      SizedBox(
                        width: 180,
                        child: TsButton(
                          key: const Key('profile_retry_button'),
                          label: 'Reintentar',
                          onPressed: () => context.read<ProfileCubit>().refresh(),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            // Datos del usuario (del ProfileLoaded o fallback de AuthCubit)
            UserEntity? user;
            if (state is ProfileLoaded) {
              user = state.user;
            } else {
              final authState = context.watch<AuthCubit>().state;
              if (authState is Authenticated) {
                user = authState.user;
              }
            }

            final displayName = user?.displayName ?? 'Tutor Tale Star';
            final email = user?.email ?? 'tutor@talestar.app';
            final pinConfigured = user?.pinConfigured ?? false;
            final createdAt = user?.createdAt;

            final initialLetter = displayName.isNotEmpty
                ? displayName.substring(0, 1).toUpperCase()
                : 'T';

            final currentTheme = context.watch<ThemeCubit>().state;

            return RefreshIndicator(
              color: AppColors.primary700,
              backgroundColor: context.surfaceColor,
              onRefresh: () => context.read<ProfileCubit>().refresh(),
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(AppSpacing.md),
                children: [
                  // -----------------------------------------------------------
                  // 1. Tarjeta de Identidad del Usuario
                  // -----------------------------------------------------------
                  Container(
                    key: const Key('profile_user_card'),
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: context.surfaceColor,
                      borderRadius: AppRadii.md,
                      border: Border.all(color: context.surface3Color),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 34,
                          backgroundColor: isDark
                              ? AppColors.primary900.withValues(alpha: 0.3)
                              : AppColors.primary100,
                          child: Text(
                            initialLetter,
                            style: AppTypography.displayMedium(
                              color: isDark ? AppColors.primary300 : AppColors.primary900,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                displayName,
                                key: const Key('profile_display_name'),
                                style: AppTypography.titleMedium(
                                  color: context.textPrimaryColor,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                email,
                                key: const Key('profile_email'),
                                style: AppTypography.bodySmall(
                                  color: context.textSecondaryColor,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (createdAt != null) ...[
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.calendar_today_outlined,
                                      size: 12,
                                      color: context.textTertiaryColor,
                                    ),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        'Registrado el ${_formatRegistrationDate(createdAt)}',
                                        key: const Key('profile_created_at'),
                                        style: AppTypography.caption(
                                          color: context.textTertiaryColor,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                              if (isMock) ...[
                                const SizedBox(height: AppSpacing.xs),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppColors.warning.withValues(alpha: 0.12),
                                    borderRadius: AppRadii.sm,
                                  ),
                                  child: Text(
                                    'Modo Demostración Activo',
                                    style: AppTypography.caption(color: AppColors.warning),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: AppSpacing.lg),

                  // -----------------------------------------------------------
                  // 2. Sección: Seguridad y Control Parental
                  // -----------------------------------------------------------
                  Text(
                    'Seguridad Parental',
                    style: AppTypography.titleSmall(color: context.textSecondaryColor),
                  ),
                  const SizedBox(height: AppSpacing.sm),

                  _buildActionCard(
                    context: context,
                    key: const Key('profile_pin_card'),
                    icon: pinConfigured
                        ? Icons.lock_outline_rounded
                        : Icons.lock_open_rounded,
                    iconColor: pinConfigured ? AppColors.success : AppColors.warning,
                    title: pinConfigured ? 'Modificar PIN Parental' : 'Configurar PIN Parental',
                    description: pinConfigured
                        ? 'PIN activo y protegido. Toca para cambiar tu clave de 4 dígitos.'
                        : 'Sin clave configurada. Crea tu PIN de 4 dígitos para activar el Modo Niño.',
                    trailingBadge: pinConfigured ? 'Activo' : 'Pendiente',
                    badgeColor: pinConfigured ? AppColors.success : AppColors.warning,
                    onTap: () async {
                      final updated = await Navigator.of(context).push<bool>(
                        MaterialPageRoute(builder: (_) => const PinSetupScreen()),
                      );
                      if (updated == true && context.mounted) {
                        context.read<ProfileCubit>().updatePinConfigured(true);
                      }
                    },
                  ),

                  const SizedBox(height: AppSpacing.sm),

                  _buildActionCard(
                    context: context,
                    key: const Key('profile_child_mode_info_card'),
                    icon: Icons.child_care_rounded,
                    iconColor: AppColors.childModeAccent,
                    title: 'Acerca del Modo Niño',
                    description:
                        'El Modo Niño confina la aplicación a un solo cuento o canción, ocultando ajustes y navegación para tranquilidad del adulto.',
                    onTap: () => _showNotice(
                      context,
                      title: 'Protección en Modo Niño',
                      message:
                          'Para activar el Modo Niño, abre cualquier cuento, imagen o canción y presiona el icono de infante en la cabecera.',
                    ),
                  ),

                  const SizedBox(height: AppSpacing.lg),

                  // -----------------------------------------------------------
                  // 3. Sección: Apariencia y Tema
                  // -----------------------------------------------------------
                  Text(
                    'Apariencia y Sistema',
                    style: AppTypography.titleSmall(color: context.textSecondaryColor),
                  ),
                  const SizedBox(height: AppSpacing.sm),

                  _buildActionCard(
                    context: context,
                    key: const Key('profile_theme_card'),
                    icon: Icons.palette_outlined,
                    iconColor: AppColors.primary700,
                    title: 'Tema Visual',
                    description: 'Alterna entre tonos claros, oscuros o sincronizados con tu teléfono.',
                    trailingBadge: currentTheme.labelSpanish,
                    badgeColor: AppColors.primary700,
                    onTap: () => ThemeSelectionSheet.show(context),
                  ),

                  const SizedBox(height: AppSpacing.lg),

                  // -----------------------------------------------------------
                  // 4. Sección: Suscripción y Planes
                  // -----------------------------------------------------------
                  Text(
                    'Suscripción y Cuenta',
                    style: AppTypography.titleSmall(color: context.textSecondaryColor),
                  ),
                  const SizedBox(height: AppSpacing.sm),

                  _buildActionCard(
                    context: context,
                    key: const Key('profile_subscription_card'),
                    icon: Icons.card_membership_rounded,
                    iconColor: AppColors.primary900,
                    title: 'Planes y Membresía',
                    description: 'Información general sobre los planes de creación de Tale Star.',
                    trailingBadge: 'Informativo',
                    badgeColor: AppColors.info,
                    onTap: () => SubscriptionPlansSheet.show(context),
                  ),

                  const SizedBox(height: AppSpacing.xl),

                  // -----------------------------------------------------------
                  // 5. Botón de Cierre de Sesión Seguro
                  // -----------------------------------------------------------
                  TsButton(
                    key: const Key('profile_logout_button'),
                    label: 'Cerrar Sesión',
                    variant: TsButtonVariant.outline,
                    icon: Icons.logout_rounded,
                    onPressed: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          backgroundColor: ctx.surfaceColor,
                          shape: const RoundedRectangleBorder(borderRadius: AppRadii.md),
                          title: Text(
                            '¿Cerrar sesión?',
                            style: AppTypography.titleMedium(color: ctx.textPrimaryColor),
                          ),
                          content: Text(
                            'Tendrás que ingresar nuevamente para acceder a tu biblioteca y creaciones.',
                            style: AppTypography.bodyMedium(color: ctx.textSecondaryColor),
                          ),
                          actions: [
                            TextButton(
                              key: const Key('logout_cancel_button'),
                              onPressed: () => Navigator.of(ctx).pop(false),
                              child: Text(
                                'Cancelar',
                                style: TextStyle(color: ctx.textSecondaryColor),
                              ),
                            ),
                            TextButton(
                              key: const Key('logout_confirm_button'),
                              onPressed: () => Navigator.of(ctx).pop(true),
                              child: const Text(
                                'Cerrar Sesión',
                                style: TextStyle(
                                  color: AppColors.danger,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );

                      if (confirm == true && context.mounted) {
                        await _performLogout(context);
                      }
                    },
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildActionCard({
    required BuildContext context,
    required Key key,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String description,
    String? trailingBadge,
    Color? badgeColor,
    required VoidCallback onTap,
  }) {
    final isDark = context.isDarkMode;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: key,
        borderRadius: AppRadii.md,
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: context.surfaceColor,
            borderRadius: AppRadii.md,
            border: Border.all(color: context.surface3Color),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.02),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: isDark ? 0.2 : 0.1),
                  borderRadius: AppRadii.sm,
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: AppTypography.button(color: context.textPrimaryColor),
                          ),
                        ),
                        if (trailingBadge != null && badgeColor != null) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: badgeColor.withValues(alpha: 0.12),
                              borderRadius: AppRadii.pill,
                            ),
                            child: Text(
                              trailingBadge,
                              style: AppTypography.caption(color: badgeColor).copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      description,
                      style: AppTypography.bodySmall(color: context.textSecondaryColor),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: context.textTertiaryColor,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showNotice(BuildContext context, {required String title, required String message}) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: ctx.surfaceColor,
        shape: const RoundedRectangleBorder(borderRadius: AppRadii.md),
        title: Text(title, style: AppTypography.titleMedium(color: ctx.textPrimaryColor)),
        content: Text(
          message,
          style: AppTypography.bodyMedium(color: ctx.textSecondaryColor),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Entendido', style: TextStyle(color: AppColors.primary700)),
          ),
        ],
      ),
    );
  }
}
