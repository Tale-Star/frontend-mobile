import 'package:flutter_test/flutter_test.dart';
import 'package:startale_mobile/features/augmented_reality/data/services/mock_ar_service.dart';
import 'package:startale_mobile/features/augmented_reality/domain/entities/ar_compatibility.dart';

void main() {
  group('MockArService', () {
    test('por defecto es compatible para permitir pruebas de demostración sin bloquear', () async {
      final service = MockArService();

      final compatibility = await service.checkCompatibility();

      expect(compatibility.isSupported, isTrue);
      expect(compatibility.availability, equals(ArCoreAvailability.supportedInstalled));
      expect(compatibility.deviceModel, contains('Simulado'));
      expect(compatibility.userMessage, contains('compatible'));
    });

    test('permite configurar compatibilidad falsa para validar diálogo de degradación', () async {
      final service = MockArService(
        isDeviceSupported: false,
        deviceModel: 'Dispositivo Incompatible X',
      );

      final compatibility = await service.checkCompatibility();

      expect(compatibility.isSupported, isFalse);
      expect(compatibility.availability, equals(ArCoreAvailability.unsupportedDeviceNotCapable));
      expect(compatibility.deviceModel, equals('Dispositivo Incompatible X'));
      expect(compatibility.userMessage, contains('Dispositivo Incompatible X'));
    });

    test('inicia sesión y emite planos simulados', () async {
      final service = MockArService(
        isDeviceSupported: true,
        simulatePlaneDetection: true,
      );

      final planesFuture = service.planesStream.first;
      await service.initializeSession();

      final planes = await planesFuture;
      expect(planes, isNotEmpty);
      expect(planes.first.id, equals('plane-mesa-01'));
    });
  });
}

