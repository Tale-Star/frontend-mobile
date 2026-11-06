import 'package:equatable/equatable.dart';

/// DTO para la petición de inicio de sesión (`LoginRequest`).
class LoginRequestModel extends Equatable {
  final String email;
  final String password;

  const LoginRequestModel({
    required this.email,
    required this.password,
  });

  Map<String, dynamic> toJson() {
    return {
      'email': email.trim(),
      'password': password,
    };
  }

  factory LoginRequestModel.fromJson(Map<String, dynamic> json) {
    return LoginRequestModel(
      email: json['email'] as String,
      password: json['password'] as String,
    );
  }

  @override
  List<Object?> get props => [email, password];
}

