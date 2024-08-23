import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import 'dart:convert';

class SharedPrefsHelper {
  static Future<void> saveUser(UserModel user) async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = json.encode(user.toJson());
    await prefs.setString(user.email, userJson);
  }

  static Future<UserModel?> getUser(String email) async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString(email);
    if (userJson == null) {
      return null;
    }
    return UserModel.fromJson(json.decode(userJson));
  }

}


