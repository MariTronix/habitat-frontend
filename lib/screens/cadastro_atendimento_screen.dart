import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../src/models.dart';
import '../src/providers.dart';
import '../src/app_theme.dart';

class CadastroAtendimentoScreen extends StatefulWidget {
  const CadastroAtendimentoScreen({super.key});

  @override
  State<CadastroAtendimentoScreen> createState() => _CadastroAtendimentoScreenState();
}

class _CadastroAtendimentoScreenState extends State<CadastroAtendimentoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nomeController = TextEditingController();
  final _cpfController = TextEditingController();
  final _telefoneController = TextEditingController();
  final _enderecoController = TextEditingController();
  final _descricaoController = TextEditingController();
  final _documentoController = TextEditingController();
  TipoAtendimento _tipo = TipoAtendimento.judicial;
  String _estagiarioId = '';
  String _coordenadorId = '';
  List<String> _arquivoNomes = [];
  bool _isSaving = false;

  void _addDocumento() {
    final text = _documentoController.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _arquivoNomes.add(text);
      _documentoController.clear();
    });
  }

  Future<void> _handleSubmit(BuildContext context) async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    final auth = context.read<AuthProvider>();
    final cases = context.read<CasesProvider>();
    final user = auth.user;

    final estagiarioId = user?.role == UserRole.estagiario ? user!.id : _estagiarioId;
    final coordenadorId = user?.role == UserRole.coordenador ? user!.id : _coordenadorId;

    if (estagiarioId.isEmpty || coordenadorId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Selecione estagiário e coordenador.')));
      setState(() => _isSaving = false);
      return;
    }

    final now = DateTime.now();
    final id = 'c${now.millisecondsSinceEpoch}';
    final novoCaso = Caso(
      id: id,
      morador: Morador(
        nome: _nomeController.text.trim(),
        cpf: _cpfController.text.trim(),
        telefone: _telefoneController.text.trim(),
        endereco: _enderecoController.text.trim(),
      ),
      descricao: _descricaoController.text.trim(),
      tipo: _tipo,
      status: CaseStatus.triagem,
      estagiarioId: estagiarioId,
      coordenadorId: coordenadorId,
      dataCriacao: now.toIso8601String().split('T').first,
      dataAtualizacao: now.toIso8601String().split('T').first,
      documentos: _arquivoNomes
          .map((nome) => Documento(id: 'd${DateTime.now().millisecondsSinceEpoch}${nome.hashCode}', nome: nome, tipo: 'pdf', data: now.toIso8601String().split('T').first))
          .toList(),
      timeline: [
        TimelineEvent(id: 't${now.millisecondsSinceEpoch}', descricao: 'Caso criado', data: now.toIso8601String().split('T').first, autor: user?.nome ?? '', tipo: 'criacao'),
      ],
    );

    cases.addCaso(novoCaso);
    setState(() => _isSaving = false);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Atendimento cadastrado com sucesso.')));
    GoRouter.of(context).go('/kanban');
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final users = auth.users.where((u) => u.ativo).toList();
    final estagiarios = users.where((u) => u.role == UserRole.estagiario).toList();
    final coordenadores = users.where((u) => u.role == UserRole.coordenador).toList();
    final user = auth.user;
    if (user?.role == UserRole.estagiario) {
      _estagiarioId = user!.id;
    }
    if (user?.role == UserRole.coordenador) {
      _coordenadorId = user!.id;
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Novo Atendimento', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 6),
            Text('Preencha todos os campos para cadastrar um novo caso', style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 24),
            _SectionCard(title: 'Dados do Morador', child: Column(children: [
              TextFormField(controller: _nomeController, decoration: const InputDecoration(labelText: 'Nome Completo *'), validator: (value) => value?.isEmpty == true ? 'Preencha este campo' : null),
              const SizedBox(height: 16),
              Row(children: [
                Expanded(child: TextFormField(controller: _cpfController, decoration: const InputDecoration(labelText: 'CPF *'), validator: (value) => value?.isEmpty == true ? 'Preencha este campo' : null)),
                const SizedBox(width: 16),
                Expanded(child: TextFormField(controller: _telefoneController, decoration: const InputDecoration(labelText: 'Telefone *'), validator: (value) => value?.isEmpty == true ? 'Preencha este campo' : null)),
              ]),
              const SizedBox(height: 16),
              TextFormField(controller: _enderecoController, decoration: const InputDecoration(labelText: 'Endereço *'), validator: (value) => value?.isEmpty == true ? 'Preencha este campo' : null),
            ])),
            const SizedBox(height: 20),
            _SectionCard(title: 'Detalhes do Caso', child: Column(children: [
              TextFormField(controller: _descricaoController, decoration: const InputDecoration(labelText: 'Descrição do Caso *'), minLines: 3, maxLines: 5, validator: (value) => value?.isEmpty == true ? 'Preencha este campo' : null),
              const SizedBox(height: 16),
              Row(children: [
                Expanded(child: RadioListTile<TipoAtendimento>(value: TipoAtendimento.judicial, groupValue: _tipo, title: const Text('Judicial'), onChanged: (value) => setState(() => _tipo = value!))),
                const SizedBox(width: 8),
                Expanded(child: RadioListTile<TipoAtendimento>(value: TipoAtendimento.conciliacao, groupValue: _tipo, title: const Text('Conciliação'), onChanged: (value) => setState(() => _tipo = value!))),
              ]),
            ])),
            const SizedBox(height: 20),
            _SectionCard(title: 'Responsáveis', child: Column(children: [
              if (user?.role != UserRole.estagiario) ...[
                DropdownButtonFormField<String>(
                  value: _estagiarioId.isEmpty ? null : _estagiarioId,
                  decoration: const InputDecoration(labelText: 'Estagiário Responsável *'),
                  items: estagiarios.map((e) => DropdownMenuItem(value: e.id, child: Text(e.nome))).toList(),
                  onChanged: (value) => setState(() => _estagiarioId = value ?? ''),
                  validator: (value) => value?.isEmpty == true ? 'Selecione um estagiário' : null,
                ),
                const SizedBox(height: 16),
              ],
              if (user?.role != UserRole.coordenador) ...[
                DropdownButtonFormField<String>(
                  value: _coordenadorId.isEmpty ? null : _coordenadorId,
                  decoration: const InputDecoration(labelText: 'Coordenador *'),
                  items: coordenadores.map((c) => DropdownMenuItem(value: c.id, child: Text(c.nome))).toList(),
                  onChanged: (value) => setState(() => _coordenadorId = value ?? ''),
                  validator: (value) => value?.isEmpty == true ? 'Selecione um coordenador' : null,
                ),
              ],
            ])),
            const SizedBox(height: 20),
            _SectionCard(title: 'Documentos Anexos', child: Column(children: [
              Row(children: [
                Expanded(child: TextFormField(controller: _documentoController, decoration: const InputDecoration(labelText: 'Nome do Documento'))),
                const SizedBox(width: 12),
                ElevatedButton(onPressed: _addDocumento, child: const Text('Adicionar')),
              ]),
              const SizedBox(height: 16),
              if (_arquivoNomes.isNotEmpty)
                Column(children: _arquivoNomes.map((name) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Expanded(child: Text(name, style: Theme.of(context).textTheme.bodyMedium)),
                      IconButton(icon: const Icon(Icons.close), onPressed: () => setState(() => _arquivoNomes.remove(name))),
                    ],
                  ),
                )).toList()),
            ])),
            const SizedBox(height: 24),
            Row(mainAxisAlignment: MainAxisAlignment.end, children: [
              OutlinedButton(onPressed: () => GoRouter.of(context).go('/kanban'), child: const Text('Cancelar')),
              const SizedBox(width: 12),
              ElevatedButton(onPressed: _isSaving ? null : () => _handleSubmit(context), child: _isSaving ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text('Cadastrar Atendimento')),
            ]),
          ],
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;
  const _SectionCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(color: HabitatTheme.card, borderRadius: BorderRadius.circular(24), border: Border.all(color: HabitatTheme.border)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 16),
        child,
      ]),
    );
  }
}
