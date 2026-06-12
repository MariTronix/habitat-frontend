import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:habitat_flutter/main.dart';
import 'package:habitat_flutter/services/api_service.dart';
import 'package:habitat_flutter/src/providers.dart';

void main() {
  testWidgets('shows login screen', (WidgetTester tester) async {
    final apiService = ApiService(baseUrl: 'http://127.0.0.1:8080');
    final authProvider = AuthProvider(apiService: apiService);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<ApiService>.value(value: apiService),
          ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
          ChangeNotifierProvider<CasesProvider>(create: (_) => CasesProvider()),
        ],
        child: HabitatApp(authProvider: authProvider),
      ),
    );

    expect(find.text('Sistema Habitat'), findsOneWidget);
    expect(find.text('Entrar'), findsOneWidget);
  });
}
