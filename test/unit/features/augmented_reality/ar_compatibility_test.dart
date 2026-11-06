import 'package:flutter_test/flutter_test.dart';
import 'package:startale_mobile/features/augmented_reality/domain/entities/ar_compatibility.dart';
import 'package:startale_mobile/features/augmented_reality/domain/entities/ar_plane.dart';

void main() {
  group('ArCoreAvailability Enum', () {
    test('mapea cadenas nativas a valores normalizados de ArCoreAvailability', () {
      expect(
        ArCoreAvailability.fromNativeString('SUPPORTED_INSTALLED'),
        ArCoreAvailability.supportedInstalled,
      );
      expect(
        ArCoreAvailability.fromNativeString('SUPPORTED_NOT_INSTALLED'),
        ArCoreAvailability.supportedNotInstalled,
      );
      expect(
        ArCoreAvailability.fromNativeString('SUPPORTED_APK_TOO_OLD'),
        ArCoreAvailability.supportedApkTooOld,
      );
      expect(
        ArCoreAvailability.fromNativeString('UNSUPPORTED_DEVICE_NOT_CAPABLE'),
        ArCoreAvailability.unsupportedDeviceNotCapable,
      );
      expect(
        ArCoreAvailability.fromNativeString('UNKNOWN_CHECKING'),
        ArCoreAvailability.unknownChecking,
      );
      expect(
        ArCoreAvailability.fromNativeString('OTRO_VALOR'),
        ArCoreAvailability.unknownError,
      );
      expect(
        ArCoreAvailability.fromNativeString(null),
        ArCoreAvailability.unknownError,
      );
    });
  });

  group('ArCompatibilityInfo Entity', () {
    test('soporta comparación por igualdad mediante Equatable', () {
      const info1 = ArCompatibilityInfo(
        isSupported: false,
        availability: ArCoreAvailability.unsupportedDeviceNotCapable,
        deviceModel: '23129RA5FL',
        userMessage: 'No compatible',
      );

      const info2 = ArCompatibilityInfo(
        isSupported: false,
        availability: ArCoreAvailability.unsupportedDeviceNotCapable,
        deviceModel: '23129RA5FL',
        userMessage: 'No compatible',
      );

      expect(info1, equals(info2));
    });
  });

  group('ArPlane Entity', () {
    test('soporta comparación por igualdad y copyWith', () {
      const plane = ArPlane(
        id: 'plane-1',
        type: ArPlaneType.horizontalUpward,
        extentX: 1.5,
        extentZ: 1.0,
      );

      final updated = plane.copyWith(
        isSelected: true,
        extentX: 2.0,
      );

      expect(updated.id, 'plane-1');
      expect(updated.isSelected, isTrue);
      expect(updated.extentX, 2.0);
      expect(plane.isSelected, isFalse);
    });
  });
}

