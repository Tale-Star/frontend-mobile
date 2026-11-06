import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radii.dart';
import '../../../../core/theme/app_typography.dart';

/// Barra superior flotante inspirada en la referencia "Mobile AR Story Reader".
///
/// Dispone de prioridad máxima de z-order para garantizar que el botón de salida (X)
/// responda de forma inmediata y confiable en cualquier momento.
class ArTopBar extends StatelessWidget {
  final VoidCallback onExit;
  final String title;
  final String? subtitle;
  final VoidCallback? onOptions;
  final bool showOptions;
  final Key? exitButtonKey;

  const ArTopBar({
    super.key,
    required this.onExit,
    required this.title,
    this.subtitle,
    this.onOptions,
    this.showOptions = true,
    this.exitButtonKey,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // 1. Botón de Salir / Cerrar AR (X) con Touch Target óptimo
            Material(
              color: Colors.transparent,
              child: InkWell(
                key: exitButtonKey ?? const Key('ar_viewer_exit_button'),
                borderRadius: BorderRadius.circular(24),
                onTap: onExit,
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.55),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.22),
                      width: 1.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.25),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.close_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(width: 8),

            // 2. Chip central flotante con icono y título/página
            Expanded(
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.65),
                    borderRadius: AppRadii.pill,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.2),
                      width: 1.0,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Insignia Tale Star
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [AppColors.primary500, AppColors.primary900],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white70, width: 0.8),
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.auto_awesome_rounded,
                            size: 14,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Texto responsivo del cuento (Título legible hasta 2 líneas + Página X de Y)
                      Flexible(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              key: const Key('ar_top_chip_text'),
                              style: AppTypography.caption(color: Colors.white).copyWith(
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.2,
                                fontSize: 11.5,
                                height: 1.2,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (subtitle != null && subtitle!.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Text(
                                  subtitle!,
                                  key: const Key('ar_top_chip_subtitle'),
                                  style: AppTypography.caption(color: Colors.white70).copyWith(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(width: 8),

            // 3. Botón de Opciones (...) o espaciador simétrico
            if (showOptions && onOptions != null)
              Material(
                color: Colors.transparent,
                child: InkWell(
                  key: const Key('ar_top_options_button'),
                  borderRadius: BorderRadius.circular(24),
                  onTap: onOptions,
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.55),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.22),
                        width: 1.2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.25),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.more_horiz_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                ),
              )
            else
              const SizedBox(width: 44),
          ],
        ),
      ),
    );
  }
}
