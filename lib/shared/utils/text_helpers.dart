/// Funciones auxiliares para formato y presentación de textos en español.
abstract class TextHelpers {
  /// Saludo contextual según la hora del día.
  static String timeGreeting() {
    final hour = DateTime.now().hour;
    if (hour >= 6 && hour < 12) {
      return 'Buenos días';
    } else if (hour >= 12 && hour < 19) {
      return 'Buenas tardes';
    } else {
      return 'Buenas noches';
    }
  }

  /// Traducción amigable de tipo de ítem de biblioteca.
  static String formatContentType(String type) {
    switch (type.toLowerCase()) {
      case 'story':
        return 'Cuento';
      case 'image':
        return 'Ilustración';
      case 'music':
        return 'Música';
      default:
        return 'Creación';
    }
  }

  /// Formato de páginas para el lector.
  static String formatPageCounter(int current, int total) {
    return 'Página $current de $total';
  }

  /// Formato amigable de fecha relativa en español.
  static String formatRelativeDate(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        if (difference.inMinutes <= 1) return 'Hace un momento';
        return 'Hace ${difference.inMinutes} min';
      }
      return 'Hace ${difference.inHours} h';
    } else if (difference.inDays == 1) {
      return 'Ayer';
    } else if (difference.inDays < 7) {
      return 'Hace ${difference.inDays} días';
    } else {
      final day = dateTime.day.toString().padLeft(2, '0');
      final month = dateTime.month.toString().padLeft(2, '0');
      return '$day/$month/${dateTime.year}';
    }
  }
}
