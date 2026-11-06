import 'package:flutter/material.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radii.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/ts_button.dart';

/// Hoja modal informativa sobre los planes de suscripción de Tale Star (Fase 7).
///
/// Siguiendo la especificación oficial del proyecto:
/// - La contratación móvil no está habilitada.
/// - La gestión se realiza exclusivamente a través de la plataforma Web oficial.
/// - No contiene simulación ficticia de pagos ni pasarelas engañosas.
class SubscriptionPlansSheet extends StatelessWidget {
  const SubscriptionPlansSheet({super.key});

  /// Muestra la hoja modal informativa.
  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const SubscriptionPlansSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    final isMock = AppConfig.instance.useMockData;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(
          top: BorderSide(
            color: isDark ? AppColors.surface3Dark : AppColors.surface3Light,
          ),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.xl,
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Indicador de arrastre superior
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: AppSpacing.md),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.surface3Dark : AppColors.surface3Light,
                    borderRadius: AppRadii.pill,
                  ),
                ),
              ),

              // Título y Cabecera
              Row(
                children: [
                  const Icon(
                    Icons.card_membership_rounded,
                    color: AppColors.primary700,
                    size: 26,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    'Planes y Membresía',
                    style: AppTypography.titleMedium(
                      color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Conoce los planes de creación de historias, generación multimedia y lectura interactiva.',
                style: AppTypography.bodySmall(
                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                ),
              ),

              const SizedBox(height: AppSpacing.md),

              // Aviso Importante de Alcance Móvil
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: AppColors.info.withValues(alpha: isDark ? 0.15 : 0.08),
                  borderRadius: AppRadii.sm,
                  border: Border.all(
                    color: AppColors.info.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.info_outline_rounded,
                      color: AppColors.info,
                      size: 20,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        'La contratación y facturación de suscripciones se realiza exclusivamente a través de la plataforma web de Tale Star. La aplicación móvil está destinada a la lectura, disfrute y supervisión parental.',
                        style: AppTypography.caption(
                          color: isDark ? AppColors.textPrimaryDark : AppColors.textSecondaryLight,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              if (isMock) ...[
                const SizedBox(height: AppSpacing.xs),
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withValues(alpha: 0.12),
                      borderRadius: AppRadii.pill,
                    ),
                    child: Text(
                      'Información Referencial de Demostración',
                      style: AppTypography.caption(color: AppColors.warning),
                    ),
                  ),
                ),
              ],

              const SizedBox(height: AppSpacing.lg),

              // Tarjeta 1: Plan Go (USD 10 / mes) — US80
              _buildPlanCard(
                isDark: isDark,
                title: 'Plan Go',
                price: 'USD 10 / mes',
                badge: 'Creación Esencial',
                badgeColor: AppColors.primary500,
                description: 'Diseñado para familias que inician su viaje en la narración creativa.',
                features: const [
                  'Lectura completa 2D y Realidad Aumentada (AR)',
                  'Modo Niño seguro con protección por PIN',
                  'Hasta 10 cuentos e ilustraciones generadas al mes',
                  'Reproducción de pistas en calidad estándar',
                  'Biblioteca compartida en el hogar',
                ],
              ),

              const SizedBox(height: AppSpacing.md),

              // Tarjeta 2: Plan Plus (USD 20 / mes) — US80
              _buildPlanCard(
                isDark: isDark,
                title: 'Plan Plus',
                price: 'USD 20 / mes',
                badge: 'Recomendado',
                badgeColor: AppColors.primary700,
                description: 'Ideal para familias activas que buscan mayor personalización visual y musical.',
                features: const [
                  'Todo lo incluido en el Plan Go',
                  'Hasta 30 cuentos e ilustraciones exclusivas al mes',
                  'Generación de melodías personalizadas en FLAC Lossless',
                  'Personalización de estilos artísticos (Storybook y 3D Flat)',
                  'Almacenamiento extendido de creaciones en la nube',
                ],
              ),

              const SizedBox(height: AppSpacing.md),

              // Tarjeta 3: Plan Pro (USD 100 / mes) — US80
              _buildPlanCard(
                isDark: isDark,
                title: 'Plan Pro',
                price: 'USD 100 / mes',
                badge: 'Educadores y Centros',
                badgeColor: AppColors.success,
                description: 'Para educadores, escuelas y creadores intensivos de contenidos infantiles.',
                features: const [
                  'Todo lo incluido en el Plan Plus',
                  'Generación ilimitada de cuentos, arte y música',
                  'Múltiples perfiles de aula y grupos de lectura',
                  'Exportación de materiales didácticos',
                  'Soporte prioritario y acceso anticipado a novedades',
                ],
              ),

              const SizedBox(height: AppSpacing.lg),

              // Botón Entendido
              TsButton(
                key: const Key('subscription_close_button'),
                label: 'Entendido',
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlanCard({
    required bool isDark,
    required String title,
    required String price,
    required String badge,
    required Color badgeColor,
    required String description,
    required List<String> features,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surface2Dark : AppColors.surfaceLight,
        borderRadius: AppRadii.md,
        border: Border.all(
          color: isDark ? AppColors.surface3Dark : AppColors.surface3Light,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Text(
                      title,
                      style: AppTypography.titleSmall(
                        color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      '· $price',
                      style: AppTypography.caption(
                        color: isDark ? AppColors.primary300 : AppColors.primary700,
                      ).copyWith(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: badgeColor.withValues(alpha: 0.12),
                  borderRadius: AppRadii.pill,
                ),
                child: Text(
                  badge,
                  style: AppTypography.caption(color: badgeColor).copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            description,
            style: AppTypography.bodySmall(
              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          const Divider(height: 1),
          const SizedBox(height: AppSpacing.sm),
          ...features.map(
            (f) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 2.5),
              child: Row(
                children: [
                  const Icon(
                    Icons.check_circle_outline_rounded,
                    color: AppColors.success,
                    size: 16,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      f,
                      style: AppTypography.bodySmall(
                        color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

