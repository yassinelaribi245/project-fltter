import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;

class FileUploadService {
  static const String _uploadUrl = "https://39a1782c9179.ngrok-free.app/uploadFile";

  static Future<String?> uploadFile({
    required String folder,
    required File file,
  }) async {
    try {
      final request = http.MultipartRequest('POST', Uri.parse(_uploadUrl));
      request.fields['folder'] = folder;
      request.files.add(await http.MultipartFile.fromPath('file', file.path));

      final response = await request.send();
      if (response.statusCode == 200) {
        return await response.stream.bytesToString();
      }
    } catch (_) {}
    return null;
  }

  static Future<List<String>?> pickAndUploadImages() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: true,
    );
    if (result == null) return null;

    final urls = <String>[];
    for (final file in result.files) {
      if (file.path == null) continue;
      final url = await uploadFile(folder: 'images', file: File(file.path!));
      if (url != null) urls.add(url);
    }
    return urls;
  }
}