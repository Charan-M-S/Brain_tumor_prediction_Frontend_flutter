import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/api_service.dart';

class PredictionsHistoryScreen extends StatefulWidget {
  @override
  _PredictionsHistoryScreenState createState() =>
      _PredictionsHistoryScreenState();
}

class _PredictionsHistoryScreenState extends State<PredictionsHistoryScreen> {
  List<dynamic> predictions = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    fetchPredictions();
  }

  /// Fetch all predictions under this doctor
  Future<void> fetchPredictions() async {
    setState(() => loading = true);

    try {
      final res = await ApiService.get("/doctor/predictions");
      print("API response: $res");
      print("Runtime type: ${res.runtimeType}");

      List<dynamic> preds = [];

      // Handle array response or object-with-predictions
      if (res is List) {
        preds = res;
      } else if (res is Map && res.containsKey('predictions')) {
        preds = res['predictions'] as List<dynamic>;
      } else {
        preds = [];
      }

      setState(() {
        predictions = preds;
        loading = false;
      });
    } catch (e) {
      setState(() => loading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  /// Validate a prediction
  void validatePrediction(String predictionId, String notes) async {
    final res = await ApiService.post("/doctor/validate/$predictionId", {
      "validated": true,
      "notes": notes,
    });

    if (res is Map && res.containsKey("message")) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Prediction validated")));
      fetchPredictions(); // Refresh list
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res["error"]?.toString() ?? "Failed")),
      );
    }
  }

  /// Download PDF report
  void downloadReport(String? reportPath) async {
    if (reportPath == null || reportPath.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Report not available")));
      return;
    }

    final url = "http://localhost:5000/$reportPath"; // Adjust host if needed
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Cannot open report URL")));
    }
  }

  /// Dialog to add notes before validation
  void _showValidationDialog(String predictionId) {
    final notesController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Validate Prediction"),
        content: TextField(
          controller: notesController,
          decoration: const InputDecoration(labelText: "Add notes"),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              validatePrediction(predictionId, notesController.text);
              Navigator.pop(ctx);
            },
            child: const Text("Validate"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return Scaffold(
        appBar: AppBar(title: const Text("Predictions History")),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Predictions History")),
      body: predictions.isEmpty
          ? const Center(child: Text("No predictions found"))
          : ListView.builder(
              itemCount: predictions.length,
              itemBuilder: (context, index) {
                final p = predictions[index] as Map<String, dynamic>;

                final patientId = p['patient_id'] ?? '';
                final predictedClass = p['predicted_class'] ?? '';
                final rawConf = p['confidence'];
                final confidence = rawConf is num
                    ? rawConf.toDouble() * 100
                    : 0.0;
                final validated = p['validated'] ?? false;
                final notes = p['notes'] ?? '';
                final predictionId = p['_id'] ?? '';
                final reportPath = p['report_pdf_path'] ?? '';
                final createdAt = p['created_at'] ?? '';

                return Card(
                  margin: const EdgeInsets.all(8),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Patient ID: $patientId",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text("Class: $predictedClass"),
                        Text("Confidence: ${confidence.toStringAsFixed(2)}%"),
                        Text("Validated: $validated"),
                        if (notes.isNotEmpty) Text("Notes: $notes"),
                        if (createdAt.isNotEmpty) Text("Created: $createdAt"),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            ElevatedButton(
                              onPressed: () =>
                                  _showValidationDialog(predictionId),
                              child: const Text("Validate"),
                            ),
                            const SizedBox(width: 10),
                            ElevatedButton(
                              onPressed: () => downloadReport(reportPath),
                              child: const Text("Download Report"),
                            ),
                          ],
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
