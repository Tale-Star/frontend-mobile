import 'package:flutter_test/flutter_test.dart';
import 'package:startale_mobile/shared/utils/text_helpers.dart';

void main() {
  group('TextHelpers', () {
    test('formatContentType traduce correctamente a español amigable', () {
      expect(TextHelpers.formatContentType('story'), 'Cuento');
      expect(TextHelpers.formatContentType('image'), 'Ilustración');
      expect(TextHelpers.formatContentType('music'), 'Música');
      expect(TextHelpers.formatContentType('unknown'), 'Creación');
    });

    test('formatPageCounter genera el contador oficial de páginas', () {
      expect(TextHelpers.formatPageCounter(1, 10), 'Página 1 de 10');
      expect(TextHelpers.formatPageCounter(5, 5), 'Página 5 de 5');
    });

    test('timeGreeting retorna un saludo válido según la hora', () {
      final greeting = TextHelpers.timeGreeting();
      expect(
        greeting == 'Buenos días' ||
            greeting == 'Buenas tardes' ||
            greeting == 'Buenas noches',
        isTrue,
      );
    });
  });
}
