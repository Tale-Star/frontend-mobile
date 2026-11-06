import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_typography.dart';

/// Barra superior oficial de Tale Star con soporte para título y distintivo de Modo Niño.
class TsAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final Widget? leading;
  final bool isChildMode;

  const TsAppBar({
    super.key,
    required this.title,
    this.actions,
    this.leading,
    this.isChildMode = false,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            style: AppTypography.titleLarge(
              color: isChildMode ? AppColors.childModeAccent : context.textPrimaryColor,
            ),
          ),
          if (isChildMode) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.childModeAccent.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Modo Niño',
                style: AppTypography.caption(color: AppColors.childModeAccent),
              ),
            ),
          ],
        ],
      ),
      leading: leading,
      actions: actions,
      backgroundColor: isChildMode ? AppColors.childModeBg : context.surfaceColor,
      elevation: 0,
      centerTitle: true,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1.0),
        child: Container(
          color: isChildMode
              ? AppColors.childModeAccent.withValues(alpha: 0.2)
              : context.surface3Color,
          height: 1.0,
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 1.0);
}
