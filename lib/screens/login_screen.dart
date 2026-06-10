import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../src/providers.dart';
import '../src/app_theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _showPassword = false;
  bool _isLoggingIn = false;

  Future<void> _handleSubmit() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      _showMessage('Preencha e-mail e senha.');
      return;
    }
    setState(() => _isLoggingIn = true);
    final auth = context.read<AuthProvider>();
    final success = await auth.login(_emailController.text.trim(), _passwordController.text.trim());
    if (!mounted) return;
    setState(() => _isLoggingIn = false);
    if (success) {
      GoRouter.of(context).go('/dashboard');
    } else {
      _showMessage('E-mail ou senha inválidos.');
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HabitatTheme.accent,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child: Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(color: HabitatTheme.accent, borderRadius: BorderRadius.circular(20)),
                          child: const Icon(Icons.home, color: Colors.white, size: 38),
                        ),
                      ),
                      const SizedBox(height: 18),
                      Text('Sistema Habitat', textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleLarge?.copyWith(color: HabitatTheme.primary)),
                      const SizedBox(height: 8),
                      Text('Gestão Jurídica de Projetos Sociais', textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: HabitatTheme.primary.withOpacity(0.7))),
                      const SizedBox(height: 28),
                      TextField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(labelText: 'E-mail'),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _passwordController,
                        obscureText: !_showPassword,
                        decoration: InputDecoration(
                          labelText: 'Senha',
                          suffixIcon: IconButton(
                            icon: Icon(_showPassword ? Icons.visibility_off : Icons.visibility),
                            onPressed: () => setState(() => _showPassword = !_showPassword),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: _isLoggingIn ? null : _handleSubmit,
                        child: _isLoggingIn
                            ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Text('Entrar'),
                      ),
                      const SizedBox(height: 12),
                      Text('Esqueceu a senha? Entre em contato com o administrador.', textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: HabitatTheme.primary.withOpacity(0.75), fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
