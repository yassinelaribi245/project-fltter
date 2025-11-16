import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:project_flutter/server_url.dart';
import 'package:url_launcher/url_launcher.dart';

class GalleryPage extends StatelessWidget {
  final List<String> urls; // images + pdfs
  final int initialIndex;
  const GalleryPage({
    super.key,
    required this.urls,
    this.initialIndex = 0,
  });

  Future<void> _openPdf(BuildContext context, String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open PDF')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final imageUrls = urls.where((u) => !u.endsWith('.pdf')).toList();
    final initialPage = imageUrls.isEmpty
        ? 0
        : imageUrls.indexWhere((u) => u == urls[initialIndex]).clamp(0, imageUrls.length - 1);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
      body: Column(
        children: [
          // gallery (only images)
          if (imageUrls.isNotEmpty)
            Expanded(
              child: PhotoViewGallery.builder(
                itemCount: imageUrls.length,
                pageController: PageController(initialPage: initialPage),
                builder: (context, i) => PhotoViewGalleryPageOptions(
                  imageProvider: NetworkImage(kNgrokBase +imageUrls[i]),
                  minScale: PhotoViewComputedScale.contained,
                  maxScale: PhotoViewComputedScale.covered * 2,
                ),
                scrollPhysics: const BouncingScrollPhysics(),
              ),
            ),
          // pdf chips
          if (urls.any((u) => u.endsWith('.pdf')))
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Wrap(
                  spacing: 12,
                  children: urls
                      .where((u) => u.endsWith('.pdf'))
                      .map(
                        (u) => ActionChip(
                          label: const Text('Open PDF'),
                          avatar: const Icon(Icons.picture_as_pdf, color: Colors.red),
                          onPressed: () => _openPdf(context, u),
                        ),
                      )
                      .toList(),
                ),
              ),
            ),
        ],
      ),
    );
  }
}