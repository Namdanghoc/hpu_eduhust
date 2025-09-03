import 'dart:convert';
import 'package:http/http.dart' as http;

class LichGiangDayGV {
  final String id;
  final String giangVienId;
  final String? hocPhanId; // ID của học phần
  final String? tenHocPhan; // Thêm tên học phần
  final int? soTinChi; // Thêm số tín chỉ
  final List<String> thu;
  final List<int> tiet;
  final String gioBatDauBuoiHoc;
  final String? diaDiem;
  final DateTime thoiGianBatDau;
  final DateTime thoiGianKetThuc;

  LichGiangDayGV({
    required this.id,
    required this.giangVienId,
    this.hocPhanId,
    this.tenHocPhan,
    this.soTinChi,
    required this.thu,
    required this.tiet,
    required this.gioBatDauBuoiHoc,
    this.diaDiem,
    required this.thoiGianBatDau,
    required this.thoiGianKetThuc,
  });

  factory LichGiangDayGV.fromJson(Map<String, dynamic> json) {
    final hocPhan = json['hocPhanId'];

    return LichGiangDayGV(
      id: json['_id'] ?? '',
      giangVienId: json['giangVienId'] ?? '',
      hocPhanId: hocPhan is Map<String, dynamic> ? hocPhan['_id'] : null,
      tenHocPhan:
          hocPhan is Map<String, dynamic> ? hocPhan['tenHocPhan'] : null,
      soTinChi: hocPhan is Map<String, dynamic> ? hocPhan['soTinChi'] : null,
      thu: List<String>.from(json['lichGiangDay']['thu']),
      tiet: List<int>.from(json['lichGiangDay']['tiet']),
      gioBatDauBuoiHoc: json['lichGiangDay']['gioBatDauBuoiHoc'] ?? '',
      diaDiem: json['diaDiem'],
      thoiGianBatDau: DateTime.parse(json['thoiGianBatDau']),
      thoiGianKetThuc: DateTime.parse(json['thoiGianKetThuc']),
    );
  }
}

class LichGiangDayService {
  static const String baseUrl = 'http://10.0.2.2:3000'; // Địa chỉ API ảo của bạn
//static const String baseUrl = 'http://192.168.1.7:3000';
  Future<List<LichGiangDayGV>> fetchLichGiangDayByGiangVien(
      String giangVienId) async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/lichgiangday/giangvien/$giangVienId'));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        print('Data từ API: ${response.body}');
        return data.map((e) => LichGiangDayGV.fromJson(e)).toList();
      } else {
        print('Lỗi API: ${response.statusCode} - ${response.body}');
        throw Exception('Lỗi khi lấy lịch giảng dạy: ${response.statusCode}');
      }
    } catch (e) {
      print('Exception: $e');
      throw Exception('Lỗi khi lấy lịch giảng dạy: $e');
    }
  }
}
