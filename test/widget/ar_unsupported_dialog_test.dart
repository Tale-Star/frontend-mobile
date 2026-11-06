import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:startale_mobile/core/theme/app_theme.dart';
import 'package:startale_mobile/features/augmented_reality/presentation/widgets/ar_unsupported_dialog.dart';

void main() {
  group('ArUnsupportedDialog Widget', () {
    testWidgets('renderiza mensaje explicativo en español y botón para regresar al lector 2D', (tester) async {
      bool dismissed = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: ArUnsupportedDialog(
              deviceModel: 'Xiaomi Redmi Note 13 4G (23129RA5FL)',
              reasonMessage:
                  'Tu dispositivo no cuenta con la certificación oficial de Google ARCore.',
              onDismiss: () {
                dismissed = true;
              },
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Realidad Aumentada no disponible'), findsOneWidget);
      expect(
        find.text('Tu dispositivo no cuenta con la certificación oficial de Google ARCore.'),
        findsOneWidget,
      );
      expect(
        find.textContaining('experiencia completa del lector tradicional 2D'),
        findsOneWidget,
      );

      final dismissBtn = find.byKey(const Key('ar_unsupported_dismiss_button'));
      expect(dismissBtn, findsOneWidget);

      await tester.tap(dismissBtn);
      await tester.pump();

      expect(dismissed, isTrue);
    });
  });
}

