import 'package:flutter/material.dart';
import 'upload_mri_screen.dart';
import 'prediction_history.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class DoctorDashboard extends StatelessWidget {
  final FlutterSecureStorage storage = const FlutterSecureStorage();

  // Logout function
  void _logout(BuildContext context) async {
    await storage.delete(key: "jwt_token"); // Remove the token
    // Navigate to login screen (replace '/login' with your route)
    Navigator.of(context).pushReplacementNamed('/login');
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text("Doctor Dashboard"),
          actions: [
            IconButton(
              icon: const Icon(Icons.logout),
              tooltip: "Logout",
              onPressed: () => _logout(context),
            ),
          ],
          bottom: TabBar(
            tabs: [
              Tab(text: "Upload MRI"),
              Tab(text: "Predictions History"),
            ],
          ),
        ),
        body: TabBarView(
          children: [UploadMRIScreen(), PredictionsHistoryScreen()],
        ),
      ),
    );
  }
}
