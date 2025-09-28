import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';

// Assuming the path to ApiService is correct
import '../../services/api_service.dart';

// NOTE: Ensure 'intl: ^0.18.1' and 'url_launcher: ^6.1.10'
// are added to your pubspec.yaml file under dependencies.

class PredictionsHistoryScreen extends StatefulWidget {
  @override
  _PredictionsHistoryScreenState createState() =>
      _PredictionsHistoryScreenState();
}

class _PredictionsHistoryScreenState extends State<PredictionsHistoryScreen> {
  // Initialize to an empty List to prevent null-related errors
  List<dynamic> allPredictions = [];
  bool loading = true;
  // Using ColorSwatch for metric card to allow shade access
  final DateFormat _dateFormat = DateFormat('MMM dd, yyyy');

  @override
  void initState() {
    super.initState();
    fetchPredictions();
  }

  /// Fetch all predictions under this doctor
  Future<void> fetchPredictions() async {
    if (!mounted) return;
    setState(() => loading = true);

    try {
      final res = await ApiService.get("/doctor/predictions");
      List<dynamic> preds = [];

      if (res is List) {
        preds = res;
      } else if (res is Map && res.containsKey('predictions')) {
        preds = res['predictions'] as List<dynamic>;
      }

      // Sort by creation date (latest first)
      preds.sort((a, b) {
        final dateA = a['created_at']?.toString() ?? '1';
        final dateB = b['created_at']?.toString() ?? '0';
        return dateB.compareTo(dateA);
      });

      if (!mounted) return;
      setState(() {
        allPredictions = preds;
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        allPredictions = []; // CRITICAL: Ensure it's not null on failure
        loading = false;
      });
      _showSnackbar("Error fetching predictions: $e", Colors.red);
    }
  }

  /// Validate a prediction
  void validatePrediction(String predictionId, String notes) async {
    try {
      final res = await ApiService.post("/doctor/validate/$predictionId", {
        "validated": true,
        "notes": notes,
      });

      if (res is Map && res.containsKey("message")) {
        _showSnackbar("Prediction validated successfully! ✅", Colors.green);
        fetchPredictions(); // Refresh list
      } else {
        _showSnackbar(
          res["error"]?.toString() ?? "Failed to validate prediction.",
          Colors.orange,
        );
      }
    } catch (e) {
      _showSnackbar("Validation error: $e", Colors.red);
    }
  }

  /// Download PDF report
  void downloadReport(String? reportPath) async {
    if (reportPath == null || reportPath.isEmpty) {
      _showSnackbar("Report not available for this entry.", Colors.orange);
      return;
    }

    // Adjust the base URL as needed for your backend server
    const baseUrl = "http://localhost:5000";
    final url = "$baseUrl/$reportPath";
    final uri = Uri.parse(url);

    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        _showSnackbar(
          "Cannot launch report URL. Make sure the server is running on $baseUrl",
          Colors.red,
        );
      }
    } catch (e) {
      _showSnackbar("An error occurred while launching URL: $e", Colors.red);
    }
  }

  /// Helper to show a consistent SnackBar
  void _showSnackbar(String message, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white)),
        backgroundColor: color,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  /// Dialog to add notes before validation
  void _showValidationDialog(String predictionId) {
    final notesController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Confirm Validation"),
        content: TextField(
          controller: notesController,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: "Add notes (optional)",
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel"),
          ),
          ElevatedButton.icon(
            onPressed: () {
              validatePrediction(predictionId, notesController.text);
              Navigator.pop(ctx);
            },
            icon: const Icon(Icons.check),
            label: const Text("Validate"),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (allPredictions.isEmpty) {
      return _buildEmptyState();
    }

    final pending = allPredictions
        .where((p) => p['validated'] == false)
        .toList();
    final validated = allPredictions
        .where((p) => p['validated'] == true)
        .toList();

    // Using a DefaultTabController for the Dashboard Tab structure
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          _buildMetricsRow(pending.length, validated.length),

          // TabBar for separation
          TabBar(
            labelColor: Theme.of(context).primaryColor,
            unselectedLabelColor: Colors.grey,
            indicatorSize: TabBarIndicatorSize.tab,
            indicator: BoxDecoration(
              borderRadius: BorderRadius.circular(50),
              color: Theme.of(context).primaryColor.withOpacity(0.1),
            ),
            tabs: [
              Tab(
                child: Text(
                  "Pending (${pending.length})",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              Tab(
                child: Text(
                  "Validated (${validated.length})",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),

          // Main content view
          Expanded(
            child: TabBarView(
              children: [
                _buildPredictionList(pending, 'pending'),
                _buildPredictionList(validated, 'validated'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- Widget Builders for Clarity and Structure ---

  Widget _buildMetricsRow(int pendingCount, int validatedCount) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildMetricCard(
            title: "Total Predictions",
            count: allPredictions.length,
            icon: Icons.timeline,
            color: Colors.blueGrey,
          ),
          _buildMetricCard(
            title: "Pending Review",
            count: pendingCount,
            icon: Icons.assignment_late,
            color: Colors.orange,
          ),
          _buildMetricCard(
            title: "Validated Records",
            count: validatedCount,
            icon: Icons.verified,
            color: Colors.green,
          ),
        ],
      ),
    );
  }

  // Adjusted signature to use ColorSwatch to fix the 'shade700' error
  Widget _buildMetricCard({
    required String title,
    required int count,
    required IconData icon,
    required ColorSwatch color, // <--- Corrected Type
  }) {
    return Expanded(
      child: Card(
        color: color.withOpacity(0.1),
        elevation: 0,
        margin: const EdgeInsets.symmetric(horizontal: 6),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(height: 8),
              Text(
                '$count',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              // Fixed the shade700 error by using color.shade700 on ColorSwatch
              Text(title, style: TextStyle(fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPredictionList(List<dynamic> list, String type) {
    if (list.isEmpty) {
      return Center(
        child: Text(
          "No $type predictions found.",
          style: const TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    // Responsive Grid View: Adjusts columns based on screen width
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 400.0, // Max width of a card (responsive)
        mainAxisExtent: 250, // Fixed height for a cleaner look
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final p = list[index] as Map<String, dynamic>;

        // **CRITICAL FIXES APPLIED HERE:**
        // Use ?.toString() ?? '' on all values expected to be Strings
        final patientId = p['patient_id']?.toString() ?? 'N/A';
        final predictedClass = p['predicted_class']?.toString() ?? 'Unknown';

        final rawConf = p['confidence'];
        final confidence = rawConf is num ? rawConf.toDouble() * 100 : 0.0;

        final validated = p['validated'] ?? false;

        final notes = p['notes']?.toString() ?? ''; // Explicitly safe string
        final predictionId = p['_id']?.toString() ?? '';
        final reportPath = p['report_pdf_path']?.toString();
        final createdAt = p['created_at']?.toString() ?? '';

        String formattedDate = 'N/A';
        if (createdAt.isNotEmpty) {
          try {
            final dateTime = DateTime.parse(createdAt).toLocal();
            formattedDate = _dateFormat.format(dateTime);
          } catch (_) {}
        }

        return PredictionCard(
          patientId: patientId,
          predictedClass: predictedClass,
          confidence: confidence,
          validated: validated,
          notes: notes,
          predictionId: predictionId,
          reportPath: reportPath,
          formattedDate: formattedDate,
          showValidationDialog: _showValidationDialog,
          downloadReport: downloadReport,
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.sentiment_satisfied_alt,
            size: 80,
            color: Colors.teal,
          ),
          const SizedBox(height: 20),
          const Text(
            "All clear! No predictions found.",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.teal,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            "Start by processing a new patient scan.",
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 30),
          ElevatedButton.icon(
            onPressed: fetchPredictions,
            icon: const Icon(Icons.refresh),
            label: const Text("Refresh Data"),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blueGrey,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }
}

// --- Unique Card Widget for Data Presentation ---
class PredictionCard extends StatelessWidget {
  final String patientId;
  final String predictedClass;
  final double confidence;
  final bool validated;
  final String notes;
  final String predictionId;
  final String? reportPath;
  final String formattedDate;
  final Function(String) showValidationDialog;
  final Function(String?) downloadReport;

  const PredictionCard({
    required this.patientId,
    required this.predictedClass,
    required this.confidence,
    required this.validated,
    required this.notes,
    required this.predictionId,
    required this.reportPath,
    required this.formattedDate,
    required this.showValidationDialog,
    required this.downloadReport,
    super.key,
  });

  Color _getClassColor(String className) {
    if (className.contains('Positive') || className.contains('Malignant'))
      return Colors.red.shade700;
    if (className.contains('Negative') || className.contains('Benign'))
      return Colors.green.shade700;
    return Colors.blueGrey;
  }

  @override
  Widget build(BuildContext context) {
    final Color classColor = _getClassColor(predictedClass);

    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        side: BorderSide(
          color: validated ? Colors.teal.shade200 : Colors.orange.shade200,
          width: 2,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Row 1: ID and Class Badge
            // Row 1: ID and Class Badge (MODIFIED to be a Column for two rows)
            Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start, // Align contents to the left
              children: [
                // FIRST ROW: Patient ID Text
                Text(
                  "Patient ID: $patientId",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18, // Slightly larger font for prominence
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 12), // Increased vertical spacing
                // SECOND ROW: Highlighted Predicted Class (REPLACED CHIP WITH CONTAINER)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: classColor, // Use the class-specific color
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      // Subtle shadow to make it pop off the card
                      BoxShadow(
                        color: classColor.withOpacity(0.4),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    predictedClass.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight:
                          FontWeight.w900, // Extra bold for maximum impact
                      color: Colors.white,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
              ],
            ),

            // Row 2: Confidence Bar
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Confidence: ${confidence.toStringAsFixed(1)}%",
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  LinearProgressIndicator(
                    value: confidence / 100,
                    backgroundColor: Colors.grey.shade200,
                    color: confidence > 85 ? Colors.teal : Colors.orange,
                    minHeight: 8,
                  ),
                ],
              ),
            ),

            // Row 3: Status and Date
            // Safe display of notes. 'notes' is guaranteed to be a non-null String ('') from parent.
            Text(
              "Notes: ${notes.isEmpty
                  ? 'N/A'
                  : notes.length > 30
                  ? notes.substring(0, 30) + '...'
                  : notes}",
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),

            const Divider(height: 15),

            // Row 4: Actions
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      validated ? "Validated" : "Pending",
                      style: TextStyle(
                        color: validated
                            ? Colors.teal.shade700
                            : Colors.orange.shade700,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      formattedDate,
                      style: const TextStyle(fontSize: 10, color: Colors.grey),
                    ),
                  ],
                ),
                Row(
                  children: [
                    if (!validated)
                      IconButton(
                        onPressed: () => showValidationDialog(predictionId),
                        icon: const Icon(
                          Icons.check_circle_outline,
                          color: Colors.teal,
                        ),
                        tooltip: "Validate",
                      ),
                    IconButton(
                      onPressed: () => downloadReport(reportPath),
                      icon: Icon(
                        Icons.picture_as_pdf,
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                      tooltip: "Download Report",
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
