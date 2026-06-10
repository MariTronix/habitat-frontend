import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_colors.dart';

// --- Modelos Simulados (Substituirão seus Contextos/Hooks depois) ---
class SimUser {
  final String id;
  final String nome;
  final String role;
  SimUser(this.id, this.nome, this.role);
}

class SimMorador {
  final String nome;
  final String cpf;
  SimMorador(this.nome, this.cpf);
}

class SimCaso {
  final String id;
  final SimMorador morador;
  final String descricao;
  final String tipo;
  String status;
  final String estagiarioId;
  final String coordenadorId;

  SimCaso(this.id, this.morador, this.descricao, this.tipo, this.status, this.estagiarioId, this.coordenadorId);
}
// --------------------------------------------------------------------

class KanbanScreen extends StatefulWidget {
  const KanbanScreen({super.key});

  @override
  State<KanbanScreen> createState() => _KanbanScreenState();
}

class _KanbanScreenState extends State<KanbanScreen> {
  // Simulação de Estado
  final SimUser currentUser = SimUser('master1', 'Mariana Mendes Lima', 'master');
  String _searchQuery = '';
  String _filterEquipe = '';
  String? _updatingId;

  // Dados Fakes
  final List<SimUser> _users = [
    SimUser('coord1', 'Lourival', 'coordenador'),
    SimUser('coord2', 'Vladson', 'coordenador'),
    SimUser('est1', 'Hugo', 'estagiario'),
    SimUser('est2', 'Gabriel', 'estagiario'),
  ];

  late List<SimCaso> _casos;

  @override
  void initState() {
    super.initState();
    _casos = [
      SimCaso('1', SimMorador('João Silva', '111.111.111-11'), 'Regularização de Terreno', 'judicial', 'triagem', 'est1', 'coord1'),
      SimCaso('2', SimMorador('Maria Oliveira', '222.222.222-22'), 'Emissão de Escritura', 'conciliacao', 'documentacao', 'est2', 'coord1'),
      SimCaso('3', SimMorador('Pedro Santos', '333.333.333-33'), 'Análise de Risco', 'judicial', 'processo', 'est1', 'coord2'),
      SimCaso('4', SimMorador('Ana Costa', '444.444.444-44'), 'Alvará Concluído', 'conciliacao', 'finalizado', 'est2', 'coord2'),
    ];
  }

  // Lógica de Drop
  Future<void> _handleDrop(SimCaso caso, String novoStatus) async {
    if (caso.status == novoStatus) return;

    setState(() => _updatingId = caso.id);
    
    await Future.delayed(const Duration(milliseconds: 800)); // Simula tempo de API
    
    setState(() {
      final index = _casos.indexWhere((c) => c.id == caso.id);
      if (index != -1) {
        _casos[index].status = novoStatus;
      }
      _updatingId = null;
    });
  }

  String _getUserName(String id) {
    return _users.firstWhere((u) => u.id == id, orElse: () => SimUser('', 'Desconhecido', '')).nome;
  }

  @override
  Widget build(BuildContext context) {
    final coordenadores = _users.where((u) => u.role == 'coordenador').toList();

    // Filtros
    var filteredCasos = _casos.where((c) {
      if (currentUser.role == 'estagiario') return c.estagiarioId == currentUser.id;
      if (currentUser.role == 'coordenador') return c.coordenadorId == currentUser.id;
      return true;
    }).where((c) {
      return _filterEquipe.isEmpty || c.coordenadorId == _filterEquipe;
    }).where((c) {
      final q = _searchQuery.toLowerCase();
      return c.morador.nome.toLowerCase().contains(q) || c.morador.cpf.contains(q);
    }).toList();

    // Definição das Colunas
    final columns = [
      {'status': 'triagem', 'label': 'Triagem', 'color': AppColors.mutedForeground},
      {'status': 'documentacao', 'label': 'Documentação', 'color': AppColors.warning},
      {'status': 'processo', 'label': 'Em Processo Judicial', 'color': AppColors.info},
      {'status': 'finalizado', 'label': 'Finalizado', 'color': AppColors.success},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header e Controles
        LayoutBuilder(
          builder: (context, constraints) {
            bool isMobile = constraints.maxWidth < 640;
            return Flex(
              direction: isMobile ? Axis.vertical : Axis.horizontal,
              crossAxisAlignment: isMobile ? CrossAxisAlignment.start : CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Mural de Casos', style: TextStyle(fontSize: 24.0, fontWeight: FontWeight.bold, color: AppColors.foreground)),
                    Text('Arraste os cards para alterar o status', style: TextStyle(fontSize: 14.0, color: AppColors.mutedForeground)),
                  ],
                ),
                if (isMobile) const SizedBox(height: 16.0),
                Wrap(
                  direction: isMobile ? Axis.vertical : Axis.horizontal,
                  spacing: 12.0, // ANTES ERA gap: 12.0
                  runSpacing: 12.0, // Adicione esta linha também
                  children: [
                    // Search Input
                    SizedBox(
                      width: isMobile ? double.infinity : 256.0,
                      height: 40.0,
                      child: TextField(
                        onChanged: (val) => setState(() => _searchQuery = val),
                        decoration: InputDecoration(
                          hintText: 'Buscar por nome ou CPF...',
                          hintStyle: TextStyle(color: AppColors.mutedForeground, fontSize: 14.0),
                          prefixIcon: Icon(Icons.search, size: 18.0, color: AppColors.mutedForeground),
                          filled: true,
                          fillColor: AppColors.card,
                          contentPadding: const EdgeInsets.symmetric(vertical: 0),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0), borderSide: BorderSide(color: AppColors.border)),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0), borderSide: BorderSide(color: AppColors.border)),
                          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0), borderSide: BorderSide(color: AppColors.accent, width: 2.0)),
                        ),
                      ),
                    ),
                    // Equipe Filter (Apenas Master)
                    if (currentUser.role == 'master')
                      Container(
                        height: 40.0,
                        width: isMobile ? double.infinity : 180.0,
                        padding: const EdgeInsets.symmetric(horizontal: 12.0),
                        decoration: BoxDecoration(
                          color: AppColors.card,
                          border: Border.all(color: AppColors.border),
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _filterEquipe.isEmpty ? null : _filterEquipe,
                            hint: Text('Todas as equipes', style: TextStyle(fontSize: 14.0, color: AppColors.foreground)),
                            isExpanded: true,
                            icon: Icon(Icons.arrow_drop_down, color: AppColors.mutedForeground),
                            onChanged: (val) => setState(() => _filterEquipe = val ?? ''),
                            items: [
                              const DropdownMenuItem(value: '', child: Text('Todas as equipes', style: TextStyle(fontSize: 14.0))),
                              ...coordenadores.map((c) => DropdownMenuItem(value: c.id, child: Text('Equipe ${c.nome}', style: const TextStyle(fontSize: 14.0)))),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 24.0),

        // Grid do Kanban
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              // Lógica para o número de colunas (grid-cols-1 md:grid-cols-2 xl:grid-cols-4)
              int crossAxisCount = 1;
              if (constraints.maxWidth >= 768) crossAxisCount = 2; // md
              if (constraints.maxWidth >= 1280) crossAxisCount = 4; // xl

              double spacing = 16.0;
              double colWidth = (constraints.maxWidth - (spacing * (crossAxisCount - 1))) / crossAxisCount;

              return SingleChildScrollView(
                child: Wrap(
                  spacing: spacing,
                  runSpacing: spacing,
                  children: columns.map((col) {
                    final status = col['status'] as String;
                    final label = col['label'] as String;
                    final color = col['color'] as Color;
                    final colCasos = filteredCasos.where((c) => c.status == status).toList();

                    return SizedBox(
                      width: colWidth,
                      // min-h-[60vh] aproximado para dar área de drop
                      child: ConstrainedBox(
                        constraints: BoxConstraints(minHeight: MediaQuery.of(context).size.height * 0.6),
                        child: DragTarget<SimCaso>(
                          onAcceptWithDetails: (details) => _handleDrop(details.data, status),
                          builder: (context, candidateData, rejectedData) {
                            return Container(
                              padding: const EdgeInsets.all(12.0),
                              decoration: BoxDecoration(
                                color: AppColors.muted.withOpacity(0.4), // bg-muted/40
                                borderRadius: BorderRadius.circular(12.0),
                                border: candidateData.isNotEmpty ? Border.all(color: AppColors.accent, width: 2) : null,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Header da Coluna
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 12.0, left: 4.0, right: 4.0),
                                    child: Row(
                                      children: [
                                        Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                                        const SizedBox(width: 8.0),
                                        Text(label, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14.0, color: AppColors.foreground)),
                                        const Spacer(),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 2.0),
                                          decoration: BoxDecoration(
                                            color: AppColors.card,
                                            borderRadius: BorderRadius.circular(12.0),
                                            border: Border.all(color: AppColors.border),
                                          ),
                                          child: Text('${colCasos.length}', style: TextStyle(fontSize: 12.0, color: AppColors.mutedForeground)),
                                        ),
                                      ],
                                    ),
                                  ),
                                  
                                  // Lista de Cards
                                  ListView.separated(
                                    shrinkWrap: true,
                                    physics: const NeverScrollableScrollPhysics(),
                                    itemCount: colCasos.length,
                                    separatorBuilder: (_, __) => const SizedBox(height: 8.0),
                                    itemBuilder: (context, index) {
                                      final caso = colCasos[index];
                                      return _buildDraggableCard(caso, colWidth - 24); // -24 é o padding do container
                                    },
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    );
                  }).toList(),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // Card Arrastável
  Widget _buildDraggableCard(SimCaso caso, double width) {
    Widget cardContent = Container(
      width: width,
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(color: AppColors.border),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))],
      ),
      child: Stack(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.drag_indicator, size: 16.0, color: AppColors.mutedForeground.withOpacity(0.4)),
              const SizedBox(width: 8.0),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(caso.morador.nome, style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14.0, color: AppColors.foreground), maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4.0),
                    Text(caso.descricao, style: TextStyle(fontSize: 12.0, color: AppColors.mutedForeground), maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 8.0),
                    Row(
                      children: [
                        Icon(Icons.work_outline, size: 12.0, color: AppColors.mutedForeground),
                        const SizedBox(width: 4.0),
                        Text(caso.tipo == 'judicial' ? 'Judicial' : 'Conciliação', style: TextStyle(fontSize: 12.0, color: AppColors.mutedForeground)),
                      ],
                    ),
                    const SizedBox(height: 8.0),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [Icon(Icons.person_outline, size: 12.0, color: AppColors.mutedForeground), const SizedBox(width: 4.0), Text(_getUserName(caso.estagiarioId), style: TextStyle(fontSize: 12.0, color: AppColors.mutedForeground))]),
                        const SizedBox(height: 2.0),
                        Text('Coord: ${_getUserName(caso.coordenadorId)}', style: TextStyle(fontSize: 12.0, color: AppColors.mutedForeground.withOpacity(0.6))),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (_updatingId == caso.id)
            Positioned(
              top: 0, right: 0,
              child: Container(
                padding: const EdgeInsets.all(4.0),
                decoration: BoxDecoration(color: AppColors.background.withOpacity(0.8), shape: BoxShape.circle),
                child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.accent)),
              ),
            ),
        ],
      ),
    );

    return Draggable<SimCaso>(
      data: caso,
      feedback: Material(color: Colors.transparent, child: Opacity(opacity: 0.8, child: cardContent)),
      childWhenDragging: Opacity(opacity: 0.3, child: cardContent),
      child: InkWell(
        onTap: () => context.go('/caso/${caso.id}'),
        child: cardContent,
      ),
    );
  }
}