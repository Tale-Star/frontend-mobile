/// Validadores estándar para formularios y campos de Tale Star.
///
/// Todos los mensajes de error están expresados en tono constructivo y en español.
abstract class Validators {
  static final RegExp _emailRegExp = RegExp(
    r'^[a-zA-Z0-9.!#$%&’*+/=?^_`{|}~-]+@[a-zA-Z0-9-]+(?:\.[a-zA-Z0-9-]+)*$',
  );

  static final RegExp _pinRegExp = RegExp(r'^\d{4}$');

  /// Validador de correo electrónico
  static String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Por favor, ingresa tu correo electrónico';
    }
    if (!_emailRegExp.hasMatch(value.trim())) {
      return 'Ingresa un formato de correo válido (ejemplo: nombre@correo.com)';
    }
    return null;
  }

  /// Validador de nombre para mostrar (display_name en RegisterRequest)
  static String? validateDisplayName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Por favor, ingresa tu nombre o alias';
    }
    if (value.trim().length > 100) {
      return 'El nombre no puede superar los 100 caracteres';
    }
    return null;
  }

  /// Validador de contraseña
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Por favor, ingresa tu contraseña';
    }
    if (value.length < 6) {
      return 'La contraseña debe contener al menos 6 caracteres';
    }
    return null;
  }

  /// Validador de confirmación de contraseña
  static String? validateConfirmPassword(String? password, String? confirmPassword) {
    if (confirmPassword == null || confirmPassword.isEmpty) {
      return 'Por favor, confirma tu contraseña';
    }
    if (password != confirmPassword) {
      return 'Las contraseñas no coinciden. Verifícalas con cuidado';
    }
    return null;
  }

  /// Validador de PIN parental de 4 dígitos
  static String? validatePin(String? value) {
    if (value == null || value.isEmpty) {
      return 'Ingresa los 4 números de tu PIN parental';
    }
    if (!_pinRegExp.hasMatch(value)) {
      return 'El PIN debe consistir exactamente en 4 dígitos numéricos';
    }
    return null;
  }
}
