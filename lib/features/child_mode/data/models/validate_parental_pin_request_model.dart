/// Modelo DTO para la solicitud de validación de PIN parental (`POST /api/v1/auth/parental-pin/validate`).
class ValidateParentalPinRequestModel {
  final String pin;

  const ValidateParentalPinRequestModel({
    required this.pin,
  });

  Map<String, dynamic> toJson() {
    return {
      'pin': pin,
    };
  }
}

