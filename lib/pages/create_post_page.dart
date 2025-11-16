import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:project_flutter/server_url.dart';
import 'package:project_flutter/services/post_service.dart';
import 'package:project_flutter/services/file_upload_service.dart';
import 'package:project_flutter/app_hashtags.dart';

class CreatePostPage extends StatefulWidget {
  const CreatePostPage({super.key});

  @override
  State<CreatePostPage> createState() => _CreatePostPageState();
}

class _CreatePostPageState extends State<CreatePostPage> {
  final _ctrl = TextEditingController();
  final _service = PostService();
  final _topics = <String>[];

  bool _isImagePost = false;
  List<String> _imageUrls = [];

  bool _submitting = false;
  bool _uploading = false;

  bool get _loading => _uploading || _submitting;
  bool get _hasTopics => _topics.isNotEmpty;

  Future<void> _submit() async {
    if (_ctrl.text.trim().isEmpty && !_isImagePost) return;
    if (!_hasTopics) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pick at least one topic')),
      );
      return;
    }
    setState(() => _submitting = true);

    try {
      if (_isImagePost) {
        if (_imageUrls.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please attach at least one file')),
          );
          return;
        }
        await _service.createImagePost(
          content: _ctrl.text,
          topics: _topics,
          images: _imageUrls,
        );
      } else {
        await _service.createTextPost(
          content: _ctrl.text,
          topics: _topics,
        );
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E405B),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E405B),
        title: const Text("New Post", style: TextStyle(color: Colors.white)),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: IntrinsicHeight(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ChoiceChip(
                          label: const Text('Text'),
                          selected: !_isImagePost,
                          onSelected: (_) => setState(() => _isImagePost = false),
                        ),
                        const SizedBox(width: 12),
                        ChoiceChip(
                          label: const Text('Images'),
                          selected: _isImagePost,
                          onSelected: (_) => setState(() => _isImagePost = true),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _ctrl,
                      maxLines: 6,
                      decoration: InputDecoration(
                        hintText: _isImagePost ? 'Add a caption...' : 'What\'s on your mind?',
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text('Pick at least one topic', style: TextStyle(color: Colors.white70)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: kAppHashtags.map((t) {
                        final isSelected = _topics.contains(t);
                        return FilterChip(
                          label: Text(t),
                          selected: isSelected,
                          onSelected: (val) => setState(() {
                            val ? _topics.add(t) : _topics.remove(t);
                          }),
                          selectedColor: const Color(0xFFFBF1D1),
                          backgroundColor: Colors.white,
                        );
                      }).toList(),
                    ),
                    if (_isImagePost) ...[
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        onPressed: _uploading ? null : _pickAndUpload,
                        icon: const Icon(Icons.attach_file),
                        label: _uploading
                            ? const SizedBox(
                                height: 16,
                                width: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text('Attach Images / PDFs'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFBF1D1),
                          foregroundColor: const Color(0xFF1E405B),
                        ),
                      ),
                      if (_imageUrls.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 100,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: _imageUrls.length,
                            itemBuilder: (_, i) => Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: Stack(
                                alignment: Alignment.topRight,
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: _imageUrls[i].endsWith('.pdf')
                                        ? Container(
                                            width: 100,
                                            color: Colors.grey.shade300,
                                            child: const Icon(
                                              Icons.picture_as_pdf,
                                              color: Colors.red,
                                              size: 40,
                                            ),
                                          )
                                        : Image.network(
                                            kNgrokBase+_imageUrls[i],
                                            width: 100,
                                            height: 100,
                                            fit: BoxFit.cover,
                                            errorBuilder: (_, __, ___) =>
                                                const Icon(Icons.broken_image),
                                          ),
                                  ),
                                  InkWell(
                                    onTap: () => setState(() => _imageUrls.removeAt(i)),
                                    child: Container(
                                      margin: const EdgeInsets.all(4),
                                      padding: const EdgeInsets.all(2),
                                      decoration: const BoxDecoration(
                                        color: Colors.black54,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.close,
                                          size: 16, color: Colors.white),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                    const Spacer(),
                    ElevatedButton(
                      onPressed: !_hasTopics || _loading ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFBF1D1),
                        minimumSize: const Size(double.infinity, 50),
                      ),
                      child: _loading
                          ? const SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Post'),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _pickAndUpload() async {
    setState(() => _uploading = true);
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
      allowMultiple: true,
    );
    if (result == null || result.files.isEmpty) {
      setState(() => _uploading = false);
      return;
    }
    final urls = <String>[];
    for (final platformFile in result.files) {
      final path = platformFile.path;
      if (path == null) continue;
      final folder = platformFile.extension == 'pdf' ? 'pdfs' : 'images';
      final url = await FileUploadService.uploadFile(
        folder: folder,
        file: File(path),
      );
      if (url != null) urls.add(url);
    }
    setState(() {
      _imageUrls = urls;
      _uploading = false;
    });
    if (urls.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No files uploaded')),
      );
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${urls.length} file(s) attached')),
    );
  }
}