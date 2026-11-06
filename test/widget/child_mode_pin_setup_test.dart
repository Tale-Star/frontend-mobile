import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:startale_mobile/features/authentication/domain/entities/user_entity.dart';
import 'package:startale_mobile/features/authentication/presentation/cubit/auth_cubit.dart';
import 'package:startale_mobile/features/authentication/presentation/cubit/auth_state.dart';
import 'package:startale_mobile/features/child_mode/domain/repositories/parental_pin_repository.dart';
import 'package:startale_mobile/features/child_mode/presentation/screens/pin_setup_screen.dart';
import 'package:startale_mobile/shared/widgets/ts_pin_field.dart';

class MockParentalPinRepository extends Mock implements ParentalPinRepository {}
class MockAuthCubit extends Mock implements AuthCubit {}

void main() {
  late MockParentalPinRepository mockRepo;
  late MockAuthCubit mockAuthCubit;

  final tUser = UserEntity(
    id: 'user-001',
    email: 'tutor@talestar.app',
    displayName: 'Tutor Demo',
    pinConfigured: false,
    createdAt: DateTime.parse('2026-10-31T12:00:00Z'),
  );

  setUp(() {
    mockRepo = MockParentalPinRepository();
    mockAuthCubit = MockAuthCubit();

    when(() => mockAuthCubit.state).thenReturn(Authenticated(tUser));
    when(() => mockAuthCubit.stream).thenAnswer((_) => Stream.value(Authenticated(tUser)));
  });

  Widget buildTestWidget() {
    return MaterialApp(
      home: BlocProvider<AuthCubit>.value(
        value: mockAuthCubit,
        child: PinSetupScreen(repository: mockRepo),
      ),
    );
  }

  group('PinSetupScreen Widget Tests', () {
    testWidgets('renderiza campos de contraseña y PIN parental correctamente', (tester) async {
      await tester.pumpWidget(buildTestWidget());

      expect(find.text('Configurar PIN Parental'), findsOneWidget);
      expect(find.byKey(const Key('pin_setup_password_field')), findsOneWidget);
      expect(find.byKey(const Key('pin_setup_new_pin_field')), findsOneWidget);
      expect(find.byKey(const Key('pin_setup_confirm_pin_field')), findsOneWidget);
      expect(find.byKey(const Key('pin_setup_submit_button')), findsOneWidget);
    });

    testWidgets('muestra error si la contraseña está vacía al enviar', (tester) async {
      await tester.pumpWidget(buildTestWidget());

      await tester.ensureVisible(find.byKey(const Key('pin_setup_submit_button')));
      await tester.tap(find.byKey(const Key('pin_setup_submit_button')));
      await tester.pumpAndSettle();

      expect(find.text('Por favor ingresa la contraseña actual de tu cuenta.'), findsOneWidget);
    });

    testWidgets('muestra error si los PINs no coinciden', (tester) async {
      await tester.pumpWidget(buildTestWidget());

      // Ingresa contraseña
      await tester.enterText(
        find.descendant(
          of: find.byKey(const Key('pin_setup_password_field')),
          matching: find.byType(TextFormField),
        ),
        'secret123',
      );

      // Simula ingreso de PIN nuevo y confirmación diferente usando los callbacks
      final newPinFinder = find.byKey(const Key('pin_setup_new_pin_field'));
      final confirmPinFinder = find.byKey(const Key('pin_setup_confirm_pin_field'));

      final TsPinField newPinWidget = tester.widget(newPinFinder);
      final TsPinField confirmPinWidget = tester.widget(confirmPinFinder);

      newPinWidget.onCompleted('1234');
      confirmPinWidget.onCompleted('9999');

      await tester.pump();

      await tester.ensureVisible(find.byKey(const Key('pin_setup_submit_button')));
      await tester.tap(find.byKey(const Key('pin_setup_submit_button')));
      await tester.pumpAndSettle();

      expect(find.text('Los números del PIN no coinciden. Verifícalos con calma.'), findsOneWidget);
    });

    testWidgets('guarda el PIN exitosamente cuando los datos son válidos', (tester) async {
      when(() => mockRepo.setParentalPin(
            currentPassword: 'secret123',
            pin: '1234',
          )).thenAnswer((_) async => tUser.copyWith(pinConfigured: true));

      await tester.pumpWidget(buildTestWidget());

      await tester.enterText(
        find.descendant(
          of: find.byKey(const Key('pin_setup_password_field')),
          matching: find.byType(TextFormField),
        ),
        'secret123',
      );

      final TsPinField newPinWidget = tester.widget(find.byKey(const Key('pin_setup_new_pin_field')));
      final TsPinField confirmPinWidget = tester.widget(find.byKey(const Key('pin_setup_confirm_pin_field')));

      newPinWidget.onCompleted('1234');
      confirmPinWidget.onCompleted('1234');

      await tester.pump();

      await tester.ensureVisible(find.byKey(const Key('pin_setup_submit_button')));
      await tester.tap(find.byKey(const Key('pin_setup_submit_button')));
      await tester.pumpAndSettle();

      verify(() => mockRepo.setParentalPin(
            currentPassword: 'secret123',
            pin: '1234',
          )).called(1);
    });
  });
}
