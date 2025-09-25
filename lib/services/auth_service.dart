import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

class AuthService {
  static const String baseUrl = "http://127.0.0.1:5000/auth"; // Replace with your backend URL
  static final FlutterSecureStorage storage = FlutterSecureStorage();

  // Login
  static Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await http.post(
      Uri.parse("$baseUrl/login"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"email": email, "password": password}),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      await storage.write(key: "jwt_token", value: data["token"]);
      await storage.write(key: "user_id", value: data["id"]);
      await storage.write(key: "role", value: data["role"]);
      await storage.write(key: "name", value: data["name"]);
    }

    return data;
  }

  // Register
  static Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
    required String role,
    String? assignedDoctorId,
  }) async {
    final response = await http.post(
      Uri.parse("$baseUrl/register"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "name": name,
        "email": email,
        "password": password,
        "role": role,
        "assigned_doctor_id": assignedDoctorId,
      }),
    );

    return jsonDecode(response.body);
  }

  // Logout
  static Future<void> logout() async {
    await storage.deleteAll();
  }

  // Get saved token
  static Future<String?> getToken() async {
    return await storage.read(key: "jwt_token");
  }
}
