import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/gym.dart';

class ApiServices {
  static const String _baseUrl = 'http://192.168.56.1:8080/api/gyms';

  static Future<List<Gym>> fetchGyms() async {
    final response = await http.get(Uri.parse(_baseUrl));

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
      headers: {'Content-Type': 'application/json; charset=UTF-8'},
      body: jsonEncode(gym.toJson()),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return Gym.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Ошибка: ${response.statusCode}');
    }
  }

  static Future<Gym> updateGym(int id, Gym gym) async {
    final response = await http.put(
      Uri.parse('$_baseUrl/$id'),
      headers: {'Content-Type': 'application/json; charset=UTF-8'},
      body: jsonEncode(gym.toJson()),
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      return Gym.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Ошибка: ${response.statusCode}');
    }
  }

  static Future<void> deleteGym(int id) async {
    final response = await http.delete(Uri.parse('$_baseUrl/$id'));

    if (response.statusCode != 204 && response.statusCode != 200) {
      throw Exception('Ошибка удаления: ${response.statusCode}');
    }
  }

  static Future<List<Gym>> fetchDeletedGyms() async {
      final response = await http.get(Uri.parse('$_baseUrl/deleted'));
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
      headers: {'Content-Type': 'application/json; charset=UTF-8'},
    );
    if (response.statusCode == 200) {
      return Gym.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Ошибка восстановления: ${response.statusCode}');
    }
  }
}
