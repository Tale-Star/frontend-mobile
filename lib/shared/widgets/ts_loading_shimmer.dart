import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radii.dart';

/// Componente de efecto esqueleto (shimmer) para estados de carga asíncronos.
class TsLoadingShimmer extends StatelessWidget {
  final Widget child;

  const TsLoadingShimmer({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Shimmer.fromColors(
      baseColor: isDark ? AppColors.surface2Dark : AppColors.surface2Light,
      highlightColor: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
      child: child,
    );
  }

  /// Bloque rectangular con esquinas redondeadas.
  static Widget box({
    required double width,
    required double height,
    BorderRadius borderRadius = AppRadii.sm,
  }) {
    return TsLoadingShimmer(
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: AppColors.surface2Light,
          borderRadius: borderRadius,
        ),
      ),
    );
  }

  /// Tarjeta simulada de cuento o ítem de biblioteca.
  static Widget card({double height = 220.0}) {
    return TsLoadingShimmer(
      child: Container(
        height: height,
        decoration: const BoxDecoration(
          color: AppColors.surface2Light,
          borderRadius: AppRadii.md,
        ),
      ),
    );
  }

  /// Lista de tarjetas esqueleto.
  static Widget list({int itemCount = 4}) {
    return ListView.separated(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: itemCount,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) => card(height: 100),
    );
  }
}
