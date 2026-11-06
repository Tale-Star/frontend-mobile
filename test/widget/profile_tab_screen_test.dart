import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:startale_mobile/core/storage/preferences_service.dart';
import 'package:startale_mobile/core/theme/theme_cubit.dart';
import 'package:startale_mobile/features/authentication/domain/entities/user_entity.dart';
import 'package:startale_mobile/features/authentication/presentation/cubit/auth_cubit.dart';
import 'package:startale_mobile/features/authentication/presentation/cubit/auth_state.dart';
import 'package:startale_mobile/features/profile/presentation/cubit/profile_cubit.dart';
import 'package:startale_mobile/features/profile/presentation/cubit/profile_state.dart';
import 'package:startale_mobile/features/profile/presentation/screens/profile_tab_screen.dart';
import 'package:startale_mobile/injection.dart';

class MockAuthCubit extends Mock implements AuthCubit {}
class MockProfileCubit extends Mock implements ProfileCubit {}
class MockPreferencesService extends Mock implements PreferencesService {}

void main() {
  late MockAuthCubit mockAuthCubit;
  late MockProfileCubit mockProfileCubit;
  late MockPreferencesService mockPreferencesService;
  late ThemeCubit themeCubit;

  final tUser = UserEntity(
    id: 'user-id-001',
    email: 'familia@talestar.com',
    displayName: 'Familia Morales',
    pinConfigured: true,
    createdAt: DateTime.parse('2026-10-01T10:00:00Z'),
  );

  setUp(() {
    mockAuthCubit = MockAuthCubit();
    mockProfileCubit = MockProfileCubit();
    mockPreferencesService = MockPreferencesService();

    when(() => mockPreferencesService.themeMode).thenReturn('light');
    when(() => mockPreferencesService.setThemeMode(any())).thenAnswer((_) async => true);
    themeCubit = ThemeCubit(preferencesService: mockPreferencesService);

    when(() => mockAuthCubit.state).thenReturn(Authenticated(tUser));
    when(() => mockAuthCubit.stream).thenAnswer((_) => const Stream.empty());
    when(() => mockAuthCubit.close()).thenAnswer((_) async {});

    when(() => mockProfileCubit.state).thenReturn(ProfileLoaded(user: tUser));
    when(() => mockProfileCubit.stream).thenAnswer((_) => const Stream.empty());
    when(() => mockProfileCubit.close()).thenAnswer((_) async {});
    when(() => mockProfileCubit.loadProfile(initialUser: any(named: 'initialUser')))
        .thenAnswer((_) async {});
    when(() => mockProfileCubit.refresh()).thenAnswer((_) async {});

    // Registrar en get_it para ProfileTabScreen
    if (sl.isRegistered<ProfileCubit>()) {
      sl.unregister<ProfileCubit>();
    }
    sl.registerFactory<ProfileCubit>(() => mockProfileCubit);
  });

  tearDown(() {
    if (sl.isRegistered<ProfileCubit>()) {
      sl.unregister<ProfileCubit>();
    }
  });

  Widget buildTestableWidget() {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthCubit>.value(value: mockAuthCubit),
        BlocProvider<ThemeCubit>.value(value: themeCubit),
      ],
      child: const MaterialApp(
        home: ProfileTabScreen(),
      ),
    );
  }

  group('ProfileTabScreen Widget Tests', () {
    testWidgets('renderiza información de identidad del usuario correctamente', (tester) async {
      await tester.pumpWidget(buildTestableWidget());
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('profile_user_card')), findsOneWidget);
      expect(find.byKey(const Key('profile_display_name')), findsOneWidget);
      expect(find.text('Familia Morales'), findsOneWidget);
      expect(find.byKey(const Key('profile_email')), findsOneWidget);
      expect(find.text('familia@talestar.com'), findsOneWidget);
      expect(find.text('F'), findsOneWidget); // Inicial de Familia Morales
      expect(find.byKey(const Key('profile_created_at')), findsOneWidget);
      expect(find.textContaining('1 de octubre de 2026'), findsOneWidget);
    });

    testWidgets('renderiza tarjeta de PIN con estado activo', (tester) async {
      await tester.pumpWidget(buildTestableWidget());
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('profile_pin_card')), findsOneWidget);
      expect(find.text('Modificar PIN Parental'), findsOneWidget);
      expect(find.text('Activo'), findsOneWidget);
    });

    testWidgets('renderiza tarjeta de tema y abre ThemeSelectionSheet al pulsar', (tester) async {
      await tester.pumpWidget(buildTestableWidget());
      await tester.pumpAndSettle();

      final themeCard = find.byKey(const Key('profile_theme_card'));
      expect(themeCard, findsOneWidget);
      expect(find.text('Claro'), findsOneWidget);

      await tester.tap(themeCard);
      await tester.pumpAndSettle();

      expect(find.text('Apariencia y Tema'), findsOneWidget);
      expect(find.text('Tema Claro'), findsOneWidget);
      expect(find.text('Tema Oscuro'), findsOneWidget);
      expect(find.text('Automático (Sistema)'), findsOneWidget);
    });

    testWidgets('renderiza tarjeta de suscripción y abre SubscriptionPlansSheet al pulsar', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(buildTestableWidget());
      await tester.pumpAndSettle();

      final subCard = find.byKey(const Key('profile_subscription_card'));
      expect(subCard, findsOneWidget);

      await tester.tap(subCard);
      await tester.pumpAndSettle();

      expect(find.text('Planes y Membresía'), findsNWidgets(2));
      expect(find.text('Plan Go'), findsOneWidget);
      expect(find.text('Plan Plus'), findsOneWidget);
      expect(find.text('Plan Pro'), findsOneWidget);
      expect(find.byKey(const Key('subscription_close_button')), findsOneWidget);

      await tester.tap(find.byKey(const Key('subscription_close_button')));
      await tester.pumpAndSettle();

      expect(find.text('Plan Go'), findsNothing);
    });

    testWidgets('botón cerrar sesión despliega confirmación y cancelar no ejecuta logout', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(buildTestableWidget());
      await tester.pumpAndSettle();

      final logoutButton = find.byKey(const Key('profile_logout_button'));
      expect(logoutButton, findsOneWidget);

      await tester.tap(logoutButton);
      await tester.pumpAndSettle();

      expect(find.text('¿Cerrar sesión?'), findsOneWidget);
      expect(find.byKey(const Key('logout_cancel_button')), findsOneWidget);
      expect(find.byKey(const Key('logout_confirm_button')), findsOneWidget);

      await tester.tap(find.byKey(const Key('logout_cancel_button')));
      await tester.pumpAndSettle();

      expect(find.text('¿Cerrar sesión?'), findsNothing);
      verifyNever(() => mockAuthCubit.logout());
    });

    testWidgets('muestra estado de error y botón de reintento ante ProfileError', (tester) async {
      when(() => mockProfileCubit.state).thenReturn(
        const ProfileError(message: 'Error de conexión', isNetworkError: true),
      );

      await tester.pumpWidget(buildTestableWidget());
      await tester.pumpAndSettle();

      expect(find.text('No pudimos cargar tu perfil'), findsOneWidget);
      expect(find.text('Error de conexión'), findsOneWidget);
      expect(find.byKey(const Key('profile_retry_button')), findsOneWidget);

      await tester.tap(find.byKey(const Key('profile_retry_button')));
      await tester.pump();

      verify(() => mockProfileCubit.refresh()).called(1);
    });
  });
}
