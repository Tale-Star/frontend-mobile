import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:startale_mobile/core/error/failures.dart';
import 'package:startale_mobile/features/authentication/domain/entities/user_entity.dart';
import 'package:startale_mobile/features/authentication/domain/repositories/auth_repository.dart';
import 'package:startale_mobile/features/authentication/presentation/cubit/auth_cubit.dart';
import 'package:startale_mobile/features/profile/presentation/cubit/profile_cubit.dart';
import 'package:startale_mobile/features/profile/presentation/cubit/profile_state.dart';

class MockAuthRepository extends Mock implements AuthRepository {}
class MockAuthCubit extends Mock implements AuthCubit {}

void main() {
  late MockAuthRepository mockAuthRepository;
  late MockAuthCubit mockAuthCubit;
  late ProfileCubit profileCubit;

  final tUser = UserEntity(
    id: 'user-id-001',
    email: 'familia@talestar.com',
    displayName: 'Familia Morales',
    pinConfigured: true,
    createdAt: DateTime.parse('2026-10-10T15:00:00Z'),
  );

  setUp(() {
    mockAuthRepository = MockAuthRepository();
    mockAuthCubit = MockAuthCubit();
    profileCubit = ProfileCubit(
      authRepository: mockAuthRepository,
      authCubit: mockAuthCubit,
    );
  });

  tearDown(() {
    profileCubit.close();
  });

  group('ProfileCubit Tests', () {
    test('estado inicial es ProfileInitial', () {
      expect(profileCubit.state, const ProfileInitial());
    });

    test('loadProfile con initialUser emite ProfileLoaded y actualiza con API', () async {
      when(() => mockAuthRepository.getProfile()).thenAnswer((_) async => tUser);

      final states = <ProfileState>[];
      profileCubit.stream.listen(states.add);

      await profileCubit.loadProfile(initialUser: tUser);

      expect(profileCubit.state, ProfileLoaded(user: tUser));
      verify(() => mockAuthCubit.updateUserPinConfigured(true)).called(1);
    });

    test('loadProfile sin initialUser emite ProfileLoading y luego ProfileLoaded', () async {
      when(() => mockAuthRepository.getProfile()).thenAnswer((_) async => tUser);

      final expectedStates = [
        const ProfileLoading(),
        ProfileLoaded(user: tUser),
      ];

      expectLater(profileCubit.stream, emitsInOrder(expectedStates));

      await profileCubit.loadProfile();
    });

    test('loadProfile emite ProfileError ante NetworkFailure', () async {
      when(() => mockAuthRepository.getProfile())
          .thenThrow(const NetworkFailure(message: 'Error de red'));

      final expectedStates = [
        const ProfileLoading(),
        const ProfileError(message: 'Error de red', isNetworkError: true),
      ];

      expectLater(profileCubit.stream, emitsInOrder(expectedStates));

      await profileCubit.loadProfile();
    });

    test('loadProfile emite ProfileError ante ServerFailure', () async {
      when(() => mockAuthRepository.getProfile())
          .thenThrow(const ServerFailure(message: 'Error 500'));

      final expectedStates = [
        const ProfileLoading(),
        const ProfileError(message: 'Error 500', isNetworkError: false),
      ];

      expectLater(profileCubit.stream, emitsInOrder(expectedStates));

      await profileCubit.loadProfile();
    });

    test('refresh emite ProfileLoading y luego ProfileLoaded', () async {
      when(() => mockAuthRepository.getProfile()).thenAnswer((_) async => tUser);

      final expectedStates = [
        const ProfileLoading(),
        ProfileLoaded(user: tUser),
      ];

      expectLater(profileCubit.stream, emitsInOrder(expectedStates));

      await profileCubit.refresh();
    });

    test('updatePinConfigured actualiza el estado local y notifica a AuthCubit', () async {
      when(() => mockAuthRepository.getProfile()).thenAnswer((_) async => tUser);
      await profileCubit.loadProfile();

      profileCubit.updatePinConfigured(false);

      expect(profileCubit.state, ProfileLoaded(user: tUser.copyWith(pinConfigured: false)));
      verify(() => mockAuthCubit.updateUserPinConfigured(false)).called(1);
    });
  });
}

