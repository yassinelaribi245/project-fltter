import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:project_flutter/services/messaging_service.dart';
import 'package:project_flutter/services/friend_service.dart';
import 'package:project_flutter/pages/chat_page.dart';
import 'package:project_flutter/services/notification_service.dart';
import 'package:project_flutter/widgets/presence_dot.dart';
import 'package:project_flutter/models/friend_request.dart';

class OtherProfilePage extends StatefulWidget {
  final String userId;
  final String userName;
  final bool? showBackArrow; // NEW

  const OtherProfilePage({
    super.key,
    required this.userId,
    required this.userName,
    this.showBackArrow, // NEW
  });

  @override
  State<OtherProfilePage> createState() => _OtherProfilePageState();
  
}

class _OtherProfilePageState extends State<OtherProfilePage> {
  final MessagingService _messagingService = MessagingService();
  final FriendService _friendService = FriendService();
  Map<String, dynamic>? userData;
  bool isLoading = true;
  bool showPosts = true;
  bool? isFriend;
  bool requestPending = false;
  bool? theySentMe; // null = none, true = they sent me, false = I sent them
  Future<void> _refreshFriendStatus() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    isFriend = await FriendService().areFriends(widget.userId);
    final outgoing = await FriendService().requestPending(widget.userId);
    final incoming = await FriendService().incomingRequests().first.then(
      (list) => list.any((r) => r.fromUid == widget.userId),
    );
    if (mounted) {
      setState(() {
        isFriend = isFriend;
        requestPending = outgoing;
        theySentMe = incoming ? true : (outgoing ? false : null);
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _refreshFriendStatus();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    try {
      final data = await _messagingService.getUserData(widget.userId);
      if (mounted) {
        setState(() {
          userData = data;
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading user data: $e')));
      }
    }
  }

  Future<void> _checkFriendStatus() async {
    final friend = await _friendService.areFriends(widget.userId);

    // 1.  did THEY send me a request?
    final incoming = await FirebaseFirestore.instance
        .collection('friendRequests')
        .where('fromUid', isEqualTo: widget.userId)
        .where('toUid', isEqualTo: FirebaseAuth.instance.currentUser?.uid)
        .get();
    final hasIncoming = incoming.docs.isNotEmpty;

    // 2.  did I send them a request?
    final outgoing = await FirebaseFirestore.instance
        .collection('friendRequests')
        .where('fromUid', isEqualTo: FirebaseAuth.instance.currentUser?.uid)
        .where('toUid', isEqualTo: widget.userId)
        .get();
    final hasOutgoing = outgoing.docs.isNotEmpty;

    if (mounted) {
      setState(() {
        isFriend = friend;
        requestPending = hasOutgoing;
        theySentMe = hasIncoming && !friend
            ? true
            : (hasOutgoing ? false : null);
      });
    }
  }

  void _onAddFriend() async {
    await _friendService.sendRequest(widget.userId);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Friend request sent to ${widget.userName}')),
      );
      setState(() => requestPending = true);
    }
  }

  void _onSendMessage() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatPage(
          otherUserId: widget.userId,
          otherUserName: widget.userName,
        ),
      ),
    );
  }

  void _showPosts() => setState(() => showPosts = true);
  void _showImages() => setState(() => showPosts = false);

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF1E405B),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final bio = userData?['bio']?.isNotEmpty == true
        ? userData!['bio']
        : 'No bio available';

    return Scaffold(
      appBar: (widget.showBackArrow ?? false)
          ? AppBar(
              backgroundColor: const Color(0xFF1E405B),
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.of(context).pop(),
              ),
            )
          : null,
      backgroundColor: const Color(0xFF1E405B),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: FadeInUp(
            duration: const Duration(milliseconds: 1000),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    CircleAvatar(
                      radius: 70,
                      backgroundImage: userData?['profilePicture'] != null
                          ? NetworkImage(userData!['profilePicture'])
                          : const AssetImage('assets/other_profile.jpg'),
                    ),
                    PresenceDot(widget.userId),
                  ],
                ),
                const SizedBox(height: 20),
                Text(
                  widget.userName,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  bio,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16, color: Colors.white70),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton(
                      onPressed: _onSendMessage,
                      style: ElevatedButton.styleFrom(
                        shape: const CircleBorder(),
                        padding: const EdgeInsets.all(14),
                      ),
                      child: const Icon(Icons.send),
                    ),
                    const SizedBox(width: 15),
                    // ------------- FRIEND BUTTON -------------
                    if (isFriend == true)
                      ElevatedButton.icon(
                        onPressed: () async {
                          await _friendService.removeFriend(widget.userId);
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Unfriended ${widget.userName}'),
                              ),
                            );
                            setState(() => _checkFriendStatus());
                          }
                        },
                        icon: const Icon(Icons.person_remove),
                        label: const Text('Unfriend'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          minimumSize: const Size(120, 45),
                        ),
                      )
                    else if (theySentMe == true)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ElevatedButton.icon(
                            icon: const Icon(Icons.check),
                            label: const Text('Accept'),
                            onPressed: () async {
                              final reqSnap = await FirebaseFirestore.instance
                                  .collection('friendRequests')
                                  .where('fromUid', isEqualTo: widget.userId)
                                  .where(
                                    'toUid',
                                    isEqualTo:
                                        FirebaseAuth.instance.currentUser!.uid,
                                  )
                                  .get();
                              if (reqSnap.docs.isNotEmpty) {
                                final req = FriendRequest.fromDoc(
                                  reqSnap.docs.first,
                                );
                                await _friendService.accept(req);
                                // AFTER the batch / delete is done
                                await _refreshFriendStatus();
                              }
                            },
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.close),
                            label: const Text('Decline'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                            ),
                            onPressed: () async {
                              // 1.  delete the friend-request document
                              final reqSnap = await FirebaseFirestore.instance
                                  .collection('friendRequests')
                                  .where('fromUid', isEqualTo: widget.userId)
                                  .where(
                                    'toUid',
                                    isEqualTo:
                                        FirebaseAuth.instance.currentUser!.uid,
                                  )
                                  .get();
                              if (reqSnap.docs.isNotEmpty) {
                                await reqSnap.docs.first.reference
                                    .delete(); // removes request
                              }

                              // 2.  delete the notification document
                              final notifSnap = await FirebaseFirestore.instance
                                  .collection('notifications')
                                  .where('fromUid', isEqualTo: widget.userId)
                                  .where(
                                    'toUid',
                                    isEqualTo:
                                        FirebaseAuth.instance.currentUser!.uid,
                                  )
                                  .where('type', isEqualTo: 'friendRequest')
                                  .get();
                              if (notifSnap.docs.isNotEmpty) {
                                // 2.  delete the notification (by sender + type)
                                await NotificationService()
                                    .deleteFriendRequestNotif(
                                      fromUid: widget.userId,
                                      toUid: FirebaseAuth
                                          .instance
                                          .currentUser!
                                          .uid,
                                    );
                              }
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Friend request declined'),
                                  ),
                                );
                                await _refreshFriendStatus();
                              }
                            },
                          ),
                        ],
                      )
                    else if (requestPending)
                      ElevatedButton.icon(
                        onPressed: null,
                        icon: Icon(Icons.watch_later),
                        label: Text('Request pending'),
                      )
                    else
                      ElevatedButton.icon(
                        onPressed: _onAddFriend,
                        icon: const Icon(Icons.person_add),
                        label: const Text('Add Friend'),
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(120, 45),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 30),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton(
                      onPressed: _showPosts,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: showPosts
                            ? const Color(0xFFFBF1D1)
                            : Colors.grey.shade400,
                      ),
                      child: const Text('Posts'),
                    ),
                    const SizedBox(width: 15),
                    ElevatedButton(
                      onPressed: _showImages,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: !showPosts
                            ? const Color(0xFFFBF1D1)
                            : Colors.grey.shade400,
                      ),
                      child: const Text('Images'),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                showPosts
                    ? Column(
                        children: List.generate(
                          5,
                          (index) => Card(
                            color: const Color(0xFFEDEDEB),
                            margin: const EdgeInsets.symmetric(vertical: 8),
                            child: ListTile(
                              leading: const Icon(Icons.article),
                              title: Text('Post #${index + 1}'),
                              subtitle: const Text(
                                'This is a placeholder post.',
                              ),
                            ),
                          ),
                        ),
                      )
                    : Column(
                        children: List.generate(
                          6,
                          (index) => Container(
                            margin: const EdgeInsets.symmetric(
                              vertical: 8,
                              horizontal: 4,
                            ),
                            height: 150,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade300,
                              borderRadius: BorderRadius.circular(15),
                              image: const DecorationImage(
                                image: AssetImage('assets/placeholder.jpg'),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ),
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
