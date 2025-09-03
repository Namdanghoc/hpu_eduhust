import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hpu_eduhust/providers/auth.dart';
import 'package:hpu_eduhust/providers/course.dart';
import 'package:hpu_eduhust/screens/admincreatecoursescreen.dart';
import 'package:hpu_eduhust/screens/editcoursescreen.dart';
import 'package:hpu_eduhust/screens/liststudentscreen.dart';
import 'package:hpu_eduhust/screens/loginscreens.dart';
import 'package:hpu_eduhust/utils/Colors.dart';
import 'package:hpu_eduhust/utils/textstyle.dart';
import 'package:hpu_eduhust/widget/drawerwidget.dart';

class AdminCourseScreen extends StatefulWidget {
  final AppUser user;
  const AdminCourseScreen({super.key, required this.user});

  @override
  State<AdminCourseScreen> createState() => _AdminCourseScreenState();
}

class _AdminCourseScreenState extends State<AdminCourseScreen> {
  final _auth = FirebaseAuth.instance;
  final HocPhanService _hocPhanService = HocPhanService();
  List<HocPhan> _courses = [];
  bool _isLoading = true;
  String _currentSpecialization = 'Tất cả';

  // Controller cho tìm kiếm
  TextEditingController _tenHocPhanController = TextEditingController();
  TextEditingController _chuyenNganhController = TextEditingController();
  TextEditingController _tenNguoiTaoController = TextEditingController();

  final List<String> _specializations = [
    'Tất cả',
    'CNTT',
    'Sư Phạm',
    'Kinh Tế',
    'Du Lịch',
    'Ngôn ngữ Trung',
    'Điện Công Nghiệp',
    'Khác',
  ];

  @override
  void initState() {
    super.initState();
    _fetchAllCourses();
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

  void _navigateToCreate() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => AdminCreateCourseScreen()),
    );
  }

  Future<void> _fetchAllCourses() async {
    setState(() => _isLoading = true);
    try {
      final data = await _hocPhanService.getHocPhans();
      setState(() {
        _courses = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      debugPrint('Lỗi khi lấy danh sách học phần: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Không thể tải danh sách học phần'),
          backgroundColor: Colors.red,
        ),
      );
    }
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
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showSearchDialog() {
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
                  controller: _tenHocPhanController,
                  decoration: InputDecoration(labelText: 'Tên học phần'),
                ),
                TextField(
                  controller: _chuyenNganhController,
                  decoration: InputDecoration(labelText: 'Chuyên ngành'),
                ),
                TextField(
                  controller: _tenNguoiTaoController,
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
                _timKiemHocPhan();
              },
              child: Text("Tìm kiếm"),
            ),
          ],
        );
      },
    );
  }

  void _editCourse(HocPhan hocPhan) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditCourseScreen(hocPhan: hocPhan),
      ),
    );

    if (result == true) {
      _fetchAllCourses();
    }
  }

  void _deleteCourse(String hocPhanId) async {
    bool? confirm = await _showDeleteConfirmationDialog();
    if (confirm == true) {
      try {
        await _hocPhanService.deleteHocPhan(hocPhanId);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Xóa học phần thành công")),
        );
        _fetchAllCourses();
      } catch (e) {
        debugPrint('Lỗi khi xóa học phần: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Không thể xóa học phần'),
            backgroundColor: Colors.red,
          ),
        );
      }
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
              onPressed: () => Navigator.pop(context, false),
              child: Text("Hủy"),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text("Xóa", style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
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

  String _formatDate(DateTime date) {
    return "${date.day}/${date.month}/${date.year}";
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _currentSpecialization == 'Tất cả'
        ? _courses
        : _courses
            .where((c) => c.chuyenNganh == _currentSpecialization)
            .toList();

    return Scaffold(
      backgroundColor: backgroundColor,
      drawer: Mydrawer(
          onSignoutTap: _signOut, onCreateTap: () {}, user: widget.user),
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          "Quản lý học phần",
          style: textsimplewhitebigger,
        ),
        centerTitle: true,
        backgroundColor: mainColor,
        actions: [
          IconButton(
            icon: Icon(Icons.search),
            onPressed: _showSearchDialog,
          ),
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _fetchAllCourses,
          ),
        ],
      ),
      body: Column(
        children: [
          // Bộ lọc chuyên ngành
          Container(
            height: 50,
            padding: EdgeInsets.symmetric(vertical: 8),
            child: ListView(
              scrollDirection: Axis.horizontal,
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

          // Hiển thị số lượng học phần
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Text(
                  "Tổng số học phần: ${filtered.length}",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),

          // Danh sách học phần
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator())
                : filtered.isEmpty
                    ? Center(child: Text("Không có học phần nào"))
                    : ListView.builder(
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final hp = filtered[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            elevation: 3,
                            child: ExpansionTile(
                              title: Text(
                                hp.tenHocPhan,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              subtitle: Text(
                                "Chuyên ngành: ${hp.chuyenNganh} | GV: ${hp.tenNguoiTao}",
                                style: TextStyle(fontSize: 14),
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: Icon(Icons.edit, color: Colors.blue),
                                    onPressed: () => _editCourse(hp),
                                    tooltip: "Chỉnh sửa",
                                  ),
                                  IconButton(
                                    icon: Icon(Icons.delete, color: Colors.red),
                                    onPressed: () => _deleteCourse(hp.id!),
                                    tooltip: "Xóa",
                                  ),
                                ],
                              ),
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      _infoRow(Icons.book,
                                          "Số tín chỉ: ${hp.soTinChi}"),
                                      _infoRow(Icons.schedule,
                                          "Thời gian: ${_formatDate(hp.thoiGianBatDau)} - ${_formatDate(hp.thoiGianKetThuc)}"),
                                      _infoRow(Icons.location_on,
                                          "Địa điểm: ${hp.diaDiem}"),
                                      _infoRow(Icons.calendar_today,
                                          "Lịch học: Thứ ${hp.thu.join(', ')} - Tiết ${hp.tiet.join(', ')}"),
                                      _infoRow(Icons.access_time,
                                          "Giờ bắt đầu: ${hp.gioBatDauBuoiHoc}"),
                                      InkWell(
                                        onTap: () => _viewRegisteredUsers(hp),
                                        child: _infoRow(
                                          Icons.group,
                                          "Số lượng đã đăng ký: ${hp.sinhVienDangKy.length}/${hp.soLuongToiDa}",
                                          isButton: true,
                                        ),
                                      ),
                                      SizedBox(height: 10),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.end,
                                        children: [
                                          ElevatedButton.icon(
                                            icon: Icon(Icons.edit),
                                            label: Text("Chỉnh sửa"),
                                            onPressed: () => _editCourse(hp),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.blue,
                                              foregroundColor: Colors.white,
                                            ),
                                          ),
                                          SizedBox(width: 10),
                                          ElevatedButton.icon(
                                            icon: Icon(Icons.delete),
                                            label: Text("Xóa"),
                                            onPressed: () =>
                                                _deleteCourse(hp.id!),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.red,
                                              foregroundColor: Colors.white,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: mainColor,
        child: Icon(Icons.add),
        onPressed: _navigateToCreate,
        tooltip: "Tạo học phần mới",
      ),
    );
  }

  Widget _infoRow(IconData icon, String text, {bool isButton = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 20, color: isButton ? Colors.blue : null),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: isButton ? Colors.blue : null,
                fontWeight: isButton ? FontWeight.bold : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
