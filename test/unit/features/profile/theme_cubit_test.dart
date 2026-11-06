import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:startale_mobile/core/storage/preferences_service.dart';
import 'package:startale_mobile/core/theme/theme_cubit.dart';

class MockPreferencesService extends Mock implements PreferencesService {}

void main() {
  late MockPreferencesService mockPreferencesService;
  late ThemeCubit themeCubit;

  setUp(() {
    mockPreferencesService = MockPreferencesService();
  });

  group('ThemeCubit Tests', () {
    test('inicializa con tema guardado en PreferencesService (light)', () {
      when(() => mockPreferencesService.themeMode).thenReturn('light');
      themeCubit = ThemeCubit(preferencesService: mockPreferencesService);

      expect(themeCubit.state, AppThemeMode.light);
      expect(themeCubit.state.toThemeMode, ThemeMode.light);
      expect(themeCubit.state.labelSpanish, 'Claro');
    });

    test('inicializa con tema guardado en PreferencesService (dark)', () {
      when(() => mockPreferencesService.themeMode).thenReturn('dark');
      themeCubit = ThemeCubit(preferencesService: mockPreferencesService);

      expect(themeCubit.state, AppThemeMode.dark);
      expect(themeCubit.state.toThemeMode, ThemeMode.dark);
      expect(themeCubit.state.labelSpanish, 'Oscuro');
    });

    test('inicializa por defecto en system si preferencia es inválida o system', () {
      when(() => mockPreferencesService.themeMode).thenReturn('system');
      themeCubit = ThemeCubit(preferencesService: mockPreferencesService);

      expect(themeCubit.state, AppThemeMode.system);
      expect(themeCubit.state.toThemeMode, ThemeMode.system);
      expect(themeCubit.state.labelSpanish, 'Automático (Sistema)');
    });

    test('setThemeMode a dark persiste en preferencias y emite dark', () async {
      when(() => mockPreferencesService.themeMode).thenReturn('light');
      when(() => mockPreferencesService.setThemeMode(any())).thenAnswer((_) async => true);

      themeCubit = ThemeCubit(preferencesService: mockPreferencesService);

      await themeCubit.setThemeMode(AppThemeMode.dark);

      expect(themeCubit.state, AppThemeMode.dark);
      verify(() => mockPreferencesService.setThemeMode('dark')).called(1);
    });

    test('setThemeMode a light persiste en preferencias y emite light', () async {
      when(() => mockPreferencesService.themeMode).thenReturn('dark');
      when(() => mockPreferencesService.setThemeMode(any())).thenAnswer((_) async => true);

      themeCubit = ThemeCubit(preferencesService: mockPreferencesService);

      await themeCubit.setThemeMode(AppThemeMode.light);

      expect(themeCubit.state, AppThemeMode.light);
      verify(() => mockPreferencesService.setThemeMode('light')).called(1);
    });

    test('setThemeMode a system persiste en preferencias y emite system', () async {
      when(() => mockPreferencesService.themeMode).thenReturn('light');
      when(() => mockPreferencesService.setThemeMode(any())).thenAnswer((_) async => true);

      themeCubit = ThemeCubit(preferencesService: mockPreferencesService);

      await themeCubit.setThemeMode(AppThemeMode.system);

      expect(themeCubit.state, AppThemeMode.system);
      verify(() => mockPreferencesService.setThemeMode('system')).called(1);
    });
  });
}

