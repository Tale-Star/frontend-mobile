import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radii.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/ts_button.dart';
import '../../../../shared/widgets/ts_snackbar.dart';
import '../../../authentication/presentation/cubit/auth_cubit.dart';
import '../../../authentication/presentation/cubit/auth_state.dart';
import '../../domain/entities/child_mode_content.dart';
import '../cubit/child_mode_cubit.dart';
import '../screens/pin_setup_screen.dart';

/// Flujo asistido oficial para activar el Modo Niño (US82).
abstract class ActivateChildModeSheet {
  /// Solicita la activación de Modo Niño con comprobación previa de PIN configurado.
  static Future<bool> requestActivation(
    BuildContext context, {
    required ChildModeContentType contentType,
    required String contentId,
    required String contentTitle,
    required String routeContext,
    required ChildModeCubit childModeCubit,
  }) async {
    final authState = context.read<AuthCubit>().state;
    if (authState is! Authenticated) {
      TsSnackBar.showWarning(
        context,
        'Debes iniciar sesión para configurar o activar el Modo Niño.',
      );
      return false;
    }

    final user = authState.user;

    // 1. Si no tiene PIN configurado, orienta al usuario hacia la configuración
    if (!user.pinConfigured) {
      final configured = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: const RoundedRectangleBorder(borderRadius: AppRadii.lg),
          title: Row(
            children: [
              const Icon(Icons.pin_outlined, color: AppColors.primary700),
              const SizedBox(width: 8),
              Text('Configurar PIN', style: AppTypography.titleMedium()),
            ],
          ),
          content: Text(
            'Para activar el Modo Niño necesitas configurar un PIN de 4 dígitos. Esta clave te permitirá salir del modo protegido y regresar a la biblioteca.',
            style: AppTypography.bodyMedium(color: AppColors.textSecondaryLight),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              key: const Key('go_to_pin_setup_button'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary700,
                foregroundColor: Colors.white,
                shape: const RoundedRectangleBorder(borderRadius: AppRadii.sm),
              ),
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Configurar PIN'),
            ),
          ],
        ),
      );

      if (configured == true && context.mounted) {
        final pinResult = await Navigator.of(context).push<bool>(
          MaterialPageRoute(builder: (_) => const PinSetupScreen()),
        );
        if (pinResult != true) {
          return false;
        }
      } else {
        return false;
      }
    }

    if (!context.mounted) return false;

    // 2. Diálogo de confirmación para activar el Modo Niño
    final confirm = await showModalBottomSheet<bool>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadii.lgValue)),
      ),
      backgroundColor: AppColors.surfaceLight,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: const BoxDecoration(
                    color: AppColors.surface3Light,
                    borderRadius: AppRadii.pill,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primary100,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.child_care_rounded,
                      color: AppColors.primary700,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('¿Activar Modo Niño?', style: AppTypography.titleMedium()),
                        const SizedBox(height: 2),
                        Text(
                          contentTitle,
                          style: AppTypography.bodySmall(color: AppColors.primary700),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Al activar el Modo Niño, los pequeños solo podrán disfrutar de este contenido. La navegación a perfil, biblioteca y ajustes requerirá tu PIN parental.',
                style: AppTypography.bodyMedium(color: AppColors.textSecondaryLight),
              ),
              const SizedBox(height: AppSpacing.lg),
              TsButton(
                key: const Key('confirm_activate_child_mode_button'),
                label: 'Activar Modo Niño',
                icon: Icons.shield_rounded,
                onPressed: () => Navigator.of(ctx).pop(true),
              ),
              const SizedBox(height: AppSpacing.xs),
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: Text(
                  'Cancelar',
                  style: AppTypography.button(color: AppColors.textSecondaryLight),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (confirm == true && context.mounted) {
      final success = await childModeCubit.activate(
        contentType: contentType,
        contentId: contentId,
        contentTitle: contentTitle,
        routeContext: routeContext,
      );

      if (success && context.mounted) {
        TsSnackBar.showSuccess(
          context,
          'Modo Niño activado. Toca el distintivo o botón atrás para desbloquear.',
        );
        return true;
      }
    }

    return false;
  }
}
