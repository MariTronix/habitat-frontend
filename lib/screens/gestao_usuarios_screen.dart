import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../src/models.dart';
import '../src/providers.dart';
import '../src/app_theme.dart';

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
    setState(() {
      _editingUser = null;
      _nomeController.clear();
      _emailController.clear();
      _senhaController.clear();
      _selectedRole = UserRole.estagiario;
      _ativo = true;
    });
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
