# habitat_flutter

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.


Observacoes:

Caso queira testar o front sem depender da api (mock), substitua a funcao main em main.dart pelo codigo abaixo:

void main() async {
  final authProvider = AuthProvider();
runApp(
  MultiProvider(
    providers: [
      ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
      ChangeNotifierProvider<CasesProvider>(create: (_) => CasesProvider()),
    ],
    child: HabitatApp(authProvider: authProvider),
  ),
);
}
