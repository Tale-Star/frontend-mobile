import 'package:equatable/equatable.dart';

/// Entidad pura del dominio que representa al usuario autenticado en Tale Star.
class UserEntity extends Equatable {
  final String id;
  final String email;
  final String displayName;
  final bool pinConfigured;
  final DateTime createdAt;

  const UserEntity({
    required this.id,
    required this.email,
    required this.displayName,
    required this.pinConfigured,
    required this.createdAt,
  });

  UserEntity copyWith({
    String? id,
    String? email,
    String? displayName,
    bool? pinConfigured,
    DateTime? createdAt,
  }) {
    return UserEntity(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      pinConfigured: pinConfigured ?? this.pinConfigured,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [id, email, displayName, pinConfigured, createdAt];
}

