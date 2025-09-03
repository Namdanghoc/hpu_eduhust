import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:hpu_eduhust/providers/chat.dart';
import 'package:hpu_eduhust/screens/loginscreens.dart';
import 'package:hpu_eduhust/utils/Colors.dart';
import 'package:hpu_eduhust/utils/textstyle.dart';
import 'package:hpu_eduhust/widget/message_bubble.dart';

class ChatScreen extends StatefulWidget {
  final String otherUserId;
  final String otherUserName;

  ChatScreen({
    required this.otherUserId,
    required this.otherUserName,
  });

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ChatService _chatService = ChatService();
  bool _isSending = false;
  late String _chatRoomId;

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => LoginScreen()),
        );
      });
      return Container();
    }

    _chatRoomId =
        _chatService.getChatRoomId(currentUser.uid, widget.otherUserId);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        iconTheme: IconThemeData(color: Colors.white),
        title: Text(
          widget.otherUserName,
          style: textsimplewhitebigger,
        ),
        leadingWidth: 40,
        centerTitle: true,
        backgroundColor: mainColor,
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<Message>>(
              stream:
                  _chatService.getMessages(currentUser.uid, widget.otherUserId),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Đã xảy ra lỗi'));
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                final messages = snapshot.data ?? [];

                if (messages.isEmpty) {
                  return Center(child: Text('Chưa có tin nhắn nào'));
                }

                return ListView.builder(
                  reverse: true,
                  padding: EdgeInsets.all(8.0),
                  itemCount: messages.length,
                  itemBuilder: (ctx, index) {
                    final message = messages[index];
                    final isMe = message.senderId == currentUser.uid;
                    print(currentUser.uid);
                    print('Id người gửi: ${message.senderId}');
                    print(isMe);

                    return MessageBubble(
                      message: message,
                      isMe: isMe,
                      onDelete: isMe
                          ? () => _chatService.deleteMessage(
                              _chatRoomId, message.id)
                          : null,
                    );
                  },
                );
              },
            ),
          ),
          Container(
            padding: EdgeInsets.all(8.0),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  spreadRadius: 1,
                  blurRadius: 3,
                  offset: Offset(0, -1),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Nhập tin nhắn...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24.0),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.grey[100],
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 8.0,
                      ),
                    ),
                    textCapitalization: TextCapitalization.sentences,
                  ),
                ),
                SizedBox(width: 8.0),
                _isSending
                    ? SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2.0),
                      )
                    : IconButton(
                        icon: Icon(Icons.send,
                            color: Theme.of(context).primaryColor),
                        onPressed: () async {
                          if (_messageController.text.trim().isEmpty) return;

                          final messageText = _messageController.text.trim();
                          _messageController.clear();

                          setState(() {
                            _isSending = true;
                          });

                          try {
                            final realName =
                                await _chatService.getRealName(currentUser.uid);

                            await _chatService.sendMessage(
                              widget.otherUserId,
                              Message(
                                senderId: currentUser.uid,
                                senderName: realName,
                                text: messageText,
                                timestamp: DateTime.now(),
                                id: '',
                              ),
                            );
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Không thể gửi tin nhắn')),
                            );
                          } finally {
                            if (mounted) {
                              setState(() {
                                _isSending = false;
                              });
                            }
                          }
                        }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }
}
