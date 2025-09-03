import 'dart:convert';
import 'package:http/http.dart' as http;

class ThoiKhoaBieu {
  String sinhVienId;
  String hocPhanId;
  String tenHocPhan;
  int soTinChi;
  String tenNguoiTao;
  List<String> thu;
  List<int> tiet;
  String gioBatDauBuoiHoc;
  String diaDiem;
  DateTime thoiGianBatDau;
  DateTime thoiGianKetThuc;

  ThoiKhoaBieu({
    required this.sinhVienId,
    required this.hocPhanId,
    required this.tenHocPhan,
    required this.soTinChi,
    required this.tenNguoiTao,
    required this.thu,
    required this.tiet,
    required this.gioBatDauBuoiHoc,
    required this.diaDiem,
    required this.thoiGianBatDau,
    required this.thoiGianKetThuc,
  });

  factory ThoiKhoaBieu.fromJson(Map<String, dynamic> json) {
    final hocPhan = json['hocPhanId'] ?? {};

    return ThoiKhoaBieu(
      sinhVienId: json['sinhVienId'] ?? '',
      hocPhanId: hocPhan['_id'] ?? '',
      tenHocPhan: hocPhan['tenHocPhan'] ?? '',
      soTinChi: hocPhan['soTinChi'] ?? 0,
      tenNguoiTao: hocPhan['tenNguoiTao'] ?? '',
      thu: List<String>.from(json['lichGiangDay']['thu'] ?? []),
      tiet: List<int>.from(json['lichGiangDay']['tiet'] ?? []),
      gioBatDauBuoiHoc: json['lichGiangDay']['gioBatDauBuoiHoc'] ?? '',
      diaDiem: json['diaDiem'] ?? '',
      thoiGianBatDau: DateTime.parse(json['thoiGianBatDau']),
      thoiGianKetThuc: DateTime.parse(json['thoiGianKetThuc']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'sinhVienId': sinhVienId,
      'hocPhanId': {'oid': hocPhanId},
      'lichGiangDay': {
        'thu': thu,
        'tiet': tiet,
        'gioBatDauBuoiHoc': gioBatDauBuoiHoc,
      },
      'diaDiem': diaDiem,
      'thoiGianBatDau': thoiGianBatDau.toIso8601String(),
      'thoiGianKetThuc': thoiGianKetThuc.toIso8601String(),
    };
  }
}

class ThoiKhoaBieuService {
  static const String baseUrl = 'http://10.0.2.2:3000'; // Địa chỉ API ảo của bạn
//static const String baseUrl = 'http://192.168.1.7:3000';
  // Hàm lấy thời khóa biểu của sinh viên
  Future<List<ThoiKhoaBieu>> getThoiKhoaBieu(String sinhVienId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/thoikhoabieu/$sinhVienId'),
        headers: {'Content-Type': 'application/json'},
      );

      // Nếu yêu cầu thành công, chuyển đổi JSON thành danh sách ThoiKhoaBieu
      if (response.statusCode == 200) {
        List<dynamic> jsonData = json.decode(response.body);
        print(jsonData);

        return jsonData.map((item) => ThoiKhoaBieu.fromJson(item)).toList();
      } else {
        throw Exception('Lỗi khi lấy thời khóa biểu');
      }
    } catch (error) {
      print("Lỗi: $error");
      rethrow;
    }
  }

  // Hàm tạo thời khóa biểu mới
  Future<bool> createThoiKhoaBieu(ThoiKhoaBieu thoiKhoaBieu) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/thoi-khoa-bieu'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(thoiKhoaBieu.toJson()),
      );

      // Kiểm tra xem yêu cầu có thành công không (HTTP 201 Created)
      return response.statusCode == 201;
    } catch (error) {
      print("Lỗi: $error");
      return false;
    }
  }

  // Hàm cập nhật thời khóa biểu
  Future<bool> updateThoiKhoaBieu(String id, ThoiKhoaBieu thoiKhoaBieu) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/thoi-khoa-bieu/$id'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(thoiKhoaBieu.toJson()),
      );

      // Kiểm tra xem yêu cầu có thành công không (HTTP 200 OK)
      return response.statusCode == 200;
    } catch (error) {
      print("Lỗi: $error");
      return false;
    }
  }

  // Hàm hủy đăng ký học phần
  Future<bool> cancelThoiKhoaBieu(String sinhVienId, String hocPhanId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/thoi-khoa-bieu/cancel'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'sinhVienId': sinhVienId,
          'hocPhanId': hocPhanId,
        }),
      );

      // Kiểm tra nếu yêu cầu thành công (HTTP 200 OK)
      return response.statusCode == 200;
    } catch (error) {
      print("Lỗi: $error");
      return false;
    }
  }
}
