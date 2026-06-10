import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_colors.dart';

class NavItem {
  final String path;
  final String label;
  final IconData icon;

  NavItem(this.path, this.label, this.icon);
}

final List<NavItem> navItems = [
  NavItem('/dashboard', 'Dashboard', Icons.dashboard_outlined),
  NavItem('/kanban', 'Mural de Casos', Icons.view_column_outlined),
  NavItem('/cadastro', 'Novo Atendimento', Icons.note_add_outlined),
  NavItem('/relatorios', 'Relatórios', Icons.bar_chart_outlined),
];

final List<NavItem> masterItems = [
  NavItem('/usuarios', 'Gestão de Usuários', Icons.group_outlined),
];

class AppLayout extends StatelessWidget {
  final Widget child;
  const AppLayout({super.key, required this.child});

  // Simulação de usuário autenticado (será substituído pelo seu AuthProvider)
  final String userRole = 'master'; 
  final String userName = 'Mariana Mendes Lima';
  final String userEmail = 'mariana@pronet.com';

  String getRoleLabel(String role) {
    switch (role) {
      case 'master': return 'Administrador';
      case 'coordenador': return 'Coordenador(a)';
      case 'estagiario': return 'Estagiário(a)';
      default: return '';
    }
  }

  void handleLogout(BuildContext context) {
    context.go('/'); 
  }

  @override
  Widget build(BuildContext context) {
    final allItems = userRole == 'master' ? [...navItems, ...masterItems] : navItems;
    final isDesktop = MediaQuery.of(context).size.width >= 1024; // lg: do Tailwind

    return Scaffold(
      backgroundColor: AppColors.background,
      // O Drawer atua como a Sidebar em telas menores (Mobile)
      drawer: isDesktop ? null : _buildSidebar(context, allItems),
      
      body: Row(
        children: [
          // Em telas grandes (Desktop), a Sidebar fica fixa na tela
          if (isDesktop) _buildSidebar(context, allItems),
          
          // Área Principal (Header + Conteúdo)
          Expanded(
            child: Column(
              children: [
                // Header
                Container(
                  height: 56.0, // h-14 do Tailwind
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    border: Border(bottom: BorderSide(color: AppColors.border)),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 0.0),
                  child: Row(
                    children: [
                      if (!isDesktop)
                        Builder( // O Builder é necessário para acessar o contexto e abrir o Drawer
                          builder: (context) => IconButton(
                            icon: const Icon(Icons.menu),
                            color: AppColors.foreground,
                            onPressed: () => Scaffold.of(context).openDrawer(),
                          ),
                        ),
                      const Spacer(),
                      if (MediaQuery.of(context).size.width >= 640) // sm:block do Tailwind
                        Text(
                          userEmail,
                          style: TextStyle(
                            fontSize: 12.0, // text-xs
                            color: AppColors.muted, // text-muted-foreground
                          ),
                        ),
                    ],
                  ),
                ),
                
                // Conteúdo Principal (children)
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.all(isDesktop ? 24.0 : 16.0), // p-4 lg:p-6
                    child: child,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar(BuildContext context, List<NavItem> items) {
    final currentPath = GoRouterState.of(context).matchedLocation;

    return Container(
      width: 256.0, // w-64 do Tailwind
      color: AppColors.sidebarBackground,
      child: Column(
        children: [
          // Sidebar Header
          Container(
            padding: const EdgeInsets.all(20.0),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColors.sidebarBorder)),
            ),
            child: Row(
              children: [
                Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Image.asset('assets/logo01.png', fit: BoxFit.contain), // Sua Logo!
                ),
                const SizedBox(width: 12.0),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Sistema Habitat',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16.0,
                        color: AppColors.sidebarForeground,
                      ),
                    ),
                    Text(
                      'Gestão Jurídica',
                      style: TextStyle(
                        fontSize: 12.0,
                        color: AppColors.sidebarForeground.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Navigation Links
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 12.0),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                final isActive = currentPath == item.path;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 4.0),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(8.0),
                      onTap: () {
                        context.go(item.path);
                        if (Scaffold.of(context).isDrawerOpen) {
                          Navigator.pop(context); // Fecha o menu no mobile ao clicar
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
                        decoration: BoxDecoration(
                          color: isActive ? AppColors.sidebarAccent : Colors.transparent,
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              item.icon,
                              size: 18.0,
                              color: isActive ? AppColors.sidebarPrimary : AppColors.sidebarForeground.withOpacity(0.7),
                            ),
                            const SizedBox(width: 12.0),
                            Text(
                              item.label,
                              style: TextStyle(
                                fontSize: 14.0,
                                fontWeight: FontWeight.w500,
                                color: isActive ? AppColors.sidebarPrimary : AppColors.sidebarForeground.withOpacity(0.7),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Sidebar Footer
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: AppColors.sidebarBorder)),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 32, height: 32,
                      decoration: BoxDecoration(
                        color: AppColors.sidebarPrimary.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          userName.substring(0, 1).toUpperCase(),
                          style: TextStyle(
                            fontSize: 14.0,
                            fontWeight: FontWeight.bold,
                            color: AppColors.sidebarPrimary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12.0),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            userName,
                            style: TextStyle(
                              fontSize: 14.0,
                              fontWeight: FontWeight.w500,
                              color: AppColors.sidebarForeground,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            getRoleLabel(userRole),
                            style: TextStyle(
                              fontSize: 12.0,
                              color: AppColors.sidebarForeground.withOpacity(0.5),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12.0),
                InkWell(
                  onTap: () => handleLogout(context),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Row(
                      children: [
                        Icon(Icons.logout, size: 16.0, color: AppColors.sidebarForeground.withOpacity(0.5)),
                        const SizedBox(width: 8.0),
                        Text(
                          'Sair',
                          style: TextStyle(
                            fontSize: 14.0,
                            color: AppColors.sidebarForeground.withOpacity(0.5),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}