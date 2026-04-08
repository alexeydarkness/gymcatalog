import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static Future<void> saveRole(String role) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('user_role', role);
  }

  static Future<String?> getRole(String role) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_role');
  }

  static Future<void> saveFavorites(List<int> ids, String role) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setStringList('favorites_$role', ids.map((id) => id.toString()).toList());
  }

  static Future<List<int>> getFavorites(String role) async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList('favorites_$role') ?? [];
    return list.map((s) => int.parse(s)).toList();
  }

  // static Future<void> saveDeleted(List<int> ids) async {
  //   final prefs = await SharedPreferences.getInstance();
  //   prefs.setStringList('deleted', ids.map((id) => id.toString()).toList());
  // }
  
  // static Future<List<int>> getDeleted() async {
  //   final prefs = await SharedPreferences.getInstance();
  //   final list = prefs.getStringList('deleted') ?? [];
  //   return list.map((s) => int.parse(s)).toList();
  // }

  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.clear();
  }

}