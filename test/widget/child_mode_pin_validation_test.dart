import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:startale_mobile/core/storage/preferences_service.dart';
import 'package:startale_mobile/features/authentication/domain/entities/user_entity.dart';
import 'package:startale_mobile/features/authentication/presentation/cubit/auth_cubit.dart';
import 'package:startale_mobile/features/authentication/presentation/cubit/auth_state.dart';
import 'package:startale_mobile/features/child_mode/domain/entities/child_mode_content.dart';
import 'package:startale_mobile/features/child_mode/domain/repositories/parental_pin_repository.dart';
import 'package:startale_mobile/features/child_mode/presentation/cubit/child_mode_cubit.dart';
import 'package:startale_mobile/features/child_mode/presentation/cubit/child_mode_state.dart';
import 'package:startale_mobile/features/child_mode/presentation/screens/pin_validation_dialog.dart';
import 'package:startale_mobile/features/child_mode/presentation/widgets/pin_keypad.dart';

class MockParentalPinRepository extends Mock implements ParentalPinRepository {}
class MockPreferencesService extends Mock implements PreferencesService {}
class MockAuthCubit extends Mock implements AuthCubit {}

void main() {
  late MockParentalPinRepository mockRepo;
  late MockPreferencesService mockPrefs;
  late MockAuthCubit mockAuthCubit;
  late ChildModeCubit cubit;

  final tUser = UserEntity(
    id: 'user-001',
    email: 'padre@talestar.app',
    displayName: 'Padre Demo',
    pinConfigured: true,
    createdAt: DateTime.parse('2026-10-31T12:00:00Z'),
  );

  setUp(() {
    mockRepo = MockParentalPinRepository();
    mockPrefs = MockPreferencesService();
    mockAuthCubit = MockAuthCubit();

    when(() => mockPrefs.isChildModeActive).thenReturn(false);
    when(() => mockPrefs.saveChildModeSession(
          contentType: any(named: 'contentType'),
          contentId: any(named: 'contentId'),
          title: any(named: 'title'),
          routeContext: any(named: 'routeContext'),
          userId: any(named: 'userId'),
        )).thenAnswer((_) async {});
    when(() => mockPrefs.clearChildModeSession()).thenAnswer((_) async {});
    when(() => mockAuthCubit.state).thenReturn(Authenticated(tUser));
    when(() => mockAuthCubit.stream).thenAnswer((_) => Stream.value(Authenticated(tUser)));

    cubit = ChildModeCubit(
      parentalPinRepository: mockRepo,
      preferencesService: mockPrefs,
      authCubit: mockAuthCubit,
    );
  });

  tearDown(() {
    cubit.close();
  });

  Widget buildTestWidget() {
    return MaterialApp(
      home: Scaffold(
        body: PinValidationDialog(cubit: cubit),
      ),
    );
  }

  group('PinValidationDialog Widget Tests', () {
    testWidgets('renderiza cabecera, indicadores y teclado numérico', (tester) async {
      await tester.pumpWidget(buildTestWidget());

      expect(find.text('PIN Parental'), findsOneWidget);
      expect(find.text('Ingresa el PIN de 4 dígitos para salir de Modo Niño.'), findsOneWidget);
      expect(find.byType(PinKeypad), findsOneWidget);
      expect(find.byKey(const Key('pin_keypad_1')), findsOneWidget);
      expect(find.byKey(const Key('pin_keypad_backspace')), findsOneWidget);
      expect(find.byKey(const Key('pin_validation_cancel_button')), findsOneWidget);
      expect(find.byKey(const Key('pin_validation_back_to_child_mode')), findsOneWidget);
    });

    testWidgets('pulsar dígitos en el teclado acumula y enviar 4 dígitos valida con el cubit', (tester) async {
      when(() => mockRepo.validateParentalPin(pin: '1234'))
          .thenAnswer((_) async => true);

      // Activa modo niño primero para poder desbloquear
      await cubit.activate(
        contentType: ChildModeContentType.story,
        contentId: 'story-1',
        contentTitle: 'Cuento',
        routeContext: '/stories/story-1/read',
      );
      cubit.requestExit();

      await tester.pumpWidget(buildTestWidget());

      // Pulsa 1, 2, 3, 4
      await tester.tap(find.byKey(const Key('pin_keypad_1')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('pin_keypad_2')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('pin_keypad_3')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('pin_keypad_4')));
      await tester.pumpAndSettle();

      verify(() => mockRepo.validateParentalPin(pin: '1234')).called(1);
    });

    testWidgets('muestra mensaje de error cuando el PIN es incorrecto', (tester) async {
      when(() => mockRepo.validateParentalPin(pin: '0000'))
          .thenAnswer((_) async => false);

      await cubit.activate(
        contentType: ChildModeContentType.story,
        contentId: 'story-1',
        contentTitle: 'Cuento',
        routeContext: '/stories/story-1/read',
      );
      cubit.requestExit();

      await tester.pumpWidget(buildTestWidget());

      // Ingresa 0, 0, 0, 0
      for (int i = 0; i < 4; i++) {
        await tester.tap(find.byKey(const Key('pin_keypad_0')));
        await tester.pump();
      }
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('pin_validation_error_banner')), findsOneWidget);
      expect(find.textContaining('El PIN ingresado es incorrecto'), findsOneWidget);
    });

    testWidgets('botón cerrar o cancelar cancela la salida y mantiene Modo Niño', (tester) async {
      await cubit.activate(
        contentType: ChildModeContentType.story,
        contentId: 'story-1',
        contentTitle: 'Cuento',
        routeContext: '/stories/story-1/read',
      );
      cubit.requestExit();

      await tester.pumpWidget(buildTestWidget());

      await tester.tap(find.byKey(const Key('pin_validation_back_to_child_mode')));
      await tester.pumpAndSettle();

      expect(cubit.state, isA<ChildModeActive>());
    });
  });
}
