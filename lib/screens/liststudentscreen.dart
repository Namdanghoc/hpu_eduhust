import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:hpu_eduhust/providers/auth.dart';
import 'package:hpu_eduhust/providers/course.dart';
import 'package:hpu_eduhust/utils/Colors.dart';
import 'package:hpu_eduhust/utils/textstyle.dart';
import 'package:hpu_eduhust/widget/drawerwidget.dart';

class CourseUsersScreen extends StatefulWidget {
  final String hocPhanId;
  final String tenHocPhan;
  final AppUser userview;

  const CourseUsersScreen({
    super.key,
    required this.hocPhanId,
    required this.tenHocPhan,
    required this.userview,
  });

  @override
  State<CourseUsersScreen> createState() => _CourseUsersScreenState();
}

class _CourseUsersScreenState extends State<CourseUsersScreen> {
  final _auth = FirebaseAuth.instance;
  final UserService _authService = UserService();
  final HocPhanService _hocPhanService = HocPhanService();
  late HocPhan _hocPhan;
  List<AppUser> _registeredUsers = [];
  bool _isLoading = true;
  TextEditingController _searchController = TextEditingController();
  String _searchTerm = '';

  @override
  void initState() {
    super.initState();
    _fetchRegisteredUsers();
  }

  void _signOut() {
    _auth.signOut();
    Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
  }

  Future<void> _fetchRegisteredUsers() async {
    setState(() => _isLoading = true);

    try {
      final hocPhan = await _hocPhanService.getHocPhanById(widget.hocPhanId);

      if (hocPhan != null && hocPhan.sinhVienDangKy.isNotEmpty) {
        setState(() {
          _hocPhan = hocPhan;
        });
        List<AppUser> users = [];
        for (String userId in hocPhan.sinhVienDangKy) {
          final user = await _authService.getUserById(userId);
          if (user != null) {
            users.add(user);
          }
        }

        setState(() {
          _registeredUsers = users;
          _isLoading = false;
        });
      } else {
        setState(() {
          _registeredUsers = [];
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Lỗi khi lấy danh sách sinh viên: $e');
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Đã xảy ra lỗi khi tải danh sách sinh viên'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  List<AppUser> get _filteredUsers {
    if (_searchTerm.isEmpty) {
      return _registeredUsers;
    }

    return _registeredUsers.where((user) {
      final searchLower = _searchTerm.toLowerCase();
      final nameLower = user.realname?.toLowerCase() ?? '';
      final emailLower = user.email?.toLowerCase() ?? '';
      final idLower = user.id?.toLowerCase() ?? '';
      final maSV = user.maId?.toLowerCase() ?? '';

      return nameLower.contains(searchLower) ||
          emailLower.contains(searchLower) ||
          idLower.contains(searchLower) ||
          maSV.contains(searchLower);
    }).toList();
  }

  Future<void> _removeUserFromCourse(String userId) async {
    bool? confirm = await _showRemoveConfirmationDialog();
    if (confirm != true) return;

    setState(() => _isLoading = true);

    try {
      final result =
          await _hocPhanService.cancelHocPhan(widget.hocPhanId, userId);

      if (result != null && result['message'] == 'Đã hủy đăng ký học phần') {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Đã xóa sinh viên khỏi học phần')),
        );
        _fetchRegisteredUsers();
      } else {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Không thể xóa sinh viên: ${result?['message'] ?? 'Lỗi không xác định'}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      debugPrint('Lỗi khi xóa sinh viên: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Đã xảy ra lỗi khi xóa sinh viên'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<bool?> _showRemoveConfirmationDialog() {
    return showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Xác nhận xóa"),
          content:
              Text("Bạn có chắc chắn muốn xóa sinh viên này khỏi học phần?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text("Hủy"),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text("Xóa"),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          "Danh sách sinh viên - ${widget.tenHocPhan}",
          style: textsimplewhitebigger,
        ),
        centerTitle: true,
        backgroundColor: mainColor,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Tìm kiếm theo tên, email hoặc mã SV',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
              onChanged: (value) {
                setState(() {
                  _searchTerm = value;
                });
              },
            ),
          ),
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              children: [
                Icon(Icons.people, color: mainColor),
                SizedBox(width: 8),
                Text(
                  'Tổng số: ${_registeredUsers.length} sinh viên',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator())
                : _filteredUsers.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.person_off,
                              size: 64,
                              color: Colors.grey,
                            ),
                            SizedBox(height: 16),
                            Text(
                              _registeredUsers.isEmpty
                                  ? "Chưa có sinh viên đăng ký học phần này"
                                  : "Không tìm thấy sinh viên phù hợp",
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[700],
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: _filteredUsers.length,
                        itemBuilder: (context, index) {
                          final user = _filteredUsers[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            elevation: 2,
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: mainColor,
                                child: Text(
                                  (user.realname?.isNotEmpty == true)
                                      ? user.realname![0].toUpperCase()
                                      : "?",
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                              title: Text(
                                user.realname ?? "Không có tên",
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(Icons.badge, size: 16),
                                      SizedBox(width: 4),
                                      Text("Mã SV: ${user.maId ?? 'N/A'}"),
                                    ],
                                  ),
                                  Row(
                                    children: [
                                      Icon(Icons.group, size: 16),
                                      SizedBox(width: 4),
                                      Text("Nhóm: ${user.group ?? 'N/A'}"),
                                    ],
                                  ),
                                  Row(
                                    children: [
                                      Icon(Icons.email, size: 16),
                                      SizedBox(width: 4),
                                      Text(
                                        user.email ?? "Không có email",
                                        style: TextStyle(fontSize: 12),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              // trailing: widget.userview.isAdmin ||
                              //         widget.userview.role == 'Giảng viên'
                              //     ? IconButton(
                              //         icon:
                              //             Icon(Icons.delete, color: Colors.red),
                              //         onPressed: () =>
                              //             _removeUserFromCourse(user.id!),
                              //       )
                              //     : null,
                              trailing: widget.userview.id ==
                                      _hocPhan.nguoiTaoId
                                  ? IconButton(
                                      icon:
                                          Icon(Icons.delete, color: Colors.red),
                                      onPressed: () =>
                                          _removeUserFromCourse(user.id!),
                                    )
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
