import 'package:flutter_test/flutter_test.dart';
import 'package:startale_mobile/features/child_mode/data/models/set_parental_pin_request_model.dart';
import 'package:startale_mobile/features/child_mode/data/models/validate_parental_pin_request_model.dart';
import 'package:startale_mobile/features/child_mode/data/models/validate_parental_pin_response_model.dart';
import 'package:startale_mobile/features/child_mode/domain/entities/child_mode_content.dart';

void main() {
  group('Child Mode Models & Entities Tests', () {
    test('SetParentalPinRequestModel serializa correctamente a JSON', () {
      const model = SetParentalPinRequestModel(
        currentPassword: 'secretPassword123',
        pin: '5678',
      );

      final json = model.toJson();

      expect(json, {
        'current_password': 'secretPassword123',
        'pin': '5678',
      });
    });

    test('ValidateParentalPinRequestModel serializa correctamente a JSON', () {
      const model = ValidateParentalPinRequestModel(pin: '4321');

      final json = model.toJson();

      expect(json, {
        'pin': '4321',
      });
    });

    test('ValidateParentalPinResponseModel deserializa valid: true y false', () {
      final validTrue = ValidateParentalPinResponseModel.fromJson({'valid': true});
      final validFalse = ValidateParentalPinResponseModel.fromJson({'valid': false});
      final validNull = ValidateParentalPinResponseModel.fromJson({});

      expect(validTrue.valid, isTrue);
      expect(validFalse.valid, isFalse);
      expect(validNull.valid, isFalse);
    });

    test('ChildModeContent entidad y conversiones de enum', () {
      final now = DateTime.now();
      final content = ChildModeContent(
        contentType: ChildModeContentType.story,
        contentId: 'story-123',
        title: 'La Pequeña Estrella Perdida',
        routeContext: '/stories/story-123/read',
        activatedAt: now,
      );

      expect(content.contentType, ChildModeContentType.story);
      expect(content.contentType.toValue(), 'story');
      expect(content.contentType.labelSpanish, 'Cuento infantil');

      expect(ChildModeContentTypeX.fromValue('image'), ChildModeContentType.image);
      expect(ChildModeContentTypeX.fromValue('music'), ChildModeContentType.music);
      expect(ChildModeContentTypeX.fromValue('story'), ChildModeContentType.story);
      expect(ChildModeContentTypeX.fromValue('unknown'), ChildModeContentType.story);

      expect(content.props, [
        ChildModeContentType.story,
        'story-123',
        'La Pequeña Estrella Perdida',
        '/stories/story-123/read',
        now,
      ]);
    });
  });
}

