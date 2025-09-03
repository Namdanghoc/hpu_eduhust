import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hpu_eduhust/providers/auth.dart';
import 'package:hpu_eduhust/providers/chat.dart';
import 'package:hpu_eduhust/providers/post.dart';
import 'package:hpu_eduhust/screens/createpostscreen.dart';
import 'package:hpu_eduhust/screens/loginscreens.dart';
import 'package:hpu_eduhust/screens/userchatscreen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hpu_eduhust/screens/userlistscreen.dart';
import 'package:hpu_eduhust/utils/Colors.dart';
import 'package:hpu_eduhust/utils/textstyle.dart';
import 'package:hpu_eduhust/widget/drawerwidget.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';

class ChatListScreen extends StatefulWidget {
  final AppUser user;
  const ChatListScreen({super.key, required this.user});
  @override
  _ChatListScreenState createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  final ChatService _chatService = ChatService();

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    final _auth = FirebaseAuth.instance;
    final accountService = UserService();
    final PostService _postService = PostService();
    List<Post> _posts = [];
    bool _isLoading = true;

    void _navigateToLogin() {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => LoginScreen()),
        (Route<dynamic> route) => false,
      );
    }

    void _signOut() {
      _auth.signOut();
      _navigateToLogin();
    }

    void _createPost() async {
      if (_auth.currentUser == null) {
        _navigateToLogin();
        return;
      }

      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => GVCreatePostScreen(
            giangvien: widget.user,
          ),
        ),
      );

      if (result == true) {}
    }

    Future<void> _fetchPosts() async {
      setState(() {
        _isLoading = true;
      });
      try {
        final posts = await _postService.getPosts();
        setState(() {
          _posts = posts;

          _isLoading = false;
        });
      } catch (e) {
        setState(() {
          _isLoading = false;
        });
        debugPrint('Lỗi khi lấy bài viết: $e');
      }
    }

    if (currentUser == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => LoginScreen()),
        );
      });
      return Container();
    }

    return Scaffold(
      backgroundColor: backgroundColor,
      drawer: Mydrawer(
        onSignoutTap: _signOut,
        onCreateTap: _createPost,
        user: widget.user,
      ),
      appBar: AppBar(
        title: Text(
          'Message',
          style: textsimplewhitebigger,
        ),
        iconTheme: IconThemeData(color: Colors.white),
        backgroundColor: mainColor,
        centerTitle: true,
      ),
      body: StreamBuilder<List<DocumentSnapshot>>(
        stream: _chatService.getChatRooms(currentUser.uid),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Đã xảy ra lỗi'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          final chatRooms = snapshot.data ?? [];

          if (chatRooms.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Chưa có cuộc trò chuyện nào'),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                            builder: (context) => UserListScreen()),
                      );
                    },
                    child: Text('Tìm người để trò chuyện'),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            itemCount: chatRooms.length,
            itemBuilder: (context, index) {
              final chatRoom = chatRooms[index].data() as Map<String, dynamic>;
              final participants = chatRoom['participants'] as List<dynamic>;
              final otherUserId = participants.firstWhere(
                (id) => id != currentUser.uid,
                orElse: () => currentUser.uid,
              );

              if (otherUserId == currentUser.uid) return SizedBox.shrink();

              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection('users')
                    .doc(otherUserId)
                    .get(),
                builder: (context, userSnapshot) {
                  if (!userSnapshot.hasData) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Shimmer.fromColors(
                        baseColor: Colors.grey[300]!,
                        highlightColor: Colors.grey[100]!,
                        child: ListTile(
                          leading: CircleAvatar(child: Icon(Icons.person)),
                          title: Container(
                              height: 10, width: 100, color: Colors.white),
                          subtitle: Container(
                              height: 8, width: 150, color: Colors.white),
                        ),
                      ),
                    );
                  }

                  final userData =
                      userSnapshot.data!.data() as Map<String, dynamic>;
                  final displayName = userData['realname'] ?? 'Không rõ';

                  final lastMessage =
                      chatRoom['lastMessage'] as String? ?? 'Không có tin nhắn';
                  final lastMessageTime =
                      (chatRoom['lastMessageTimestamp'] as Timestamp?)
                              ?.toDate() ??
                          DateTime.now();
                  final isLastMessageMine =
                      chatRoom['lastSenderId'] == currentUser.uid;

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.15),
                            spreadRadius: 1,
                            blurRadius: 5,
                            offset: Offset(0, 3),
                          ),
                        ],
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        leading: CircleAvatar(
                          radius: 24,
                          backgroundColor: Theme.of(context).primaryColor,
                          child: Text(
                            displayName[0].toUpperCase(),
                            style: TextStyle(color: Colors.white, fontSize: 20),
                          ),
                        ),
                        title: Text(
                          displayName,
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        subtitle: Row(
                          children: [
                            if (isLastMessageMine)
                              Text('Bạn: ',
                                  style:
                                      TextStyle(fontWeight: FontWeight.w500)),
                            Expanded(
                              child: Text(
                                lastMessage,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(color: Colors.grey[700]),
                              ),
                            ),
                          ],
                        ),
                        trailing: Text(
                          DateFormat('HH:mm').format(lastMessageTime),
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 12,
                          ),
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ChatScreen(
                                otherUserId: otherUserId,
                                otherUserName: displayName,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => UserListScreen()),
          );
        },
        child: Icon(Icons.message),
        tooltip: 'Cuộc trò chuyện mới',
      ),
    );
  }
}
