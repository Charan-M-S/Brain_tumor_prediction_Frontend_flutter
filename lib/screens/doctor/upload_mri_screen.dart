import 'dart:io' show File; // Only available on mobile/desktop
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/api_service.dart'; // Your custom service

// Define the Color Palette (Consistent with other screens)
const Color primaryColor = Color(0xFF1D5D9B); // Darker Blue
const Color accentColor = Color(0xFFF4D160); // Golden Accent
const Color successColor = Color(
  0xFF38A169,
); // Green for Success/High Confidence
const Color dangerColor = Color(0xFFE53E3E); // Red for Danger/Low Confidence

class UploadMRIScreen extends StatefulWidget {
  @override
  _UploadMRIScreenState createState() => _UploadMRIScreenState();
}

class _UploadMRIScreenState extends State<UploadMRIScreen> {
  File? _selectedFile; // Mobile/Desktop
  Uint8List? _webImage; // Web
  XFile? _imageFile;
  final _patientIdController = TextEditingController();
  bool loading = false;
  String? predictedClass;
  String? segmentationPath;
  double? confidence;

  // --- Core Logic ---

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      // Reset results upon selecting new image
      setState(() {
        predictedClass = null;
        confidence = null;
      });

      if (kIsWeb) {
        final bytes = await pickedFile.readAsBytes();
        setState(() {
          _webImage = bytes;
          _imageFile = pickedFile;
          _selectedFile = null;
        });
      } else {
        setState(() {
          _selectedFile = File(pickedFile.path);
          _imageFile = pickedFile;
          _webImage = null;
        });
      }
    }
  }

  Future<void> uploadAndPredict() async {
    final patientId = _patientIdController.text.trim();

    if ((kIsWeb && _webImage == null) || (!kIsWeb && _selectedFile == null)) {
      _showSnackbar("Please select an MRI image first.", Colors.orange);
      return;
    }

    if (patientId.isEmpty) {
      _showSnackbar("Please enter Patient ID.", Colors.orange);
      return;
    }

    setState(() => loading = true);

    try {
      final req = ApiServiceMultipartRequest("POST", "/doctor/predict");

      if (kIsWeb) {
        req.files.add(
          ApiServiceMultipartFile.fromBytes(
            field: "mri_image",
            bytes: _webImage!,
            filename: _imageFile?.name ?? "upload.png",
          ),
        );
      } else {
        final fileObj = await ApiServiceMultipartFile.fromPath(
          field: "mri_image",
          filePath: _selectedFile!.path,
        );
        req.files.add(fileObj);
      }

      req.fields["patient_id"] = patientId;

      final res = await ApiService.sendMultipart(req);

      if (!mounted) return;

      if (res.containsKey("class") && res.containsKey("confidence")) {
        setState(() {
          predictedClass = res["class"];
          confidence = (res["confidence"] as num).toDouble();
          segmentationPath =
              res["segmentation_path"]; // NEW: Optional segmentation
          print(segmentationPath);
        });
        _showSnackbar("Prediction successful", successColor);
      } else {
        setState(() {
          predictedClass = null;
          confidence = null;
          segmentationPath = null;
        });
        _showSnackbar(res["error"] ?? "Prediction failed", dangerColor);
      }
    } catch (e) {
      if (!mounted) return;
      _showSnackbar("Error: $e", dangerColor);
    } finally {
      if (!mounted) return;
      setState(() => loading = false);
    }
  }

  void _showSnackbar(String message, Color color) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message), backgroundColor: color));
  }

  // --- Build Methods (Responsive Layouts) ---

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Reduced max width for better utilization in the dashboard context
        bool isDesktop = constraints.maxWidth >= 1000;
        bool isTablet =
            constraints.maxWidth >= 600 && constraints.maxWidth < 1000;

        if (isDesktop) {
          return _buildDesktopLayout();
        } else if (isTablet) {
          return _buildTabletLayout();
        } else {
          return _buildMobileLayout();
        }
      },
    );
  }

  Widget _buildDesktopLayout() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left Column - Upload Section (Wider space for form)
              Expanded(
                flex: 2,
                child: Card(
                  elevation: 6,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionHeader(
                          'Upload MRI Scan',
                          Icons.cloud_upload_outlined,
                          primaryColor,
                        ),
                        const SizedBox(height: 32),

                        _buildPatientIdField(),
                        const SizedBox(height: 32),

                        _buildImageUploadSection(isLarge: true),
                        const SizedBox(height: 32),

                        Row(
                          children: [
                            Expanded(child: _buildSelectButton(isLarge: true)),
                            const SizedBox(width: 16),
                            Expanded(child: _buildPredictButton(isLarge: true)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 24),

              // Right Column - Results Section (Takes remaining space)
              Expanded(flex: 1, child: _buildResultsSection()),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTabletLayout() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // Upload Card
          Card(
            elevation: 6,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader(
                    'Upload & Analyze',
                    Icons.cloud_upload_outlined,
                    primaryColor,
                  ),
                  const SizedBox(height: 24),

                  _buildPatientIdField(),
                  const SizedBox(height: 24),

                  _buildImageUploadSection(isLarge: false),
                  const SizedBox(height: 24),

                  Row(
                    children: [
                      Expanded(child: _buildSelectButton(isLarge: false)),
                      const SizedBox(width: 16),
                      Expanded(child: _buildPredictButton(isLarge: false)),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Results Card
          _buildResultsSection(),
        ],
      ),
    );
  }

  Widget _buildMobileLayout() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // Upload Card
          Card(
            elevation: 6,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.stretch, // Stretch buttons fully
                children: [
                  _buildSectionHeader(
                    'Upload MRI Scan',
                    Icons.cloud_upload_outlined,
                    primaryColor,
                  ),
                  const SizedBox(height: 20),

                  _buildPatientIdField(),
                  const SizedBox(height: 20),

                  _buildImageUploadSection(isLarge: false),
                  const SizedBox(height: 20),

                  _buildSelectButton(isLarge: false),
                  const SizedBox(height: 12),
                  _buildPredictButton(isLarge: false),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),
          _buildResultsSection(),
        ],
      ),
    );
  }

  // --- Shared Component Widgets ---

  Widget _buildSectionHeader(String title, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, size: 28, color: color),
        const SizedBox(width: 12),
        Text(
          title,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
          ),
        ),
      ],
    );
  }

  Widget _buildPatientIdField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Patient Information',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _patientIdController,
          decoration: InputDecoration(
            labelText: "Patient ID (e.g., P001)",
            prefixIcon: Icon(
              Icons.person_outline,
              color: primaryColor.withOpacity(0.7),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: primaryColor, width: 2),
            ),
            filled: true,
            fillColor: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildImageUploadSection({required bool isLarge}) {
    final imageHeight = isLarge ? 300.0 : 200.0;
    final hasImage =
        (kIsWeb && _webImage != null) || (!kIsWeb && _selectedFile != null);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'MRI Image Preview',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          height: imageHeight,
          decoration: BoxDecoration(
            border: Border.all(
              color: hasImage ? primaryColor : Colors.grey[300]!,
              width: hasImage
                  ? 3
                  : 2, // Highlight border when image is selected
              style: BorderStyle.solid,
            ),
            borderRadius: BorderRadius.circular(12),
            color: Colors.white,
          ),
          child: hasImage ? _buildImagePreview() : _buildImagePlaceholder(),
        ),
      ],
    );
  }

  Widget _buildImagePreview() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: kIsWeb && _webImage != null
          ? Image.memory(
              _webImage!,
              fit: BoxFit.contain,
              width: double.infinity,
            )
          : !kIsWeb && _selectedFile != null
          ? Image.file(
              _selectedFile!,
              fit: BoxFit.contain,
              width: double.infinity,
            )
          : Container(),
    );
  }

  Widget _buildImagePlaceholder() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.image_search, size: 48, color: Colors.grey[400]),
        const SizedBox(height: 16),
        Text(
          "No MRI image selected",
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          "PNG, JPG format supported.",
          style: TextStyle(color: Colors.grey[500], fontSize: 14),
        ),
      ],
    );
  }

  Widget _buildSelectButton({required bool isLarge}) {
    return SizedBox(
      width: double.infinity,
      height: isLarge ? 56 : 48,
      child: OutlinedButton.icon(
        // Used OutlinedButton for secondary action
        onPressed: _pickImage,
        icon: Icon(Icons.file_upload_outlined, size: isLarge ? 24 : 20),
        label: Text(
          "Select MRI Image",
          style: TextStyle(
            fontSize: isLarge ? 16 : 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryColor,
          backgroundColor: Colors.white,
          side: const BorderSide(color: primaryColor, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Widget _buildPredictButton({required bool isLarge}) {
    return SizedBox(
      width: double.infinity,
      height: isLarge ? 56 : 48,
      child: ElevatedButton.icon(
        onPressed: loading ? null : uploadAndPredict,
        icon: loading
            ? SizedBox(
                height: isLarge ? 24 : 20,
                width: isLarge ? 24 : 20,
                child: const CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : Icon(Icons.analytics_sharp, size: isLarge ? 24 : 20),
        label: Text(
          loading ? "Analyzing..." : "Analyze MRI",
          style: TextStyle(
            fontSize: isLarge ? 16 : 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 5,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Widget _buildResultsSection() {
    // Determine confidence color for use in result cards
    final resultColor = confidence != null
        ? (confidence! * 100) >= 80
              ? successColor
              : (confidence! * 100) >= 60
              ? accentColor
              : dangerColor
        : Colors.grey;

    if (predictedClass == null || confidence == null) {
      return Card(
        elevation: 6,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            children: [
              Icon(Icons.search_off, size: 60, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                'Awaiting Analysis',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Results will appear here after a successful analysis.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: resultColor.withOpacity(0.5),
          width: 2,
        ), // Highlight the results card
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader(
              'Final Prediction',
              Icons.check_circle,
              resultColor,
            ),
            const SizedBox(height: 20),

            _buildResultItem(
              icon: Icons.medical_information,
              title: 'Predicted Class',
              value: predictedClass!,
              color: primaryColor, // Always use primary for class
            ),
            const SizedBox(height: 16),

            _buildResultItem(
              icon: Icons.lightbulb_outline,
              title: 'Confidence Level',
              value: '${(confidence! * 100).toStringAsFixed(1)}%',
              color: resultColor, // Color-coded confidence
            ),

            const SizedBox(height: 20),
            _buildConfidenceIndicator(resultColor),

            // --- NEW: Segmentation Image Section ---
            if (segmentationPath != null) ...[
              const SizedBox(height: 24),
              Text(
                'Tumor Segmentation',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.grey[800],
                ),
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  'http://127.0.0.1:5000/$segmentationPath', // Replace with your actual server URL
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.contain,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildResultItem({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildConfidenceIndicator(Color color) {
    final confidencePercent = confidence! * 100;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Confidence Breakdown',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: confidence!,
            backgroundColor: Colors.grey[200],
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 12,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          confidencePercent >= 80
              ? 'Recommendation: High Confidence. Ready for Doctor Validation.'
              : confidencePercent >= 60
              ? 'Note: Medium Confidence. Review additional data before validating.'
              : 'Warning: Low Confidence. Model suggestion needs careful verification.',
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
      ],
    );
  }
}
