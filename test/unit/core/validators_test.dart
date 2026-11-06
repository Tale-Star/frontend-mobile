import 'package:flutter_test/flutter_test.dart';
import 'package:startale_mobile/shared/utils/validators.dart';

void main() {
  group('Validators', () {
    group('validateEmail', () {
      test('debe retornar error si el correo es nulo o vacío', () {
        expect(Validators.validateEmail(null), isNotNull);
        expect(Validators.validateEmail(''), isNotNull);
        expect(Validators.validateEmail('   '), isNotNull);
      });

      test('debe retornar error si el formato es inválido', () {
        expect(Validators.validateEmail('correo_sin_arroba.com'), isNotNull);
        expect(Validators.validateEmail('test@'), isNotNull);
        expect(Validators.validateEmail('@dominio.com'), isNotNull);
      });

      test('debe retornar null cuando el correo es válido', () {
        expect(Validators.validateEmail('padre@talestar.com'), isNull);
        expect(Validators.validateEmail('docente.123@escuela.edu'), isNull);
      });
    });

    group('validateDisplayName', () {
      test('debe retornar error si el nombre está vacío', () {
        expect(Validators.validateDisplayName(null), isNotNull);
        expect(Validators.validateDisplayName(''), isNotNull);
      });

      test('debe retornar error si supera 100 caracteres', () {
        final longName = 'A' * 101;
        expect(Validators.validateDisplayName(longName), isNotNull);
      });

      test('debe retornar null cuando el nombre es válido', () {
        expect(Validators.validateDisplayName('Familia Pérez'), isNull);
        expect(Validators.validateDisplayName('Profa. Claudia'), isNull);
      });
    });

    group('validatePassword', () {
      test('debe retornar error si la contraseña está vacía', () {
        expect(Validators.validatePassword(null), isNotNull);
        expect(Validators.validatePassword(''), isNotNull);
      });

      test('debe retornar error si tiene menos de 6 caracteres', () {
        expect(Validators.validatePassword('12345'), isNotNull);
      });

      test('debe retornar null con 6 o más caracteres', () {
        expect(Validators.validatePassword('secreto123'), isNull);
      });
    });

    group('validateConfirmPassword', () {
      test('debe retornar error si la confirmación no coincide', () {
        expect(
          Validators.validateConfirmPassword('password123', 'otra_cosa'),
          isNotNull,
        );
      });

      test('debe retornar null si ambas coinciden', () {
        expect(
          Validators.validateConfirmPassword('password123', 'password123'),
          isNull,
        );
      });
    });

    group('validatePin', () {
      test('debe retornar error si no son exactamente 4 dígitos', () {
        expect(Validators.validatePin(null), isNotNull);
        expect(Validators.validatePin(''), isNotNull);
        expect(Validators.validatePin('12'), isNotNull);
        expect(Validators.validatePin('12345'), isNotNull);
        expect(Validators.validatePin('12a4'), isNotNull);
      });

      test('debe retornar null con 4 dígitos numéricos', () {
        expect(Validators.validatePin('1234'), isNull);
        expect(Validators.validatePin('0000'), isNull);
      });
    });
  });
}
