import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:hpu_eduhust/providers/auth.dart';
import 'package:hpu_eduhust/providers/course.dart';
import 'package:hpu_eduhust/providers/lichgiangdaygv.dart';
import 'package:hpu_eduhust/providers/post.dart';
import 'package:hpu_eduhust/providers/schedule.dart';
import 'package:hpu_eduhust/screens/createpostscreen.dart';
import 'package:hpu_eduhust/screens/loginscreens.dart';
import 'package:hpu_eduhust/utils/Colors.dart';
import 'package:hpu_eduhust/utils/textstyle.dart';
import 'package:hpu_eduhust/widget/drawerwidget.dart';
import 'package:intl/intl.dart';

class LichGiangDayScreen extends StatefulWidget {
  final AppUser user;
  final String giangVienId;

  const LichGiangDayScreen(
      {super.key, required this.giangVienId, required this.user});

  @override
  State<LichGiangDayScreen> createState() => _LichGiangDayScreenState();
}

class _LichGiangDayScreenState extends State<LichGiangDayScreen> {
  late Future<List<LichGiangDayGV>> _lichFuture;
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
    _lichFuture =
        LichGiangDayService().fetchLichGiangDayByGiangVien(widget.giangVienId);
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

  String formatDate(DateTime date) {
    return DateFormat('dd/MM/yyyy').format(date);
  }

  String mapThuToVietnamese(String thu) {
    final Map<String, String> thuMap = {
      'Hai': 'Thứ Hai',
      'Ba': 'Thứ Ba',
      'Tu': 'Thứ Tư',
      'Nam': 'Thứ Năm',
      'Sau': 'Thứ Sáu',
      'Bay': 'Thứ Bảy',
      'CN': 'Chủ Nhật',
    };

    return thuMap[thu] ?? thu;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      drawer: Mydrawer(
          onSignoutTap: _signOut, onCreateTap: _createPost, user: widget.user),
      appBar: AppBar(
        title: const Text(
          'Teaching schedule',
          style: textsimplewhitebigger,
        ),
        centerTitle: true,
        iconTheme: IconThemeData(color: Colors.white),
        backgroundColor: mainColor,
        foregroundColor: Colors.white,
        elevation: 2,
      ),
      body: FutureBuilder<List<LichGiangDayGV>>(
        future: _lichFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline,
                        size: 48, color: Colors.red),
                    const SizedBox(height: 16),
                    Text(
                      'Đã xảy ra lỗi khi tải dữ liệu',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text('Chi tiết: ${snapshot.error}'),
                  ],
                ),
              ),
            );
          }

          final lichList = snapshot.data!;

          if (lichList.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.calendar_today,
                      size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(
                    'Không có lịch giảng dạy',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: lichList.length,
            padding: const EdgeInsets.all(12),
            itemBuilder: (context, index) {
              final lich = lichList[index];
              final tenHocPhan = lich.tenHocPhan;
              final thuList =
                  lich.thu.map((t) => mapThuToVietnamese(t)).join(', ');
              final tietList = lich.tiet.map((t) => t.toString()).join(', ');

              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.access_time, color: mainColor),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '${thuList} - ${tenHocPhan}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: _buildInfoItem(
                              context,
                              'Tiết học',
                              tietList,
                              Icons.format_list_numbered,
                            ),
                          ),
                          Expanded(
                            child: _buildInfoItem(
                              context,
                              'Giờ học',
                              lich.gioBatDauBuoiHoc,
                              Icons.watch_later_outlined,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _buildInfoItem(
                              context,
                              'Địa điểm',
                              lich.diaDiem ?? 'Chưa có',
                              Icons.location_on_outlined,
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: _buildInfoItem(
                              context,
                              'Bắt đầu',
                              formatDate(lich.thoiGianBatDau),
                              Icons.calendar_today,
                            ),
                          ),
                          Expanded(
                            child: _buildInfoItem(
                              context,
                              'Kết thúc',
                              formatDate(lich.thoiGianKetThuc),
                              Icons.event_available,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildInfoItem(
      BuildContext context, String label, String value, IconData icon) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Colors.blueGrey),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
