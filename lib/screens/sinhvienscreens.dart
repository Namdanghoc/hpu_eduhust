import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:hpu_eduhust/providers/auth.dart';
import 'package:hpu_eduhust/providers/post.dart';
import 'package:hpu_eduhust/screens/createpostscreen.dart';
import 'package:hpu_eduhust/screens/loginscreens.dart';
import 'package:hpu_eduhust/screens/postdetailscreen.dart';
import 'package:hpu_eduhust/utils/Colors.dart';
import 'package:hpu_eduhust/utils/textstyle.dart';
import 'package:hpu_eduhust/widget/drawerwidget.dart';

class HSScreenHome extends StatefulWidget {
  final AppUser hocsinh;
  const HSScreenHome({Key? key, required this.hocsinh}) : super(key: key);

  @override
  State<HSScreenHome> createState() => _HSScreenHomeState();
}

class _HSScreenHomeState extends State<HSScreenHome> {
  final _auth = FirebaseAuth.instance;
  final PostService _postService = PostService();
  List<Post> _posts = [];
  List<Post> _filteredPosts = [];
  bool _isLoading = true;
  String _currentSpecialization = 'Chung'; // Theo dõi chuyên ngành hiện tại

  // Danh sách các chuyên ngành
  final List<Map<String, dynamic>> _specializations = [
    {'name': 'Chung', 'color': Colors.purple},
    {'name': 'CNTT', 'color': Colors.blue},
    {'name': 'Sư Phạm', 'color': Colors.green},
    {'name': 'Kinh Tế', 'color': Colors.orange},
    {'name': 'Du Lịch', 'color': Colors.red},
    {'name': 'Ngôn ngữ Trung', 'color': Colors.teal},
    {'name': 'Điện Công Nghiệp', 'color': Colors.teal},
    {'name': 'Khác', 'color': Colors.teal},
  ];

  @override
  void initState() {
    super.initState();
    _fetchPosts();
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
          giangvien: widget.hocsinh,
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
        _filterPosts();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      debugPrint('Lỗi khi lấy bài viết: $e');
    }
  }

  // Lọc bài viết dựa trên chuyên ngành đã chọn
  void _filterPosts() {
    if (_currentSpecialization == 'Chung') {
      _filteredPosts = List.from(_posts);
    } else {
      _filteredPosts = _posts
          .where((post) => post.specialization == _currentSpecialization)
          .toList();
    }
  }

  void _changeSpecialization(String specialization) {
    if (_currentSpecialization != specialization) {
      setState(() {
        _currentSpecialization = specialization;
        _filterPosts(); // Lọc lại sau khi thay đổi chuyên ngành
      });
    }
  }

  Widget _buildPostCard(Post post) {
    return GestureDetector(
      onTap: () {
        // Chuyển sang màn hình chi tiết bài viết
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PostDetailScreen(
              post: post,
              currentUserId: widget.hocsinh.id!,
              userview: widget.hocsinh,
            ),
          ),
        );
      },
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title + Specialization + Category
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      post.title,
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                  if (post.specialization.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getSpecializationColor(post.specialization),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        post.specialization,
                        style:
                            const TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              if (post.category.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: Text(
                    post.category,
                    style: const TextStyle(
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                        color: Colors.black54),
                  ),
                ),
              const SizedBox(height: 8),

              // Ảnh bài viết
              if (post.imageUrl.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    post.imageUrl,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: 200,
                    errorBuilder: (context, error, stackTrace) =>
                        const Text('Không thể tải ảnh'),
                  ),
                ),
              const SizedBox(height: 8),

              // Nội dung ngắn
              Text(
                post.content,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),

              const SizedBox(height: 8),

              // Thông tin tác giả + ngày đăng
              Row(
                children: [
                  // Ảnh đại diện
                  if (post.authorAvatarUrl != null &&
                      post.authorAvatarUrl!.isNotEmpty)
                    CircleAvatar(
                      radius: 16,
                      backgroundImage: NetworkImage(post.authorAvatarUrl!),
                      backgroundColor: Colors.grey[200],
                    ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Tác giả: ${post.author}',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ),
                  Text(
                    '${post.createdAt.day}/${post.createdAt.month}/${post.createdAt.year}',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getSpecializationColor(String specialization) {
    final spec = _specializations.firstWhere(
      (element) => element['name'] == specialization,
      orElse: () => {'name': 'Khác', 'color': Colors.grey},
    );
    return spec['color'];
  }

  Widget _buildSpecializationFilter() {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: _specializations
              .map((spec) => _buildFilterButton(
                    spec['name'],
                    spec['color'],
                  ))
              .toList(),
        ),
      ),
    );
  }

  Widget _buildFilterButton(String specialization, Color color) {
    final isSelected = _currentSpecialization == specialization;

    return Container(
      margin: const EdgeInsets.only(left: 2, right: 2),
      child: Material(
        color: isSelected ? color : Colors.grey.shade200,
        borderRadius: BorderRadius.zero,
        child: InkWell(
          onTap: () => _changeSpecialization(specialization),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            alignment: Alignment.center,
            child: Text(
              specialization,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.black87,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      drawer: Mydrawer(
          onSignoutTap: _signOut,
          onCreateTap: _createPost,
          user: widget.hocsinh),
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text('Home', style: textsimplewhitebigger),
        centerTitle: true,
        backgroundColor: mainColor,
      ),
      body: Column(
        children: [
          _buildSpecializationFilter(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredPosts.isEmpty
                    ? Center(
                        child: Text(
                          _currentSpecialization == 'Chung'
                              ? 'Chưa có bài viết nào'
                              : 'Chưa có bài viết nào cho ngành $_currentSpecialization',
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _fetchPosts,
                        child: ListView.builder(
                          itemCount: _filteredPosts.length,
                          itemBuilder: (context, index) =>
                              _buildPostCard(_filteredPosts[index]),
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}
