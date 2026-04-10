import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/gym.dart';

class ApiServices {
  static const String _host = 'http://192.168.56.1:8080';
  static const String _baseUrl = '$_host/api/gyms';
  static const String _authUrl = '$_host/api/auth';
  static const Duration _timeout = Duration(seconds: 10);

  static String? _token;

  static Map<String, String> get _headers => {
    'Content-Type': 'application/json; charset=UTF-8',
    if (_token != null) 'Authorization': 'Bearer $_token',
  };


  static Future<List<Gym>> fetchGyms() async {
    final response = await http.get(Uri.parse(_baseUrl)).timeout(_timeout);

    if (response.statusCode == 200) {
      final List<dynamic> jsonList = jsonDecode(response.body);
      return jsonList.map((json) => Gym.fromJson(json)).toList();
    } else {
      throw Exception('Ошибка загрзки!: ${response.statusCode}');
    }
  }


  static Future<Gym> createGym(Gym gym) async {
    final response = await http.post(
      Uri.parse(_baseUrl),
      headers: _headers,
      body: jsonEncode(gym.toJson()),
    ).timeout(_timeout);

    if (response.statusCode == 200 || response.statusCode == 201) {
      return Gym.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Ошибка: ${response.statusCode}');
    }
  }

  static Future<Gym> updateGym(int id, Gym gym) async {
    final response = await http.put(
      Uri.parse('$_baseUrl/$id'),
      headers: _headers,
      body: jsonEncode(gym.toJson()),
    ).timeout(_timeout);
    if (response.statusCode == 200 || response.statusCode == 201) {
      return Gym.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Ошибка: ${response.statusCode}');
    }
  }

  static Future<void> deleteGym(int id) async {
    final response = await http.delete(Uri.parse('$_baseUrl/$id')).timeout(_timeout);

    if (response.statusCode != 204 && response.statusCode != 200) {
      throw Exception('Ошибка удаления: ${response.statusCode}');
    }
  }

  static Future<List<Gym>> fetchDeletedGyms() async {
      final response = await http.get(Uri.parse('$_baseUrl/deleted')).timeout(_timeout);
      if (response.statusCode == 200) {
        final List<dynamic> jsonList = jsonDecode(response.body);
        return jsonList.map((json) => Gym.fromJson((json))).toList();
      } else {
        throw Exception('Ошибка загрузки: ${response.statusCode}');
      }
  }
  
  static Future<Gym> restoreGym(int id) async {
    final response = await http.put(
      Uri.parse('$_baseUrl/$id/restore'),
      headers: _headers,
    ).timeout(_timeout);
    if (response.statusCode == 200) {
      return Gym.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Ошибка восстановления: ${response.statusCode}');
    }
  }

  static Future<Map<String, dynamic>> login(String username, String password) async {
      final response = await http.post(
        Uri.parse('$_authUrl/login'),
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: jsonEncode({'username': username, 'password': password}),
      ).timeout(_timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _token = data['token'];
        return data;
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['error'] ?? 'Ошибка входа');
      }
  }

  static Future<Map<String, dynamic>> register(String username, String password, String role) async {
      final response = await http.post(
        Uri.parse('$_authUrl/register'),
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: jsonEncode({'username': username, 'password': password, 'role': role}),
      ).timeout(_timeout);

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        _token = data['token'];
        return data;
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['error'] ?? 'Ошибка регистрации');
      }
  }

  static void logout() {
    _token = null;
  }
}
