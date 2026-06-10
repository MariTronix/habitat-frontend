import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_colors.dart';

// --- Modelos Simulados Expandidos ---
class SimAnotacao {
  final String id, texto, autor, data;
  SimAnotacao(this.id, this.texto, this.autor, this.data);
}

class SimTimeline {
  final String id, action, userName, createdAt;
  SimTimeline(this.id, this.action, this.userName, this.createdAt);
}

class SimDoc {
  final String id, fileName, contentType;
  SimDoc(this.id, this.fileName, this.contentType);
}

class SimMorador {
  final String nome, cpf, telefone, endereco;
  SimMorador(this.nome, this.cpf, this.telefone, this.endereco);
}

class SimCaso {
  final String id;
  final SimMorador morador;
  final String descricao, tipo;
  String status;
  final String estagiarioId, coordenadorId, dataCriacao;
  List<SimAnotacao> anotacoes;
  List<SimTimeline> timeline;
  List<SimDoc> documentos;
  
  Map<String, String>? caminhoJudicial;
  Map<String, String>? conciliacao;

  SimCaso({
    required this.id, required this.morador, required this.descricao,
    required this.tipo, required this.status, required this.estagiarioId,
    required this.coordenadorId, required this.dataCriacao,
    required this.anotacoes, required this.timeline, required this.documentos,
    this.caminhoJudicial, this.conciliacao,
  });
}

// ---------------------------------------------------------

class DetalhesCasoScreen extends StatefulWidget {
  final String casoId;
  const DetalhesCasoScreen({super.key, required this.casoId});

  @override
  State<DetalhesCasoScreen> createState() => _DetalhesCasoScreenState();
}

class _DetalhesCasoScreenState extends State<DetalhesCasoScreen> {
  String _activeTab = 'info';
  final _novaAnotacaoController = TextEditingController();
  bool _isUploadingDoc = false;

  // Controllers para Caminho Judicial
  final _judProcController = TextEditingController();
  final _judVaraController = TextEditingController();
  final _judDataController = TextEditingController();
  final _judStatusController = TextEditingController();

  // Controllers para Conciliação
  final _concOutraParteController = TextEditingController();
  final _concDataController = TextEditingController();
  final _concLocalController = TextEditingController();
  final _concResController = TextEditingController();

  late SimCaso caso;

  final Map<String, String> statusLabels = {
    'triagem': 'Triagem',
    'documentacao': 'Documentação',
    'processo': 'Em Processo Judicial',
    'finalizado': 'Finalizado',
  };

  final Map<String, Color> statusColors = {
    'triagem': AppColors.mutedForeground,
    'documentacao': AppColors.warning,
    'processo': AppColors.info,
    'finalizado': AppColors.success,
  };

  @override
  void initState() {
    super.initState();
    // Simulação da busca do caso pelo ID
    caso = SimCaso(
      id: widget.casoId,
      morador: SimMorador('João Silva', '111.111.111-11', '(81) 99999-9999', 'Rua das Flores, 123, Recife'),
      descricao: 'Morador busca regularização fundiária de terreno ocupado há mais de 15 anos.',
      tipo: 'judicial',
      status: 'processo',
      estagiarioId: 'Hugo',
      coordenadorId: 'Lourival',
      dataCriacao: '10/06/2026',
      anotacoes: [
        SimAnotacao('a1', 'Documentação inicial recolhida.', 'Hugo', '11/06/2026'),
      ],
      timeline: [
        SimTimeline('t1', 'Caso criado na Triagem', 'Mariana', '10/06/2026 14:30'),
        SimTimeline('t2', 'Status alterado para Em Processo Judicial', 'Lourival', '12/06/2026 09:15'),
      ],
      documentos: [
        SimDoc('d1', 'RG_Copia.pdf', 'application/pdf'),
        SimDoc('d2', 'Comprovante_Residencia.jpg', 'image/jpeg'),
      ],
    );

    // Preencher forms se já existirem dados
    if (caso.caminhoJudicial != null) {
      _judProcController.text = caso.caminhoJudicial!['numeroProcesso'] ?? '';
      _judVaraController.text = caso.caminhoJudicial!['varaJudicial'] ?? '';
      _judDataController.text = caso.caminhoJudicial!['dataEntrada'] ?? '';
      _judStatusController.text = caso.caminhoJudicial!['statusProcesso'] ?? '';
    }
  }

  @override
  void dispose() {
    _novaAnotacaoController.dispose();
    _judProcController.dispose(); _judVaraController.dispose(); _judDataController.dispose(); _judStatusController.dispose();
    _concOutraParteController.dispose(); _concDataController.dispose(); _concLocalController.dispose(); _concResController.dispose();
    super.dispose();
  }

  void _showToast(String title, [Color? color]) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(title),
        backgroundColor: color ?? AppColors.foreground,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _addAnotacao() {
    if (_novaAnotacaoController.text.trim().isEmpty) return;
    setState(() {
      caso.anotacoes.add(SimAnotacao(
        DateTime.now().toString(),
        _novaAnotacaoController.text,
        'Mariana', // Usuário atual
        'Hoje',
      ));
      _novaAnotacaoController.clear();
    });
    _showToast('Anotação adicionada');
  }

  void _handleStatusChange(String newStatus) {
    setState(() {
      caso.status = newStatus;
      caso.timeline.add(SimTimeline(
        DateTime.now().toString(),
        'Status alterado para ${statusLabels[newStatus]}',
        'Mariana',
        'Agora',
      ));
    });
    _showToast('Status atualizado para ${statusLabels[newStatus]}', AppColors.success);
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1024), // max-w-5xl
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Botão Voltar
              TextButton.icon(
                onPressed: () => context.pop(),
                icon: Icon(Icons.arrow_back, size: 16.0, color: AppColors.mutedForeground),
                label: Text('Voltar', style: TextStyle(color: AppColors.mutedForeground)),
                style: TextButton.styleFrom(padding: EdgeInsets.zero, alignment: Alignment.centerLeft),
              ),
              const SizedBox(height: 16.0),

              // Header do Caso
              _buildHeader(),
              const SizedBox(height: 24.0),

              // Abas (Tabs)
              _buildTabs(),
              const SizedBox(height: 24.0),

              // Conteúdo da Aba Ativa
              if (_activeTab == 'info') _buildInfoTab(),
              if (_activeTab == 'timeline') _buildTimelineTab(),
              if (_activeTab == 'docs') _buildDocsTab(),
              if (_activeTab == 'judicial') _buildJudicialTab(),
              if (_activeTab == 'conciliacao') _buildConciliacaoTab(),
              
              const SizedBox(height: 40.0),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(12.0), border: Border.all(color: AppColors.border)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(caso.morador.nome, style: TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold, color: AppColors.foreground)),
                    Text('${caso.morador.cpf} • ${caso.morador.telefone}', style: TextStyle(fontSize: 14.0, color: AppColors.mutedForeground)),
                    Text(caso.morador.endereco, style: TextStyle(fontSize: 14.0, color: AppColors.mutedForeground)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
                    decoration: BoxDecoration(color: statusColors[caso.status], borderRadius: BorderRadius.circular(16.0)),
                    child: Text(statusLabels[caso.status]!, style: const TextStyle(fontSize: 12.0, fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
                  const SizedBox(height: 8.0),
                  Container(
                    height: 32,
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    decoration: BoxDecoration(border: Border.all(color: AppColors.border), borderRadius: BorderRadius.circular(8.0)),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: caso.status,
                        style: TextStyle(fontSize: 12.0, color: AppColors.foreground),
                        icon: Icon(Icons.arrow_drop_down, size: 16.0, color: AppColors.mutedForeground),
                        onChanged: (v) { if (v != null) _handleStatusChange(v); },
                        items: statusLabels.keys.map((s) => DropdownMenuItem(value: s, child: Text(statusLabels[s]!))).toList(),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16.0),
          Wrap(
            spacing: 16.0,
            runSpacing: 8.0,
            children: [
              _buildBadgedInfo('Tipo:', caso.tipo == 'judicial' ? 'Judicial' : 'Conciliação'),
              _buildBadgedInfo('Estagiário:', caso.estagiarioId),
              _buildBadgedInfo('Coordenador:', caso.coordenadorId),
              _buildBadgedInfo('Criado em:', caso.dataCriacao),
            ],
          ),
          const SizedBox(height: 16.0),
          Row(
            children: [
              OutlinedButton.icon(
                onPressed: () => _showToast('Download de Procuração iniciado'),
                icon: const Icon(Icons.download, size: 14.0),
                label: const Text('Procuração', style: TextStyle(fontSize: 12.0)),
                style: OutlinedButton.styleFrom(foregroundColor: AppColors.foreground, side: BorderSide(color: AppColors.border)),
              ),
              const SizedBox(width: 8.0),
              OutlinedButton.icon(
                onPressed: () => _showToast('Download de Declaração iniciado'),
                icon: const Icon(Icons.download, size: 14.0),
                label: const Text('Decl. Hipossuficiência', style: TextStyle(fontSize: 12.0)),
                style: OutlinedButton.styleFrom(foregroundColor: AppColors.foreground, side: BorderSide(color: AppColors.border)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBadgedInfo(String label, String value) {
    return RichText(
      text: TextSpan(
        style: TextStyle(fontSize: 12.0, color: AppColors.mutedForeground),
        children: [
          TextSpan(text: '$label '),
          TextSpan(text: value, style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.foreground)),
        ],
      ),
    );
  }

  Widget _buildTabs() {
    final tabs = [
      {'key': 'info', 'label': 'Informações', 'icon': Icons.description_outlined},
      {'key': 'timeline', 'label': 'Linha do Tempo', 'icon': Icons.access_time},
      {'key': 'docs', 'label': 'Documentos', 'icon': Icons.upload_file},
      if (caso.tipo == 'judicial') {'key': 'judicial', 'label': 'Caminho Judicial', 'icon': Icons.balance},
      if (caso.tipo == 'conciliacao') {'key': 'conciliacao', 'label': 'Conciliação', 'icon': Icons.handshake_outlined},
    ];

    return Container(
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.border))),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: tabs.map((t) {
            bool isActive = _activeTab == t['key'];
            return InkWell(
              onTap: () => setState(() => _activeTab = t['key'] as String),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: isActive ? AppColors.accent : Colors.transparent, width: 2.0)),
                ),
                child: Row(
                  children: [
                    Icon(t['icon'] as IconData, size: 16.0, color: isActive ? AppColors.accent : AppColors.mutedForeground),
                    const SizedBox(width: 8.0),
                    Text(
                      t['label'] as String,
                      style: TextStyle(fontSize: 14.0, fontWeight: FontWeight.w500, color: isActive ? AppColors.accent : AppColors.mutedForeground),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildInfoTab() {
    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(12.0), border: Border.all(color: AppColors.border)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Descrição do Caso', style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.w600, color: AppColors.foreground)),
          const SizedBox(height: 8.0),
          Text(caso.descricao, style: TextStyle(fontSize: 14.0, color: AppColors.mutedForeground)),
          
          const SizedBox(height: 24.0),
          Text('Anotações', style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.w600, color: AppColors.foreground)),
          const SizedBox(height: 12.0),
          
          ...caso.anotacoes.map((a) => Container(
            margin: const EdgeInsets.only(bottom: 12.0),
            padding: const EdgeInsets.all(12.0),
            decoration: BoxDecoration(color: AppColors.muted.withOpacity(0.5), borderRadius: BorderRadius.circular(8.0)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(a.autor, style: TextStyle(fontSize: 12.0, fontWeight: FontWeight.bold, color: AppColors.foreground)),
                    Text(a.data, style: TextStyle(fontSize: 12.0, color: AppColors.mutedForeground)),
                  ],
                ),
                const SizedBox(height: 4.0),
                Text(a.texto, style: TextStyle(fontSize: 14.0, color: AppColors.foreground)),
              ],
            ),
          )),
          
          const SizedBox(height: 8.0),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: TextField(
                  controller: _novaAnotacaoController,
                  maxLines: 2,
                  decoration: InputDecoration(
                    hintText: 'Adicionar anotação...',
                    hintStyle: TextStyle(color: AppColors.mutedForeground, fontSize: 14.0),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0), borderSide: BorderSide(color: AppColors.border)),
                  ),
                ),
              ),
              const SizedBox(width: 12.0),
              ElevatedButton(
                onPressed: _addAnotacao,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: AppColors.accentForeground,
                  padding: const EdgeInsets.all(16.0),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
                ),
                child: const Icon(Icons.edit, size: 20.0),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineTab() {
    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(12.0), border: Border.all(color: AppColors.border)),
      child: Column(
        children: caso.timeline.asMap().entries.map((entry) {
          int idx = entry.key;
          SimTimeline ev = entry.value;
          bool isLast = idx == caso.timeline.length - 1;
          
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  Container(width: 12, height: 12, margin: const EdgeInsets.only(top: 4.0), decoration: BoxDecoration(color: AppColors.accent, shape: BoxShape.circle)),
                  if (!isLast) Container(width: 2, height: 40, color: AppColors.border),
                ],
              ),
              const SizedBox(width: 16.0),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(ev.action, style: TextStyle(fontSize: 14.0, fontWeight: FontWeight.w500, color: AppColors.foreground)),
                      Text('${ev.userName} • ${ev.createdAt}', style: TextStyle(fontSize: 12.0, color: AppColors.mutedForeground)),
                    ],
                  ),
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildDocsTab() {
    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(12.0), border: Border.all(color: AppColors.border)),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Documentos', style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.w600, color: AppColors.foreground)),
              OutlinedButton.icon(
                onPressed: () {
                  setState(() => _isUploadingDoc = true);
                  Future.delayed(const Duration(seconds: 1), () {
                    setState(() {
                      caso.documentos.add(SimDoc(DateTime.now().toString(), 'Novo_Documento.pdf', 'application/pdf'));
                      _isUploadingDoc = false;
                    });
                    _showToast('Upload concluído', AppColors.success);
                  });
                },
                icon: _isUploadingDoc ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.upload_file, size: 14.0),
                label: Text(_isUploadingDoc ? 'Enviando...' : 'Upload', style: const TextStyle(fontSize: 12.0)),
              ),
            ],
          ),
          const SizedBox(height: 16.0),
          if (caso.documentos.isEmpty)
            Padding(padding: const EdgeInsets.all(32.0), child: Text('Nenhum documento anexado.', style: TextStyle(color: AppColors.mutedForeground))),
          ...caso.documentos.map((d) => Container(
            padding: const EdgeInsets.symmetric(vertical: 12.0),
            decoration: BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.border))),
            child: Row(
              children: [
                Icon(Icons.description_outlined, size: 24.0, color: AppColors.accent),
                const SizedBox(width: 12.0),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(d.fileName, style: TextStyle(fontSize: 14.0, fontWeight: FontWeight.w500, color: AppColors.foreground)),
                      Text(d.contentType.split('/')[1].toUpperCase(), style: TextStyle(fontSize: 12.0, color: AppColors.mutedForeground)),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.download, size: 20.0),
                  color: AppColors.mutedForeground,
                  onPressed: () => _showToast('Download iniciado'),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildJudicialTab() {
    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(12.0), border: Border.all(color: AppColors.border)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Caminho Judicial', style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.w600, color: AppColors.foreground)),
          const SizedBox(height: 16.0),
          Row(
            children: [
              Expanded(child: _buildTextField('Número do Processo', _judProcController)),
              const SizedBox(width: 16.0),
              Expanded(child: _buildTextField('Vara Judicial', _judVaraController)),
            ],
          ),
          const SizedBox(height: 16.0),
          Row(
            children: [
              Expanded(child: _buildTextField('Data de Entrada', _judDataController)),
              const SizedBox(width: 16.0),
              Expanded(child: _buildTextField('Status do Processo', _judStatusController)),
            ],
          ),
          const SizedBox(height: 24.0),
          ElevatedButton(
            onPressed: () => _showToast('Dados judiciais salvos', AppColors.success),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.accent, foregroundColor: AppColors.accentForeground),
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
  }

  Widget _buildConciliacaoTab() {
    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(12.0), border: Border.all(color: AppColors.border)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Conciliação', style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.w600, color: AppColors.foreground)),
          const SizedBox(height: 16.0),
          _buildTextField('Dados da Outra Parte', _concOutraParteController),
          const SizedBox(height: 16.0),
          Row(
            children: [
              Expanded(child: _buildTextField('Data da Audiência', _concDataController)),
              const SizedBox(width: 16.0),
              Expanded(child: _buildTextField('Local', _concLocalController)),
            ],
          ),
          const SizedBox(height: 16.0),
          _buildTextField('Resultado da Conciliação', _concResController, maxLines: 3),
          const SizedBox(height: 24.0),
          ElevatedButton(
            onPressed: () => _showToast('Dados de conciliação salvos', AppColors.success),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.accent, foregroundColor: AppColors.accentForeground),
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, {int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 14.0, fontWeight: FontWeight.w500, color: AppColors.foreground)),
        const SizedBox(height: 8.0),
        TextField(
          controller: controller,
          maxLines: maxLines,
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 12.0),
            filled: true,
            fillColor: AppColors.background,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0), borderSide: BorderSide(color: AppColors.border)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0), borderSide: BorderSide(color: AppColors.border)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0), borderSide: BorderSide(color: AppColors.accent)),
          ),
        ),
      ],
    );
  }
}