import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import '../../../../core/config/app_config.dart';

/// Visor del feed de cámara nativo de Google ARCore renderizado con OpenGL ES 2.0 (PlatformView).
///
/// Configurado con `hitTestBehavior: PlatformViewHitTestBehavior.transparent` para garantizar
/// que la vista nativa de cámara jamás intercepte ni bloquee los toques sobre los controles
/// y overlays interactivos de Flutter ubicados encima.
///
/// En modo test, modo mock o plataformas secundarias, degrada elegantemente a un gradiente inmersivo.
class ArCameraFeedView extends StatelessWidget {
  const ArCameraFeedView({super.key});

  @override
  Widget build(BuildContext context) {
    final bool isRealAndroidAr = !kIsWeb &&
        Platform.isAndroid &&
        !AppConfig.instance.useMockAr &&
        !Platform.environment.containsKey('FLUTTER_TEST');

    if (isRealAndroidAr) {
      return const AndroidView(
        viewType: 'com.startale.startale_mobile/ar_view',
        hitTestBehavior: PlatformViewHitTestBehavior.transparent,
      );
    }

    return Container(
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment.center,
          radius: 1.1,
          colors: [
            Color(0xFF1C1A29),
            Color(0xFF0C0A14),
          ],
        ),
      ),
    );
  }
}
