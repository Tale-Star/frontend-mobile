import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:startale_mobile/core/error/failures.dart';
import 'package:startale_mobile/features/authentication/domain/entities/user_entity.dart';
import 'package:startale_mobile/features/authentication/domain/repositories/auth_repository.dart';
import 'package:startale_mobile/features/authentication/presentation/cubit/auth_cubit.dart';
import 'package:startale_mobile/features/authentication/presentation/cubit/auth_state.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockAuthRepository mockRepository;
  late AuthCubit cubit;

  setUp(() {
    mockRepository = MockAuthRepository();
    cubit = AuthCubit(authRepository: mockRepository);
  });

  tearDown(() {
    cubit.close();
  });

  final tUser = UserEntity(
    id: 'user-id-001',
    email: 'docente@talestar.app',
    displayName: 'Profe Lucía',
    pinConfigured: true,
    createdAt: DateTime.parse('2026-10-31T09:00:00Z'),
  );

  test('estado inicial debe ser AuthInitial', () {
    expect(cubit.state, equals(const AuthInitial()));
  });

  group('checkAuthStatus', () {
    blocTest<AuthCubit, AuthState>(
      'emite [AuthLoading, Authenticated] cuando existe sesión previa válida',
      build: () {
        when(() => mockRepository.getCurrentUser()).thenAnswer((_) async => tUser);
        return cubit;
      },
      act: (c) => c.checkAuthStatus(),
      expect: () => [
        const AuthLoading(),
        Authenticated(tUser),
      ],
    );

    blocTest<AuthCubit, AuthState>(
      'emite [AuthLoading, Unauthenticated] cuando no hay sesión activa',
      build: () {
        when(() => mockRepository.getCurrentUser()).thenAnswer((_) async => null);
        return cubit;
      },
      act: (c) => c.checkAuthStatus(),
      expect: () => [
        const AuthLoading(),
        const Unauthenticated(),
      ],
    );
  });

  group('login', () {
    blocTest<AuthCubit, AuthState>(
      'emite [AuthLoading, Authenticated] cuando el inicio de sesión es exitoso',
      build: () {
        when(() => mockRepository.login(
              email: 'docente@talestar.app',
              password: 'SecretPassword123',
              rememberMe: true,
            )).thenAnswer((_) async => tUser);
        return cubit;
      },
      act: (c) => c.login(
        email: 'docente@talestar.app',
        password: 'SecretPassword123',
        rememberMe: true,
      ),
      expect: () => [
        const AuthLoading(),
        Authenticated(tUser),
      ],
    );

    blocTest<AuthCubit, AuthState>(
      'emite [AuthLoading, AuthError] cuando las credenciales son incorrectas',
      build: () {
        when(() => mockRepository.login(
              email: any(named: 'email'),
              password: any(named: 'password'),
              rememberMe: any(named: 'rememberMe'),
            )).thenThrow(const AuthFailure(message: 'Credenciales inválidas'));
        return cubit;
      },
      act: (c) => c.login(
        email: 'wrong@test.com',
        password: 'wrong',
        rememberMe: false,
      ),
      expect: () => [
        const AuthLoading(),
        const AuthError('Credenciales inválidas'),
      ],
    );
  });

  group('register', () {
    blocTest<AuthCubit, AuthState>(
      'emite [AuthLoading, Authenticated] cuando el registro es exitoso',
      build: () {
        when(() => mockRepository.register(
              email: 'nuevo@talestar.app',
              displayName: 'Tutor Juan',
              password: 'Password123!',
              parentalPin: '9876',
              rememberMe: true,
            )).thenAnswer((_) async => tUser);
        return cubit;
      },
      act: (c) => c.register(
        email: 'nuevo@talestar.app',
        displayName: 'Tutor Juan',
        password: 'Password123!',
        parentalPin: '9876',
        rememberMe: true,
      ),
      expect: () => [
        const AuthLoading(),
        Authenticated(tUser),
      ],
    );

    blocTest<AuthCubit, AuthState>(
      'emite [AuthLoading, AuthError] cuando el correo ya está registrado',
      build: () {
        when(() => mockRepository.register(
              email: any(named: 'email'),
              displayName: any(named: 'displayName'),
              password: any(named: 'password'),
              parentalPin: any(named: 'parentalPin'),
              rememberMe: any(named: 'rememberMe'),
            )).thenThrow(const ServerFailure(message: 'El correo ya está registrado'));
        return cubit;
      },
      act: (c) => c.register(
        email: 'repetido@talestar.app',
        displayName: 'Tutor',
        password: 'pass',
        rememberMe: true,
      ),
      expect: () => [
        const AuthLoading(),
        const AuthError('El correo ya está registrado'),
      ],
    );
  });

  group('logout', () {
    blocTest<AuthCubit, AuthState>(
      'emite [AuthLoading, Unauthenticated] al cerrar sesión',
      build: () {
        when(() => mockRepository.logout()).thenAnswer((_) async {});
        return cubit;
      },
      act: (c) => c.logout(),
      expect: () => [
        const AuthLoading(),
        const Unauthenticated(),
      ],
    );
  });

  group('requestPasswordReset (US04)', () {
    blocTest<AuthCubit, AuthState>(
      'emite [AuthLoading, PasswordResetSent] al solicitar reseteo con éxito',
      build: () {
        when(() => mockRepository.requestPasswordReset(email: any(named: 'email')))
            .thenAnswer((_) async {});
        return cubit;
      },
      act: (c) => c.requestPasswordReset(email: 'docente@talestar.app'),
      expect: () => [
        const AuthLoading(),
        const PasswordResetSent('docente@talestar.app'),
      ],
    );
  });
}

