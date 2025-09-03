import 'dart:convert';
import 'package:http/http.dart' as http;

class Post {
  final String id;
  final String title;
  final String content;
  final String imageUrl;
  final String author;
  final String authorId;
  final String? authorAvatarUrl;
  final DateTime createdAt;
  final String category;
  final String specialization;
  final List<String> likes;
  final List<String> dislikes;
  final List<Comment> comments;

  // Thêm getter để lấy số lượng likes và dislikes
  int get likeCount => likes.length;
  int get dislikeCount => dislikes.length;
  int get commentCount => comments.length;

  Post({
    required this.id,
    required this.title,
    required this.content,
    required this.imageUrl,
    required this.author,
    required this.authorId,
    this.authorAvatarUrl,
    required this.createdAt,
    required this.category,
    required this.specialization,
    required this.likes,
    required this.dislikes,
    required this.comments,
  });

  factory Post.fromJson(Map<String, dynamic> json) {
    return Post(
      id: json['_id'],
      title: json['title'] ?? '',
      content: json['content'] ?? '',
      imageUrl: json['imageUrl'] ?? '',
      author: json['author'] ?? '',
      authorId: json['authorId'] ?? '',
      authorAvatarUrl: json['authorAvatarUrl'],
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      category: json['category'] ?? '',
      specialization: json['specialization'] ?? '',
      likes: List<String>.from(json['likes'] ?? []),
      dislikes: List<String>.from(json['dislikes'] ?? []),
      comments: (json['comments'] as List? ?? [])
          .map((e) => Comment.fromJson(e))
          .toList(),
    );
  }

  // Kiểm tra xem người dùng hiện tại đã like/dislike bài viết chưa
  bool isLikedByUser(String userId) => likes.contains(userId);
  bool isDislikedByUser(String userId) => dislikes.contains(userId);
}

class Comment {
  final String userId;
  final String userName;
  final String userAvatarUrl;
  final String content;
  final DateTime createdAt;

  Comment({
    required this.userId,
    required this.userName,
    required this.userAvatarUrl,
    required this.content,
    required this.createdAt,
  });

  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      userId: json['userId'] ?? '',
      userName: json['userName'] ?? '',
      userAvatarUrl: json['userAvatarUrl'] ?? '',
      content: json['content'] ?? '',
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
    );
  }
}

class PostService {
  static const String baseUrl = 'http://10.0.2.2:3000'; // Địa chỉ API ảo của bạn
//static const String baseUrl = 'http://192.168.1.7:3000';
  // Hàm lấy danh sách bài viết với đầy đủ thông tin likes, dislikes, comments
  Future<List<Post>> getPosts({
    String? category,
    String? specialization,
    String? authorId,
    bool sortByNewest = true,
  }) async {
    // Xây dựng query parameters
    final Map<String, String> queryParams = {};

    if (category != null && category.isNotEmpty) {
      queryParams['category'] = category;
    }

    if (specialization != null && specialization.isNotEmpty) {
      queryParams['specialization'] = specialization;
    }

    if (authorId != null && authorId.isNotEmpty) {
      queryParams['authorId'] = authorId;
    }

    // Thêm tham số sắp xếp nếu cần
    if (sortByNewest) {
      queryParams['sort'] = 'createdAt:desc';
    }

    final uri =
        Uri.parse('$baseUrl/posts').replace(queryParameters: queryParams);

    try {
      final response = await http.get(uri);
      print('Request URL: ${uri.toString()}');
      print('Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List postsJson = data['data'];
        final posts = postsJson.map((e) => Post.fromJson(e)).toList();

        // Kiểm tra và log thông tin
        print('Loaded ${posts.length} posts');
        for (var post in posts) {
          print('Post ID: ${post.id}');
          print('  Title: ${post.title}');
          print('  Likes: ${post.likeCount}');
          print('  Dislikes: ${post.dislikeCount}');
          print('  Comments: ${post.commentCount}');
        }

        return posts;
      } else {
        throw Exception(
            'Không thể tải danh sách bài viết: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching posts: $e');
      throw Exception('Không thể tải danh sách bài viết: $e');
    }
  }

  // Lấy bài viết theo danh mục
  Future<List<Post>> getPostsByCategory(String category) async {
    return getPosts(category: category);
  }

  // Lấy bài viết theo chuyên ngành
  Future<List<Post>> getPostsBySpecialization(String specialization) async {
    return getPosts(specialization: specialization);
  }

  // Lấy bài viết theo ID của tác giả
  Future<List<Post>> getPostsByAuthorId(String authorId) async {
    return getPosts(authorId: authorId);
  }

  // Lấy chi tiết một bài viết
  Future<Post> getPostById(String postId) async {
    final uri = Uri.parse('$baseUrl/posts/$postId');

    try {
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return Post.fromJson(data['post']);
      } else {
        throw Exception(
            'Không thể tải chi tiết bài viết: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching post detail: $e');
      throw Exception('Không thể tải chi tiết bài viết: $e');
    }
  }

  // Like một bài viết
  Future<Post> likePost(String postId, String userId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/posts/$postId/like'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'userId': userId}),
      );
      print('$baseUrl/posts/$postId/like');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return Post.fromJson(data['post']);
      } else {
        throw Exception('Không thể like bài viết: ${response.statusCode}');
      }
    } catch (e) {
      print('Error liking post: $e');
      throw Exception('Không thể like bài viết: $e');
    }
  }

  // Dislike một bài viết
  Future<Post> dislikePost(String postId, String userId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/posts/$postId/dislike'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'userId': userId}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return Post.fromJson(data['post']);
      } else {
        throw Exception('Không thể dislike bài viết: ${response.statusCode}');
      }
    } catch (e) {
      print('Error disliking post: $e');
      throw Exception('Không thể dislike bài viết: $e');
    }
  }

  // Thêm comment cho một bài viết
  Future<Post> addComment(
    String postId,
    String userId,
    String userName,
    String userAvatarUrl,
    String content,
  ) async {
    final Map<String, dynamic> data = {
      'postId': postId,
      'userId': userId,
      'userName': userName,
      'userAvatarUrl': userAvatarUrl,
      'content': content,
    };
    print(data);

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/posts/$postId/comment'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(data),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return Post.fromJson(responseData['post']);
      } else {
        throw Exception('Không thể thêm bình luận: ${response.statusCode}');
      }
    } catch (e) {
      print('Error adding comment: $e');
      throw Exception('Không thể thêm bình luận: $e');
    }
  }

  Future<bool> createPost({
    required String title,
    required String content,
    String? imageUrl,
    required String author,
    required String authorId,
    String? authorAvatarUrl,
    String category = '',
    String specialization = '',
  }) async {
    final Map<String, dynamic> data = {
      'title': title,
      'content': content,
      'imageUrl': imageUrl ?? '',
      'author': author,
      'authorId': authorId,
      'authorAvatarUrl': authorAvatarUrl,
      'category': category,
      'specialization': specialization,
    };
    print('Creating post with data: $data');

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/posts'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(data),
      );

      print('Create post response: ${response.statusCode}');
      return response.statusCode == 201;
    } catch (e) {
      print('Error creating post: $e');
      return false;
    }
  }

  Future<bool> updatePost(
  String id, {
  required String title,
  required String content,
  required String authorId, // Thêm authorId để xác thực người chỉnh sửa
  String? imageUrl,
  String? category,
  String? specialization,
  String? authorAvatarUrl,
}) async {
  final Map<String, dynamic> data = {
    'title': title,
    'content': content,
    'authorId': authorId, // gửi để server xác minh quyền sửa
    'imageUrl': imageUrl ?? '',
  };

  if (category != null) data['category'] = category;
  if (specialization != null) data['specialization'] = specialization;
  if (authorAvatarUrl != null && authorAvatarUrl.isNotEmpty) {
    data['authorAvatarUrl'] = authorAvatarUrl;
  }

  try {
    final response = await http.put(
      Uri.parse('$baseUrl/posts/$id'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(data),
    );

    if (response.statusCode == 200) {
      return true;
    } else {
      print('Update failed: ${response.body}');
      return false;
    }
  } catch (e) {
    print('Error updating post: $e');
    return false;
  }
}


  // Xóa bài viết
  Future<bool> deletePost(String id) async {
    try {
      final response = await http.delete(Uri.parse('$baseUrl/posts/$id'));
      return response.statusCode == 200;
    } catch (e) {
      print('Error deleting post: $e');
      return false;
    }
  }
}
