import 'package:flutter/material.dart';
import '../../../../core/theme/app_radii.dart';
import '../../../../core/theme/app_typography.dart';

/// Controles flotantes inferiores inspirados en la referencia "Mobile AR Story Reader".
///
/// Ofrece botones circulares discretos para avanzar/retroceder páginas,
/// un indicador minimalista "X / Y" y un botón de texto "Salir de AR".
class ArFloatingControls extends StatelessWidget {
  final int currentPage;
  final int totalPages;
  final bool hasPrevious;
  final bool hasNext;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;
  final VoidCallback onExit;

  const ArFloatingControls({
    super.key,
    required this.currentPage,
    required this.totalPages,
    required this.hasPrevious,
    required this.hasNext,
    required this.onPrevious,
    required this.onNext,
    required this.onExit,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.only(left: 24, right: 24, bottom: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Fila de controles circulares: [ < ]  [ 3/6 ]  [ > ]
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 1. Botón Anterior ( < )
                _buildCircularButton(
                  key: const Key('ar_previous_page_button'),
                  icon: Icons.chevron_left_rounded,
                  enabled: hasPrevious,
                  onTap: onPrevious,
                ),

                const SizedBox(width: 20),

                // 2. Pastilla de página centrada (ej. "3 / 6")
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.75),
                    borderRadius: AppRadii.pill,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.22),
                      width: 1.0,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Text(
                    '$currentPage/$totalPages',
                    key: const Key('ar_page_indicator_text'),
                    style: AppTypography.button(color: Colors.white).copyWith(
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.0,
                      fontSize: 14,
                    ),
                  ),
                ),

                const SizedBox(width: 20),

                // 3. Botón Siguiente ( > )
                _buildCircularButton(
                  key: const Key('ar_next_page_button'),
                  icon: Icons.chevron_right_rounded,
                  enabled: hasNext,
                  onTap: onNext,
                ),
              ],
            ),

            const SizedBox(height: 12),

            // 4. Acción textual "Salir de AR" / "Exit AR"
            GestureDetector(
              key: const Key('ar_floating_exit_text_button'),
              onTap: onExit,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: Text(
                  'Salir de AR',
                  style: AppTypography.caption(color: Colors.white.withValues(alpha: 0.85)).copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    shadows: const [
                      Shadow(
                        color: Colors.black87,
                        blurRadius: 6,
                        offset: Offset(0, 1),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCircularButton({
    required Key key,
    required IconData icon,
    required bool enabled,
    required VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: key,
        borderRadius: BorderRadius.circular(28),
        onTap: enabled ? onTap : null,
        child: Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.65),
            shape: BoxShape.circle,
            border: Border.all(
              color: enabled
                  ? Colors.white.withValues(alpha: 0.25)
                  : Colors.white.withValues(alpha: 0.1),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Center(
            child: Icon(
              icon,
              color: enabled ? Colors.white : Colors.white24,
              size: 32,
            ),
          ),
        ),
      ),
    );
  }
}

