import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:project_flutter/server_url.dart';
import 'package:project_flutter/services/messaging_service.dart';
import 'package:project_flutter/widgets/presence_dot.dart';
import 'package:project_flutter/pages/gallery_page.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';

class ChatPage extends StatefulWidget {
  final String otherUserId;
  final String otherUserName;
  const ChatPage({
    super.key,
    required this.otherUserId,
    required this.otherUserName,
  });

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final MessagingService _messagingService = MessagingService();
  final TextEditingController _messageController = TextEditingController();
  late String _conversationId;
  bool _uploading = false;

  @override
  void initState() {
    super.initState();
    _conversationId = _messagingService.getConversationId(
      _messagingService.currentUserId!,
      widget.otherUserId,
    );
    _messagingService.startConversation(widget.otherUserId);
  }

  void _sendText() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;
    _messageController.clear();
    await _messagingService.sendMessage(_conversationId, text);
  }

  void _pickFile() async {
    setState(() => _uploading = true);
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
      allowMultiple: false,
    );
    if (result == null || result.files.single.path == null) {
      setState(() => _uploading = false);
      return;
    }
    final file = File(result.files.single.path!);
    try {
      await _messagingService.sendFileMessage(_conversationId, file);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _openFile(String url) async {
  final uri = Uri.parse(url.trim());
  if (url.endsWith('.pdf')) {
    // Force browser tab – never crash
    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
        webViewConfiguration: const WebViewConfiguration(enableJavaScript: true),
      );
      if (!launched) throw 'launchUrl false';
    } catch (_) {
      // Last resort: copy to clipboard + snack-bar
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('PDF link copied to clipboard')),
        );
        Clipboard.setData(ClipboardData(text: url));
      }
    }
  } else {
    // IMAGE – open zoomable gallery
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => GalleryPage(urls: [url.trim()], initialIndex: 0),
      ),
    );
  }
}

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    return DateFormat('dd MMM yyyy').format(date);
  }

  String _formatTime(DateTime? date) {
    if (date == null) return '';
    return DateFormat('HH:mm').format(date);
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E405B),
        title: Row(
          children: [
            Text(widget.otherUserName, style: const TextStyle(color: Colors.white)),
            const SizedBox(width: 6),
            PresenceDot(widget.otherUserId),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.attach_file, color: Color(0xFFFBF1D1)),
            onPressed: _uploading ? null : _pickFile,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _messagingService.getMessages(_conversationId),
              builder: (context, snapshot) {
                if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                final messages = snapshot.data!;
                if (messages.isEmpty) {
                  return const Center(child: Text('No messages yet.', style: TextStyle(color: Colors.white70)));
                }
                return ListView.builder(
                  reverse: true,
                  itemCount: messages.length,
                  itemBuilder: (_, index) {
                    final msg = messages[index];
                    final isMe = msg['senderId'] == _messagingService.currentUserId;
                    final isText = msg['isText'] ?? true;
                    final ts = msg['timestamp'] as Timestamp?;
                    final dateTime = ts?.toDate();
                    final time = _formatTime(dateTime);
                    final date = _formatDate(dateTime);

                    // Day-header logic
                    final prevTs = index < messages.length - 1
                        ? messages[index + 1]['timestamp'] as Timestamp?
                        : null;
                    final prevDate = prevTs == null
                        ? ''
                        : _formatDate(prevTs.toDate());
                    final showDateHeader = date != prevDate;

                    return Column(
                      children: [
                        if (showDateHeader)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Text(date, style: const TextStyle(fontSize: 12, color: Colors.white70)),
                          ),
                        Align(
                          alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                          child: Column(
                            crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                            children: [
                              Container(
                                margin: const EdgeInsets.symmetric(vertical: 2, horizontal: 8),
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: isMe ? const Color(0xFFFBF1D1) : Colors.grey.shade300,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: isText
                                    ? Text(msg['content'], style: const TextStyle(fontSize: 16))
                                    : GestureDetector(
                                        onTap: () => _openFile(msg['content']),
                                        child: msg['content'].toString().endsWith('.pdf')
                                            ? Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  const Icon(Icons.picture_as_pdf,
                                                      color: Colors.red, size: 28),
                                                  const SizedBox(width: 6),
                                                  Text('PDF', style: TextStyle(color: Colors.grey.shade800)),
                                                ],
                                              )
                                            : ClipRRect(
                                                borderRadius: BorderRadius.circular(8),
                                                child: Image.network(
                                                  kNgrokBase+msg['content'].toString().trim(),
                                                  width: 200,
                                                  fit: BoxFit.cover,
                                                  errorBuilder: (_, __, ___) =>
                                                      const Icon(Icons.broken_image),
                                                ),
                                              ),
                                      ),
                              ),
                              const SizedBox(height: 2),
                              Text(time, style: const TextStyle(fontSize: 10, color: Colors.white70)),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),
          if (_uploading) const LinearProgressIndicator(),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Type a message…',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(20)),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.send, color: Color(0xFFFBF1D1)),
                  onPressed: _sendText,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}