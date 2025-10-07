import 'package:flutter/material.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/doctor/doctor_dashboard.dart';
import 'screens/patient/patient_dashboard.dart';
import 'screens/Home_page.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Brain Tumor App",
      initialRoute: "/home",
      routes: {
        "/login": (_) => LoginScreen(),
        "/register": (_) => RegisterScreen(),
        "/doctor": (_) => DoctorDashboard(),
        '/patient': (_) => PatientDashboard(),
        '/home': (_) => HomePage(),
      },
    );
  }
}
