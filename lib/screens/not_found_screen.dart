import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class NotFoundScreen extends StatelessWidget {
  const NotFoundScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Text('404', style: Theme.of(context).textTheme.displayLarge?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Text('Oops! Página não encontrada', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 24),
        ElevatedButton(onPressed: () => GoRouter.of(context).go('/'), child: const Text('Voltar para o início')),
      ]),
    );
  }
}
