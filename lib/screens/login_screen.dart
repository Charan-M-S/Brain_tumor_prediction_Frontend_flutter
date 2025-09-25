import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../services/api_service.dart';
import 'doctor/doctor_dashboard.dart';
import 'patient/patient_dashboard.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool loading = false;
  final storage = FlutterSecureStorage();

  void login() async {
    final email = _emailController.text;
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Enter email and password")));
      return;
    }

    setState(() => loading = true);

    final res = await ApiService.post("/auth/login", {
      "email": email,
      "password": password,
    });

    setState(() => loading = false);

    if (res.containsKey("token")) {
      // Save JWT
      await storage.write(key: "jwt_token", value: res["token"]);

      // Navigate based on role
      final role = res["role"];
      if (role == "doctor") {
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (_) => DoctorDashboard()));
      } else {
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (_) => PatientDashboard()));
      }
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(res["error"] ?? "Login failed")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Login")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _emailController,
              decoration: InputDecoration(labelText: "Email"),
            ),
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(labelText: "Password"),
              obscureText: true,
            ),
            SizedBox(height: 20),
            loading
                ? CircularProgressIndicator()
                : ElevatedButton(onPressed: login, child: Text("Login")),
            TextButton(
              onPressed: () {
                Navigator.pushNamed(context, "/register");
              },
              child: Text("Don't have an account? Register"),
            ),
          ],
        ),
      ),
    );
  }
}
