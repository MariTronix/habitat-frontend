import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  final String _baseUrl = 'http://127.0.0.1:8080/api';
  String? _token;

  // Método para salvar o token após o login
  void setToken(String token) {
    _token = token;
  }

  // Exemplo de chamada genérica
  Future<http.Response> post(String endpoint, Map<String, dynamic> body) async {
    final response = await http.post(
      Uri.parse('$_baseUrl$endpoint'),
      headers: {
        'Content-Type': 'application/json',
        if (_token != null) 'Authorization': 'Bearer $_token',
      },
      body: jsonEncode(body),
    );
    return response;
  }
}