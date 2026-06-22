import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'package:provider/provider.dart';

  import '../services/api_service.dart';

class SimUser {
  String id;
  String nome;
  String email;
  String role;
  bool ativo;
  String? senha;
  String? coordinatorId;

  SimUser({
    required this.id,
    required this.nome,
    required this.email,
    required this.role,
    required this.ativo,
    this.senha,
    this.coordinatorId,
  });

  SimUser clone() => SimUser(id: id, nome: nome, email: email, role: role, ativo: ativo, senha: senha, coordinatorId: coordinatorId);
}

class GestaoUsuariosScreen extends StatefulWidget {
  const GestaoUsuariosScreen({super.key});

  @override
  State<GestaoUsuariosScreen> createState() => _GestaoUsuariosScreenState();
}

class _GestaoUsuariosScreenState extends State<GestaoUsuariosScreen> {
  // Lista inicial simulada
  List<SimUser> users = [
    SimUser(id: '1', nome: 'Mariana Mendes Lima', email: 'mariana@pronet.com', role: 'master', ativo: true),
    SimUser(id: '2', nome: 'Lourival', email: 'lourival@pronet.com', role: 'coordenador', ativo: true),
    SimUser(id: '3', nome: 'Vladson', email: 'vladson@pronet.com', role: 'coordenador', ativo: true),
    SimUser(id: '4', nome: 'Hugo', email: 'hugo@pronet.com', role: 'estagiario', ativo: true, coordinatorId: '2'),
  ];

  final Map<String, String> roleLabels = {
    'master': 'Administrador',
    'coordenador': 'Coordenador',
    'estagiario': 'Estagiário'
  };

  void _showToast(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.destructive : AppColors.foreground,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _removeUser(String id) {
    setState(() {
      final index = users.indexWhere((u) => u.id == id);
      if (index != -1) {
        users[index].ativo = false; 
      }
    });
    _showToast('Usuário inativado com sucesso.');
  }

  void _openUserModal({SimUser? userToEdit}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return UserModal(
          isNew: userToEdit == null,
          initialUser: userToEdit ?? SimUser(id: DateTime.now().millisecondsSinceEpoch.toString(), nome: '', email: '', role: 'estagiario', ativo: true),
          allUsers: users,
          onSave: (savedUser) async {
            final userPayload = {
             'name': savedUser.nome,
              'email': savedUser.email,
              'password': savedUser.senha ?? '',
              'role': _mapRoleToJava(savedUser.role), 
              if (savedUser.role == 'estagiario' && savedUser.coordinatorId != null) 
                'coordinatorId': int.tryParse(savedUser.coordinatorId!),
            };

            try {
              final api = Provider.of<ApiService>(context, listen: false);

              if (userToEdit == null) {
                await api.createUser(userPayload);
                
                setState(() {
                  users.add(savedUser);
                });
                _showToast('Usuário criado com sucesso.');
              } else {
                setState(() {
                  final index = users.indexWhere((u) => u.id == savedUser.id);
                  if (index != -1) users[index] = savedUser;
                });
                _showToast('Usuário atualizado (Apenas em memória por enquanto).');
              }
            } catch (e) {
              _showToast(e.toString(), isError: true);
            }
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 896), // max-w-4xl
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              LayoutBuilder(
                builder: (context, constraints) {
                  bool isMobile = constraints.maxWidth < 500;
                  return Flex(
                    direction: isMobile ? Axis.vertical : Axis.horizontal,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: isMobile ? CrossAxisAlignment.start : CrossAxisAlignment.center,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Gestão de Usuários', style: TextStyle(fontSize: 24.0, fontWeight: FontWeight.bold, color: AppColors.foreground)),
                          Text('Gerencie os acessos ao sistema', style: TextStyle(fontSize: 14.0, color: AppColors.mutedForeground)),
                        ],
                      ),
                      if (isMobile) const SizedBox(height: 16.0),
                      ElevatedButton.icon(
                        onPressed: () => _openUserModal(),
                        icon: const Icon(Icons.add, size: 18.0),
                        label: const Text('Novo Usuário'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.accent,
                          foregroundColor: AppColors.accentForeground,
                          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 24.0),

              // Tabela
              Container(
                decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(12.0), border: Border.all(color: AppColors.border)),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    headingRowColor: WidgetStateProperty.all(AppColors.muted.withOpacity(0.5)),
                    dividerThickness: 1,
                    dataRowMinHeight: 60,
                    dataRowMaxHeight: 60,
                    columns: const [
                      DataColumn(label: Text('Nome', style: TextStyle(fontWeight: FontWeight.w600))),
                      DataColumn(label: Text('E-mail', style: TextStyle(fontWeight: FontWeight.w600))),
                      DataColumn(label: Text('Perfil', style: TextStyle(fontWeight: FontWeight.w600))),
                      DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.w600))),
                      DataColumn(label: Text('Ações', style: TextStyle(fontWeight: FontWeight.w600))),
                    ],
                    rows: users.map((u) {
                      return DataRow(
                        cells: [
                          DataCell(Text(u.nome, style: TextStyle(fontWeight: FontWeight.w500, color: AppColors.foreground))),
                          DataCell(Text(u.email, style: TextStyle(color: AppColors.mutedForeground))),
                          DataCell(
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 2.0),
                              decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(12.0)),
                              child: Text(roleLabels[u.role]!, style: TextStyle(fontSize: 12.0, fontWeight: FontWeight.w500, color: AppColors.primary)),
                            ),
                          ),
                          DataCell(
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 2.0),
                              decoration: BoxDecoration(color: u.ativo ? AppColors.success.withOpacity(0.1) : AppColors.destructive.withOpacity(0.1), borderRadius: BorderRadius.circular(12.0)),
                              child: Text(u.ativo ? 'Ativo' : 'Inativo', style: TextStyle(fontSize: 12.0, fontWeight: FontWeight.w500, color: u.ativo ? AppColors.success : AppColors.destructive)),
                            ),
                          ),
                          DataCell(
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(icon: Icon(Icons.edit_outlined, size: 18.0, color: AppColors.foreground), onPressed: () => _openUserModal(userToEdit: u), splashRadius: 20),
                                IconButton(icon: Icon(Icons.delete_outline, size: 18.0, color: AppColors.destructive), onPressed: () => _removeUser(u.id), splashRadius: 20),
                              ],
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _mapRoleToJava(String dartRole) {
    switch (dartRole) {
      case 'master': return 'ADMINISTRATOR';
      case 'coordenador': return 'COORDINATOR';
      case 'estagiario': return 'INTERN';
      default: return 'INTERN';
    }
  }
}

// Modal Component
class UserModal extends StatefulWidget {
  final bool isNew;
  final SimUser initialUser;
  final List<SimUser> allUsers;
  final Function(SimUser) onSave;

  const UserModal({super.key, required this.isNew, required this.initialUser, required this.allUsers, required this.onSave});

  @override
  State<UserModal> createState() => _UserModalState();
}

class _UserModalState extends State<UserModal> {
  late SimUser editing;
  final TextEditingController _senhaController = TextEditingController();

  final List<Map<String, dynamic>> passwordRules = [
    {'label': 'Mínimo 6 caracteres', 'test': (String p) => p.length >= 6},
    {'label': 'Letra maiúscula (A-Z)', 'test': (String p) => RegExp(r'[A-Z]').hasMatch(p)},
    {'label': 'Letra minúscula (a-z)', 'test': (String p) => RegExp(r'[a-z]').hasMatch(p)},
    {'label': 'Número (0-9)', 'test': (String p) => RegExp(r'\d').hasMatch(p)},
    {'label': 'Caractere especial (!@#\$...)', 'test': (String p) => RegExp(r'[!@#$%^&*()_+\-=\[\]{};' r"':" r'\\|,.<>\/?]').hasMatch(p)},
  ];

  @override
  void initState() {
    super.initState();
    editing = widget.initialUser.clone();
  }

  @override
  void dispose() {
    _senhaController.dispose();
    super.dispose();
  }

  bool _validatePassword(String p) => passwordRules.every((rule) => (rule['test'] as Function(String))(p));

  void _handleSave() {
    final senha = _senhaController.text;
    
    if (widget.isNew && !_validatePassword(senha)) {
      _showError('A senha não atende aos requisitos mínimos de segurança.');
      return;
    }
    
    if (!widget.isNew && senha.isNotEmpty && !_validatePassword(senha)) {
      _showError('A nova senha não atende aos requisitos mínimos de segurança.');
      return;
    }

    if (senha.isNotEmpty) editing.senha = senha;
    widget.onSave(editing);
    Navigator.of(context).pop();
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: AppColors.destructive, behavior: SnackBarBehavior.floating));
  }

  @override
  Widget build(BuildContext context) {
    final coordenadores = widget.allUsers.where((u) => u.role == 'coordenador').toList();
    final senhaAtual = _senhaController.text;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: Container(
        width: 450,
        padding: const EdgeInsets.all(24.0),
        decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(12.0)),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Modal Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(widget.isNew ? 'Novo Usuário' : 'Editar Usuário', style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.w600, color: AppColors.foreground)),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.of(context).pop(), padding: EdgeInsets.zero, constraints: const BoxConstraints(), splashRadius: 20),
                ],
              ),
              const SizedBox(height: 16.0),

              // Inputs
              _buildInput('Nome', editing.nome, (v) => setState(() => editing.nome = v)),
              const SizedBox(height: 12.0),
              _buildInput('E-mail', editing.email, (v) => setState(() => editing.email = v)),
              const SizedBox(height: 12.0),
              
              Text('Senha ${widget.isNew ? '' : '(deixe em branco para manter)'}', style: TextStyle(fontSize: 14.0, fontWeight: FontWeight.w500, color: AppColors.foreground)),
              const SizedBox(height: 6.0),
              TextField(
                controller: _senhaController,
                obscureText: true,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: widget.isNew ? 'Ex: Senha@123' : 'Deixe em branco para não alterar',
                  hintStyle: TextStyle(color: AppColors.mutedForeground, fontSize: 14.0),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 12.0),
                  filled: true,
                  fillColor: AppColors.background,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0), borderSide: BorderSide(color: AppColors.border)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0), borderSide: BorderSide(color: AppColors.border)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0), borderSide: BorderSide(color: AppColors.accent)),
                ),
              ),
              
              if (widget.isNew || senhaAtual.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Requisitos da senha:', style: TextStyle(fontSize: 12.0, fontWeight: FontWeight.w500, color: AppColors.mutedForeground)),
                      const SizedBox(height: 4.0),
                      ...passwordRules.map((rule) {
                        bool ok = (rule['test'] as Function(String))(senhaAtual);
                        return Row(
                          children: [
                            Icon(ok ? Icons.check_circle : Icons.radio_button_unchecked, size: 12.0, color: ok ? AppColors.success : AppColors.mutedForeground),
                            const SizedBox(width: 4.0),
                            Text(rule['label'], style: TextStyle(fontSize: 12.0, color: ok ? AppColors.success : AppColors.mutedForeground)),
                          ],
                        );
                      }),
                    ],
                  ),
                ),

              const SizedBox(height: 12.0),
              Text('Perfil', style: TextStyle(fontSize: 14.0, fontWeight: FontWeight.w500, color: AppColors.foreground)),
              const SizedBox(height: 6.0),
              DropdownButtonFormField<String>(
                value: editing.role,
                decoration: _dropdownDecoration(),
                items: [
                  const DropdownMenuItem(value: 'estagiario', child: Text('Estagiário')),
                  const DropdownMenuItem(value: 'coordenador', child: Text('Coordenador')),
                  if (!widget.isNew && editing.role == 'master') const DropdownMenuItem(value: 'master', child: Text('Administrador')),
                ],
                onChanged: (v) => setState(() => editing.role = v!),
              ),

              if (editing.role == 'estagiario') ...[
                const SizedBox(height: 12.0),
                Text('Coordenador Vinculado', style: TextStyle(fontSize: 14.0, fontWeight: FontWeight.w500, color: AppColors.foreground)),
                const SizedBox(height: 6.0),
                DropdownButtonFormField<String>(
                  value: editing.coordinatorId,
                  decoration: _dropdownDecoration(),
                  hint: const Text('Selecione...'),
                  items: coordenadores.map((c) => DropdownMenuItem(value: c.id, child: Text(c.nome))).toList(),
                  onChanged: (v) => setState(() => editing.coordinatorId = v),
                ),
              ],

              const SizedBox(height: 16.0),
              Row(
                children: [
                  Checkbox(
                    value: editing.ativo,
                    onChanged: (v) => setState(() => editing.ativo = v!),
                    activeColor: AppColors.accent,
                  ),
                  const Text('Ativo', style: TextStyle(fontSize: 14.0)),
                ],
              ),

              const SizedBox(height: 24.0),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(foregroundColor: AppColors.foreground, side: BorderSide(color: AppColors.border)),
                    child: const Text('Cancelar'),
                  ),
                  const SizedBox(width: 12.0),
                  ElevatedButton(
                    onPressed: _handleSave,
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.accent, foregroundColor: AppColors.accentForeground),
                    child: const Text('Salvar'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInput(String label, String value, Function(String) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 14.0, fontWeight: FontWeight.w500, color: AppColors.foreground)),
        const SizedBox(height: 6.0),
        TextField(
          controller: TextEditingController(text: value)..selection = TextSelection.collapsed(offset: value.length),
          onChanged: onChanged,
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

  InputDecoration _dropdownDecoration() {
    return InputDecoration(
      contentPadding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 12.0),
      filled: true,
      fillColor: AppColors.background,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0), borderSide: BorderSide(color: AppColors.border)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0), borderSide: BorderSide(color: AppColors.border)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0), borderSide: BorderSide(color: AppColors.accent)),
    );
  }
}