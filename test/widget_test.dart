import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:startale_mobile/app.dart';
import 'package:startale_mobile/core/storage/secure_storage_service.dart';
import 'package:startale_mobile/injection.dart';

class MockFlutterSecureStorage extends Mock implements FlutterSecureStorage {}

void main() {
  setUp(() async {
    await resetDependencies();
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    final mockStorage = MockFlutterSecureStorage();
    when(() => mockStorage.read(key: any(named: 'key')))
        .thenAnswer((_) async => null);
    when(() => mockStorage.delete(key: any(named: 'key')))
        .thenAnswer((_) async {});

    await initDependencies(
      testPrefs: prefs,
      testSecureStorage: SecureStorageService(storage: mockStorage),
    );
  });

  tearDown(() async {
    await resetDependencies();
  });

  testWidgets('TaleStarApp smoke test — inicializa y monta sin errores', (WidgetTester tester) async {
    await tester.pumpWidget(const TaleStarApp());
    await tester.pumpAndSettle();

    // Dado que no hay token persistido, el Auth Guard de GoRouter redirige a /login
    expect(find.text('Iniciar Sesión'), findsAtLeastNWidgets(1));
    expect(find.byType(TaleStarApp), findsOneWidget);
  });
}
