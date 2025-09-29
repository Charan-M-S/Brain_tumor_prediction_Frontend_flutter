import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart'; // Required for date formatting
import '../../services/api_service.dart';

// Define the Color Palette (Consistent with other screens)
const Color primaryColor = Color(0xFF1D5D9B); // Darker Blue
const Color accentColor = Color(0xFFF4D160); // Golden Accent
const Color backgroundColor = Color(0xFFF7F9FC); // Light background
const Color successColor = Color(0xFF38A169); // Green for Success/Validated
const Color dangerColor = Color(0xFFE53E3E); // Red for Danger/Prediction

class PatientDashboard extends StatefulWidget {
  @override
  _PatientDashboardState createState() => _PatientDashboardState();
}

class _PatientDashboardState extends State<PatientDashboard> {
  List<dynamic> predictions = [];
  bool loading = true;
  final DateFormat _dateFormat = DateFormat('MMM dd, yyyy');
  final DateFormat _parseFormat = DateFormat('EEE, dd MMM yyyy HH:mm:ss Z');

  // change this to your backend base URL
  final String baseUrl = "http://localhost:5000";
  // For Android emulator use: "http://10.0.2.2:5000"

  @override
  void initState() {
    super.initState();
    fetchPredictions();
  }

  /// Fetches the patient's predictions.
  void fetchPredictions() async {
    if (!mounted) return;
    setState(() => loading = true);

    try {
      final res = await ApiService.get("/patient/predictions");

      if (!mounted) return;

      List<dynamic> preds = (res is List) ? res : [];

      // Sort by creation date (latest first)
      preds.sort((a, b) {
        final dateA = a['created_at']?.toString() ?? '1';
        final dateB = b['created_at']?.toString() ?? '0';
        return dateB.compareTo(dateA);
      });

      setState(() {
        predictions = preds;
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => loading = false);
      _showSnackbar("Error fetching data: $e", dangerColor);
    }
  }

  /// Downloads the PDF report.
  void downloadReport(String predictionId) async {
    // Note: The URL is constructed here based on the prediction ID.
    final url = "$baseUrl/patient/report/$predictionId";
    final uri = Uri.parse(url);

    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        _showSnackbar(
          "Cannot launch report URL. Please check server status.",
          dangerColor,
        );
      }
    } catch (e) {
      _showSnackbar("An error occurred: $e", dangerColor);
    }
  }

  /// Helper function to show consistent SnackBar messages
  void _showSnackbar(String message, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white)),
        backgroundColor: color,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return Scaffold(
        appBar: AppBar(title: const Text("Patient Dashboard")),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: backgroundColor,
      body: predictions.isEmpty
          ? _buildEmptyState()
          : CustomScrollView(
              slivers: [
                SliverAppBar(
                  expandedHeight: 150.0,
                  floating: true,
                  pinned: true,
                  backgroundColor: primaryColor,
                  flexibleSpace: FlexibleSpaceBar(
                    title: const Text(
                      "Your Scan History 🧠",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                    centerTitle: true,
                    background: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [primaryColor.withOpacity(0.9), primaryColor],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.all(12.0),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final pred = predictions[index];
                      return _buildPredictionCard(pred);
                    }, childCount: predictions.length),
                  ),
                ),
              ],
            ),
    );
  }

  // --- Helper Widgets ---

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.health_and_safety_outlined,
            size: 80,
            color: primaryColor.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          const Text(
            "No Records Found",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          const Text("Your analysis results will appear here."),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: fetchPredictions,
            icon: const Icon(Icons.refresh),
            label: const Text("Refresh"),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPredictionCard(Map<dynamic, dynamic> pred) {
    final String doctorName = pred['doctor_name'] ?? 'Doctor Unknown';
    final String predictedClass = pred['predicted_class'] ?? 'N/A';
    final double confidence = (pred['confidence'] as num?)?.toDouble() ?? 0.0;
    final bool validated = pred['validated'] ?? false;
    final String notes = pred['notes'] ?? 'No notes provided by the doctor.';
    final String predictionId = pred['_id'] ?? '';
    final String createdAt = pred['created_at']?.toString() ?? '';

    final Color statusColor = validated ? successColor : accentColor;
    final String statusText = validated ? 'Validated' : 'Pending Review';

    String formattedDate = 'N/A';
    if (createdAt.isNotEmpty) {
      try {
        // Accessing _parseFormat (which must be defined as a class field)
        final DateTime parsedDate = _parseFormat
            .parse(createdAt, true)
            .toLocal();

        // Accessing _dateFormat (which must be defined as a class field)
        formattedDate = _dateFormat.format(parsedDate);
      } catch (e) {
        // Printing the full error here can help verify if the input string format is the problem
        // print('Date parsing error with input: $createdAt. Error: $e');
        formattedDate = 'Invalid Date';
      }
    }

    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        side: BorderSide(color: statusColor.withOpacity(0.5), width: 1.5),
      ),
      child: ExpansionTile(
        initiallyExpanded: false,
        leading: Icon(
          validated ? Icons.verified_user : Icons.pending_actions,
          color: statusColor,
        ),
        title: Text(
          predictedClass,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: predictedClass.toLowerCase().contains('malignant')
                ? dangerColor
                : primaryColor,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.calendar_today, size: 14, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  formattedDate,
                  style: TextStyle(color: Colors.grey[600], fontSize: 13),
                ),
              ],
            ),
            const SizedBox(height: 4),
            // Status Tag
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                statusText.toUpperCase(),
                style: TextStyle(
                  color: statusColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 10,
                ),
              ),
            ),
          ],
        ),
        children: <Widget>[
          const Divider(height: 1, thickness: 1, indent: 16, endIndent: 16),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 12.0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDetailRow(
                  'Consulting Doctor',
                  doctorName,
                  Icons.person_outline,
                ),
                const SizedBox(height: 8),
                _buildDetailRow(
                  'Model Confidence',
                  '${(confidence * 100).toStringAsFixed(2)}%',
                  Icons.trending_up,
                  confidence > 0.8 ? successColor : dangerColor,
                ),
                const SizedBox(height: 12),

                // Notes
                Text(
                  'Doctor\'s Notes:',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  notes,
                  style: const TextStyle(fontStyle: FontStyle.italic),
                ),
                const SizedBox(height: 20),

                // Download Button
                Center(
                  child: ElevatedButton.icon(
                    onPressed: validated
                        ? () => downloadReport(predictionId)
                        : null,
                    icon: const Icon(Icons.download),
                    label: Text(
                      validated ? "Download Final Report" : "Report Not Ready",
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: validated ? primaryColor : Colors.grey,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(
    String label,
    String value,
    IconData icon, [
    Color? valueColor,
  ]) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: primaryColor.withOpacity(0.7)),
          const SizedBox(width: 8),
          Text(
            '$label:',
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: valueColor ?? Colors.black87,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
