import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../src/models.dart';
import '../src/providers.dart';
import '../src/app_theme.dart';

class KanbanScreen extends StatefulWidget {
  const KanbanScreen({super.key});

  @override
  State<KanbanScreen> createState() => _KanbanScreenState();
}

class _KanbanScreenState extends State<KanbanScreen> {
  String _searchQuery = '';
  String _filterCoordenador = '';
  final ScrollController _mainScrollController = ScrollController();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final casesProvider = context.watch<CasesProvider>();
    final users = context.read<AuthProvider>().users;
    final user = auth.user;
    final coordenadores = users.where((u) => u.role == UserRole.coordenador).toList();

    final filtered = casesProvider.casos.where((c) {
      if (user?.role == UserRole.estagiario) return c.estagiarioId == user?.id;
      if (user?.role == UserRole.coordenador) return c.coordenadorId == user?.id;
      return true;
    }).where((c) {
      final query = _searchQuery.toLowerCase();
      return c.morador.nome.toLowerCase().contains(query) || c.morador.cpf.contains(query);
    }).where((c) {
      if (_filterCoordenador.isEmpty) return true;
      return c.coordenadorId == _filterCoordenador;
    }).toList();

    final columns = [
      _KanbanColumn(status: CaseStatus.triagem, label: 'Triagem', color: HabitatTheme.primary.withOpacity(0.35)),
      _KanbanColumn(status: CaseStatus.documentacao, label: 'Documentação', color: HabitatTheme.warning.withOpacity(0.35)),
      _KanbanColumn(status: CaseStatus.processo, label: 'Em Processo Judicial', color: HabitatTheme.info.withOpacity(0.35)),
      _KanbanColumn(status: CaseStatus.finalizado, label: 'Finalizado', color: HabitatTheme.success.withOpacity(0.35)),
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      controller: _mainScrollController,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Mural de Casos', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 6),
          Text('Arraste os cards para alterar o status', style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Buscar por nome ou CPF...'),
                  onChanged: (value) => setState(() => _searchQuery = value),
                ),
              ),
              const SizedBox(width: 16),
              if (user?.role == UserRole.master)
                SizedBox(
                  width: 220,
                  child: DropdownButtonFormField<String>(
                    value: _filterCoordenador.isEmpty ? null : _filterCoordenador,
                    decoration: const InputDecoration(hintText: 'Equipe'),
                    items: [
                      const DropdownMenuItem(value: '', child: Text('Todas as equipes')),
                      ...coordenadores.map((c) => DropdownMenuItem(value: c.id, child: Text(c.nome))).toList(),
                    ],
                    onChanged: (value) => setState(() => _filterCoordenador = value ?? ''),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 24),
          LayoutBuilder(builder: (context, constraints) {
            final crossAxisCount = constraints.maxWidth > 1300 ? 4 : constraints.maxWidth > 900 ? 2 : 1;
            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: crossAxisCount, crossAxisSpacing: 16, mainAxisSpacing: 16, childAspectRatio: 0.85),
              itemCount: columns.length,
              itemBuilder: (context, index) {
                final column = columns[index];
                final items = filtered.where((c) => c.status == column.status).toList();
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: column.color, borderRadius: BorderRadius.circular(24)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(width: 10, height: 10, decoration: BoxDecoration(color: column.status.color, shape: BoxShape.circle)),
                          const SizedBox(width: 8),
                          Expanded(child: Text(column.label, style: Theme.of(context).textTheme.titleMedium)),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(color: Colors.white70, borderRadius: BorderRadius.circular(12)),
                            child: Text('${items.length}', style: Theme.of(context).textTheme.bodyMedium),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        // 1. Envolvemos o ListView com o NotificationListener
                        child: NotificationListener<OverscrollNotification>(
                          onNotification: (OverscrollNotification info) {
                            // 2. Transfere a força da rolagem para a tela principal
                            if (info.overscroll != 0) {
                              _mainScrollController.jumpTo(
                                _mainScrollController.offset + info.overscroll,
                              );
                            }
                            return true; // Remove o efeito visual de fim de lista (ondinha do Android)
                          },
                          child: ListView.builder(
                            // 3. A física Clamping é obrigatória para gerar o evento de overscroll
                            physics: const ClampingScrollPhysics(),
                            itemCount: items.length,
                            itemBuilder: (context, itemIndex) {
                              final caso = items[itemIndex];
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: GestureDetector(
                                  onTap: () => GoRouter.of(context).go('/caso/${caso.id}'),
                                  child: _KanbanCard(caso: caso),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          }),
        ],
      ),
    );
  }
}

class _KanbanColumn {
  final CaseStatus status;
  final String label;
  final Color color;
  const _KanbanColumn({required this.status, required this.label, required this.color});
}

class _KanbanCard extends StatelessWidget {
  final Caso caso;
  const _KanbanCard({required this.caso});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: HabitatTheme.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: HabitatTheme.border),
        boxShadow: null,
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.drag_indicator, size: 18, color: Colors.grey),
              const SizedBox(width: 8),
              Expanded(child: Text(caso.morador.nome, style: const TextStyle(fontWeight: FontWeight.w600))),
            ],
          ),
          const SizedBox(height: 10),
          Text(caso.descricao, style: Theme.of(context).textTheme.bodyMedium, maxLines: 2, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 14),
          Row(
            children: [
              Icon(caso.tipo == TipoAtendimento.judicial ? Icons.balance : Icons.handshake, size: 16, color: Colors.grey[700]),
              const SizedBox(width: 6),
              Text(caso.tipo.label, style: const TextStyle(fontSize: 12, color: Colors.black54)),
            ],
          ),
          const SizedBox(height: 10),
          Text('Estagiário: ${caso.estagiarioId}', style: const TextStyle(fontSize: 12, color: Colors.black54)),
          Text('Coord: ${caso.coordenadorId}', style: const TextStyle(fontSize: 12, color: Colors.black54)),
        ],
      ),
    );
  }
}
