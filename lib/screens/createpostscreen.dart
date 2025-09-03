import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:hpu_eduhust/providers/cloudinary.dart';
import 'package:image_picker/image_picker.dart';
import 'package:hpu_eduhust/providers/post.dart';
import 'package:hpu_eduhust/providers/auth.dart';
import 'package:hpu_eduhust/screens/loginscreens.dart';
import 'package:hpu_eduhust/utils/Colors.dart';
import 'package:hpu_eduhust/utils/textstyle.dart';
import 'package:hpu_eduhust/widget/drawerwidget.dart';

class GVCreatePostScreen extends StatefulWidget {
  final AppUser giangvien;

  const GVCreatePostScreen({Key? key, required this.giangvien})
      : super(key: key);

  @override
  State<GVCreatePostScreen> createState() => _GVCreatePostScreenState();
}

class _GVCreatePostScreenState extends State<GVCreatePostScreen> {
  final _auth = FirebaseAuth.instance;
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();

  final List<String> _categoryOptions = [
    'Thông báo',
    'Tin tức',
    'Sự kiện',
    'Tài liệu',
    'Công tác Sinh viên',
    'Tài Chính Kế Toán',
    'Nghiên Cứu Khoa Học',
    'Khác'
  ];
  final List<String> _specializationOptions = [
    'Chung',
    'CNTT',
    'Sư Phạm',
    'Kinh Tế',
    'Du Lịch',
    'Ngôn ngữ Trung',
    'Điện Công Nghiệp',
    'Khác'
  ];

  String? _selectedCategory;
  String? _selectedSpecialization;
  File? _imageFile;
  bool _isUploading = false;
  bool _isSubmitting = false;

  final PostService _postService = PostService();
  final CloudinaryService _cloudinaryService = CloudinaryService();
  final ImagePicker _imagePicker = ImagePicker();

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

  Future<void> _pickImage(ImageSource source) async {
    try {
      final pickedFile = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          _imageFile = File(pickedFile.path);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi khi chọn ảnh: $e')),
      );
    }
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Chọn từ thư viện'),
                onTap: () {
                  Navigator.of(context).pop();
                  _pickImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Chụp ảnh mới'),
                onTap: () {
                  Navigator.of(context).pop();
                  _pickImage(ImageSource.camera);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<String?> _uploadImageToCloudinary() async {
    if (_imageFile == null) return null;

    setState(() {
      _isUploading = true;
    });

    try {
      final imageUrl = await _cloudinaryService.uploadImage(_imageFile!);
      return imageUrl;
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi khi tải ảnh lên: $e')),
      );
      return null;
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  Future<void> _submitPost() async {
    if (!_formKey.currentState!.validate()) return;

    // Kiểm tra xem danh mục và chuyên ngành đã được chọn chưa
    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn danh mục')),
      );
      return;
    }

    if (_selectedSpecialization == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn chuyên ngành')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      // Upload ảnh nếu có
      String? imageUrl;
      if (_imageFile != null) {
        imageUrl = await _uploadImageToCloudinary();
        if (imageUrl == null) {
          setState(() => _isSubmitting = false);
          return; // Nếu upload ảnh thất bại thì không tiếp tục
        }
      }

      await _postService.createPost(
        title: _titleController.text.trim(),
        content: _contentController.text.trim(),
        imageUrl: imageUrl ?? "", // Sử dụng URL ảnh đã upload hoặc rỗng
        author: widget.giangvien.realname ?? "",
        authorAvatarUrl: widget.giangvien.avatarUrl ?? "",
        authorId: widget.giangvien.id ?? "",
        category: _selectedCategory!,
        specialization: _selectedSpecialization!,
      );

      if (mounted) {
        Navigator.of(context)
            .pop(true); // Quay lại và refresh danh sách bài viết
      }
    } catch (e) {
      print('Lỗi khi tạo bài viết: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi khi tạo bài viết: $e')),
      );
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      drawer: Mydrawer(
          onSignoutTap: _signOut, onCreateTap: () {}, user: widget.giangvien),
      appBar: AppBar(
        title: const Text(
          'Create Post',
          style: textsimplewhitebigger,
        ),
        centerTitle: true,
        backgroundColor: mainColor,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Tiêu đề'),
                validator: (value) =>
                    value!.isEmpty ? 'Vui lòng nhập tiêu đề' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _contentController,
                decoration: const InputDecoration(labelText: 'Nội dung'),
                maxLines: 5,
                validator: (value) =>
                    value!.isEmpty ? 'Vui lòng nhập nội dung' : null,
              ),
              const SizedBox(height: 16),
              const Text(
                'Danh mục:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _categoryOptions.map((category) {
                  bool isSelected = _selectedCategory == category;
                  return ChoiceChip(
                    label: Text(category),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        _selectedCategory = selected ? category : null;
                      });
                    },
                    selectedColor:
                        Theme.of(context).primaryColor.withOpacity(0.7),
                    backgroundColor: Colors.grey.withOpacity(0.2),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              const Text(
                'Chuyên ngành:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _specializationOptions.map((specialization) {
                  bool isSelected = _selectedSpecialization == specialization;
                  return ChoiceChip(
                    label: Text(specialization),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        _selectedSpecialization =
                            selected ? specialization : null;
                      });
                    },
                    selectedColor:
                        Theme.of(context).primaryColor.withOpacity(0.7),
                    backgroundColor: Colors.grey.withOpacity(0.2),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),

              // Image picker card
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Hình ảnh bài viết:',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      if (_imageFile != null) ...[
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.file(
                            _imageFile!,
                            width: double.infinity,
                            height: 200,
                            fit: BoxFit.cover,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            OutlinedButton.icon(
                              icon: const Icon(Icons.refresh),
                              label: const Text('Đổi ảnh'),
                              onPressed: _showImageSourceDialog,
                            ),
                            OutlinedButton.icon(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              label: const Text(
                                'Xóa ảnh',
                                style: TextStyle(color: Colors.red),
                              ),
                              onPressed: () {
                                setState(() {
                                  _imageFile = null;
                                });
                              },
                            ),
                          ],
                        ),
                      ] else ...[
                        InkWell(
                          onTap: _showImageSourceDialog,
                          child: Container(
                            width: double.infinity,
                            height: 120,
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey),
                            ),
                            child: const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.add_photo_alternate, size: 40),
                                SizedBox(height: 8),
                                Text('Nhấn để thêm ảnh'),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: (_isSubmitting || _isUploading) ? null : _submitPost,
                child: (_isSubmitting || _isUploading)
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(_isUploading
                              ? 'Đang tải ảnh lên...'
                              : 'Đang đăng bài...'),
                        ],
                      )
                    : const Text('Đăng bài'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(12),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
