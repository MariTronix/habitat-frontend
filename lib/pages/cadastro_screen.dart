import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart'; // Importante para o acesso à API
import '../theme/app_colors.dart';
import '../services/api_service.dart'; // O serviço que criamos

class SimUser {
  final String id;
  final String nome;
  final String role;
  SimUser(this.id, this.nome, this.role);
}

class CadastroScreen extends StatefulWidget {
  const CadastroScreen({super.key});

  @override
  State<CadastroScreen> createState() => _CadastroScreenState();
}

class _CadastroScreenState extends State<CadastroScreen> {
  final _nomeController = TextEditingController();
  final _cpfController = TextEditingController();
  final _telefoneController = TextEditingController();
  final _enderecoController = TextEditingController();
  final _descricaoController = TextEditingController();
  
  String _tipoAtendimento = 'judicial';
  String? _estagiarioId;
  String? _coordenadorId;
  
  List<PlatformFile> _files = [];
  bool _isUploading = false;

  final List<SimUser> _users = [
    SimUser('coord1', 'Lourival (Coordenador)', 'coordenador'),
    SimUser('coord2', 'Vladson (Coordenador)', 'coordenador'),
    SimUser('est1', 'Hugo (Estagiário)', 'estagiario'),
    SimUser('est2', 'Gabriel (Estagiário)', 'estagiario'),
  ];

  @override
  void dispose() {
    _nomeController.dispose();
    _cpfController.dispose();
    _telefoneController.dispose();
    _enderecoController.dispose();
    _descricaoController.dispose();
    super.dispose();
  }

  Future<void> _pickFiles() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx', 'jpg', 'png', 'jpeg'],
    );

    if (result != null) {
      setState(() => _files.addAll(result.files));
    }
  }

  void _removeFile(int index) => setState(() => _files.removeAt(index));

  Future<void> _handleSubmit() async {
    if (_nomeController.text.isEmpty || _cpfController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Preencha os campos obrigatórios!')));
      return;
    }

    setState(() => _isUploading = true);

    try {
      final api = Provider.of<ApiService>(context, listen: false);

      final Map<String, dynamic> body = {
        'nome': _nomeController.text,
        'cpf': _cpfController.text.replaceAll(RegExp(r'\D'), ''),
        'telefone': _telefoneController.text.replaceAll(RegExp(r'\D'), ''),
        'endereco': _enderecoController.text,
        'descricao': _descricaoController.text,
        'tipo': _tipoAtendimento,
        'estagiarioId': _estagiarioId,
        'coordenadorId': _coordenadorId,
      };

      final response = await api.post('/atendimentos', body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Atendimento cadastrado com sucesso!'), backgroundColor: AppColors.success),
        );
        context.go('/kanban');
      } else {
        throw Exception('Erro ${response.statusCode}: Não foi possível salvar no servidor.');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final estagiarios = _users.where((u) => u.role == 'estagiario').toList();
    final coordenadores = _users.where((u) => u.role == 'coordenador').toList();

    return SingleChildScrollView(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 768),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Novo Atendimento', style: TextStyle(fontSize: 24.0, fontWeight: FontWeight.bold, color: AppColors.foreground)),
              const SizedBox(height: 24.0),
              
              // Formulário simplificado visualmente para o exemplo
              _buildFormSection('Dados do Morador', [
                _buildTextField('Nome Completo *', 'Nome completo', _nomeController),
                _buildTextField('CPF *', '000.000.000-00', _cpfController, inputFormatters: [CpfInputFormatter()]),
              ]),
              
              const SizedBox(height: 16.0),
              
              _buildFormSection('Responsáveis', [
                _buildDropdown('Estagiário *', estagiarios, _estagiarioId, (v) => setState(() => _estagiarioId = v)),
                _buildDropdown('Coordenador *', coordenadores, _coordenadorId, (v) => setState(() => _coordenadorId = v)),
              ]),

              const SizedBox(height: 24.0),

              ElevatedButton(
                onPressed: _isUploading ? null : _handleSubmit,
                child: Text(_isUploading ? 'Salvando...' : 'Cadastrar Atendimento'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- Helpers de UI ---
  Widget _buildFormSection(String title, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(color: AppColors.card, border: Border.all(color: AppColors.border), borderRadius: BorderRadius.circular(12)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        ...children,
      ]),
    );
  }

  Widget _buildTextField(String label, String hint, TextEditingController controller, {List<TextInputFormatter>? inputFormatters}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: controller,
        inputFormatters: inputFormatters,
        decoration: InputDecoration(labelText: label, hintText: hint, border: const OutlineInputBorder()),
      ),
    );
  }

  Widget _buildDropdown(String label, List<SimUser> items, String? value, Function(String?) onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: DropdownButtonFormField<String>(
        value: value,
        decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
        items: items.map((u) => DropdownMenuItem(value: u.id, child: Text(u.nome))).toList(),
        onChanged: onChanged,
      ),
    );
  }
}

// Formatadores mantidos conforme original
class CpfInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final text = newValue.text.replaceAll(RegExp(r'\D'), '');
    final buffer = StringBuffer();
    for (int i = 0; i < text.length; i++) {
      if (i == 3 || i == 6) buffer.write('.');
      if (i == 9) buffer.write('-');
      buffer.write(text[i]);
    }
    final formatted = buffer.toString();
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

class TelefoneInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final text = newValue.text.replaceAll(RegExp(r'\D'), '');
    final buffer = StringBuffer();
    if (text.length > 0) buffer.write('(');
    for (int i = 0; i < text.length; i++) {
      if (i == 2) buffer.write(') ');
      if (i == 7) buffer.write('-');
      buffer.write(text[i]);
    }
    final formatted = buffer.toString();
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}