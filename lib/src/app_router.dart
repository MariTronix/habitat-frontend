import 'package:go_router/go_router.dart';
import 'app_scaffold.dart';
import 'models.dart';
import 'providers.dart';
import '../screens/login_screen.dart';
import '../screens/dashboard_screen.dart';
import '../screens/kanban_screen.dart';
import '../screens/cadastro_atendimento_screen.dart';
import '../screens/detalhes_caso_screen.dart';
import '../screens/relatorios_screen.dart';
import '../screens/gestao_usuarios_screen.dart';

GoRouter createRouter(AuthProvider auth) {
  return GoRouter(
    initialLocation: '/',
    refreshListenable: auth,
    debugLogDiagnostics: false,
    routes: [
      GoRoute(path: '/', builder: (context, state) => const LoginScreen()),
      ShellRoute(
        builder: (context, state, child) => HabitatScaffold(child: child),
        routes: [
          GoRoute(path: '/dashboard', builder: (context, state) => const DashboardScreen()),
          GoRoute(path: '/kanban', builder: (context, state) => const KanbanScreen()),
          GoRoute(path: '/cadastro', builder: (context, state) => const CadastroAtendimentoScreen()),
          GoRoute(path: '/caso/:id', builder: (context, state) {
            final id = state.pathParameters['id'] ?? '';
            return DetalhesCasoScreen(casoId: id);
          }),
          GoRoute(path: '/relatorios', builder: (context, state) => const RelatoriosScreen()),
          GoRoute(path: '/usuarios', builder: (context, state) => const GestaoUsuariosScreen()),
        ],
      ),
    ],
    redirect: (context, state) {
      final loggingIn = state.location == '/';
      if (!auth.isAuthenticated && !loggingIn) return '/';
      if (auth.isAuthenticated && loggingIn) return '/dashboard';
      if (state.location == '/usuarios' && auth.user?.role != UserRole.master) return '/dashboard';
      return null;
    },
  );
}
