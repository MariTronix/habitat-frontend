import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/api_service.dart';
import 'src/app_router.dart';
import 'src/app_theme.dart';
import 'src/providers.dart';

void main() {
  final apiService = ApiService();
  print('✅ [INIT] ApiService criado com URL: ${apiService.baseUrl}');
  final authProvider = AuthProvider(apiService: apiService);
  print('✅ [INIT] AuthProvider criado com ApiService injetado');

  runApp(
    MultiProvider(
      providers: [
        Provider<ApiService>.value(value: apiService),
        ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
        ChangeNotifierProvider<CasesProvider>(create: (_) => CasesProvider()),
      ],
      child: HabitatApp(authProvider: authProvider),
    ),
  );
}

class HabitatApp extends StatelessWidget {
  final AuthProvider authProvider;

  const HabitatApp({super.key, required this.authProvider});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Habitat',
      debugShowCheckedModeBanner: false,
      routerConfig: createRouter(authProvider),
      theme: HabitatTheme.light,
    );
  }
}
