import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'package:project_flutter/server_url.dart'; // ← single base URL

class FileUploadService {
  /* ----------  UPLOAD SINGLE FILE  ---------- */
  /// returns **path only**  e.g.  /images/abc.jpg
  static Future<String?> uploadFile({
    required String folder, // 'images' | 'pdfs'
    required File file,
  }) async {
    try {
      final url = Uri.parse('$kNgrokBase/uploadFile');
      final request = http.MultipartRequest('POST', url);
      request.fields['folder'] = folder;
      request.files.add(await http.MultipartFile.fromPath('file', file.path));

      final response = await request.send();
      if (response.statusCode == 200) {
        // server returns **path only**  e.g.  /images/abc.jpg
        final path = await response.stream.bytesToString();
        return path.trim();
      }
    } catch (_) {}
    return null;
  }

  /* ----------  PICK & UPLOAD MULTIPLE IMAGES  ---------- */
  /// returns **List<path>**  e.g.  ['/images/a.jpg', '/images/b.jpg']
  static Future<List<String>?> pickAndUploadImages() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: true,
    );
    if (result == null) return null;

    final paths = <String>[];
    for (final platformFile in result.files) {
      final path = platformFile.path;
      if (path == null) continue;
      final uploaded = await uploadFile(
        folder: 'images',
        file: File(path),
      );
      if (uploaded != null) paths.add(uploaded);
    }
    return paths.isEmpty ? null : paths;
  }
}