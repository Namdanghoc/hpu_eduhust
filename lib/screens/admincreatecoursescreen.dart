import 'package:flutter/material.dart';
import 'package:hpu_eduhust/utils/Colors.dart';
import 'package:hpu_eduhust/utils/textstyle.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hpu_eduhust/providers/auth.dart';
import 'package:hpu_eduhust/providers/course.dart';

class AdminCreateCourseScreen extends StatefulWidget {
  const AdminCreateCourseScreen({super.key});

  @override
  State<AdminCreateCourseScreen> createState() =>
      _AdminCreateCourseScreenState();
}

class _AdminCreateCourseScreenState extends State<AdminCreateCourseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _tenController = TextEditingController();
  final _soTinChiController = TextEditingController();
  final _diaDiemController = TextEditingController();
  final _gioBatDauBuoiHocController = TextEditingController();
  final _soLuongToiDaController = TextEditingController();

  DateTime? _thoiGianBatDau;
  DateTime? _thoiGianKetThuc;

  List<String> _thu = [];
  List<int> _tiet = [];
  final _tietController = TextEditingController();

  String _selectedChuyenNganh = 'CNTT';
  AppUser? _selectedGiangVien;
  List<AppUser> _danhSachGiangVien = [];
  bool _isLoading = true;

  final List<String> _dsChuyenNganh = [
    'CNTT',
    'Sư Phạm',
    'Kinh Tế',
    'Du Lịch',
    'Ngôn ngữ Trung',
    'Điện Công Nghiệp',
    'Khác',
  ];

  final HocPhanService _hocPhanService = HocPhanService();

  @override
  void initState() {
    super.initState();
    _fetchGiangVien();
  }

  Future<void> _fetchGiangVien() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final usersRef = FirebaseFirestore.instance.collection('users');
      final snapshot = await usersRef.where('isAdmin', isEqualTo: true).get();
      final List<AppUser> giangVienList = snapshot.docs.map((doc) {
        final data = doc.data();
        return AppUser(
          id: doc.id,
          email: data['email'] ?? '',
          realname: data['realname'] ?? '',
          role: data['role'] ?? '',
          avatarUrl: data['photoURL'],
        );
      }).toList();

      setState(() {
        _danhSachGiangVien = giangVienList;
        _isLoading = false;

        // Select first instructor by default if list is not empty
        if (_danhSachGiangVien.isNotEmpty) {
          _selectedGiangVien = _danhSachGiangVien.first;
        }
      });
    } catch (e) {
      print('Error fetching instructors: $e');
      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi khi tải danh sách giảng viên: $e')),
      );
    }
  }

  Future<void> _chonNgay(BuildContext context, bool isBatDau) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2024),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        if (isBatDau) {
          _thoiGianBatDau = picked;
        } else {
          _thoiGianKetThuc = picked;
        }
      });
    }
  }

  void _submit() async {
    if (_formKey.currentState!.validate() &&
        _thoiGianBatDau != null &&
        _thoiGianKetThuc != null &&
        _thu.isNotEmpty &&
        _tiet.isNotEmpty &&
        _selectedGiangVien != null) {
      try {
        final hocPhan = HocPhan(
          id: '',
          tenHocPhan: _tenController.text,
          soTinChi: int.tryParse(_soTinChiController.text) ?? 0,
          nguoiTaoId: _selectedGiangVien!.id!,
          tenNguoiTao: _selectedGiangVien!.realname!,
          thoiGianBatDau: _thoiGianBatDau!,
          thoiGianKetThuc: _thoiGianKetThuc!,
          diaDiem: _diaDiemController.text,
          thu: _thu,
          tiet: _tiet,
          gioBatDauBuoiHoc: _gioBatDauBuoiHocController.text,
          soLuongToiDa: int.tryParse(_soLuongToiDaController.text) ?? 0,
          sinhVienDangKy: [],
          chuyenNganh: _selectedChuyenNganh,
        );

        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => Center(child: CircularProgressIndicator()),
        );

        await _hocPhanService
            .createHocPhan(hocPhan); // chỉ cần gọi, nếu lỗi sẽ ném Exception

        Navigator.of(context).pop();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Tạo học phần thành công")),
        );
        _resetForm();
      } catch (e) {
        Navigator.of(context).pop(); // hide loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Vui lòng nhập đầy đủ thông tin")),
      );
    }
  }

  void _resetForm() {
    _formKey.currentState?.reset();
    _tenController.clear();
    _soTinChiController.clear();
    _diaDiemController.clear();
    _gioBatDauBuoiHocController.clear();
    _soLuongToiDaController.clear();
    _tietController.clear();

    setState(() {
      _thoiGianBatDau = null;
      _thoiGianKetThuc = null;
      _thu = [];
      _tiet = [];
      _selectedChuyenNganh = 'CNTT';
      if (_danhSachGiangVien.isNotEmpty) {
        _selectedGiangVien = _danhSachGiangVien.first;
      } else {
        _selectedGiangVien = null;
      }
    });
  }

  @override
  void dispose() {
    _tenController.dispose();
    _soTinChiController.dispose();
    _diaDiemController.dispose();
    _gioBatDauBuoiHocController.dispose();
    _soLuongToiDaController.dispose();
    _tietController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        automaticallyImplyLeading: true,
        backgroundColor: mainColor,
        title: Text(
          "Create course",
          style: textsimplewhitebigger,
        ),
        centerTitle: true,
        iconTheme: IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _fetchGiangVien,
            tooltip: 'Tải lại danh sách giảng viên',
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: ListView(
                  children: [
                    Card(
                      elevation: 4,
                      margin: EdgeInsets.only(bottom: 16),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Thông tin giảng viên",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 10),
                            Container(
                              width: double.infinity,
                              child: DropdownButtonFormField<AppUser>(
                                decoration: InputDecoration(
                                  labelText: "Chọn giảng viên",
                                  border: OutlineInputBorder(),
                                ),
                                value: _selectedGiangVien,
                                items: _danhSachGiangVien.map((giangVien) {
                                  return DropdownMenuItem<AppUser>(
                                    value: giangVien,
                                    child: Text(
                                      "${giangVien.realname} - ${giangVien.email}",
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                      softWrap: false,
                                    ),
                                  );
                                }).toList(),
                                validator: (value) => value == null
                                    ? "Vui lòng chọn giảng viên"
                                    : null,
                                onChanged: (value) {
                                  setState(() {
                                    _selectedGiangVien = value;
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Card(
                      elevation: 4,
                      margin: EdgeInsets.only(bottom: 16),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Thông tin học phần",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 10),
                            TextFormField(
                              controller: _tenController,
                              decoration: InputDecoration(
                                labelText: "Tên học phần",
                                border: OutlineInputBorder(),
                              ),
                              validator: (value) =>
                                  value!.isEmpty ? "Không được để trống" : null,
                            ),
                            SizedBox(height: 10),
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: _soTinChiController,
                                    decoration: InputDecoration(
                                      labelText: "Số tín chỉ",
                                      border: OutlineInputBorder(),
                                    ),
                                    keyboardType: TextInputType.number,
                                    validator: (value) => value!.isEmpty
                                        ? "Nhập số tín chỉ"
                                        : null,
                                  ),
                                ),
                                SizedBox(width: 10),
                                Expanded(
                                  child: TextFormField(
                                    controller: _soLuongToiDaController,
                                    decoration: InputDecoration(
                                      labelText: "Số lượng tối đa",
                                      border: OutlineInputBorder(),
                                    ),
                                    keyboardType: TextInputType.number,
                                    validator: (value) => value!.isEmpty
                                        ? "Nhập số lượng tối đa"
                                        : null,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 10),
                            DropdownButtonFormField<String>(
                              value: _selectedChuyenNganh,
                              decoration: InputDecoration(
                                labelText: "Chuyên ngành",
                                border: OutlineInputBorder(),
                              ),
                              items: _dsChuyenNganh
                                  .map((e) => DropdownMenuItem(
                                      value: e, child: Text(e)))
                                  .toList(),
                              onChanged: (value) {
                                setState(() {
                                  _selectedChuyenNganh = value!;
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                    Card(
                      elevation: 4,
                      margin: EdgeInsets.only(bottom: 16),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Thời gian và địa điểm",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 10),
                            TextFormField(
                              controller: _diaDiemController,
                              decoration: InputDecoration(
                                labelText: "Địa điểm",
                                border: OutlineInputBorder(),
                              ),
                              validator: (value) => value!.isEmpty
                                  ? "Vui lòng nhập địa điểm"
                                  : null,
                            ),
                            SizedBox(height: 10),
                            TextFormField(
                              controller: _gioBatDauBuoiHocController,
                              decoration: InputDecoration(
                                labelText: "Giờ bắt đầu buổi học (VD: 7h30)",
                                border: OutlineInputBorder(),
                              ),
                              validator: (value) => value!.isEmpty
                                  ? "Vui lòng nhập giờ bắt đầu"
                                  : null,
                            ),
                            SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: ListTile(
                                    title: Text("Ngày bắt đầu"),
                                    subtitle: Text(_thoiGianBatDau == null
                                        ? "Chưa chọn"
                                        : "${_thoiGianBatDau!.day}/${_thoiGianBatDau!.month}/${_thoiGianBatDau!.year}"),
                                    trailing: ElevatedButton(
                                      onPressed: () => _chonNgay(context, true),
                                      child: Text("Chọn"),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: ListTile(
                                    title: Text("Ngày kết thúc"),
                                    subtitle: Text(_thoiGianKetThuc == null
                                        ? "Chưa chọn"
                                        : "${_thoiGianKetThuc!.day}/${_thoiGianKetThuc!.month}/${_thoiGianKetThuc!.year}"),
                                    trailing: ElevatedButton(
                                      onPressed: () =>
                                          _chonNgay(context, false),
                                      child: Text("Chọn"),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    Card(
                      elevation: 4,
                      margin: EdgeInsets.only(bottom: 16),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Lịch học",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 10),
                            Text("Chọn các thứ trong tuần:"),
                            SizedBox(height: 5),
                            Wrap(
                              spacing: 8.0,
                              children:
                                  ['Hai', 'Ba', 'Tư', 'Năm', 'Sáu', 'Bảy', 'CN']
                                      .map((thu) => FilterChip(
                                            label: Text(thu),
                                            selected: _thu.contains(thu),
                                            onSelected: (bool selected) {
                                              setState(() {
                                                if (selected) {
                                                  _thu.add(thu);
                                                } else {
                                                  _thu.remove(thu);
                                                }
                                              });
                                            },
                                          ))
                                      .toList(),
                            ),
                            SizedBox(height: 10),
                            TextFormField(
                              controller: _tietController,
                              decoration: InputDecoration(
                                labelText: "Tiết học (VD: 1,2,3)",
                                hintText:
                                    "Nhập các tiết học cách nhau bởi dấu phẩy",
                                border: OutlineInputBorder(),
                              ),
                              validator: (value) => value!.isEmpty
                                  ? "Vui lòng nhập tiết học"
                                  : null,
                              onChanged: (value) {
                                final parts = value.split(',');
                                setState(() {
                                  _tiet = parts
                                      .map((e) => int.tryParse(e.trim()))
                                      .where((e) => e != null)
                                      .map((e) => e!)
                                      .toList();
                                });
                              },
                            ),
                            SizedBox(height: 8),
                            if (_tiet.isNotEmpty)
                              Wrap(
                                spacing: 8.0,
                                children: _tiet
                                    .map((t) => Chip(
                                          label: Text("Tiết $t"),
                                          onDeleted: () {
                                            setState(() {
                                              _tiet.remove(t);
                                              _tietController.text =
                                                  _tiet.join(', ');
                                            });
                                          },
                                        ))
                                    .toList(),
                              ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 10),
                    ElevatedButton.icon(
                      icon: Icon(Icons.save),
                      label: Text("TẠO HỌC PHẦN"),
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 16),
                      ),
                      onPressed: _submit,
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
