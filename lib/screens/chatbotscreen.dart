import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:hpu_eduhust/providers/auth.dart';
import 'package:hpu_eduhust/providers/post.dart';
import 'package:hpu_eduhust/screens/createpostscreen.dart';
import 'package:hpu_eduhust/screens/loginscreens.dart';
import 'package:hpu_eduhust/utils/Colors.dart';
import 'package:hpu_eduhust/utils/textstyle.dart';
import 'package:hpu_eduhust/widget/drawerwidget.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class Message {
  final String text;
  final bool isUser;
  final DateTime time;

  Message({required this.text, required this.isUser, required this.time});
}

class ChatBotScreen extends StatefulWidget {
  final AppUser user;

  const ChatBotScreen({Key? key, required this.user}) : super(key: key);
  @override
  _ChatBotScreenState createState() => _ChatBotScreenState();
}

class _ChatBotScreenState extends State<ChatBotScreen> {
  TextEditingController _controller = TextEditingController();
  final List<Message> _messages = [];
  final _auth = FirebaseAuth.instance;
  final PostService _postService = PostService();
  List<Post> _posts = [];
  bool _isLoadingb = true;
  bool _isLoading = false;
  final ScrollController _scrollController = ScrollController();

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

    if (result == true) {
      _fetchPosts();
    }
  }

  Future<void> _fetchPosts() async {
    setState(() {
      _isLoadingb = true;
    });
    try {
      final posts = await _postService.getPosts();
      setState(() {
        _posts = posts;

        _isLoadingb = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingb = false;
      });
      debugPrint('Lỗi khi lấy bài viết: $e');
    }
  }

  Future<void> _sendMessage() async {
    if (_controller.text.trim().isEmpty) return;

    // Thêm tin nhắn người dùng vào danh sách
    final userMessage = Message(
      text: _controller.text,
      isUser: true,
      time: DateTime.now(),
    );

    setState(() {
      _messages.add(userMessage);
      _isLoading = true;
    });

    _controller.clear();

    // Cuộn xuống tin nhắn mới nhất
    _scrollToBottom();

    try {
      // IP máy ảo final 
      String apiUrl = 'http://10.0.2.2:3000/chat';
      // final String apiUrl = 'http://192.168.1.7:3000/chat';
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'message': userMessage.text}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // Thêm tin nhắn phản hồi từ chatbot
        final botMessage = Message(
          text: data['response'],
          isUser: false,
          time: DateTime.now(),
        );

        setState(() {
          _messages.add(botMessage);
          _isLoading = false;
        });
      } else {
        // Xử lý lỗi
        final errorMessage = Message(
          text: "Không thể kết nối với server. Vui lòng thử lại sau.",
          isUser: false,
          time: DateTime.now(),
        );

        setState(() {
          _messages.add(errorMessage);
          _isLoading = false;
        });
      }
    } catch (e) {
      final errorMessage = Message(
        text: "Đã xảy ra lỗi: $e",
        isUser: false,
        time: DateTime.now(),
      );

      setState(() {
        _messages.add(errorMessage);
        _isLoading = false;
      });
    }

    // Cuộn xuống tin nhắn mới nhất
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      drawer: Mydrawer(
          onSignoutTap: _signOut, onCreateTap: _createPost, user: widget.user),
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text("ChatBot Assistant", style: textsimplewhitebigger),
        centerTitle: true,
        backgroundColor: mainColor,
        elevation: 2,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                _messages.clear();
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Khu vực tin nhắn
          Expanded(
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 10, vertical: 15),
              decoration: BoxDecoration(
                color: Colors.grey[100],
              ),
              child: _messages.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.chat_bubble_outline,
                            size: 80,
                            color: Colors.grey[400],
                          ),
                          SizedBox(height: 20),
                          Text(
                            "Hãy bắt đầu cuộc trò chuyện",
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      controller: _scrollController,
                      itemCount: _messages.length,
                      itemBuilder: (context, index) {
                        final message = _messages[index];
                        return _buildMessageItem(message);
                      },
                    ),
            ),
          ),

          // Indicator khi đang chờ phản hồi
          if (_isLoading)
            Container(
              padding: EdgeInsets.symmetric(vertical: 8),
              color: Colors.white,
              child: Row(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 16),
                    child: Text(
                      "Đang nhập...",
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                  SizedBox(width: 10),
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.teal),
                    ),
                  ),
                ],
              ),
            ),

          // Khu vực nhập tin nhắn
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  offset: Offset(0, -2),
                  blurRadius: 2,
                  color: Colors.black12,
                )
              ],
            ),
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: 'Nhập tin nhắn...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.grey[200],
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                    ),
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                SizedBox(width: 8),
                Material(
                  color: Colors.teal,
                  borderRadius: BorderRadius.circular(30),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(30),
                    onTap: _sendMessage,
                    child: Container(
                      padding: EdgeInsets.all(10),
                      child: Icon(
                        Icons.send,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageItem(Message message) {
    final alignment =
        message.isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start;

    final bubbleColor = message.isUser ? Colors.teal : Colors.white;

    final textColor = message.isUser ? Colors.white : Colors.black87;

    final bubbleBorder = message.isUser
        ? BorderRadius.only(
            topLeft: Radius.circular(12),
            topRight: Radius.circular(12),
            bottomLeft: Radius.circular(12),
          )
        : BorderRadius.only(
            topLeft: Radius.circular(12),
            topRight: Radius.circular(12),
            bottomRight: Radius.circular(12),
          );

    final avatarWidget = message.isUser
        ? null
        : CircleAvatar(
            backgroundColor: Colors.teal[200],
            child: Icon(
              Icons.android,
              size: 18,
              color: Colors.white,
            ),
            radius: 16,
          );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: alignment,
        children: [
          Row(
            mainAxisAlignment: message.isUser
                ? MainAxisAlignment.end
                : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!message.isUser) avatarWidget ?? SizedBox(),
              SizedBox(width: message.isUser ? 0 : 8),
              Flexible(
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  margin: EdgeInsets.only(
                    left: message.isUser ? 50 : 0,
                    right: message.isUser ? 0 : 50,
                  ),
                  decoration: BoxDecoration(
                    color: bubbleColor,
                    borderRadius: bubbleBorder,
                    boxShadow: [
                      BoxShadow(
                        blurRadius: 2,
                        offset: Offset(0, 1),
                        color: Colors.black.withOpacity(0.1),
                      )
                    ],
                  ),
                  child: Text(
                    message.text,
                    style: TextStyle(
                      color: textColor,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
              SizedBox(width: message.isUser ? 8 : 0),
              if (message.isUser)
                CircleAvatar(
                  backgroundColor: Colors.blue[100],
                  child: Icon(
                    Icons.person,
                    size: 18,
                    color: Colors.blue[800],
                  ),
                  radius: 16,
                ),
            ],
          ),
          Padding(
            padding: EdgeInsets.only(
              top: 4,
              right: message.isUser ? 40 : 0,
              left: message.isUser ? 0 : 40,
            ),
            child: Text(
              _formatTime(message.time),
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    return "${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}";
  }
}
