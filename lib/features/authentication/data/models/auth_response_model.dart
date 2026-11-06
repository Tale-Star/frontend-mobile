import 'package:equatable/equatable.dart';
import 'user_model.dart';

/// DTO para la respuesta de autenticación del backend (`AuthResponse`).
class AuthResponseModel extends Equatable {
  final String accessToken;
  final String tokenType;
  final UserModel user;

  const AuthResponseModel({
    required this.accessToken,
    this.tokenType = 'bearer',
    required this.user,
  });

  factory AuthResponseModel.fromJson(Map<String, dynamic> json) {
    return AuthResponseModel(
      accessToken: json['access_token'] as String,
      tokenType: (json['token_type'] as String?) ?? 'bearer',
      user: UserModel.fromJson(json['user'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'access_token': accessToken,
      'token_type': tokenType,
      'user': user.toJson(),
    };
  }

  @override
  List<Object?> get props => [accessToken, tokenType, user];
}

