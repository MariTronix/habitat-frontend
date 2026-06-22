import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../src/models.dart';
import '../src/providers.dart';
import '../src/app_theme.dart';
import '../services/api_service.dart';

class GestaoUsuariosScreen extends StatefulWidget {
  const GestaoUsuariosScreen({super.key});

  @override
  State<GestaoUsuariosScreen> createState() => _GestaoUsuariosScreenState();
}

class _GestaoUsuariosScreenState extends State<GestaoUsuariosScreen> {
  User? _editingUser;
  final _formKey = GlobalKey<FormState>();
  final _nomeController = TextEditingController();
  final _emailController = TextEditingController();
  final _senhaController = TextEditingController();
  UserRole _selectedRole = UserRole.estagiario;
  bool _ativo = true;

  void _openEdit(User user) {
    setState(() {
      _editingUser = user;
      _nomeController.text = user.nome;
      _emailController.text = user.email;
      _senhaController.clear();
      _selectedRole = user.role;
      _ativo = user.ativo;
    });
  }

  void _openNew() {
    // 1. Limpeza inicial
    setState(() {
      _editingUser = null;
      _nomeController.clear();
      _emailController.clear();
      _senhaController.clear();
      _selectedRole = UserRole.estagiario;
      _ativo = true;
    });

    showDialog(
      context: context,
      builder: (context) {
        // 2. O StatefulBuilder permite atualizar a interface apenas de dentro da janela
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Novo Usuário'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: _nomeController,
                      decoration: const InputDecoration(
                        labelText: 'Nome completo',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'E-mail',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _senhaController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Senha',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 3. A Caixa de Seleção (Dropdown) para o Cargo
                    DropdownButtonFormField<UserRole>(
                      value: _selectedRole,
                      decoration: const InputDecoration(
                        labelText: 'Cargo no Sistema',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: UserRole.estagiario,
                          child: Text('Estagiário'),
                        ),
                        DropdownMenuItem(
                          value: UserRole.coordenador,
                          child: Text('Coordenador'),
                        ),
                      ],
                      onChanged: (UserRole? newValue) {
                        if (newValue != null) {
                          // Usamos o setDialogState para atualizar o dropdown visualmente!
                          setDialogState(() {
                            _selectedRole = newValue;
                          });
                        }
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancelar', style: TextStyle(color: Colors.red)),
                ),
                ElevatedButton(
                  onPressed: () async {
                    // 4. Lógica de Persistência (Salvamento)
                    await _salvarUsuario(context);
                  },
                  child: const Text('Salvar Usuário'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _salvarUsuario(BuildContext dialogContext) async {
    if (_nomeController.text.isEmpty || _emailController.text.isEmpty || _senhaController.text.isEmpty) {
      ScaffoldMessenger.of(dialogContext).showSnackBar(
        const SnackBar(content: Text('Por favor, preencha todos os campos!'), backgroundColor: Colors.red),
      );
      return;
    }

    final Map<String, dynamic> novoUsuario = {
      'name': _nomeController.text.trim(),
      'email': _emailController.text.trim(),
      'password': _senhaController.text.trim(),
      'role': _mapRoleToJava(_selectedRole.name),
      if (_selectedRole.name == 'estagiario') 'coordinatorId': 8,
    };

    try {
      // 2. Chama a API de verdade
      final apiService = Provider.of<ApiService>(context, listen: false);
      await apiService.createUser(novoUsuario);

      // 3. Fecha o modal de carregamento e mostra sucesso
      if (!mounted) return;
      Navigator.of(dialogContext).pop();
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Usuário cadastrado com sucesso no banco!'), backgroundColor: Colors.green),
      );
      
    } catch (error) {
      // 4. Mostra o erro exato do Java na tela
      if (!mounted) return;
      ScaffoldMessenger.of(dialogContext).showSnackBar(
        SnackBar(content: Text(error.toString().replaceAll('Exception: ', '')), backgroundColor: Colors.red),
      );
    }
  }

  String _mapRoleToJava(String dartRole) {
    switch (dartRole.toLowerCase()) {
      case 'master': return 'ADMINISTRATOR';
      case 'coordenador': return 'COORDINATOR';
      case 'estagiario': return 'INTERN';
      default: return 'INTERN';
    }
  }

  void _save(BuildContext context) {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    if (_editingUser == null) {
      final id = 'u${DateTime.now().millisecondsSinceEpoch}';
      auth.addUser(User(id: id, nome: _nomeController.text.trim(), email: _emailController.text.trim(), role: _selectedRole, ativo: _ativo, senha: _senhaController.text.trim().isEmpty ? 'Senha@123' : _senhaController.text.trim()));
    } else {
      auth.updateUser(_editingUser!.id, nome: _nomeController.text.trim(), email: _emailController.text.trim(), role: _selectedRole, ativo: _ativo, senha: _senhaController.text.trim().isEmpty ? null : _senhaController.text.trim());
    }
    setState(() => _editingUser = null);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Usuário salvo com sucesso')));
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final users = auth.users;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // O Expanded faz a coluna de textos ocupar apenas o espaço disponível,
            // impedindo que ela empurre o botão para fora da tela.
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Gestão de Usuários',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Gerencie os acessos ao sistema',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            // Um pequeno espaço para o texto não colar no botão se a tela for muito estreita
            const SizedBox(width: 16),
            ElevatedButton.icon(
              onPressed: _openNew,
              icon: const Icon(Icons.add),
              label: const Text('Novo Usuário'),
            ),
          ],
        ),
        const SizedBox(height: 24),
        if (_editingUser != null || _editingUser == null && _nomeController.text.isNotEmpty)
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            margin: const EdgeInsets.only(bottom: 24),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Text(_editingUser == null ? 'Novo Usuário' : 'Editar Usuário', style: Theme.of(context).textTheme.titleMedium),
                    IconButton(onPressed: () => setState(() => _editingUser = null), icon: const Icon(Icons.close)),
                  ]),
                  const SizedBox(height: 20),
                  TextFormField(controller: _nomeController, decoration: const InputDecoration(labelText: 'Nome'), validator: (value) => value?.isEmpty == true ? 'Preencha o nome' : null),
                  const SizedBox(height: 16),
                  TextFormField(controller: _emailController, decoration: const InputDecoration(labelText: 'E-mail'), validator: (value) => value?.isEmpty == true ? 'Preencha o e-mail' : null),
                  const SizedBox(height: 16),
                  TextFormField(controller: _senhaController, decoration: InputDecoration(labelText: _editingUser == null ? 'Senha' : 'Senha (deixe em branco para manter)'), obscureText: true),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<UserRole>(
                    value: _selectedRole,
                    decoration: const InputDecoration(labelText: 'Perfil'),
                    items: UserRole.values.map((role) => DropdownMenuItem(value: role, child: Text(role.label))).toList(),
                    onChanged: (value) => setState(() => _selectedRole = value!),
                  ),
                  const SizedBox(height: 16),
                  Row(children: [
                    const Text('Ativo'),
                    Switch(value: _ativo, onChanged: (value) => setState(() => _ativo = value)),
                  ]),
                  const SizedBox(height: 16),
                  Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                    TextButton(onPressed: () => setState(() => _editingUser = null), child: const Text('Cancelar')),
                    const SizedBox(width: 12),
                    ElevatedButton(onPressed: () => _save(context), child: const Text('Salvar')),
                  ]),
                ]),
              ),
            ),
          ),
        Container(
          decoration: BoxDecoration(color: HabitatTheme.card, borderRadius: BorderRadius.circular(24), border: Border.all(color: HabitatTheme.border)),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columns: const [
                DataColumn(label: Text('Nome')),
                DataColumn(label: Text('E-mail')),
                DataColumn(label: Text('Perfil')),
                DataColumn(label: Text('Status')),
                DataColumn(label: Text('Ações')),
              ],
              rows: users.map((user) {
                return DataRow(cells: [
                  DataCell(Text(user.nome)),
                  DataCell(Text(user.email)),
                  DataCell(Text(user.role.label)),
                  DataCell(Text(user.ativo ? 'Ativo' : 'Inativo', style: TextStyle(color: user.ativo ? HabitatTheme.success : Colors.red))),
                  DataCell(Row(children: [
                    IconButton(icon: const Icon(Icons.edit), onPressed: () => _openEdit(user)),
                    IconButton(icon: const Icon(Icons.delete), onPressed: () => context.read<AuthProvider>().toggleUserActive(user.id)),
                  ])),
                ]);
              }).toList(),
            ),
          ),
        ),
      ]),
    );
  }
}
