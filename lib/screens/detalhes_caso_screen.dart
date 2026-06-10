import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../src/models.dart';
import '../src/providers.dart';
import '../src/app_theme.dart';

class DetalhesCasoScreen extends StatefulWidget {
  final String casoId;
  const DetalhesCasoScreen({super.key, required this.casoId});

  @override
  State<DetalhesCasoScreen> createState() => _DetalhesCasoScreenState();
}

class _DetalhesCasoScreenState extends State<DetalhesCasoScreen> {
  CaseStatus? _selectedStatus;
  final TextEditingController _anotacaoController = TextEditingController();
  final TextEditingController _procedimentoController = TextEditingController();
  final TextEditingController _informacaoController = TextEditingController();

  void _addAnotacao(Caso caso, String autor) {
    final text = _anotacaoController.text.trim();
    if (text.isEmpty) return;
    final now = DateTime.now().toIso8601String().split('T').first;
    final anotacao = Anotacao(id: 'a${now.hashCode}', texto: text, autor: autor, data: now);
    final updated = [...caso.anotacoes, anotacao];
    context.read<CasesProvider>().updateCaso(caso.id, anotacoes: updated);
    _anotacaoController.clear();
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Anotação adicionada')));
  }

  void _saveJudicial(Caso caso) {
    final current = caso.caminhoJudicial;
    if (current == null) {
      final novo = CaminhoJudicial(
        numeroProcesso: _procedimentoController.text.trim(),
        varaJudicial: _informacaoController.text.trim(),
        dataEntrada: DateTime.now().toIso8601String().split('T').first,
        statusProcesso: 'Registro atualizado',
      );
      context.read<CasesProvider>().updateCaso(caso.id, caminhoJudicial: novo);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Dados judiciais salvos')));
    }
  }

  void _saveConciliacao(Caso caso) {
    final novo = Conciliacao(
      dadosOutraParte: _procedimentoController.text.trim(),
      dataAudiencia: DateTime.now().toIso8601String().split('T').first,
      local: _informacaoController.text.trim(),
      resultado: 'Aguardando resultado',
    );
    context.read<CasesProvider>().updateCaso(caso.id, conciliacao: novo);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Dados de conciliação salvos')));
  }

  void _addDocumento(Caso caso) {
    final nome = _procedimentoController.text.trim();
    if (nome.isEmpty) return;
    final doc = Documento(id: 'd${nome.hashCode}${DateTime.now().millisecondsSinceEpoch}', nome: nome, tipo: 'pdf', data: DateTime.now().toIso8601String().split('T').first);
    final updated = [...caso.documentos, doc];
    context.read<CasesProvider>().updateCaso(caso.id, documentos: updated);
    _procedimentoController.clear();
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Documento adicionado')));
  }

  @override
  Widget build(BuildContext context) {
    final casesProvider = context.watch<CasesProvider>();
    final caso = casesProvider.getCasoById(widget.casoId);
    if (caso == null) {
      return Center(child: Text('Caso não encontrado', style: Theme.of(context).textTheme.titleMedium));
    }

    _selectedStatus = _selectedStatus ?? caso.status;
    final tabs = [
      const Tab(text: 'Informações'),
      const Tab(text: 'Linha do Tempo'),
      const Tab(text: 'Documentos'),
      if (caso.tipo == TipoAtendimento.judicial) const Tab(text: 'Caminho Judicial'),
      if (caso.tipo == TipoAtendimento.conciliacao) const Tab(text: 'Conciliação'),
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Detalhes do Caso', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 10),
          _CaseHeader(caso: caso, selectedStatus: _selectedStatus!, onStatusChange: (status) {
            context.read<CasesProvider>().updateCaso(caso.id, status: status, dataAtualizacao: DateTime.now().toIso8601String().split('T').first);
            setState(() => _selectedStatus = status);
          }),
          const SizedBox(height: 20),
          DefaultTabController(
            length: tabs.length,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TabBar(tabs: tabs, labelColor: HabitatTheme.accent, unselectedLabelColor: Colors.black54, indicatorColor: HabitatTheme.accent),
                const SizedBox(height: 16),
                SizedBox(
                  height: 620,
                  child: TabBarView(children: [
                    _buildInfoTab(caso),
                    _buildTimelineTab(caso),
                    _buildDocumentsTab(caso),
                    if (caso.tipo == TipoAtendimento.judicial) _buildJudicialTab(caso),
                    if (caso.tipo == TipoAtendimento.conciliacao) _buildConciliacaoTab(caso),
                  ]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoTab(Caso caso) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _InfoBlock(title: 'Descrição do Caso', child: Text(caso.descricao, style: Theme.of(context).textTheme.bodyLarge)),
          _InfoBlock(
            title: 'Anotações',
            child: Column(
              children: [
                ...caso.anotacoes.map((a) => Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    title: Text(a.texto),
                    subtitle: Text('${a.autor} • ${a.data}'),
                  ),
                )),
                TextField(
                  controller: _anotacaoController,
                  maxLines: 3,
                  decoration: const InputDecoration(labelText: 'Adicionar anotação'),
                ),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton(
                    onPressed: () => _addAnotacao(caso, context.read<AuthProvider>().user?.nome ?? ''),
                    child: const Text('Salvar'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineTab(Caso caso) {
    return ListView.separated(
      itemCount: caso.timeline.length,
      separatorBuilder: (_, __) => const Divider(),
      itemBuilder: (context, index) {
        final event = caso.timeline[index];
        return ListTile(
          title: Text(event.descricao),
          subtitle: Text('${event.autor} • ${event.data}'),
          leading: CircleAvatar(backgroundColor: HabitatTheme.accent.withOpacity(0.2), child: const Icon(Icons.history, color: HabitatTheme.accent)),
        );
      },
    );
  }

  Widget _buildDocumentsTab(Caso caso) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: caso.documentos.isEmpty
              ? Center(child: Text('Nenhum documento anexado.', style: Theme.of(context).textTheme.bodyMedium))
              : ListView.builder(
                  itemCount: caso.documentos.length,
                  itemBuilder: (context, index) {
                    final doc = caso.documentos[index];
                    return ListTile(
                      leading: const Icon(Icons.insert_drive_file, color: HabitatTheme.accent),
                      title: Text(doc.nome),
                      subtitle: Text(doc.tipo.toUpperCase()),
                      trailing: Text(doc.data, style: Theme.of(context).textTheme.bodySmall),
                    );
                  },
                ),
        ),
        const SizedBox(height: 12),
        TextField(controller: _procedimentoController, decoration: const InputDecoration(labelText: 'Nome do documento para anexar')),
        const SizedBox(height: 12),
        ElevatedButton(onPressed: () => _addDocumento(caso), child: const Text('Adicionar Documento')),
      ],
    );
  }

  Widget _buildJudicialTab(Caso caso) {
    final caminho = caso.caminhoJudicial;
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (caminho != null) ...[
            _InfoBlock(title: 'Número do Processo', child: Text(caminho.numeroProcesso)),
            _InfoBlock(title: 'Vara Judicial', child: Text(caminho.varaJudicial)),
            _InfoBlock(title: 'Data de Entrada', child: Text(caminho.dataEntrada)),
            _InfoBlock(title: 'Status do Processo', child: Text(caminho.statusProcesso)),
          ] else ...[
            TextField(controller: _procedimentoController, decoration: const InputDecoration(labelText: 'Número do Processo')),
            const SizedBox(height: 16),
            TextField(controller: _informacaoController, decoration: const InputDecoration(labelText: 'Vara Judicial ou Observação')),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: () => _saveJudicial(caso), child: const Text('Salvar')),
          ],
        ],
      ),
    );
  }

  Widget _buildConciliacaoTab(Caso caso) {
    final conciliacao = caso.conciliacao;
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (conciliacao != null) ...[
            _InfoBlock(title: 'Dados Outra Parte', child: Text(conciliacao.dadosOutraParte)),
            _InfoBlock(title: 'Data da Audiência', child: Text(conciliacao.dataAudiencia)),
            _InfoBlock(title: 'Local', child: Text(conciliacao.local)),
            _InfoBlock(title: 'Resultado', child: Text(conciliacao.resultado)),
          ] else ...[
            TextField(controller: _procedimentoController, decoration: const InputDecoration(labelText: 'Dados da Outra Parte')),
            const SizedBox(height: 16),
            TextField(controller: _informacaoController, decoration: const InputDecoration(labelText: 'Local da Audiência')),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: () => _saveConciliacao(caso), child: const Text('Salvar')),
          ],
        ],
      ),
    );
  }
}

class _CaseHeader extends StatelessWidget {
  final Caso caso;
  final CaseStatus selectedStatus;
  final ValueChanged<CaseStatus> onStatusChange;
  const _CaseHeader({required this.caso, required this.selectedStatus, required this.onStatusChange});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(color: HabitatTheme.card, borderRadius: BorderRadius.circular(24), border: Border.all(color: HabitatTheme.border)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(caso.morador.nome, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        Text('${caso.morador.cpf} • ${caso.morador.telefone}', style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: 6),
        Text(caso.morador.endereco, style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: 16),
        Wrap(spacing: 12, runSpacing: 12, children: [
          _StatusChip(status: caso.status),
          DropdownButton<CaseStatus>(
            value: selectedStatus,
            items: CaseStatus.values.map((status) => DropdownMenuItem(value: status, child: Text(status.label))).toList(),
            onChanged: (status) {
              if (status != null) onStatusChange(status);
            },
          ),
        ]),
      ]),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final CaseStatus status;
  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(color: status.color.withOpacity(0.16), borderRadius: BorderRadius.circular(16)),
      child: Text(status.label, style: TextStyle(color: status.color, fontWeight: FontWeight.bold)),
    );
  }
}

class _InfoBlock extends StatelessWidget {
  final String title;
  final Widget child;
  const _InfoBlock({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: HabitatTheme.card, borderRadius: BorderRadius.circular(20), border: Border.all(color: HabitatTheme.border)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 10),
        child,
      ]),
    );
  }
}
