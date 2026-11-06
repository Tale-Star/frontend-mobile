import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../reader/domain/entities/story_page_detail.dart';

/// Tarjeta tridimensional del cuento anclada en el entorno físico de Realidad Aumentada.
///
/// Refinada fielmente según la especificación de diseño **MU-09 Mobile AR Story Reader**:
/// - Estética de página ilustrada / libro virtual suspendido en el espacio 3D.
/// - Marco blanco nítido con esquinas redondeadas y sombra de oclusión multicapa.
/// - Ilustración destacada en la mitad superior correspondiente a cada página.
/// - Área de narración desplazable verticalmente sin truncar texto con elipsis.
/// - Separación rigurosa de gestos: scroll de lectura independiente de rotación/escala 3D.
/// - Proyección reactiva vinculada a la Pose real y perspectiva del Anchor de ARCore.
class ArStoryCard3d extends StatefulWidget {
  final StoryPageDetail? page;
  final int pageNumber;
  final int totalPages;
  final double scale;
  final double rotationY;
  final double rotationX;
  final double spatialOffsetX;
  final double spatialOffsetY;
  final double spatialScaleMultiplier;
  final double spatialYaw;
  final double spatialPitch;
  final bool isAnchorTracking;
  final bool isAnchorInView;
  final ValueChanged<double> onScaleChanged;
  final void Function(double rotationY, double rotationX) onRotationChanged;
  final VoidCallback onResetTransform;

  const ArStoryCard3d({
    super.key,
    required this.page,
    required this.pageNumber,
    required this.totalPages,
    required this.scale,
    required this.rotationY,
    required this.rotationX,
    this.spatialOffsetX = 0.0,
    this.spatialOffsetY = 0.0,
    this.spatialScaleMultiplier = 1.0,
    this.spatialYaw = 0.0,
    this.spatialPitch = 0.0,
    this.isAnchorTracking = false,
    this.isAnchorInView = true,
    required this.onScaleChanged,
    required this.onRotationChanged,
    required this.onResetTransform,
  });

  @override
  State<ArStoryCard3d> createState() => _ArStoryCard3dState();
}

class _ArStoryCard3dState extends State<ArStoryCard3d> {
  final ScrollController _textScrollController = ScrollController();
  bool _canScrollMore = false;
  bool _isAtBottom = false;

  double _baseScale = 1.0;
  double _baseRotationY = 0.0;
  Offset _startFocalPoint = Offset.zero;

  @override
  void initState() {
    super.initState();
    _textScrollController.addListener(_handleScrollListener);
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkScrollability());
  }

  @override
  void didUpdateWidget(covariant ArStoryCard3d oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reiniciar posición de scroll al cambiar de página
    if (oldWidget.pageNumber != widget.pageNumber) {
      if (_textScrollController.hasClients) {
        _textScrollController.jumpTo(0.0);
      }
      WidgetsBinding.instance.addPostFrameCallback((_) => _checkScrollability());
    }
  }

  @override
  void dispose() {
    _textScrollController.removeListener(_handleScrollListener);
    _textScrollController.dispose();
    super.dispose();
  }

  void _handleScrollListener() {
    if (!_textScrollController.hasClients) return;
    final maxScroll = _textScrollController.position.maxScrollExtent;
    final currentOffset = _textScrollController.offset;

    final atBottom = currentOffset >= (maxScroll - 6.0);
    final canScroll = maxScroll > 4.0;

    if (atBottom != _isAtBottom || canScroll != _canScrollMore) {
      setState(() {
        _isAtBottom = atBottom;
        _canScrollMore = canScroll;
      });
    }
  }

  void _checkScrollability() {
    if (!_textScrollController.hasClients) return;
    final maxScroll = _textScrollController.position.maxScrollExtent;
    setState(() {
      _canScrollMore = maxScroll > 4.0;
      _isAtBottom = _textScrollController.offset >= (maxScroll - 6.0);
    });
  }

  String _resolveIllustrationAsset() {
    if (widget.page?.demoIllustrationAsset != null &&
        widget.page!.demoIllustrationAsset!.trim().isNotEmpty) {
      return widget.page!.demoIllustrationAsset!.trim();
    }
    return switch (widget.pageNumber) {
      1 => 'assets/demo/demo_forest.png',
      2 => 'assets/demo/demo_castle.png',
      3 => 'assets/demo/demo_space.png',
      _ => 'assets/demo/demo_space.png',
    };
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;
    final screenHeight = mediaQuery.size.height;

    // Dimensiones responsivas equilibradas según la proporción polaroid de MU-09
    final cardWidth = math.min(screenWidth * 0.76, 310.0);
    final cardHeight = math.min(screenHeight * 0.58, 470.0);
    final illustrationHeight = cardHeight * 0.56;

    final pageText = widget.page?.text.trim().isNotEmpty == true
        ? widget.page!.text.trim()
        : 'Cada estrella guardaba un misterio esperando a ser explorado.';

    // Ángulos de perspectiva resultantes: rotación de cámara física + ajuste manual
    final effectiveYaw = (widget.spatialYaw * 0.35) + widget.rotationY;
    final effectivePitch = (widget.spatialPitch * 0.25) + widget.rotationX;
    final totalScale = (widget.scale * widget.spatialScaleMultiplier).clamp(0.55, 1.85);

    return Center(
      child: Transform.translate(
        offset: Offset(widget.spatialOffsetX, widget.spatialOffsetY),
        child: Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.001) // Perspectiva cónica 3D
            ..rotateY(effectiveYaw) // Rotación horizontal de perspectiva física
            ..rotateX(effectivePitch) // Inclinación vertical respecto a la mesa
            ..rotateZ(-0.015) // Inclinación sutil orgánica MU-09
            ..scaleByDouble(totalScale, totalScale, 1.0, 1.0),
          child: Container(
            width: cardWidth,
            height: cardHeight,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: Colors.white,
                width: 3.5,
              ),
              boxShadow: [
                // Sombra de oclusión ambiental espacial de gran profundidad
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.36),
                  blurRadius: 36,
                  spreadRadius: 2,
                  offset: const Offset(4, 18),
                ),
                // Resplandor sutil púrpura de Tale Star
                BoxShadow(
                  color: AppColors.primary900.withValues(alpha: 0.16),
                  blurRadius: 22,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              children: [
                // -------------------------------------------------------------
                // 1. ILUSTRACIÓN: Admite gestos de rotación espacial y escala
                // -------------------------------------------------------------
                GestureDetector(
                  key: const Key('ar_story_card_illustration_gesture'),
                  onScaleStart: (details) {
                    _baseScale = widget.scale;
                    _baseRotationY = widget.rotationY;
                    _startFocalPoint = details.focalPoint;
                  },
                  onScaleUpdate: (details) {
                    if (details.scale != 1.0) {
                      final newScale = _baseScale * details.scale;
                      widget.onScaleChanged(newScale);
                    }
                    final deltaX = details.focalPoint.dx - _startFocalPoint.dx;
                    final newRotationY = _baseRotationY + (deltaX * 0.0018);
                    widget.onRotationChanged(newRotationY, widget.rotationX);
                  },
                  onDoubleTap: widget.onResetTransform,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      height: illustrationHeight,
                      width: double.infinity,
                      color: const Color(0xFFE9EBEF),
                      child: Image.asset(
                        _resolveIllustrationAsset(),
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return _buildThematicIllustration();
                        },
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // -------------------------------------------------------------
                // 2. ÁREA NARRATIVA: Desplazamiento vertical nativo y completo
                // -------------------------------------------------------------
                Expanded(
                  child: Stack(
                    children: [
                      // Scroll del texto narrativo sin truncamiento
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Scrollbar(
                          controller: _textScrollController,
                          thumbVisibility: _canScrollMore,
                          thickness: 3.0,
                          radius: const Radius.circular(8),
                          child: SingleChildScrollView(
                            controller: _textScrollController,
                            physics: const BouncingScrollPhysics(),
                            padding: const EdgeInsets.only(bottom: 16),
                            child: Text(
                              pageText,
                              key: const Key('ar_page_narrative_text'),
                              textAlign: TextAlign.center,
                              style: AppTypography.bodyMedium().copyWith(
                                color: const Color(0xFF1E1F27),
                                fontWeight: FontWeight.w400,
                                fontSize: 13.5,
                                height: 1.48,
                                fontStyle: FontStyle.normal, // No cursiva forzada
                                letterSpacing: 0.1,
                              ),
                            ),
                          ),
                        ),
                      ),

                      // Indicador discreto de contenido adicional abajo (degradado sutil)
                      if (_canScrollMore && !_isAtBottom)
                        Positioned(
                          left: 0,
                          right: 0,
                          bottom: 0,
                          height: 28,
                          child: IgnorePointer(
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.white.withValues(alpha: 0.0),
                                    Colors.white.withValues(alpha: 0.95),
                                  ],
                                ),
                              ),
                              child: const Align(
                                alignment: Alignment.bottomCenter,
                                child: Icon(
                                  Icons.keyboard_arrow_down_rounded,
                                  size: 16,
                                  color: AppColors.primary500,
                                ),
                              ),
                            ),
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
    );
  }

  /// Ilustración temática infantil con estética oficial de Tale Star como fallback hermoso
  Widget _buildThematicIllustration() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFF9B88FD),
            Color(0xFF6B53FD),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.22),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.auto_awesome_rounded,
                size: 28,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tale Star AR',
              style: AppTypography.caption(color: Colors.white).copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 11.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
