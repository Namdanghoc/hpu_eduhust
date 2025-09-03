import 'package:flutter/material.dart';
import 'package:hpu_eduhust/providers/auth.dart';
import 'package:hpu_eduhust/providers/post.dart';
import 'package:hpu_eduhust/screens/authordetailscreen.dart';
import 'package:hpu_eduhust/utils/Colors.dart';
//import 'package:hpu_eduhust/providers/post.dart'; // Import service để gọi API
import 'package:intl/intl.dart'; // Thêm package để format ngày tháng

class PostDetailScreen extends StatefulWidget {
  final Post post;
  final String currentUserId; // Thêm ID người dùng hiện tại
  final AppUser userview;

  const PostDetailScreen({
    super.key,
    required this.post,
    required this.currentUserId,
    required this.userview,
  });

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  late Post _post;
  final TextEditingController _commentController = TextEditingController();
  final PostService _postService = PostService();
  bool _isCommentsVisible = false;
  bool _isSubmittingComment = false;

  @override
  void initState() {
    super.initState();
    _post = widget.post;
  }

  void navigateToAuthorDetails(String authorId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AuthorDetailsScreen(
          authorId: authorId,
          currentUserId: widget.currentUserId,
          userview: widget.userview,
        ),
      ),
    );
    print('Clicked on author: ${_post.author}');
  }

  // Xử lý khi người dùng like bài viết
  Future<void> _handleLike() async {
    try {
      final updatedPost =
          await _postService.likePost(_post.id, widget.currentUserId);
      setState(() {
        _post = updatedPost;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không thể like bài viết: $e')),
      );
    }
  }

  // Xử lý khi người dùng dislike bài viết
  Future<void> _handleDislike() async {
    try {
      final updatedPost =
          await _postService.dislikePost(_post.id, widget.currentUserId);
      setState(() {
        _post = updatedPost;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không thể dislike bài viết: $e')),
      );
    }
  }

  // Xử lý khi người dùng gửi comment
  Future<void> _submitComment() async {
    if (_commentController.text.trim().isEmpty) return;

    setState(() {
      _isSubmittingComment = true;
    });

    try {
      final updatedPost = await _postService.addComment(
        widget.post.id,
        widget.currentUserId,
        widget.userview.realname ?? "",
        widget.userview.avatarUrl ?? "",
        _commentController.text.trim(),
      );

      setState(() {
        _post = updatedPost;
        _commentController.clear();
        _isSubmittingComment = false;
      });
    } catch (e) {
      setState(() {
        _isSubmittingComment = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không thể gửi bình luận: $e')),
      );
    }
  }

  // Widget hiển thị danh sách comments
  Widget _buildCommentsSection() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      height: _isCommentsVisible ? null : 0,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_isCommentsVisible) ...[
            const Divider(thickness: 1),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'Bình luận',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            if (_post.comments.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Center(
                  child: Text(
                    'Chưa có bình luận nào.',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              ),
            ..._post.comments.map((comment) => _buildCommentItem(comment)),
            const SizedBox(height: 16),
            _buildCommentInput(),
          ],
        ],
      ),
    );
  }

  // Widget hiển thị từng comment
  Widget _buildCommentItem(Comment comment) {
    final formattedDate =
        DateFormat('dd/MM/yyyy HH:mm').format(comment.createdAt);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: Colors.indigo.shade100,
            backgroundImage: NetworkImage(comment.userAvatarUrl),
            child: comment.userAvatarUrl.isEmpty
                ? const Icon(Icons.person, color: Colors.indigo)
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      comment.userName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      formattedDate,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(comment.content),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Widget input để thêm comment mới
  Widget _buildCommentInput() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _commentController,
            decoration: InputDecoration(
              hintText: 'Viết bình luận...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(24),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            maxLines: null,
          ),
        ),
        const SizedBox(width: 8),
        ElevatedButton(
          onPressed: _isSubmittingComment ? null : _submitComment,
          style: ElevatedButton.styleFrom(
            backgroundColor: mainColor,
            shape: const CircleBorder(),
            padding: const EdgeInsets.all(12),
          ),
          child: _isSubmittingComment
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.send, color: Colors.white),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool hasLiked = _post.isLikedByUser(widget.currentUserId);
    final bool hasDisliked = _post.isDislikedByUser(widget.currentUserId);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        centerTitle: true,
        title: const Text(
          'Chi tiết bài viết',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: mainColor,
        foregroundColor: Colors.white,
        elevation: 1,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Text(
                _post.title,
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: Colors.indigo,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                const Icon(Icons.bookmark, color: mainColor),
                const SizedBox(width: 4),
                Text(
                  _post.specialization,
                  style: const TextStyle(
                      color: mainColor, fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 12),
                const Icon(Icons.folder, color: mainColor),
                const SizedBox(width: 4),
                Text(
                  _post.category,
                  style: const TextStyle(
                      color: mainColor, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 20),
            if (_post.imageUrl.isNotEmpty)
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.3),
                      spreadRadius: 2,
                      blurRadius: 5,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    _post.imageUrl,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      width: double.infinity,
                      height: 200,
                      color: Colors.grey.shade300,
                      child: const Center(
                        child: Icon(Icons.error_outline, size: 40),
                      ),
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 16),
            Text(
              _post.content,
              style: const TextStyle(fontSize: 16, height: 1.5),
            ),
            const SizedBox(height: 24),

            // Phần tương tác: Like, Dislike, Comments
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Like button
                  InkWell(
                    onTap: _handleLike,
                    borderRadius: BorderRadius.circular(24),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        children: [
                          Icon(
                            hasLiked ? Icons.thumb_up : Icons.thumb_up_outlined,
                            color: hasLiked ? mainColor : Colors.grey,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "${_post.likeCount}",
                            style: TextStyle(
                              color: hasLiked ? mainColor : Colors.grey,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Dislike button
                  InkWell(
                    onTap: _handleDislike,
                    borderRadius: BorderRadius.circular(24),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        children: [
                          Icon(
                            hasDisliked
                                ? Icons.thumb_down
                                : Icons.thumb_down_outlined,
                            color: hasDisliked ? Colors.red : Colors.grey,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "${_post.dislikeCount}",
                            style: TextStyle(
                              color: hasDisliked ? Colors.red : Colors.grey,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Comments button
                  InkWell(
                    onTap: () {
                      setState(() {
                        _isCommentsVisible = !_isCommentsVisible;
                      });
                    },
                    borderRadius: BorderRadius.circular(24),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        children: [
                          Icon(
                            _isCommentsVisible
                                ? Icons.comment
                                : Icons.comment_outlined,
                            color: _isCommentsVisible ? mainColor : Colors.grey,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "${_post.commentCount}",
                            style: TextStyle(
                              color:
                                  _isCommentsVisible ? mainColor : Colors.grey,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Phần comments (ẩn/hiện)
            _buildCommentsSection(),

            const SizedBox(height: 24),
            if (widget.currentUserId != widget.post.authorId)
              InkWell(
                onTap: () => navigateToAuthorDetails(widget.post.authorId),
                borderRadius: BorderRadius.circular(24),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: Colors.indigo.shade100,
                        backgroundImage: (_post.authorAvatarUrl != null)
                            ? NetworkImage(_post.authorAvatarUrl!)
                            : null,
                        child: (_post.authorAvatarUrl == null)
                            ? const Icon(Icons.person, color: Colors.indigo)
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Tác giả',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              _post.author,
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios,
                          size: 16, color: Colors.grey),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }
}
