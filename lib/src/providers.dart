import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'models.dart';
import 'mock_data.dart';

class AuthProvider extends ChangeNotifier {
  AuthProvider({ApiService? apiService}) : _apiService = apiService;

  final ApiService? _apiService;
  User? _user;
  
  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  User? get user => _user;
  bool get isAuthenticated => _user != null;
  
  final List<User> _users = List.of(mockUsers);
  List<User> get users => List.unmodifiable(_users);

  Future<bool> login(String email, String password) async {
    _errorMessage = null; 
    
    if (_apiService != null) {
      try {
        final data = await _apiService.login(email, password);
        final remoteUser = data['user'];
        if (remoteUser is Map<String, dynamic>) {
          _user = _userFromApi(remoteUser);
          _upsertUser(_user!);
          await loadUsersFromApi();
          notifyListeners();
          return true; 
        }
      } on ApiException catch (error) {
        print('❌ ERRO NA API: ${error.statusCode} - ${error.message}');
        _errorMessage = error.message;
        return false; 
      } catch (e, stackTrace) {
        print('❌ ERRO INESPERADO: $e');
        print('Stack: $stackTrace');
        _errorMessage = 'Ocorreu um erro inesperado ao tentar fazer login.';
        return false;
      }
    }

    print('⚠️ ApiService não está injetado, usando fallback mock');
    final match = _users.where((user) => user.email == email && user.senha == password && user.ativo).toList();
    if (match.isEmpty) {
      _errorMessage = 'E-mail ou senha incorretos (Mock).';
      return false;
    }
    
    _user = match.first;
    notifyListeners();
    return true;
  }

  Future<void> loadUsersFromApi() async {
    if (_apiService == null) {
      print('⚠️ ApiService não está injetado para loadUsersFromApi');
      return;
    }
    try {
      print('Carregando usuários da API...');
      final usersData = await _apiService.fetchUsers();
      print('Usuários carregados: ${usersData.length}');
      _users.clear();
      for (final userData in usersData) {
        if (userData is Map<String, dynamic>) {
          final user = _userFromApi(userData);
          _upsertUser(user);
        }
      }
      notifyListeners();
    } catch (e, stackTrace) {
      print('ERRO AO CARREGAR USUÁRIOS: $e');
      print('Stack: $stackTrace');
    }
  }

  void logout() {
    _user = null;
    _apiService?.clearToken();
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

  User _userFromApi(Map<String, dynamic> data) {
    return User(
      id: data['id']?.toString() ?? '',
      nome: data['name']?.toString() ?? '',
      email: data['email']?.toString() ?? '',
      role: _roleFromApi(data['role']?.toString()),
      ativo: data['status'] is bool ? data['status'] as bool : true,
      senha: '',
    );
  }

  UserRole _roleFromApi(String? role) {
    switch (role) {
      case 'ADMINISTRATOR':
        return UserRole.master;
      case 'COORDINATOR':
        return UserRole.coordenador;
      case 'INTERN':
        return UserRole.estagiario;
      default:
        return UserRole.estagiario;
    }
  }

  void _upsertUser(User user) {
    final index = _users.indexWhere((existing) => existing.id == user.id || existing.email == user.email);
    if (index < 0) {
      _users.insert(0, user);
      return;
    }
    _users[index] = user;
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
