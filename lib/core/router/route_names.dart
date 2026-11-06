/// Nombres y rutas del enrutador de Tale Star.
abstract class RouteNames {
  // Autenticación
  static const String login = 'login';
  static const String loginPath = '/login';

  static const String register = 'register';
  static const String registerPath = '/register';

  static const String forgotPassword = 'forgotPassword';
  static const String forgotPasswordPath = '/forgot-password';

  // Navegación Principal (5 pestañas oficiales)
  static const String images = 'images';
  static const String imagesPath = '/images';

  static const String stories = 'stories';
  static const String storiesPath = '/stories';

  static const String music = 'music';
  static const String musicPath = '/music';

  static const String library = 'library';
  static const String libraryPath = '/library';

  static const String profile = 'profile';
  static const String profilePath = '/profile';

  // Lector 2D y Realidad Aumentada
  static const String reader = 'reader';
  static const String readerPath = '/stories/:storyId/read';

  static const String arReader = 'arReader';
  static const String arReaderPath = '/stories/:storyId/ar';

  // Visor de Imagen
  static const String imageViewer = 'imageViewer';
  static const String imageViewerPath = '/media/image/:id';

  // Reproductor Musical FLAC (Fase 4)
  static const String musicPlayer = 'musicPlayer';
  static const String musicPlayerPath = '/music/player';

  // Modo Niño y Desbloqueo de PIN
  static const String pinSetup = 'pinSetup';
  static const String pinSetupPath = '/child-mode/setup';

  static const String pinUnlock = 'pinUnlock';
  static const String pinUnlockPath = '/child-mode/unlock';
}
