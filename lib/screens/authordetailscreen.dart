import 'package:flutter/material.dart';
import 'package:hpu_eduhust/components/text_box.dart';
import 'package:hpu_eduhust/providers/auth.dart';
import 'package:hpu_eduhust/providers/post.dart';
import 'package:hpu_eduhust/screens/postdetailscreen.dart';
import 'package:hpu_eduhust/utils/Colors.dart';
import 'package:hpu_eduhust/utils/textstyle.dart';
import 'package:intl/intl.dart';
import 'package:ionicons/ionicons.dart';

class AuthorDetailsScreen extends StatefulWidget {
  final String authorId;
  final String currentUserId; 
  final AppUser userview;

  const AuthorDetailsScreen(
      {super.key,
      required this.authorId,
      required this.currentUserId,
      required this.userview});

  @override
  State<AuthorDetailsScreen> createState() => _AuthorDetailsScreenState();
}

class _AuthorDetailsScreenState extends State<AuthorDetailsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  AppUser? author;
  final _authService = UserService();
  final _postService = PostService();

  List<Post> posts = []; 
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchAuthorData();
    _fetchAuthorPosts();
  }

  // Hàm này gọi loadInfo từ UserService để lấy dữ liệu của tác giả
  Future<void> _fetchAuthorData() async {
    try {
      AppUser? fetchedAuthor = await _authService.loadUserInfo(widget.authorId);

      if (fetchedAuthor != null) {
        setState(() {
          author = fetchedAuthor; 
        });
      } else {
        print('Author not found');
      }
    } catch (e) {
      print('Error fetching author data: $e');
    }
  }

  // Hàm lấy các bài viết của tác giả dựa trên authorId
  Future<void> _fetchAuthorPosts() async {
    try {
  
      List<Post> fetchedPosts =
          await _postService.getPostsByAuthorId(widget.authorId);

      setState(() {
        posts = fetchedPosts; 
        isLoading = false; 
      });
    } catch (e) {
      print('Error fetching posts: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  String formatDate(DateTime date) {
    return DateFormat('dd-MM-yyyy').format(date);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          'Author Details',
          style: textsimplewhitebigger,
        ),
        centerTitle: true,
        backgroundColor: mainColor,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white, // Màu chữ và icon khi tab được chọn
          unselectedLabelColor: Colors.white70, // Màu khi chưa chọn
          indicatorColor: Colors.white, // Màu gạch dưới
          tabs: const [
            Tab(
              icon: Icon(Icons.info, size: 24),
              child: Text(
                'Info',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            Tab(
              icon: Icon(Icons.article, size: 24),
              child: Text(
                'Posts',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
      body: isLoading
          ? Center(
              child:
                  CircularProgressIndicator()) // Hiển thị loading nếu chưa có dữ liệu
          : TabBarView(
              controller: _tabController,
              children: [
                // Tab 1: Info
                author == null
                    ? const Center(child: CircularProgressIndicator())
                    : Builder(
                        builder: (context) {
                          final currentAuthor =
                              author!; // đảm bảo không null tại đây
                          return SingleChildScrollView(
                            child: Container(
                              color: backgroundColor,
                              child: Column(
                                children: [
                                  const SizedBox(height: 50),
                                  Center(
                                    child: currentAuthor.avatarUrl != null
                                        ? CircleAvatar(
                                            radius: 80,
                                            backgroundImage: NetworkImage(
                                                currentAuthor.avatarUrl!),
                                            backgroundColor: Colors.grey[300],
                                          )
                                        : const Icon(
                                            Icons.person,
                                            color: Colors.white,
                                            size: 72,
                                          ),
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    currentAuthor.email ?? '',
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      color: mainColor,
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  const Padding(
                                    padding: EdgeInsets.only(left: 25),
                                    child: Text(
                                      'My detail',
                                      style: TextStyle(
                                          color: mainColor, fontSize: 16),
                                    ),
                                  ),
                                  MyTextBox2(
                                    text: currentAuthor.realname ?? 'Unknown',
                                    sectionName: 'Real name',
                                    icon: Ionicons.person_circle_outline,
                                  ),
                                  MyTextBox2(
                                    text: currentAuthor.gender ?? 'Unknown',
                                    sectionName: 'Gender',
                                    icon: Ionicons.male_female_outline,
                                  ),
                                  MyTextBox2(
                                    text: currentAuthor.dateOfBirth != null
                                        ? formatDate(currentAuthor.dateOfBirth!)
                                        : 'Unknown',
                                    sectionName: 'Date of Birth',
                                    icon: Icons.cake,
                                  ),
                                  MyTextBox2(
                                    text:
                                        currentAuthor.phoneNumber ?? 'Unknown',
                                    sectionName: 'Phone Number',
                                    icon: Ionicons.call,
                                  ),
                                  MyTextBox2(
                                    text: currentAuthor.role ?? 'Unknown',
                                    sectionName: 'Role',
                                    icon: Ionicons.accessibility,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),

                // Tab 2: Hiển thị danh sách bài viết của tác giả
                SingleChildScrollView(
                  child: Column(
                    children: [
                    
                      if (posts.isNotEmpty)
                        ...posts.map((post) => GestureDetector(
                              onTap: () {
                          
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => PostDetailScreen(
                                      post: post,
                                      currentUserId: widget.currentUserId,
                                      userview: widget.userview,
                                    ),
                                  ),
                                );
                              },
                              child: Card(
                                margin: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 8),
                                elevation: 2,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                                child: Padding(
                                  padding: const EdgeInsets.all(12.0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // Title + Specialization + Category
                                      Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              post.title,
                                              style: const TextStyle(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.bold),
                                            ),
                                          ),
                                          if (post.specialization.isNotEmpty)
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 4),
                                              decoration: BoxDecoration(
                                                color: _getSpecializationColor(
                                                    post.specialization),
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                              child: Text(
                                                post.specialization,
                                                style: const TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 12),
                                              ),
                                            ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      if (post.category.isNotEmpty)
                                        Padding(
                                          padding:
                                              const EdgeInsets.only(top: 4.0),
                                          child: Text(
                                            post.category,
                                            style: const TextStyle(
                                                fontSize: 12,
                                                fontStyle: FontStyle.italic,
                                                color: Colors.black54),
                                          ),
                                        ),
                                      const SizedBox(height: 8),
                                      if (post.imageUrl.isNotEmpty)
                                        ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          child: Image.network(
                                            post.imageUrl,
                                            fit: BoxFit.cover,
                                            width: double.infinity,
                                            height: 200,
                                            errorBuilder: (context, error,
                                                    stackTrace) =>
                                                const Text('Không thể tải ảnh'),
                                          ),
                                        ),
                                      const SizedBox(height: 8),
                                      Text(
                                        post.content,
                                        maxLines: 3,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          // Ảnh đại diện
                                          if (post.authorAvatarUrl != null &&
                                              post.authorAvatarUrl!.isNotEmpty)
                                            CircleAvatar(
                                              radius: 16,
                                              backgroundImage: NetworkImage(
                                                  post.authorAvatarUrl!),
                                              backgroundColor: Colors.grey[200],
                                            ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              'Tác giả: ${post.author}',
                                              style: const TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey),
                                            ),
                                          ),
                                          Text(
                                            '${post.createdAt.day}/${post.createdAt.month}/${post.createdAt.year}',
                                            style: const TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ))
                      else
                        Text(
                            'No posts available'), // Hiển thị khi không có bài viết
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Color _getSpecializationColor(String specialization) {
   
    if (specialization == 'Math') {
      return Colors.blue;
    } else if (specialization == 'Science') {
      return Colors.green;
    }
    return Colors.grey;
  }
}
