/// Modelo DTO para la solicitud de configuración o cambio de PIN parental (`PUT /api/v1/auth/parental-pin`).
class SetParentalPinRequestModel {
  final String currentPassword;
  final String pin;

  const SetParentalPinRequestModel({
    required this.currentPassword,
    required this.pin,
  });

  Map<String, dynamic> toJson() {
    return {
      'current_password': currentPassword,
      'pin': pin,
    };
  }
}

