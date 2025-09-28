import 'dart:convert';
import 'dart:typed_data';
import 'dart:io' show File; // Only available on mobile/desktop
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Small helper representing an uploaded file (by bytes).
class ApiServiceMultipartFile {
  final String field;
  final Uint8List bytes;
  final String filename;
  final String contentType;

  ApiServiceMultipartFile({
    required this.field,
    required this.bytes,
    required this.filename,
    required this.contentType,
  });

  /// Create from bytes (use this on web and mobile with XFile.readAsBytes())
  static ApiServiceMultipartFile fromBytes({
    required String field,
    required Uint8List bytes,
    required String filename,
    String? contentType,
  }) {
    final ct = contentType ?? _guessContentTypeFromFilename(filename);
    return ApiServiceMultipartFile(
      field: field,
      bytes: bytes,
      filename: filename,
      contentType: ct,
    );
  }

  /// Create from a file path (mobile/desktop only)
  static Future<ApiServiceMultipartFile> fromPath({
    required String field,
    required String filePath,
    String? contentType,
  }) async {
    final file = File(filePath);
    final bytes = await file.readAsBytes();
    final filename = file.uri.pathSegments.last;
    final ct = contentType ?? _guessContentTypeFromFilename(filename);
    return ApiServiceMultipartFile(
      field: field,
      bytes: bytes,
      filename: filename,
      contentType: ct,
    );
  }

  // Simple mime-type guess (extend if needed)
  static String _guessContentTypeFromFilename(String filename) {
    final ext = filename.split('.').last.toLowerCase();
    switch (ext) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'pdf':
        return 'application/pdf';
      default:
        return 'application/octet-stream';
    }
  }
}

class ApiServiceMultipartRequest {
  final String method;
  final String endpoint;
  final Map<String, String> fields = {};
  final List<ApiServiceMultipartFile> files = [];

  ApiServiceMultipartRequest(this.method, this.endpoint);
}

class ApiService {
  static const baseUrl = "http://127.0.0.1:5000"; // replace with your PC IP
  static final FlutterSecureStorage storage = FlutterSecureStorage();

  // JSON header helper
  static Future<Map<String, String>> getHeaders({bool json = true}) async {
    final token = await storage.read(key: "jwt_token");
    final headers = <String, String>{};
    if (token != null) headers["Authorization"] = "Bearer $token";
    if (json) headers["Content-Type"] = "application/json";
    return headers;
  }

  // ---------------- JSON APIs ----------------
  static Future<dynamic> get(String endpoint) async {
    final uri = Uri.parse(baseUrl + endpoint);
    final response = await http.get(uri, headers: await getHeaders());
    return _safeDecode(response);
  }

  static Future<Map<String, dynamic>> post(String endpoint, Map body) async {
    final uri = Uri.parse(baseUrl + endpoint);
    final response = await http.post(
      uri,
      headers: await getHeaders(),
      body: jsonEncode(body),
    );
    return _safeDecode(response);
  }

  static Future<Map<String, dynamic>> put(String endpoint, Map body) async {
    final uri = Uri.parse(baseUrl + endpoint);
    final response = await http.put(
      uri,
      headers: await getHeaders(),
      body: jsonEncode(body),
    );
    return _safeDecode(response);
  }

  // ---------------- Multipart (works on web & mobile) ----------------
  static Future<Map<String, dynamic>> sendMultipart(
    ApiServiceMultipartRequest req,
  ) async {
    final uri = Uri.parse(baseUrl + req.endpoint);

    // Boundary for multipart
    final boundary =
        '----dart-http-boundary-${DateTime.now().millisecondsSinceEpoch}';

    // Build the multipart body manually:
    final bodyBytes = _encodeMultipart(boundary, req.fields, req.files);

    // Headers
    final headers = await getHeaders(json: false);
    headers['Content-Type'] = 'multipart/form-data; boundary=$boundary';

    final response = await http.post(uri, headers: headers, body: bodyBytes);
    return _safeDecode(response);
  }

  // ---------- helpers ----------
  static dynamic _safeDecode(http.Response response) {
  final status = response.statusCode;
  final body = response.body;
  if (body.isEmpty) {
    return {"status": status, "message": "No body"};
  }

  try {
    final decoded = jsonDecode(body); // <-- Don't cast to Map
    if (decoded is Map<String, dynamic>) {
      decoded['__status'] = status; // attach status
    }
    return decoded; // could be Map or List
  } catch (e) {
    return {
      "error": "Failed to decode response",
      "status": status,
      "body": body,
    };
  }
}


  // Encodes fields and files to multipart bytes per RFC 2388
  static Uint8List _encodeMultipart(
    String boundary,
    Map<String, String> fields,
    List<ApiServiceMultipartFile> files,
  ) {
    final crlf = '\r\n';
    final list = <int>[];
    void writeString(String s) => list.addAll(utf8.encode(s));

    // Fields
    fields.forEach((name, value) {
      writeString('--$boundary$crlf');
      writeString('Content-Disposition: form-data; name="$name"$crlf$crlf');
      writeString(value);
      writeString(crlf);
    });

    // Files
    for (final f in files) {
      writeString('--$boundary$crlf');
      writeString(
        'Content-Disposition: form-data; name="${f.field}"; filename="${f.filename}"$crlf',
      );
      writeString('Content-Type: ${f.contentType}$crlf$crlf');
      list.addAll(f.bytes);
      writeString(crlf);
    }

    // Final boundary
    writeString('--$boundary--$crlf');

    return Uint8List.fromList(list);
  }
}
