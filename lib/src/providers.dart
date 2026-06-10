import 'package:flutter/material.dart';
import 'models.dart';
import 'mock_data.dart';

class AuthProvider extends ChangeNotifier {
  User? _user;
  User? get user => _user;
  bool get isAuthenticated => _user != null;
  List<User> _users = List.of(mockUsers);

  List<User> get users => List.unmodifiable(_users);

  bool login(String email, String password) {
    final match = _users.where((user) => user.email == email && user.senha == password && user.ativo).toList();
    if (match.isEmpty) return false;
    _user = match.first;
    notifyListeners();
    return true;
  }

  void logout() {
    _user = null;
    notifyListeners();
  }

  void addUser(User user) {
    _users.insert(0, user);
    notifyListeners();
  }

  void updateUser(String id, {
    String? nome,
    String? email,
    UserRole? role,
    bool? ativo,
    String? senha,
  }) {
    final index = _users.indexWhere((u) => u.id == id);
    if (index < 0) return;
    final existing = _users[index];
    _users[index] = User(
      id: existing.id,
      nome: nome ?? existing.nome,
      email: email ?? existing.email,
      role: role ?? existing.role,
      ativo: ativo ?? existing.ativo,
      senha: senha?.isNotEmpty == true ? senha! : existing.senha,
    );
    if (_user?.id == id) {
      _user = _users[index];
    }
    notifyListeners();
  }

  void toggleUserActive(String id) {
    final index = _users.indexWhere((u) => u.id == id);
    if (index < 0) return;
    final existing = _users[index];
    _users[index] = User(
      id: existing.id,
      nome: existing.nome,
      email: existing.email,
      role: existing.role,
      ativo: !existing.ativo,
      senha: existing.senha,
    );
    notifyListeners();
  }
}

class CasesProvider extends ChangeNotifier {
  final List<Caso> _casos = List.of(mockCasos);

  List<Caso> get casos => List.unmodifiable(_casos);

  Caso? getCasoById(String id) {
    for (final caso in _casos) {
      if (caso.id == id) return caso;
    }
    return null;
  }

  void addCaso(Caso caso) {
    _casos.insert(0, caso);
    notifyListeners();
  }

  void updateCaso(String id, {
    CaseStatus? status,
    String? descricao,
    CaminhoJudicial? caminhoJudicial,
    Conciliacao? conciliacao,
    List<Anotacao>? anotacoes,
    List<Documento>? documentos,
    List<TimelineEvent>? timeline,
    String? dataAtualizacao,
  }) {
    final index = _casos.indexWhere((c) => c.id == id);
    if (index < 0) return;
    final current = _casos[index];
    _casos[index] = Caso(
      id: current.id,
      morador: current.morador,
      descricao: descricao ?? current.descricao,
      tipo: current.tipo,
      status: status ?? current.status,
      estagiarioId: current.estagiarioId,
      coordenadorId: current.coordenadorId,
      dataCriacao: current.dataCriacao,
      dataAtualizacao: dataAtualizacao ?? current.dataAtualizacao,
      caminhoJudicial: caminhoJudicial ?? current.caminhoJudicial,
      conciliacao: conciliacao ?? current.conciliacao,
      anotacoes: anotacoes ?? current.anotacoes,
      documentos: documentos ?? current.documentos,
      timeline: timeline ?? current.timeline,
    );
    notifyListeners();
  }

  void moveCasoToStatus(String id, CaseStatus status) {
    final current = getCasoById(id);
    if (current == null) return;
    updateCaso(
      id,
      status: status,
      dataAtualizacao: DateTime.now().toIso8601String().split('T').first,
      timeline: [
        ...current.timeline,
        TimelineEvent(
          id: 't${DateTime.now().millisecondsSinceEpoch}',
          descricao: 'Status alterado para ${status.label}',
          data: DateTime.now().toIso8601String().split('T').first,
          autor: '',
          tipo: 'status',
        ),
      ],
    );
  }
}
