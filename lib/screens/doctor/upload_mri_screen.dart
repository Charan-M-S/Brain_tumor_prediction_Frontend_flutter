import 'dart:io' show File; // Only available on mobile/desktop
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/api_service.dart'; // Your custom service

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
  double? confidence;

  // Pick image
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      if (kIsWeb) {
        final bytes = await pickedFile.readAsBytes();
        setState(() {
          _webImage = bytes;
          _imageFile = pickedFile;
          _selectedFile = null; // Clear mobile file
        });
      } else {
        setState(() {
          _selectedFile = File(pickedFile.path);
          _imageFile = pickedFile;
          _webImage = null; // Clear web bytes
        });
      }
    }
  }

  // Upload and predict
Future<void> uploadAndPredict() async {
  final patientId = _patientIdController.text.trim();

  if ((kIsWeb && _webImage == null) || (!kIsWeb && _selectedFile == null)) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Please select an MRI image first.")),
    );
    return;
  }

  if (patientId.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Please enter Patient ID.")),
    );
    return;
  }

  setState(() => loading = true);

  try {
    final req = ApiServiceMultipartRequest("POST", "/doctor/predict");

    // Web: use bytes
    if (kIsWeb) {
      req.files.add(
        ApiServiceMultipartFile.fromBytes(
          field: "mri_image",
          bytes: _webImage!,
          filename: _imageFile?.name ?? "upload.png",
        ),
      );
    } 
    // Mobile/Desktop: use file path
    else {
      final fileObj = await ApiServiceMultipartFile.fromPath(
        field: "mri_image",
        filePath: _selectedFile!.path,
      );
      req.files.add(fileObj);
    }

    req.fields["patient_id"] = patientId;

    final res = await ApiService.sendMultipart(req);

    // New response structure: class and confidence at top level
    if (res.containsKey("class") && res.containsKey("confidence")) {
      setState(() {
        predictedClass = res["class"];
        confidence = (res["confidence"] as num).toDouble();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Prediction successful")),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res["error"] ?? "Prediction failed")),
      );
    }
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Error: $e")),
    );
  } finally {
    setState(() => loading = false);
  }
}

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          TextField(
            controller: _patientIdController,
            decoration: InputDecoration(labelText: "Patient ID"),
          ),
          const SizedBox(height: 10),

          // Image preview
          if (kIsWeb && _webImage != null)
            Image.memory(_webImage!, height: 200)
          else if (!kIsWeb && _selectedFile != null)
            Image.file(_selectedFile!, height: 200)
          else
            Container(
              height: 200,
              color: Colors.grey[200],
              child: Center(child: Text("No image selected")),
            ),

          const SizedBox(height: 10),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton(
                onPressed: _pickImage,
                child: Text("Select MRI Image"),
              ),
              ElevatedButton(
                onPressed: loading ? null : uploadAndPredict,
                child: loading
                    ? SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(color: Colors.white),
                      )
                    : Text("Predict"),
              ),
            ],
          ),

          const SizedBox(height: 20),

          if (predictedClass != null && confidence != null)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Predicted Class: $predictedClass",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Text("Confidence: ${(confidence! * 100).toStringAsFixed(2)}%"),
              ],
            ),
        ],
      ),
    );
  }
}