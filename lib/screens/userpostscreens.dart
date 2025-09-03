import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:hpu_eduhust/providers/auth.dart';
import 'package:hpu_eduhust/screens/createpostscreen.dart';
import 'package:hpu_eduhust/screens/loginscreens.dart';
import 'package:hpu_eduhust/screens/postdetailscreen.dart';
import 'package:hpu_eduhust/utils/Colors.dart';
import 'package:hpu_eduhust/utils/textstyle.dart';
import 'package:hpu_eduhust/widget/drawerwidget.dart';
import 'package:intl/intl.dart';
import 'package:hpu_eduhust/providers/post.dart';
import 'package:hpu_eduhust/screens/editpostscreen.dart'; 

class UserPostsScreen extends StatefulWidget {
  final String authorId;
  final String currentUserId;
  final AppUser user;

  const UserPostsScreen({
    super.key,
    required this.authorId,
    required this.currentUserId,
    required this.user,
  });

  @override
  State<UserPostsScreen> createState() => _UserPostsScreenState();
}

class _UserPostsScreenState extends State<UserPostsScreen> {
  final _auth = FirebaseAuth.instance;
  final PostService _postService = PostService();
  List<Post> _posts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserPosts();
  }

  void _signOut() {
    _auth.signOut();
    _navigateToLogin();
  }

  void _navigateToLogin() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => LoginScreen()),
      (Route<dynamic> route) => false,
    );
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

  Future<void> _loadUserPosts() async {
    try {
      final posts = await _postService.getPostsByAuthorId(widget.authorId);
      setState(() {
        _posts = posts;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading posts: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deletePostWithConfirmation(String postId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: const Text('Bạn có chắc chắn muốn xóa bài viết này?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Xóa', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await _postService.deletePost(postId);
      if (success) {
        setState(() {
          _posts.removeWhere((p) => p.id == postId);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã xóa bài viết')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Xóa bài viết thất bại')),
        );
      }
    }
  }

  String _formatDate(DateTime date) {
    return DateFormat('dd-MM-yyyy').format(date);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      drawer: Mydrawer(
          onSignoutTap: _signOut, onCreateTap: _createPost, user: widget.user),
      appBar: AppBar(
        title: const Text(
          'My Post',
          style: textsimplewhitebigger,
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        backgroundColor: mainColor,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _posts.isEmpty
              ? const Center(child: Text('Không có bài viết nào.'))
              : ListView.builder(
                  itemCount: _posts.length,
                  itemBuilder: (context, index) {
                    final post = _posts[index];
                    final isOwner = post.authorId == widget.currentUserId;
                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => PostDetailScreen(
                              post: post,
                              currentUserId: widget.currentUserId,
                              userview: widget.user,
                            ),
                          ),
                        );
                      },
                      child: Card(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        child: ListTile(
                          title: Text(post.title),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                post.content,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(Icons.thumb_up,
                                      size: 16, color: Colors.green),
                                  const SizedBox(width: 4),
                                  Text('${post.likes.length}'),
                                  const SizedBox(width: 12),
                                  Icon(Icons.thumb_down,
                                      size: 16, color: Colors.red),
                                  const SizedBox(width: 4),
                                  Text('${post.dislikes.length}'),
                                  const SizedBox(width: 12),
                                  Icon(Icons.comment,
                                      size: 16, color: Colors.blueGrey),
                                  const SizedBox(width: 4),
                                  Text('${post.comments.length}'),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Ngày đăng: ${_formatDate(post.createdAt)}',
                                style: const TextStyle(
                                    fontSize: 12, color: Colors.grey),
                              ),
                            ],
                          ),
                          trailing: isOwner
                              ? PopupMenuButton<String>(
                                  onSelected: (value) async {
                                    if (value == 'edit') {
                                      final updated =
                                          await Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (_) => EditPostScreen(
                                            post: post,
                                            user: widget.user,
                                          ),
                                        ),
                                      );
                                      if (updated == true) {
                                        _loadUserPosts();
                                      }
                                    } else if (value == 'delete') {
                                      _deletePostWithConfirmation(post.id);
                                    }
                                  },
                                  itemBuilder: (_) => const [
                                    PopupMenuItem(
                                      value: 'edit',
                                      child: Text('Chỉnh sửa'),
                                    ),
                                    PopupMenuItem(
                                      value: 'delete',
                                      child: Text('Xóa'),
                                    ),
                                  ],
                                )
                              : null,
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
