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

  // change this to your backend base URL
  final String baseUrl = "http://127.0.0.1:5000";
  // For Android emulator use: "http://10.0.2.2:5000"

  @override
  void initState() {
    super.initState();
    fetchPredictions();
  }

  void fetchPredictions() async {
    setState(() => loading = true);
    final res = await ApiService.get("/patient/predictions");

    setState(() {
      // if your API returns a list at the top level
      predictions = (res as List?) ?? [];
      loading = false;
    });
  }

  void downloadReport(String predictionId) async {
    final url = "http://localhost:5000/patient/report/$predictionId";
    final uri = Uri.parse(url);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication,
        );
        
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Cannot launch report URL")));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("An Error occured while launching report url")),
      );
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
                  color: Colors.grey[100],
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Doctor Name
                        Text(
                          "Doctor: ${pred['doctor_name'] ?? 'Unknown'}",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.blue[800],
                          ),
                        ),
                        SizedBox(height: 6),

                        // Predicted Class
                        Text(
                          "Prediction: ${pred['predicted_class'] ?? 'Unknown'}",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: Colors.red[700],
                          ),
                        ),
                        SizedBox(height: 6),

                        // Confidence
                        Text(
                          "Confidence: ${(pred['confidence'] * 100).toStringAsFixed(2)}%",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.green[700],
                          ),
                        ),
                        SizedBox(height: 6),

                        // Status
                        Text(
                          "Validation Status: ${pred['status'] ?? 'pending'}",
                          style: TextStyle(
                            fontStyle: FontStyle.italic,
                            color: Colors.grey[700],
                          ),
                        ),
                        SizedBox(height: 10),

                        // Download Button
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
