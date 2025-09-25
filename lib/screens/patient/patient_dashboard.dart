import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/api_service.dart';

class PatientDashboard extends StatefulWidget {
  @override
  _PatientDashboardState createState() => _PatientDashboardState();
}

class _PatientDashboardState extends State<PatientDashboard> {
  List predictions = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    fetchPredictions();
  }

  void fetchPredictions() async {
    setState(() => loading = true);
    final res = await ApiService.get("/patient/predictions");
    setState(() {
      predictions = res["predictions"] ?? [];
      loading = false;
    });
  }

  void downloadReport(String predictionId) async {
    final res = await ApiService.get("/patient/report/$predictionId");
    final path = res["report_path"];
    if (path != null) {
      final url = "http://127.0.0.1:5000/$path"; // Update base URL if needed
      if (await canLaunch(url)) {
        await launch(url);
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Could not open report")));
      }
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Report not found")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Patient Dashboard")),
      body: loading
          ? Center(child: CircularProgressIndicator())
          : predictions.isEmpty
          ? Center(child: Text("No predictions found"))
          : ListView.builder(
              itemCount: predictions.length,
              itemBuilder: (context, index) {
                final pred = predictions[index];
                return Card(
                  margin: EdgeInsets.all(8),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Prediction ID: ${pred['_id']}",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text("Class: ${pred['predicted_class']}"),
                        Text(
                          "Confidence: ${(pred['confidence'] * 100).toStringAsFixed(2)}%",
                        ),
                        Text("Validated: ${pred['validated']}"),
                        SizedBox(height: 10),
                        ElevatedButton(
                          onPressed: pred['validated'] == true
                              ? () => downloadReport(pred['_id'])
                              : null,
                          child: Text("Download Report"),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
