import 'dart:io';
import 'package:flutter/material.dart';
import 'package:project_flutter/services/messaging_service.dart';
import 'package:project_flutter/widgets/presence_dot.dart';
import 'package:project_flutter/pages/gallery_page.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:file_picker/file_picker.dart';

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
    if (url.endsWith('.pdf')) {
      final uri = Uri.parse(url);
      try {
        final can = await canLaunchUrl(uri);
        if (!can) throw 'canLaunchUrl false';
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } catch (_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not open PDF')),
          );
        }
      }
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => GalleryPage(urls: [url], initialIndex: 0),
        ),
      );
    }
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
                    return Align(
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isMe ? const Color(0xFFFBF1D1) : Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: isText
                            ? Text(msg['content'], style: const TextStyle(fontSize: 16))
                            : GestureDetector(
                                onTap: () => _openFile(msg['content']),
                                child: msg['content'].endsWith('.pdf')
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
                                          msg['content'],
                                          width: 200,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) =>
                                              const Icon(Icons.broken_image),
                                        ),
                                      ),
                              ),
                      ),
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