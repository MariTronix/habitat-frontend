import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../components/layout.dart';
import '../pages/login_screen.dart';
import '../pages/dashboard_screen.dart';
import '../pages/kanban_screen.dart';
import '../pages/cadastro_screen.dart';
import '../pages/detalhes_caso_screen.dart';
import '../pages/relatorios_screen.dart';
import '../pages/gestao_usuarios_screen.dart'; // NOVA IMPORTAÇÃO

class PlaceholderScreen extends StatelessWidget {
  final String title;
  const PlaceholderScreen({super.key, required this.title});
  @override
  Widget build(BuildContext context) => Scaffold(body: Center(child: Text(title)));
}

class AppRouter {
  static bool isAuthenticated = false;
  static String userRole = 'master';

  static final GoRouter router = GoRouter(
    initialLocation: '/', 
    redirect: (context, state) {
      final isLoggingIn = state.matchedLocation == '/';

      if (!isAuthenticated && !isLoggingIn) {
        return '/';
      }
      if (isAuthenticated && isLoggingIn) {
        return '/dashboard';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const LoginScreen(),
      ),

      ShellRoute(
        builder: (context, state, child) {
          return AppLayout(child: child);
        },
        routes: [
          GoRoute(
            path: '/dashboard',
            builder: (context, state) => const DashboardScreen(),
          ),
          GoRoute(
            path: '/kanban',
            builder: (context, state) => const KanbanScreen(),
          ),
          GoRoute(
            path: '/cadastro',
            builder: (context, state) => const CadastroScreen(),
          ),
          GoRoute(
            path: '/caso/:id',
            builder: (context, state) {
              final id = state.pathParameters['id'] ?? '0';
              return DetalhesCasoScreen(casoId: id);
            },
          ),
          GoRoute(
            path: '/relatorios',
            builder: (context, state) => const RelatoriosScreen(),
          ),
          GoRoute(
            path: '/usuarios',
            redirect: (context, state) {
              if (userRole != 'master') {
                return '/dashboard';
              }
              return null;
            },
            builder: (context, state) => const GestaoUsuariosScreen(), // ROTA FINAL ATUALIZADA
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) => const PlaceholderScreen(title: 'Not Found (404)'),
  );
}