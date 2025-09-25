import 'package:flutter/material.dart';
import 'upload_mri_screen.dart';
import 'prediction_history.dart';

class DoctorDashboard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text("Doctor Dashboard"),
          bottom: TabBar(
            tabs: [
              Tab(text: "Upload MRI"),
              Tab(text: "Predictions History"),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            UploadMRIScreen(),
            PredictionsHistoryScreen(),
          ],
        ),
      ),
    );
  }
}
