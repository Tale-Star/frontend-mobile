import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app.dart';
import 'core/config/app_config.dart';
import 'injection.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Configuración de ambiente (.env)
  await AppConfig.initialize();

  // Bloqueo de orientación para lectura estable
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Inicialización de inyección de dependencias (Service Locator)
  await initDependencies();

  runApp(const TaleStarApp());
}
