import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'app_theme.dart';
import 'models.dart';
import 'providers.dart';

class HabitatScaffold extends StatelessWidget {
  final Widget child;
  const HabitatScaffold({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final currentPath = GoRouterState.of(context).location;
    final isDesktop = MediaQuery.of(context).size.width >= 1000;

    return Scaffold(
      appBar: AppBar(
        title: Text('Sistema Habitat', style: Theme.of(context).textTheme.titleLarge),
        elevation: 0,
        backgroundColor: Theme.of(context).cardColor,
        centerTitle: false,
        leading: isDesktop ? null : Builder(builder: (context) {
          return IconButton(
            icon: const Icon(Icons.menu, color: HabitatTheme.primary),
            onPressed: () => Scaffold.of(context).openDrawer(),
          );
        }),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Center(
              child: Text(auth.user?.email ?? '', style: Theme.of(context).textTheme.bodyMedium),
            ),
          ),
        ],
      ),
      drawer: isDesktop ? null : Drawer(child: _MenuColumn(currentPath: currentPath, onLogout: () => auth.logout())),

      body: SafeArea(
        child: Row(
          children: [
            if (isDesktop) SizedBox(width: 280, child: _MenuColumn(currentPath: currentPath, onLogout: () => auth.logout())),
            Expanded(child: child),
          ],
        ),
      ),
    );
  }
}

class _MenuColumn extends StatelessWidget {
  final String currentPath;
  final VoidCallback onLogout;
  const _MenuColumn({required this.currentPath, required this.onLogout});

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthProvider>();
    final user = auth.user;
    final navItems = [
      _NavItem(path: '/dashboard', label: 'Dashboard', icon: Icons.dashboard),
      _NavItem(path: '/kanban', label: 'Mural de Casos', icon: Icons.view_kanban),
      _NavItem(path: '/cadastro', label: 'Novo Atendimento', icon: Icons.add_box),
      _NavItem(path: '/relatorios', label: 'Relatórios', icon: Icons.bar_chart),
    ];

    final masterItems = [
      _NavItem(path: '/usuarios', label: 'Gestão de Usuários', icon: Icons.people),
    ];

    final allItems = user?.role == UserRole.master ? [...navItems, ...masterItems] : navItems;

    return Container(
      color: const Color(0xFF111827),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(color: HabitatTheme.accent, borderRadius: BorderRadius.circular(12)),
                    child: Center(child: Text((user?.nome.substring(0, 1).toUpperCase() ?? ''), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Sistema Habitat', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        Text('Gestão Jurídica', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white70)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                children: allItems.map((item) {
                  final selected = currentPath == item.path;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 4.0),
                    child: ListTile(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      selected: selected,
                      selectedTileColor: Colors.white12,
                      leading: Icon(item.icon, color: selected ? HabitatTheme.accent : Colors.white70),
                      title: Text(item.label, style: TextStyle(color: selected ? Colors.white : Colors.white70)),
                      onTap: () {
                        GoRouter.of(context).go(item.path);
                        if (Scaffold.of(context).isDrawerOpen) Navigator.pop(context);
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
            const Divider(color: Colors.white12),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(user?.nome ?? '', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text(user?.role.label ?? '', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        onLogout();
                        GoRouter.of(context).go('/');
                      },
                      icon: const Icon(Icons.logout, color: Colors.white),
                      label: const Text('Sair', style: TextStyle(color: Colors.white)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.white24),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem {
  final String path;
  final String label;
  final IconData icon;
  const _NavItem({required this.path, required this.label, required this.icon});
}
