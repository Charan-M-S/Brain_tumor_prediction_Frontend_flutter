import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/api_service.dart';

class PredictionsHistoryScreen extends StatefulWidget {
  @override
  _PredictionsHistoryScreenState createState() =>
      _PredictionsHistoryScreenState();
}

class _PredictionsHistoryScreenState extends State<PredictionsHistoryScreen> {
  List predictions = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    fetchPredictions();
  }

  Future<void> fetchPredictions() async {
    setState(() => loading = true);

    try {
      // 1️⃣ Fetch patients under this doctor
     final res = await ApiService.get("/doctor/patients");
    final patients = res as List<dynamic>; // ✅ cast to List
    List<String> patientIds = patients.map((p) => p['_id'].toString()).toList();

      List tempPreds = [];

      // 2️⃣ Fetch predictions for each patient
      for (String pid in patientIds) {
        final predRes = await ApiService.get("/patient/predictions");
        final patientPreds =
            predRes["predictions"]?.where((p) => p["patient_id"] == pid) ??
                [];
        tempPreds.addAll(patientPreds);
      }

      setState(() {
        predictions = tempPreds;
        loading = false;
      });
    } catch (e) {
      setState(() => loading = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  void validatePrediction(String predictionId, String notes) async {
    final res = await ApiService.post("/doctor/validate/$predictionId", {
      "validated": true,
      "notes": notes,
    });

    if (res.containsKey("message")) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Prediction validated")));
      fetchPredictions(); // Refresh list
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(res["error"] ?? "Failed")));
    }
  }

  void downloadReport(String reportPath) async {
    if (reportPath == null || reportPath.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Report not available")));
      return;
    }

    final url = "http://127.0.0.1:5000/$reportPath";
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Cannot open report URL")));
    }
  }

  void _showValidationDialog(String predictionId) {
    final notesController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("Validate Prediction"),
        content: TextField(
          controller: notesController,
          decoration: InputDecoration(labelText: "Add notes"),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text("Cancel")),
          ElevatedButton(
            onPressed: () {
              validatePrediction(predictionId, notesController.text);
              Navigator.pop(ctx);
            },
            child: Text("Validate"),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return loading
        ? Center(child: CircularProgressIndicator())
        : predictions.isEmpty
            ? Center(child: Text("No predictions found"))
            : ListView.builder(
                itemCount: predictions.length,
                itemBuilder: (context, index) {
                  final p = predictions[index];
                  return Card(
                    margin: EdgeInsets.all(8),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Patient ID: ${p['patient_id']}",
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 16)),
                          SizedBox(height: 5),
                          Text("Class: ${p['predicted_class']}"),
                          Text(
                              "Confidence: ${(p['confidence'] * 100).toStringAsFixed(2)}%"),
                          Text("Validated: ${p['validated']}"),
                          Text("Notes: ${p['notes'] ?? ''}"),
                          SizedBox(height: 10),
                          Row(
                            children: [
                              ElevatedButton(
                                  onPressed: () =>
                                      _showValidationDialog(p['_id']),
                                  child: Text("Validate")),
                              SizedBox(width: 10),
                              ElevatedButton(
                                  onPressed: () =>
                                      downloadReport(p['report_pdf_path']),
                                  child: Text("Download Report")),
                            ],
                          )
                        ],
                      ),
                    ),
                  );
                },
              );
  }
}
