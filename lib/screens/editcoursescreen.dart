import 'package:flutter/material.dart';
import 'package:hpu_eduhust/providers/course.dart';
import 'package:hpu_eduhust/utils/Colors.dart';
import 'package:hpu_eduhust/utils/textstyle.dart';

class EditCourseScreen extends StatefulWidget {
  final HocPhan hocPhan; // Khóa học hiện tại cần chỉnh sửa
  const EditCourseScreen({super.key, required this.hocPhan});

  @override
  State<EditCourseScreen> createState() => _EditCourseScreenState();
}

class _EditCourseScreenState extends State<EditCourseScreen> {
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

  String _selectedChuyenNganh = 'CNTT'; // Mặc định giá trị chuyên ngành

  final List<String> _dsChuyenNganh = [
    'CNTT',
    'Sư Phạm',
    'Kinh Tế',
    'Du Lịch',
    'Ngôn ngữ Trung',
    'Điện Công Nghiệp',
    'Khác',
  ];

  final HocPhanService _hocPhanService = HocPhanService();

  @override
  void initState() {
    super.initState();
    _tenController.text = widget.hocPhan.tenHocPhan;
    _soTinChiController.text = widget.hocPhan.soTinChi.toString();
    _diaDiemController.text = widget.hocPhan.diaDiem;
    _gioBatDauBuoiHocController.text = widget.hocPhan.gioBatDauBuoiHoc;
    _soLuongToiDaController.text = widget.hocPhan.soLuongToiDa.toString();
    _thoiGianBatDau = widget.hocPhan.thoiGianBatDau;
    _thoiGianKetThuc = widget.hocPhan.thoiGianKetThuc;
    _thu = List.from(widget.hocPhan.thu);
    _tiet = List.from(widget.hocPhan.tiet);
    _selectedChuyenNganh = widget.hocPhan.chuyenNganh;
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
        _tiet.isNotEmpty) {
      final hocPhan = HocPhan(
        id: widget.hocPhan.id,
        tenHocPhan: _tenController.text,
        soTinChi: int.tryParse(_soTinChiController.text) ?? 0,
        nguoiTaoId: widget.hocPhan.nguoiTaoId,
        tenNguoiTao: widget.hocPhan.tenNguoiTao,
        thoiGianBatDau: _thoiGianBatDau!,
        thoiGianKetThuc: _thoiGianKetThuc!,
        diaDiem: _diaDiemController.text,
        thu: _thu,
        tiet: _tiet,
        gioBatDauBuoiHoc: _gioBatDauBuoiHocController.text,
        soLuongToiDa: int.tryParse(_soLuongToiDaController.text) ?? 0,
        sinhVienDangKy: widget.hocPhan.sinhVienDangKy,
        chuyenNganh: _selectedChuyenNganh,
      );

      await _hocPhanService.updateHocPhan(widget.hocPhan.id, hocPhan);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Cập nhật học phần thành công")),
      );

      Navigator.pop(
          context, true); // Đóng màn hình và trở lại màn hình trước đó
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Vui lòng nhập đầy đủ thông tin")),
      );
    }
  }

  @override
  void dispose() {
    _tenController.dispose();
    _soTinChiController.dispose();
    _diaDiemController.dispose();
    _gioBatDauBuoiHocController.dispose();
    _soLuongToiDaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text(
          "Edit coures",
          style: textsimplewhitebigger,
        ),
        centerTitle: true,
        backgroundColor: mainColor,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _tenController,
                decoration: InputDecoration(labelText: "Tên học phần"),
                validator: (value) =>
                    value!.isEmpty ? "Không được để trống" : null,
              ),
              TextFormField(
                controller: _soTinChiController,
                decoration: InputDecoration(labelText: "Số tín chỉ"),
                keyboardType: TextInputType.number,
                validator: (value) => value!.isEmpty ? "Nhập số tín chỉ" : null,
              ),
              TextFormField(
                controller: _diaDiemController,
                decoration: InputDecoration(labelText: "Địa điểm"),
              ),
              TextFormField(
                controller: _gioBatDauBuoiHocController,
                decoration: InputDecoration(
                    labelText: "Giờ bắt đầu buổi học (VD: 7h30)"),
              ),
              TextFormField(
                controller: _soLuongToiDaController,
                decoration: InputDecoration(labelText: "Số lượng tối đa"),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: Text(_thoiGianBatDau == null
                        ? "Chọn ngày bắt đầu"
                        : "Bắt đầu: ${_thoiGianBatDau!.toLocal().toString().split(' ')[0]}"),
                  ),
                  ElevatedButton(
                    onPressed: () => _chonNgay(context, true),
                    child: Text("Chọn"),
                  ),
                ],
              ),
              Row(
                children: [
                  Expanded(
                    child: Text(_thoiGianKetThuc == null
                        ? "Chọn ngày kết thúc"
                        : "Kết thúc: ${_thoiGianKetThuc!.toLocal().toString().split(' ')[0]}"),
                  ),
                  ElevatedButton(
                    onPressed: () => _chonNgay(context, false),
                    child: Text("Chọn"),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text("Chọn các thứ học (ví dụ: Hai, Ba, Tu):"),
              Wrap(
                spacing: 8.0,
                children: ['Hai', 'Ba', 'Tư', 'Năm', 'Sáu', 'Bảy']
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
              const SizedBox(height: 10),
              Text("Nhập các tiết học (vd: 1, 2, 3):"),
              TextFormField(
                decoration: InputDecoration(labelText: "Tiết học"),
                keyboardType: TextInputType.text,
                onChanged: (value) {
                  final parts = value.split(',');
                  _tiet = parts
                      .map((e) => int.tryParse(e.trim()))
                      .where((e) => e != null)
                      .map((e) => e!)
                      .toList();
                },
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: _selectedChuyenNganh,
                decoration: InputDecoration(labelText: "Chuyên ngành"),
                items: _dsChuyenNganh
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedChuyenNganh = value!;
                  });
                },
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _submit,
                child: Text("Cập nhật học phần"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
