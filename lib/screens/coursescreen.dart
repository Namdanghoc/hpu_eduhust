import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:hpu_eduhust/providers/auth.dart';
import 'package:hpu_eduhust/providers/course.dart';
import 'package:hpu_eduhust/providers/post.dart';
import 'package:hpu_eduhust/screens/createcoursescreens.dart';
import 'package:hpu_eduhust/screens/createpostscreen.dart';
import 'package:hpu_eduhust/screens/editcoursescreen.dart';
import 'package:hpu_eduhust/screens/liststudentscreen.dart';
import 'package:hpu_eduhust/screens/loginscreens.dart';
import 'package:hpu_eduhust/utils/Colors.dart';
import 'package:hpu_eduhust/utils/textstyle.dart';
import 'package:hpu_eduhust/widget/drawerwidget.dart';

class CourseScreen extends StatefulWidget {
  final AppUser user;
  const CourseScreen({super.key, required this.user});
  @override
  State<CourseScreen> createState() => _CourseScreenState();
}

class _CourseScreenState extends State<CourseScreen> {
  final _auth = FirebaseAuth.instance;
  final HocPhanService _hocPhanService = HocPhanService();
  final PostService _postService = PostService();
  List<Post> _posts = [];
  List<HocPhan> _courses = [];
  String _currentSpecialization = 'Chung';
  bool _isLoading = true;
  bool _showSearchForm = false;
  TextEditingController _tenHocPhanController = TextEditingController();
  TextEditingController _chuyenNganhController = TextEditingController();
  TextEditingController _tenNguoiTaoController = TextEditingController();

  final List<String> _specializations = [
    'Chung',
    'CNTT',
    'Sư Phạm',
    'Kinh Tế',
    'Du Lịch',
    'Ngôn ngữ Trung',
    'Điện Công Nghiệp',
    'Khác',
  ];

  @override
  void initState() {
    super.initState();
    _fetchCourses();
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

  Future<void> _fetchCourses() async {
    setState(() => _isLoading = true);
    final data = await _hocPhanService.getHocPhans();
    setState(() {
      _courses = data;
      _isLoading = false;
    });
  }

  Future<void> _timKiemHocPhan() async {
    setState(() => _isLoading = true);

    try {
      final results = await _hocPhanService.searchHocPhan(
        chuyenNganh: _chuyenNganhController.text.trim(),
        tenGV: _tenNguoiTaoController.text.trim(),
        tenHocPhan: _tenHocPhanController.text.trim(),
      );

      setState(() {
        _courses = results;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      debugPrint('Lỗi tìm kiếm học phần: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Lỗi khi tìm kiếm học phần'),
            backgroundColor: Colors.red),
      );
    }
  }

  void showSearchDialog({
    required BuildContext context,
    required TextEditingController tenHocPhanController,
    required TextEditingController chuyenNganhController,
    required TextEditingController tenNguoiTaoController,
    required void Function() onSearch,
  }) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Tìm kiếm học phần"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: tenHocPhanController,
                  decoration: InputDecoration(labelText: 'Tên học phần'),
                ),
                TextField(
                  controller: chuyenNganhController,
                  decoration: InputDecoration(labelText: 'Chuyên ngành'),
                ),
                TextField(
                  controller: tenNguoiTaoController,
                  decoration: InputDecoration(labelText: 'Tên người tạo'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text("Hủy"),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                onSearch();
              },
              child: Text("Tìm kiếm"),
            ),
          ],
        );
      },
    );
  }

  void _navigateToCreateCourse() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CreateCourseScreen(giangVien: widget.user),
      ),
    );
    if (result == true) {
      _fetchCourses();
    }
  }

  void _viewRegisteredUsers(HocPhan hocPhan) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CourseUsersScreen(
          hocPhanId: hocPhan.id!,
          tenHocPhan: hocPhan.tenHocPhan,
          userview: widget.user,
        ),
      ),
    );
  }

  void _registerCourse(String hocPhanId) async {
    final result =
        await _hocPhanService.registerHocPhan(hocPhanId, widget.user.id!);

    // Kiểm tra nếu result null hoặc không có message
    if (result == null || !result.containsKey('message')) {
      debugPrint('Lỗi đăng ký học phần: Không có phản hồi từ API');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi khi đăng ký học phần, vui lòng thử lại.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final message = result['message'] ?? 'Đăng ký thành công';

    if (message == 'Đăng ký học phần thành công') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
      _fetchCourses();
    } else {
      // In log lỗi
      debugPrint('Lỗi đăng ký học phần: $message');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi: $message'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _cancelRegistration(String hocPhanId) async {
    final result =
        await _hocPhanService.cancelHocPhan(hocPhanId, widget.user.id!);

    // Kiểm tra nếu result null hoặc không có message
    if (result == null || !result.containsKey('message')) {
      debugPrint('Lỗi hủy học phần: Không có phản hồi từ API');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi khi hủy học phần, vui lòng thử lại.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final message = result['message'] ?? 'Không thể hủy đăng ký';

    if (message == 'Đã hủy đăng ký học phần') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
      _fetchCourses();
    } else {
      debugPrint('Lỗi hủy học phần: $message');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi: $message'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _deleteCourse(String hocPhanId) async {
    bool? confirm = await _showDeleteConfirmationDialog();
    if (confirm == true) {
      await _hocPhanService.deleteHocPhan(hocPhanId);
      _fetchCourses();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Xóa học phần thành công")),
      );
    }
  }

  Future<bool?> _showDeleteConfirmationDialog() {
    return showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Xác nhận xóa"),
          content: Text("Bạn có chắc chắn muốn xóa học phần này không?"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false); // Không xóa
              },
              child: Text("Hủy"),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context, true); // Đồng ý xóa
              },
              child: Text("Xóa"),
            ),
          ],
        );
      },
    );
  }

  String _formatDate(DateTime date) {
    return "${date.day}/${date.month}/${date.year}";
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _currentSpecialization == 'Chung'
        ? _courses
        : _courses
            .where((c) => c.chuyenNganh == _currentSpecialization)
            .toList();

    return Scaffold(
      backgroundColor: backgroundColor,
      drawer: Mydrawer(
          onSignoutTap: _signOut, onCreateTap: _createPost, user: widget.user),
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          "List course",
          style: textsimplewhitebigger,
        ),
        centerTitle: true,
        backgroundColor: mainColor,
        actions: [
          // if (widget.user.isAdmin)
          //   IconButton(
          //     onPressed: _navigateToCreateCourse,
          //     icon: Icon(Icons.add),
          //   ),
          // if (!widget.user.isAdmin)
          IconButton(
            icon: Icon(Icons.search),
            onPressed: () {
              showSearchDialog(
                context: context,
                tenHocPhanController: _tenHocPhanController,
                chuyenNganhController: _chuyenNganhController,
                tenNguoiTaoController: _tenNguoiTaoController,
                onSearch: _timKiemHocPhan,
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _specializations.map((spec) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: ChoiceChip(
                    label: Text(spec),
                    selected: _currentSpecialization == spec,
                    onSelected: (_) {
                      setState(() => _currentSpecialization = spec);
                    },
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator())
                : filtered.isEmpty
                    ? Center(child: Text("Không có học phần"))
                    : ListView.builder(
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final hp = filtered[index];
                          final isOwner = widget.user.id == hp.nguoiTaoId;
                          return Card(
                            margin: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            child: ListTile(
                              title: Text(
                                hp.tenHocPhan,
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(Icons.book, size: 20),
                                      SizedBox(width: 8),
                                      Text("Chuyên ngành: ${hp.chuyenNganh}"),
                                    ],
                                  ),
                                  Row(
                                    children: [
                                      Icon(Icons.school, size: 20),
                                      SizedBox(width: 8),
                                      Text("Số tín chỉ: ${hp.soTinChi}"),
                                    ],
                                  ),
                                  Row(
                                    children: [
                                      Icon(Icons.schedule, size: 20),
                                      SizedBox(width: 8),
                                      Text(
                                          "Thời gian: ${_formatDate(hp.thoiGianBatDau)} - ${_formatDate(hp.thoiGianKetThuc)}"),
                                    ],
                                  ),
                                  Row(
                                    children: [
                                      Icon(Icons.location_on, size: 20),
                                      SizedBox(width: 8),
                                      Text("Địa điểm: ${hp.diaDiem}"),
                                    ],
                                  ),
                                  Row(
                                    children: [
                                      Icon(Icons.person, size: 20),
                                      SizedBox(width: 8),
                                      Text("Giảng viên: ${hp.tenNguoiTao}"),
                                    ],
                                  ),
                                  Row(
                                    children: [
                                      Icon(Icons.calendar_today, size: 20),
                                      SizedBox(width: 8),
                                      Text(
                                          "Lịch học: Thứ ${hp.thu.join(', ')} - Tiết ${hp.tiet.join(', ')}"),
                                    ],
                                  ),
                                  Row(
                                    children: [
                                      Icon(Icons.access_time, size: 20),
                                      SizedBox(width: 8),
                                      Text(
                                          "Giờ bắt đầu: ${hp.gioBatDauBuoiHoc}"),
                                    ],
                                  ),
                                  Row(
                                    children: [
                                      InkWell(
                                        onTap: () => _viewRegisteredUsers(hp),
                                        child: Row(
                                          children: [
                                            Icon(Icons.group, size: 20),
                                            SizedBox(width: 8),
                                            Text(
                                              "Số lượng đã đăng ký: ${hp.sinhVienDangKy.length}/${hp.soLuongToiDa}",
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              isThreeLine: true,
                              trailing: widget.user.role == 'Sinh viên'
                                  ? (hp.sinhVienDangKy.contains(widget.user.id)
                                      ? TextButton(
                                          onPressed: () =>
                                              _cancelRegistration(hp.id!),
                                          child: Text("Huỷ"),
                                        )
                                      : TextButton(
                                          onPressed: () =>
                                              _registerCourse(hp.id!),
                                          child: Text("Đăng ký"),
                                        ))
                                  // : isOwner
                                  //     ? PopupMenuButton<String>(
                                  //         onSelected: (value) {
                                  //           if (value == 'delete') {
                                  //             _deleteCourse(hp.id!);
                                  //           }
                                  //           if (value == 'edit') {
                                  //             Navigator.pop(context);
                                  //             Navigator.push(
                                  //               context,
                                  //               MaterialPageRoute(
                                  //                 builder: (context) =>
                                  //                     EditCourseScreen(
                                  //                         hocPhan:
                                  //                             hp), // Truyền dữ liệu học phần
                                  //               ),
                                  //             );
                                  //           }
                                  //         },
                                  //         itemBuilder: (BuildContext context) {
                                  //           return [
                                  //             PopupMenuItem<String>(
                                  //               value: 'edit',
                                  //               child: Text('Chỉnh sửa'),
                                  //             ),
                                  //             PopupMenuItem<String>(
                                  //               value: 'delete',
                                  //               child: Text('Xóa'),
                                  //             ),
                                  //           ];
                                  //         },
                                  //       )
                                  : null,
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
