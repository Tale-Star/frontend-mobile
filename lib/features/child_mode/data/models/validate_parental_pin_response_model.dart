/// Modelo DTO para la respuesta de validación de PIN parental (`POST /api/v1/auth/parental-pin/validate`).
class ValidateParentalPinResponseModel {
  final bool valid;

  const ValidateParentalPinResponseModel({
    required this.valid,
  });

  factory ValidateParentalPinResponseModel.fromJson(Map<String, dynamic> json) {
    return ValidateParentalPinResponseModel(
      valid: (json['valid'] as bool?) ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'valid': valid,
    };
  }
}

