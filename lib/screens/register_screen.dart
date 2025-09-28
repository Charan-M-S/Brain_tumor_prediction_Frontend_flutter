import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../services/api_service.dart';
import 'doctor/doctor_dashboard.dart';
import 'patient/patient_dashboard.dart';

// Define the Color Palette (Consistent with LoginScreen)
const Color primaryColor = Color(0xFF1D5D9B); // Darker Blue
const Color accentColor = Color(0xFFF4D160); // Golden Accent
const Color backgroundColor = Color(0xFFF7F9FC); // Light background

class RegisterScreen extends StatefulWidget {
  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  String _role = "patient"; // default
  bool loading = false;
  final storage = const FlutterSecureStorage();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void register() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    setState(() => loading = true);

    try {
      final res = await ApiService.post("/auth/register", {
        "name": name,
        "email": email,
        "password": password,
        "role": _role,
      });

      if (!mounted) return;
      setState(() => loading = false);

      if (res.containsKey("message")) {
        _showSnackbar("Registration successful! Logging you in...", Colors.green);

        // Auto-login after registration
        final loginRes = await ApiService.post("/auth/login", {
          "email": email,
          "password": password,
        });

        if (loginRes.containsKey("token")) {
          await storage.write(key: "jwt_token", value: loginRes["token"]);
          final role = loginRes["role"];

          // Navigate based on role
          if (role == "doctor") {
            Navigator.pushReplacement(
                context, MaterialPageRoute(builder: (_) => DoctorDashboard()));
          } else {
            Navigator.pushReplacement(
                context, MaterialPageRoute(builder: (_) => PatientDashboard()));
          }
        } else {
          _showSnackbar("Registration succeeded, but auto-login failed.", Colors.orange);
          // Optionally navigate to login page if auto-login fails
          Navigator.pop(context); 
        }
      } else {
        _showSnackbar(res["error"] ?? "Registration failed.", Colors.red);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => loading = false);
      _showSnackbar("Network Error: Could not reach server.", Colors.red);
    }
  }

  void _showSnackbar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: color,
    ));
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Remove AppBar for a full-page focused registration form
      backgroundColor: backgroundColor,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 500),
            padding: const EdgeInsets.all(30.0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Logo/Title Section
                  Icon(
                    Icons.app_registration,
                    size: 60,
                    color: primaryColor,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Create Account',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      color: primaryColor,
                    ),
                  ),
                  const SizedBox(height: 5),
                  const Text(
                    'Join the platform as a Doctor or Patient.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 30),

                  // Name Field
                  TextFormField(
                    controller: _nameController,
                    keyboardType: TextInputType.name,
                    decoration: _inputDecoration(
                      labelText: "Full Name",
                      icon: Icons.person_outline,
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),

                  // Email Field
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: _inputDecoration(
                      labelText: "Email Address",
                      icon: Icons.email_outlined,
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty || !value.contains('@')) {
                        return 'Please enter a valid email';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),

                  // Password Field
                  TextFormField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: _inputDecoration(
                      labelText: "Password",
                      icon: Icons.lock_outline,
                    ),
                    validator: (value) {
                      if (value == null || value.length < 6) {
                        return 'Password must be at least 6 characters';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),

                  // Role Dropdown Field (Styled to match TextFields)
                  DropdownButtonFormField<String>(
                    value: _role,
                    decoration: _inputDecoration(
                      labelText: "Registering as",
                      icon: Icons.assignment_ind_outlined,
                    ),
                    items: const [
                      DropdownMenuItem(
                          value: "patient", child: Text("Patient (User)")),
                      DropdownMenuItem(
                          value: "doctor", child: Text("Doctor (Medical Professional)")),
                    ],
                    onChanged: (val) => setState(() => _role = val!),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please select a role';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 30),

                  // Register Button
                  ElevatedButton(
                    onPressed: loading ? null : register,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      elevation: 5,
                    ),
                    child: loading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            "Register Now",
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                  ),
                  const SizedBox(height: 15),

                  // Login Link
                  TextButton(
                    onPressed: () {
                      // Navigate back to the login screen
                      Navigator.pop(context);
                    },
                    child: Text(
                      "Already have an account? Login Here",
                      style: TextStyle(color: primaryColor.withOpacity(0.8)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({required String labelText, required IconData icon}) {
    return InputDecoration(
      labelText: labelText,
      prefixIcon: Icon(icon, color: primaryColor.withOpacity(0.7)),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Colors.grey),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: primaryColor, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 10),
      fillColor: Colors.white,
      filled: true,
    );
  }
}