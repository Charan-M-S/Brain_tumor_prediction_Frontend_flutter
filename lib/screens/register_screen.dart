import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../services/api_service.dart';
import 'doctor/doctor_dashboard.dart';
import 'patient/patient_dashboard.dart';

class RegisterScreen extends StatefulWidget {
  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String _role = "patient"; // default
  bool loading = false;
  final storage = FlutterSecureStorage();

  void register() async {
    final name = _nameController.text;
    final email = _emailController.text;
    final password = _passwordController.text;

    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Fill all fields")));
      return;
    }

    setState(() => loading = true);

    final res = await ApiService.post("/auth/register", {
      "name": name,
      "email": email,
      "password": password,
      "role": _role,
    });

    setState(() => loading = false);

    if (res.containsKey("message")) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Registered successfully")));

      // Auto-login after registration
      final loginRes = await ApiService.post("/auth/login", {
        "email": email,
        "password": password,
      });

      if (loginRes.containsKey("token")) {
        await storage.write(key: "jwt_token", value: loginRes["token"]);
        final role = loginRes["role"];
        if (role == "doctor") {
          Navigator.pushReplacement(
              context, MaterialPageRoute(builder: (_) => DoctorDashboard()));
        } else {
          Navigator.pushReplacement(
              context, MaterialPageRoute(builder: (_) => PatientDashboard()));
        }
      }
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(res["error"] ?? "Registration failed")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Register")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(controller: _nameController, decoration: InputDecoration(labelText: "Name")),
            TextField(controller: _emailController, decoration: InputDecoration(labelText: "Email")),
            TextField(controller: _passwordController, decoration: InputDecoration(labelText: "Password"), obscureText: true),
            DropdownButton<String>(
              value: _role,
              items: [
                DropdownMenuItem(child: Text("Patient"), value: "patient"),
                DropdownMenuItem(child: Text("Doctor"), value: "doctor"),
              ],
              onChanged: (val) => setState(() => _role = val!),
            ),
            SizedBox(height: 20),
            loading
                ? CircularProgressIndicator()
                : ElevatedButton(onPressed: register, child: Text("Register")),
          ],
        ),
      ),
    );
  }
}
