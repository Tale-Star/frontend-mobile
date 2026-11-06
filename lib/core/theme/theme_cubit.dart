import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../storage/preferences_service.dart';

/// Modos de apariencia visual soportados en Tale Star (Fase 7).
enum AppThemeMode {
  system,
  light,
  dark;

  ThemeMode get toThemeMode {
    switch (this) {
      case AppThemeMode.light:
        return ThemeMode.light;
      case AppThemeMode.dark:
        return ThemeMode.dark;
      case AppThemeMode.system:
        return ThemeMode.system;
    }
  }

  static AppThemeMode fromString(String? mode) {
    switch (mode?.toLowerCase().trim()) {
      case 'light':
        return AppThemeMode.light;
      case 'dark':
        return AppThemeMode.dark;
      case 'system':
      default:
        return AppThemeMode.system;
    }
  }

  String toStorageString() {
    switch (this) {
      case AppThemeMode.light:
        return 'light';
      case AppThemeMode.dark:
        return 'dark';
      case AppThemeMode.system:
        return 'system';
    }
  }

  String get labelSpanish {
    switch (this) {
      case AppThemeMode.light:
        return 'Claro';
      case AppThemeMode.dark:
        return 'Oscuro';
      case AppThemeMode.system:
        return 'Automático (Sistema)';
    }
  }
}

/// Cubit que gestiona y persiste la selección de apariencia visual en toda la app.
class ThemeCubit extends Cubit<AppThemeMode> {
  final PreferencesService _preferencesService;

  ThemeCubit({required PreferencesService preferencesService})
      : _preferencesService = preferencesService,
        super(AppThemeMode.fromString(preferencesService.themeMode));

  /// Actualiza y persiste la preferencia de tema visual.
  Future<void> setThemeMode(AppThemeMode mode) async {
    await _preferencesService.setThemeMode(mode.toStorageString());
    emit(mode);
  }
}

