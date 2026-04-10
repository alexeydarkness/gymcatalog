import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static Future<void> saveRole(String role) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('user_role', role);
  }

  static Future<String?> getRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_role');
  }

  static Future<void> saveFavorites(List<int> ids, String username) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setStringList('favorites_$username', ids.map((id) => id.toString()).toList());
  }

  static Future<List<int>> getFavorites(String username) async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList('favorites_$username') ?? [];
    return list.map((s) => int.parse(s)).toList();
  }

  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.clear();
  }

}