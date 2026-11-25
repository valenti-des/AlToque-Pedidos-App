import 'package:app/basedate.dart';
import 'package:app/pages/api_settings_page.dart';
import 'package:app/pages/login_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('normalizes a valid API base URL', () {
    expect(
      ApiConfig.normalizeBaseUrl(' http://192.168.1.25:8080/ '),
      'http://192.168.1.25:8080',
    );
  });

  test('rejects API URLs with a path or missing host', () {
    expect(
      () => ApiConfig.normalizeBaseUrl('http://192.168.1.25:8080/api'),
      throwsFormatException,
    );
    expect(
      () => ApiConfig.normalizeBaseUrl('http:///8080'),
      throwsFormatException,
    );
  });

  test('persists the selected URL across configuration reloads', () async {
    await ApiConfig.initialize();
    await ApiConfig.setBaseUrl('http://192.168.1.25:8080');
    await ApiConfig.initialize();

    expect(ApiConfig.baseUrl, 'http://192.168.1.25:8080');
  });

  testWidgets('login screen can save a new API address', (tester) async {
    await ApiConfig.initialize();
    await tester.pumpWidget(
      MaterialApp(
        home: LoginPage(onCustomerContinue: (_, _) {}, onStaffLogin: (_, _) {}),
      ),
    );

    await tester.tap(find.byTooltip('Configurar conexión'));
    await tester.pumpAndSettle();
    expect(find.byType(ApiSettingsPage), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'http://192.168.1.50:8080');
    await tester.tap(find.text('Guardar dirección'));
    await tester.pumpAndSettle();

    expect(ApiConfig.baseUrl, 'http://192.168.1.50:8080');
    expect(find.byType(LoginPage), findsOneWidget);
  });
}
