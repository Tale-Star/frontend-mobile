import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:startale_mobile/core/storage/preferences_service.dart';
import 'package:startale_mobile/core/theme/app_theme.dart';
import 'package:startale_mobile/core/theme/theme_cubit.dart';
import 'package:startale_mobile/features/profile/presentation/widgets/theme_selection_sheet.dart';

class MockPreferencesService extends Mock implements PreferencesService {}

void main() {
  late MockPreferencesService mockPreferencesService;
  late ThemeCubit themeCubit;

  setUp(() {
    mockPreferencesService = MockPreferencesService();
    when(() => mockPreferencesService.themeMode).thenReturn('light');
    when(() => mockPreferencesService.setThemeMode(any())).thenAnswer((_) async => true);
    themeCubit = ThemeCubit(preferencesService: mockPreferencesService);
  });

  Widget buildAppWithTheme() {
    return BlocProvider<ThemeCubit>.value(
      value: themeCubit,
      child: BlocBuilder<ThemeCubit, AppThemeMode>(
        builder: (context, themeMode) {
          return MaterialApp(
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeMode.toThemeMode,
            home: Builder(
              builder: (ctx) {
                return Scaffold(
                  body: Center(
                    child: ElevatedButton(
                      key: const Key('open_theme_sheet'),
                      onPressed: () => ThemeSelectionSheet.show(ctx),
                      child: Text('Modo: ${Theme.of(ctx).brightness.name}'),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  group('Theme Switching & Reactivity Widget Tests', () {
    testWidgets('cambia reactivamente de tema claro a tema oscuro y persiste', (tester) async {
      await tester.pumpWidget(buildAppWithTheme());
      await tester.pumpAndSettle();

      expect(find.text('Modo: light'), findsOneWidget);

      // Abrir selector
      await tester.tap(find.byKey(const Key('open_theme_sheet')));
      await tester.pumpAndSettle();

      // Seleccionar Oscuro
      await tester.tap(find.byKey(const Key('theme_option_dark')));
      await tester.pumpAndSettle();

      // Comprobar que MaterialApp actualizó a modo oscuro
      expect(find.text('Modo: dark'), findsOneWidget);
      expect(themeCubit.state, AppThemeMode.dark);
      verify(() => mockPreferencesService.setThemeMode('dark')).called(1);
    });

    testWidgets('cambia reactivamente de tema oscuro a claro y persiste', (tester) async {
      when(() => mockPreferencesService.themeMode).thenReturn('dark');
      themeCubit = ThemeCubit(preferencesService: mockPreferencesService);

      await tester.pumpWidget(buildAppWithTheme());
      await tester.pumpAndSettle();

      expect(find.text('Modo: dark'), findsOneWidget);

      await tester.tap(find.byKey(const Key('open_theme_sheet')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('theme_option_light')));
      await tester.pumpAndSettle();

      expect(find.text('Modo: light'), findsOneWidget);
      expect(themeCubit.state, AppThemeMode.light);
      verify(() => mockPreferencesService.setThemeMode('light')).called(1);
    });

    testWidgets('permite seleccionar modo Automático (Sistema)', (tester) async {
      await tester.pumpWidget(buildAppWithTheme());
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('open_theme_sheet')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('theme_option_system')));
      await tester.pumpAndSettle();

      expect(themeCubit.state, AppThemeMode.system);
      verify(() => mockPreferencesService.setThemeMode('system')).called(1);
    });
  });
}

