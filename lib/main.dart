import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'theme/app_colors.dart';
import 'routes/app_router.dart';
import 'services/api_service.dart'; // Importação essencial

void main() {
  runApp(
    // MultiProvider centralizando os serviços que o app usa
    MultiProvider(
      providers: [
        // Aqui incluímos o ApiService de verdade
        Provider<ApiService>(
          create: (_) => ApiService(),
        ),
      ],
      child: const HabitatApp(),
    ),
  );
}

class HabitatApp extends StatelessWidget {
  const HabitatApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Habitat',
      debugShowCheckedModeBanner: false,
      
      // Configurações do go_router
      routerConfig: AppRouter.router,
      
      // Tema definido
      theme: ThemeData(
        textTheme: GoogleFonts.interTextTheme(Theme.of(context).textTheme),
        scaffoldBackgroundColor: AppColors.background,
        primaryColor: AppColors.primary,
        colorScheme: ColorScheme.light(
          primary: AppColors.primary,
          secondary: AppColors.secondary,
          surface: AppColors.card,
          error: AppColors.destructive,
          onPrimary: AppColors.primaryForeground,
          onSurface: AppColors.foreground,
        ),
      ),
    );
  }
}