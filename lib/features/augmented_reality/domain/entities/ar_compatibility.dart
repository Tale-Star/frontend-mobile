import 'package:equatable/equatable.dart';

/// Estados de disponibilidad de Google Play Services for AR (ARCore).
enum ArCoreAvailability {
  supportedInstalled,
  supportedNotInstalled,
  supportedApkTooOld,
  unsupportedDeviceNotCapable,
  unknownChecking,
  unknownError;

  static ArCoreAvailability fromNativeString(String? value) {
    switch (value?.toUpperCase().trim()) {
      case 'SUPPORTED_INSTALLED':
        return ArCoreAvailability.supportedInstalled;
      case 'SUPPORTED_NOT_INSTALLED':
        return ArCoreAvailability.supportedNotInstalled;
      case 'SUPPORTED_APK_TOO_OLD':
        return ArCoreAvailability.supportedApkTooOld;
      case 'UNSUPPORTED_DEVICE_NOT_CAPABLE':
        return ArCoreAvailability.unsupportedDeviceNotCapable;
      case 'UNKNOWN_CHECKING':
        return ArCoreAvailability.unknownChecking;
      default:
        return ArCoreAvailability.unknownError;
    }
  }
}

/// Información diagnóstica de compatibilidad del dispositivo con Realidad Aumentada.
class ArCompatibilityInfo extends Equatable {
  final bool isSupported;
  final ArCoreAvailability availability;
  final String deviceModel;
  final String userMessage;

  const ArCompatibilityInfo({
    required this.isSupported,
    required this.availability,
    required this.deviceModel,
    required this.userMessage,
  });

  @override
  List<Object?> get props => [
        isSupported,
        availability,
        deviceModel,
        userMessage,
      ];
}

