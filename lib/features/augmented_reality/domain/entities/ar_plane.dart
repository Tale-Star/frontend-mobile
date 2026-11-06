import 'package:equatable/equatable.dart';

/// Tipo de superficie plana detectada en el espacio tridimensional.
enum ArPlaneType {
  horizontalUpward,
  horizontalDownward,
  vertical,
  unknown,
}

/// Representación en el dominio de un plano o superficie detectada por ARCore.
class ArPlane extends Equatable {
  final String id;
  final ArPlaneType type;
  final double extentX;
  final double extentZ;
  final double centerPoseX;
  final double centerPoseY;
  final double centerPoseZ;
  final bool isSelected;

  const ArPlane({
    required this.id,
    this.type = ArPlaneType.horizontalUpward,
    this.extentX = 1.0,
    this.extentZ = 1.0,
    this.centerPoseX = 0.0,
    this.centerPoseY = 0.0,
    this.centerPoseZ = -1.0,
    this.isSelected = false,
  });

  ArPlane copyWith({
    String? id,
    ArPlaneType? type,
    double? extentX,
    double? extentZ,
    double? centerPoseX,
    double? centerPoseY,
    double? centerPoseZ,
    bool? isSelected,
  }) {
    return ArPlane(
      id: id ?? this.id,
      type: type ?? this.type,
      extentX: extentX ?? this.extentX,
      extentZ: extentZ ?? this.extentZ,
      centerPoseX: centerPoseX ?? this.centerPoseX,
      centerPoseY: centerPoseY ?? this.centerPoseY,
      centerPoseZ: centerPoseZ ?? this.centerPoseZ,
      isSelected: isSelected ?? this.isSelected,
    );
  }

  @override
  List<Object?> get props => [
        id,
        type,
        extentX,
        extentZ,
        centerPoseX,
        centerPoseY,
        centerPoseZ,
        isSelected,
      ];
}

