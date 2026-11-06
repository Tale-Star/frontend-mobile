import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:startale_mobile/core/error/failures.dart';
import 'package:startale_mobile/core/storage/preferences_service.dart';
import 'package:startale_mobile/features/authentication/domain/entities/user_entity.dart';
import 'package:startale_mobile/features/authentication/presentation/cubit/auth_cubit.dart';
import 'package:startale_mobile/features/authentication/presentation/cubit/auth_state.dart';
import 'package:startale_mobile/features/child_mode/domain/entities/child_mode_content.dart';
import 'package:startale_mobile/features/child_mode/domain/repositories/parental_pin_repository.dart';
import 'package:startale_mobile/features/child_mode/presentation/cubit/child_mode_cubit.dart';
import 'package:startale_mobile/features/child_mode/presentation/cubit/child_mode_state.dart';

class MockParentalPinRepository extends Mock implements ParentalPinRepository {}
class MockPreferencesService extends Mock implements PreferencesService {}
class MockAuthCubit extends Mock implements AuthCubit {}

void main() {
  late MockParentalPinRepository mockRepo;
  late MockPreferencesService mockPrefs;
  late MockAuthCubit mockAuthCubit;
  late ChildModeCubit cubit;

  final tUserWithPin = UserEntity(
    id: 'user-001',
    email: 'padre@talestar.app',
    displayName: 'Padre Tale Star',
    pinConfigured: true,
    createdAt: DateTime.parse('2026-10-31T12:00:00Z'),
  );

  final tUserWithoutPin = tUserWithPin.copyWith(pinConfigured: false);

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

    cubit = ChildModeCubit(
      parentalPinRepository: mockRepo,
      preferencesService: mockPrefs,
      authCubit: mockAuthCubit,
    );
  });

  tearDown(() {
    cubit.close();
  });

  test('estado inicial es ChildModeInactive', () {
    expect(cubit.state, const ChildModeInactive());
  });

  group('ChildModeCubit - activate', () {
    test('retorna false si el usuario no está autenticado', () async {
      when(() => mockAuthCubit.state).thenReturn(const Unauthenticated());

      final result = await cubit.activate(
        contentType: ChildModeContentType.story,
        contentId: 'story-1',
        contentTitle: 'Cuento de prueba',
        routeContext: '/stories/story-1/read',
      );

      expect(result, isFalse);
      expect(cubit.state, const ChildModeInactive());
    });

    test('retorna false si el usuario autenticado no tiene PIN configurado', () async {
      when(() => mockAuthCubit.state).thenReturn(Authenticated(tUserWithoutPin));

      final result = await cubit.activate(
        contentType: ChildModeContentType.story,
        contentId: 'story-1',
        contentTitle: 'Cuento de prueba',
        routeContext: '/stories/story-1/read',
      );

      expect(result, isFalse);
      expect(cubit.state, const ChildModeInactive());
    });

    test('activa el modo niño exitosamente cuando el usuario tiene PIN', () async {
      when(() => mockAuthCubit.state).thenReturn(Authenticated(tUserWithPin));

      final result = await cubit.activate(
        contentType: ChildModeContentType.story,
        contentId: 'story-1',
        contentTitle: 'Cuento de prueba',
        routeContext: '/stories/story-1/read',
      );

      expect(result, isTrue);
      expect(cubit.state, isA<ChildModeActive>());
      final active = cubit.state as ChildModeActive;
      expect(active.content.contentId, 'story-1');
      expect(active.userId, 'user-001');

      verify(() => mockPrefs.saveChildModeSession(
            contentType: 'story',
            contentId: 'story-1',
            title: 'Cuento de prueba',
            routeContext: '/stories/story-1/read',
            userId: 'user-001',
          )).called(1);
    });
  });

  group('ChildModeCubit - requestExit y cancelExit', () {
    setUp(() async {
      when(() => mockAuthCubit.state).thenReturn(Authenticated(tUserWithPin));
      await cubit.activate(
        contentType: ChildModeContentType.story,
        contentId: 'story-1',
        contentTitle: 'Cuento',
        routeContext: '/stories/story-1/read',
      );
    });

    test('requestExit transiciona a ChildModeUnlocking', () {
      cubit.requestExit();
      expect(cubit.state, isA<ChildModeUnlocking>());
    });

    test('cancelExit regresa a ChildModeActive', () {
      cubit.requestExit();
      expect(cubit.state, isA<ChildModeUnlocking>());

      cubit.cancelExit();
      expect(cubit.state, isA<ChildModeActive>());
    });
  });

  group('ChildModeCubit - validatePinAndExit', () {
    setUp(() async {
      when(() => mockAuthCubit.state).thenReturn(Authenticated(tUserWithPin));
      await cubit.activate(
        contentType: ChildModeContentType.story,
        contentId: 'story-1',
        contentTitle: 'Cuento',
        routeContext: '/stories/story-1/read',
      );
      cubit.requestExit();
    });

    test('desactiva Modo Niño cuando el PIN es válido', () async {
      when(() => mockRepo.validateParentalPin(pin: '1234'))
          .thenAnswer((_) async => true);

      final result = await cubit.validatePinAndExit('1234');

      expect(result, isTrue);
      expect(cubit.state, const ChildModeInactive());
      verify(() => mockPrefs.clearChildModeSession()).called(1);
    });

    test('permanece activo y emite ValidationError cuando el PIN es incorrecto', () async {
      when(() => mockRepo.validateParentalPin(pin: '0000'))
          .thenAnswer((_) async => false);

      final result = await cubit.validatePinAndExit('0000');

      expect(result, isFalse);
      expect(cubit.state, isA<ChildModeValidationError>());
      final err = cubit.state as ChildModeValidationError;
      expect(err.failedAttempts, 1);
      expect(err.attemptsRemaining, 2);
      expect(err.isLockedOut, isFalse);
    });

    test('bloquea por 30s tras 3 intentos fallidos', () async {
      when(() => mockRepo.validateParentalPin(pin: '0000'))
          .thenAnswer((_) async => false);

      await cubit.validatePinAndExit('0000'); // intento 1
      await cubit.validatePinAndExit('0000'); // intento 2
      final result = await cubit.validatePinAndExit('0000'); // intento 3 -> lockout

      expect(result, isFalse);
      expect(cubit.state, isA<ChildModeValidationError>());
      final err = cubit.state as ChildModeValidationError;
      expect(err.isLockedOut, isTrue);
      expect(err.lockoutSecondsRemaining, 30);
      expect(cubit.isLockedOut, isTrue);
    });

    test('ante fallo de red, permanece activo y emite ValidationError constructivo', () async {
      when(() => mockRepo.validateParentalPin(pin: '1234'))
          .thenThrow(const NetworkFailure(message: 'Sin internet'));

      final result = await cubit.validatePinAndExit('1234');

      expect(result, isFalse);
      expect(cubit.state, isA<ChildModeValidationError>());
      final err = cubit.state as ChildModeValidationError;
      expect(err.errorMessage, 'Sin internet');
    });
  });

  group('ChildModeCubit - restoreSession', () {
    test('restaura ChildModeActive si las preferencias tenían la sesión activa', () async {
      when(() => mockPrefs.isChildModeActive).thenReturn(true);
      when(() => mockPrefs.childModeContentType).thenReturn('story');
      when(() => mockPrefs.childModeContentId).thenReturn('story-persisted-1');
      when(() => mockPrefs.childModeContentTitle).thenReturn('Cuento Persistido');
      when(() => mockPrefs.childModeRouteContext).thenReturn('/stories/story-persisted-1/read');
      when(() => mockPrefs.childModeUserId).thenReturn('user-001');

      await cubit.restoreSession();

      expect(cubit.state, isA<ChildModeActive>());
      final active = cubit.state as ChildModeActive;
      expect(active.content.contentId, 'story-persisted-1');
      expect(active.content.title, 'Cuento Persistido');
      expect(active.userId, 'user-001');
    });

    test('emite ChildModeInactive si no había sesión guardada', () async {
      when(() => mockPrefs.isChildModeActive).thenReturn(false);

      await cubit.restoreSession();

      expect(cubit.state, const ChildModeInactive());
    });
  });
}
