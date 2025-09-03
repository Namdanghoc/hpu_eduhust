import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:hpu_eduhust/providers/auth.dart';
import 'package:hpu_eduhust/providers/post.dart';
import 'package:hpu_eduhust/providers/schedule.dart';
import 'package:hpu_eduhust/providers/course.dart';
import 'package:hpu_eduhust/screens/createpostscreen.dart';
import 'package:hpu_eduhust/screens/loginscreens.dart';
import 'package:hpu_eduhust/utils/Colors.dart';
import 'package:hpu_eduhust/utils/textstyle.dart';
import 'package:hpu_eduhust/widget/drawerwidget.dart';

class ThoiKhoaBieuScreen extends StatefulWidget {
  final String sinhVienId;
  final AppUser user;

  ThoiKhoaBieuScreen({required this.sinhVienId, required this.user});

  @override
  _ThoiKhoaBieuScreenState createState() => _ThoiKhoaBieuScreenState();
}

class _ThoiKhoaBieuScreenState extends State<ThoiKhoaBieuScreen> {
  final _auth = FirebaseAuth.instance;
  late ThoiKhoaBieuService _thoiKhoaBieuService;
  late Future<List<ThoiKhoaBieu>> _thoiKhoaBieuFuture;
  final HocPhanService _hocPhanService = HocPhanService();
  final PostService _postService = PostService();
  List<Post> _posts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _thoiKhoaBieuService = ThoiKhoaBieuService();
    _thoiKhoaBieuFuture =
        _thoiKhoaBieuService.getThoiKhoaBieu(widget.sinhVienId);
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

  void _cancelRegistration(String hocPhanId) async {
    final result =
        await _hocPhanService.cancelHocPhan(hocPhanId, widget.sinhVienId);

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
      setState(() {
        _thoiKhoaBieuFuture =
            _thoiKhoaBieuService.getThoiKhoaBieu(widget.sinhVienId);
      });
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      drawer: Mydrawer(
          onSignoutTap: _signOut, onCreateTap: _createPost, user: widget.user),
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          "Thời khóa biểu",
          style: textsimplewhitebigger,
        ),
        centerTitle: true,
        backgroundColor: mainColor,
      ),
      body: FutureBuilder<List<ThoiKhoaBieu>>(
        future: _thoiKhoaBieuFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text("Có lỗi xảy ra"));
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text("Không có dữ liệu"));
          }

          List<ThoiKhoaBieu> thoiKhoaBieuList = snapshot.data!;

          // Tạo một bản đồ sắp xếp theo thứ
          Map<String, List<ThoiKhoaBieu>> thoiKhoaBieuByDay = {};
          for (var thoiKhoaBieu in thoiKhoaBieuList) {
            for (var thu in thoiKhoaBieu.thu) {
              if (!thoiKhoaBieuByDay.containsKey(thu)) {
                thoiKhoaBieuByDay[thu] = [];
              }
              thoiKhoaBieuByDay[thu]!.add(thoiKhoaBieu);
            }
          }

          // Sắp xếp theo thứ tự: Thứ 2, Thứ 3, ... đến Thứ 7
          List<String> daysOfWeek = [
            'Hai',
            'Ba',
            'Tư',
            'Năm',
            'Sáu',
            'Bảy',
            'Chủ nhật'
          ];

          return ListView(
            children: daysOfWeek.map((day) {
              if (thoiKhoaBieuByDay[day] == null ||
                  thoiKhoaBieuByDay[day]!.isEmpty) {
                return Container();
              }
              var lessons = thoiKhoaBieuByDay[day]!;
              lessons.sort((a, b) {
                return a.gioBatDauBuoiHoc.compareTo(b.gioBatDauBuoiHoc);
              });

              return ExpansionTile(
                title: Text(day,
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                children: lessons.map((thoiKhoaBieu) {
                  return Card(
                      margin: EdgeInsets.symmetric(vertical: 4, horizontal: 10),
                      child: ListTile(
                        title: Text('Môn học: ${thoiKhoaBieu.tenHocPhan}',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                                "Giờ bắt đầu: ${thoiKhoaBieu.gioBatDauBuoiHoc}"),
                            Text("Tiết: ${thoiKhoaBieu.tiet.join(', ')}"),
                            Text("Địa điểm: ${thoiKhoaBieu.diaDiem}"),
                            Text("Số tín chỉ: ${thoiKhoaBieu.soTinChi}"),
                            Row(
                              children: [
                                Icon(Icons.person, size: 20),
                                SizedBox(width: 8),
                                Text("Giảng viên: ${thoiKhoaBieu.tenNguoiTao}"),
                              ],
                            ),
                            SizedBox(height: 8),
                            Align(
                              alignment: Alignment.centerRight,
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  _cancelRegistration(thoiKhoaBieu.hocPhanId);
                                },
                                icon: Icon(Icons.cancel),
                                label: Text(
                                  "Huỷ đăng ký",
                                  style: textsimplewhite,
                                ),
                                style: ElevatedButton.styleFrom(
                                    backgroundColor: mainColor),
                              ),
                            )
                          ],
                        ),
                      ));
                }).toList(),
              );
            }).toList(),
          );
        },
      ),
    );
  }
}
