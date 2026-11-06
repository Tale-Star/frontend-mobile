import 'package:equatable/equatable.dart';

/// DTO para la petición de registro (`RegisterRequest`).
class RegisterRequestModel extends Equatable {
  final String email;
  final String displayName;
  final String password;
  final String? parentalPin;

  const RegisterRequestModel({
    required this.email,
    required this.displayName,
    required this.password,
    this.parentalPin,
  });

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{
      'email': email.trim(),
      'display_name': displayName.trim(),
      'password': password,
    };
    if (parentalPin != null && parentalPin!.trim().isNotEmpty) {
      data['parental_pin'] = parentalPin!.trim();
    }
    return data;
  }

  factory RegisterRequestModel.fromJson(Map<String, dynamic> json) {
    return RegisterRequestModel(
      email: json['email'] as String,
      displayName: json['display_name'] as String,
      password: json['password'] as String,
      parentalPin: json['parental_pin'] as String?,
    );
  }

  @override
  List<Object?> get props => [email, displayName, password, parentalPin];
}

