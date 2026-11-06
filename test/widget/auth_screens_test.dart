import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:startale_mobile/core/theme/app_theme.dart';
import 'package:startale_mobile/features/authentication/presentation/cubit/auth_cubit.dart';
import 'package:startale_mobile/features/authentication/presentation/cubit/auth_state.dart';
import 'package:startale_mobile/features/authentication/presentation/screens/forgot_password_screen.dart';
import 'package:startale_mobile/features/authentication/presentation/screens/login_screen.dart';
import 'package:startale_mobile/features/authentication/presentation/screens/register_screen.dart';

class MockAuthCubit extends Mock implements AuthCubit {}

void main() {
  late MockAuthCubit mockAuthCubit;

  setUp(() {
    mockAuthCubit = MockAuthCubit();
    when(() => mockAuthCubit.state).thenReturn(const Unauthenticated());
    when(() => mockAuthCubit.stream).thenAnswer((_) => const Stream.empty());
  });

  Widget buildTestWidget(Widget child) {
    return MaterialApp(
      theme: AppTheme.lightTheme,
      home: BlocProvider<AuthCubit>.value(
        value: mockAuthCubit,
        child: child,
      ),
    );
  }

  group('LoginScreen Widget Tests', () {
    testWidgets('renderiza campos de correo, contraseña, botón y checkbox Recordarme', (tester) async {
      await tester.pumpWidget(buildTestWidget(const LoginScreen()));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('login_email_field')), findsOneWidget);
      expect(find.byKey(const Key('login_password_field')), findsOneWidget);
      expect(find.byKey(const Key('login_remember_me_checkbox')), findsOneWidget);
      expect(find.byKey(const Key('login_submit_button')), findsOneWidget);
      expect(find.text('Tale Star'), findsOneWidget);
    });

    testWidgets('valida campos requeridos al presionar Iniciar Sesión con campos vacíos', (tester) async {
      await tester.pumpWidget(buildTestWidget(const LoginScreen()));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('login_submit_button')));
      await tester.pumpAndSettle();

      expect(find.text('Por favor, ingresa tu correo electrónico'), findsOneWidget);
      expect(find.text('Por favor, ingresa tu contraseña'), findsOneWidget);
      verifyNever(() => mockAuthCubit.login(
            email: any(named: 'email'),
            password: any(named: 'password'),
            rememberMe: any(named: 'rememberMe'),
          ));
    });

    testWidgets('permite alternar el estado del checkbox Recordarme', (tester) async {
      await tester.pumpWidget(buildTestWidget(const LoginScreen()));
      await tester.pumpAndSettle();

      final checkboxFinder = find.byKey(const Key('login_remember_me_checkbox'));
      Checkbox checkbox = tester.widget<Checkbox>(checkboxFinder);
      final initialVal = checkbox.value;

      await tester.tap(checkboxFinder);
      await tester.pumpAndSettle();

      checkbox = tester.widget<Checkbox>(checkboxFinder);
      expect(checkbox.value, isNot(equals(initialVal)));
    });

    testWidgets('invoca login en el Cubit cuando los datos son válidos', (tester) async {
      when(() => mockAuthCubit.login(
            email: any(named: 'email'),
            password: any(named: 'password'),
            rememberMe: any(named: 'rememberMe'),
          )).thenAnswer((_) async {});

      await tester.pumpWidget(buildTestWidget(const LoginScreen()));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.descendant(
          of: find.byKey(const Key('login_email_field')),
          matching: find.byType(TextFormField),
        ),
        'padre@talestar.app',
      );

      await tester.enterText(
        find.descendant(
          of: find.byKey(const Key('login_password_field')),
          matching: find.byType(TextFormField),
        ),
        'Password123!',
      );

      await tester.tap(find.byKey(const Key('login_submit_button')));
      await tester.pumpAndSettle();

      verify(() => mockAuthCubit.login(
            email: 'padre@talestar.app',
            password: 'Password123!',
            rememberMe: any(named: 'rememberMe'),
          )).called(1);
    });
  });

  group('RegisterScreen Widget Tests', () {
    testWidgets('renderiza formulario de registro con campos oficiales', (tester) async {
      await tester.pumpWidget(buildTestWidget(const RegisterScreen()));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('register_display_name_field')), findsOneWidget);
      expect(find.byKey(const Key('register_email_field')), findsOneWidget);
      expect(find.byKey(const Key('register_password_field')), findsOneWidget);
      expect(find.byKey(const Key('register_confirm_password_field')), findsOneWidget);
      expect(find.byKey(const Key('register_submit_button')), findsOneWidget);
      expect(find.text('Crear tu cuenta'), findsOneWidget);
    });

    testWidgets('despliega campo de PIN parental opcional al presionar el expander', (tester) async {
      await tester.pumpWidget(buildTestWidget(const RegisterScreen()));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('register_pin_field')), findsNothing);

      final expanderFinder = find.text('Configurar PIN parental ahora (opcional)');
      await tester.ensureVisible(expanderFinder);
      await tester.pumpAndSettle();

      await tester.tap(expanderFinder);
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('register_pin_field')), findsOneWidget);
    });
  });

  group('ForgotPasswordScreen Widget Tests (US04)', () {
    testWidgets('renderiza campo de correo y botón de envío asistido', (tester) async {
      await tester.pumpWidget(buildTestWidget(const ForgotPasswordScreen()));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('forgot_password_email_field')), findsOneWidget);
      expect(find.byKey(const Key('forgot_password_submit_button')), findsOneWidget);
      expect(find.text('Recuperar Contraseña'), findsOneWidget);
    });

    testWidgets('muestra diálogo de confirmación cuando se emite PasswordResetSent', (tester) async {
      when(() => mockAuthCubit.state).thenReturn(const PasswordResetSent('mama@talestar.app'));
      when(() => mockAuthCubit.stream).thenAnswer(
        (_) => Stream.value(const PasswordResetSent('mama@talestar.app')),
      );

      await tester.pumpWidget(buildTestWidget(const ForgotPasswordScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Solicitud Enviada'), findsOneWidget);
      expect(find.text('mama@talestar.app'), findsOneWidget);
      expect(find.text('Nota de prueba MVP: El servicio de correo está simulado en cliente. Tu cuenta permanece protegida.'), findsOneWidget);
    });
  });
}