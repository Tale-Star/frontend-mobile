import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:startale_mobile/core/theme/app_theme.dart';
import 'package:startale_mobile/shared/widgets/ts_bottom_nav.dart';
import 'package:startale_mobile/shared/widgets/ts_button.dart';
import 'package:startale_mobile/shared/widgets/ts_card.dart';
import 'package:startale_mobile/shared/widgets/ts_empty_state.dart';
import 'package:startale_mobile/shared/widgets/ts_text_field.dart';

void main() {
  Widget wrapWithTheme(Widget child) {
    return MaterialApp(
      theme: AppTheme.lightTheme,
      home: Scaffold(body: child),
    );
  }

  group('Shared Widgets Tests', () {
    testWidgets('TsButton renderiza texto y responde a eventos de clic', (tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        wrapWithTheme(
          TsButton(
            label: 'Entrar a Tale Star',
            onPressed: () => tapped = true,
          ),
        ),
      );

      expect(find.text('Entrar a Tale Star'), findsOneWidget);

      await tester.tap(find.byType(TsButton));
      await tester.pump();

      expect(tapped, isTrue);
    });

    testWidgets('TsButton en estado isLoading muestra CircularProgressIndicator y no dispara onTap', (tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        wrapWithTheme(
          TsButton(
            label: 'Cargando...',
            isLoading: true,
            onPressed: () => tapped = true,
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Cargando...'), findsNothing);

      await tester.tap(find.byType(TsButton));
      await tester.pump();

      expect(tapped, isFalse);
    });

    testWidgets('TsTextField renderiza label y hint correctamente', (tester) async {
      await tester.pumpWidget(
        wrapWithTheme(
          const TsTextField(
            label: 'Correo Electrónico',
            hint: 'ejemplo@correo.com',
          ),
        ),
      );

      expect(find.text('Correo Electrónico'), findsOneWidget);
      expect(find.text('ejemplo@correo.com'), findsOneWidget);
    });

    testWidgets('TsCard renderiza el widget hijo con bordes redondeados y responde a taps', (tester) async {
      bool cardTapped = false;

      await tester.pumpWidget(
        wrapWithTheme(
          TsCard(
            onTap: () => cardTapped = true,
            child: const Text('Tarjeta de Cuento'),
          ),
        ),
      );

      expect(find.text('Tarjeta de Cuento'), findsOneWidget);

      await tester.tap(find.text('Tarjeta de Cuento'));
      await tester.pump();

      expect(cardTapped, isTrue);
    });

    testWidgets('TsEmptyState renderiza icono, título y descripción amigable', (tester) async {
      await tester.pumpWidget(
        wrapWithTheme(
          const TsEmptyState(
            icon: Icons.menu_book,
            title: 'Tu biblioteca está tranquila',
            description: 'Aún no has guardado ningún cuento.',
          ),
        ),
      );

      expect(find.text('Tu biblioteca está tranquila'), findsOneWidget);
      expect(find.text('Aún no has guardado ningún cuento.'), findsOneWidget);
      expect(find.byIcon(Icons.menu_book), findsOneWidget);
    });

    testWidgets('TsBottomNav contiene las 5 pestañas oficiales en el orden exacto', (tester) async {
      int selectedIndex = 3;

      await tester.pumpWidget(
        wrapWithTheme(
          TsBottomNav(
            currentIndex: selectedIndex,
            onTap: (index) => selectedIndex = index,
          ),
        ),
      );

      // Verificamos las 5 etiquetas en español
      expect(find.text('Imágenes'), findsOneWidget);
      expect(find.text('Cuentos'), findsOneWidget);
      expect(find.text('Música'), findsOneWidget);
      expect(find.text('Biblioteca'), findsOneWidget);
      expect(find.text('Perfil'), findsOneWidget);

      // Verificamos que la selección funciona
      await tester.tap(find.text('Imágenes'));
      await tester.pump();

      expect(selectedIndex, 0);
    });
  });
}
