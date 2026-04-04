import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/gym.dart';

class ApiServices {
  static const String _url = 'https://gist.githubusercontent.com/alexeydarkness/8f3a0c2a4b284cb0c11fb08040f910e0/raw/';

  static Future<List<Gym>> fetchGyms() async {
    final response = await http.get(Uri.parse(_url));

    if (response.statusCode == 200) {
      final List<dynamic> jsonList = jsonDecode(response.body);
      return jsonList.map((json) => Gym.fromJson(json)).toList();
    } else {
      throw Exception('Ошибка загрзки!: ${response.statusCode}');
    }
  }
}
