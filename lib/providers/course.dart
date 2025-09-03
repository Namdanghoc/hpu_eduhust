import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;

class HocPhan {
  final String id;
  final String tenHocPhan;
  final int soTinChi;
  final String nguoiTaoId;
  final String tenNguoiTao;
  final DateTime thoiGianBatDau;
  final DateTime thoiGianKetThuc;
  final String diaDiem;
  final List<String> thu;
  final List<int> tiet;
  final String gioBatDauBuoiHoc;
  final int soLuongToiDa;
  final List<String> sinhVienDangKy;
  final String chuyenNganh;

  HocPhan({
    required this.id,
    required this.tenHocPhan,
    required this.soTinChi,
    required this.nguoiTaoId,
    required this.tenNguoiTao,
    required this.thoiGianBatDau,
    required this.thoiGianKetThuc,
    required this.diaDiem,
    required this.thu,
    required this.tiet,
    required this.gioBatDauBuoiHoc,
    required this.soLuongToiDa,
    required this.sinhVienDangKy,
    required this.chuyenNganh,
  });

  factory HocPhan.fromJson(Map<String, dynamic> json) {
    return HocPhan(
      id: json['_id'],
      tenHocPhan: json['tenHocPhan'],
      soTinChi: json['soTinChi'],
      nguoiTaoId: json['nguoiTaoId'],
      tenNguoiTao: json['tenNguoiTao'],
      thoiGianBatDau: DateTime.parse(json['thoiGianBatDau']),
      thoiGianKetThuc: DateTime.parse(json['thoiGianKetThuc']),
      diaDiem: json['diaDiem'],
      thu: List<String>.from(json['lichGiangDay']['thu']),
      tiet: List<int>.from(json['lichGiangDay']['tiet']),
      gioBatDauBuoiHoc: json['lichGiangDay']['gioBatDauBuoiHoc'],
      soLuongToiDa: json['soLuongToiDa'],
      sinhVienDangKy: List<String>.from(json['sinhVienDangKy']),
      chuyenNganh: json['chuyenNganh'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'tenHocPhan': tenHocPhan,
      'soTinChi': soTinChi,
      'nguoiTaoId': nguoiTaoId,
      'tenNguoiTao': tenNguoiTao,
      'thoiGianBatDau': thoiGianBatDau.toIso8601String(),
      'thoiGianKetThuc': thoiGianKetThuc.toIso8601String(),
      'diaDiem': diaDiem,
      'lichGiangDay': {
        'thu': thu,
        'tiet': tiet,
        'gioBatDauBuoiHoc': gioBatDauBuoiHoc,
      },
      'soLuongToiDa': soLuongToiDa,
      'chuyenNganh': chuyenNganh,
    };
  }
}

class HocPhanService {
   static const String baseUrl = 'http://10.0.2.2:3000'; // Địa chỉ API ảo của bạn
//static const String baseUrl = 'http://192.168.1.7:3000';
  Future<void> createHocPhan(HocPhan hocPhan) async {
    final response = await http.post(
      Uri.parse('$baseUrl/hocphans'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(hocPhan.toJson()),
    );
    print(jsonEncode(hocPhan.toJson()));

    if (response.statusCode == 201) {
      return; // Thành công
    } else {
      final responseData = jsonDecode(response.body);
      final errorMessage = responseData['message'] ?? 'Tạo học phần thất bại';
      throw Exception(errorMessage); // Ném lỗi để xử lý bên ngoài
    }
  }

  Future<List<HocPhan>> getHocPhans({
    String? chuyenNganh,
    String? tenGV,
    String? tenHocPhan,
  }) async {
    try {
      final queryParams = {
        if (chuyenNganh != null && chuyenNganh.isNotEmpty)
          'chuyenNganh': chuyenNganh,
        if (tenGV != null && tenGV.isNotEmpty) 'tenNguoiTao': tenGV,
        if (tenHocPhan != null && tenHocPhan.isNotEmpty)
          'tenHocPhan': tenHocPhan,
      };

      final uri =
          Uri.parse('$baseUrl/hocphans').replace(queryParameters: queryParams);
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final List<dynamic> data = json['hocPhans'] ?? [];
        print(data);
        return data.map((e) => HocPhan.fromJson(e)).toList();
      } else {
        print('Lỗi khi lấy học phần: ${response.statusCode}');
      }
    } catch (e) {
      print('Lỗi kết nối API học phần: $e');
    }
    return [];
  }

  Future<List<HocPhan>> searchHocPhan({
    String? chuyenNganh,
    String? tenGV,
    String? tenHocPhan,
  }) async {
    try {
      final queryParams = {
        if (chuyenNganh != null && chuyenNganh.isNotEmpty)
          'chuyenNganh': chuyenNganh,
        if (tenGV != null && tenGV.isNotEmpty) 'tenNguoiTao': tenGV,
        if (tenHocPhan != null && tenHocPhan.isNotEmpty)
          'tenHocPhan': tenHocPhan,
      };
      final uri = Uri.parse('$baseUrl/search-hocphan')
          .replace(queryParameters: queryParams);
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final List<dynamic> data = json['hocPhans'] ?? [];
        return data.map((e) => HocPhan.fromJson(e)).toList();
      } else {
        print('Lỗi khi tìm kiếm học phần: ${response.statusCode}');
      }
    } catch (e) {
      print('Lỗi kết nối API tìm kiếm học phần: $e');
    }
    return [];
  }

  Future<bool> updateHocPhan(String id, HocPhan hocPhan) async {
    final response = await http.put(
      Uri.parse('$baseUrl/hocphans/$id'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(hocPhan.toJson()),
    );
    return response.statusCode == 200;
  }

  Future<bool> deleteHocPhan(String id) async {
    final response = await http.delete(Uri.parse('$baseUrl/hocphans/$id'));
    return response.statusCode == 200;
  }

  Future<Map<String, dynamic>> registerHocPhan(
      String id, String studentId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/hocphans/$id/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'sinhVienId': studentId}),
      );

      final data = jsonDecode(response.body);
      print(data);
      print(response.statusCode);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {
          'success': true,
          'message': data['message'] ?? 'Đăng ký học phần thành công',
        };
      } else {
        return {
          'success': false,
          'message':
              data['message'] ?? 'Lỗi không xác định khi đăng ký học phần',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Lỗi khi kết nối với máy chủ: $e',
      };
    }
  }

  Future<Map<String, dynamic>> cancelHocPhan(
      String id, String studentId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/hocphans/$id/cancel'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'sinhVienId': studentId}),
      );

      final data = jsonDecode(response.body);
      print(data);
      print(response.statusCode);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {
          'success': true,
          'message': data['message'] ?? 'Đã hủy đăng ký học phần',
        };
      } else {
        return {
          'success': false,
          'message':
              data['message'] ?? 'Lỗi không xác định khi hủy đăng ký học phần',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Lỗi khi kết nối với máy chủ: $e',
      };
    }
  }

  Future<HocPhan?> getHocPhanById(String id) async {
    print("Getting hocphan with ID: $id");

    try {
      final response = await http.get(Uri.parse('$baseUrl/hocphans/$id'));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return HocPhan.fromJson(data);
      } else {
        print('Failed to load hocphan: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error fetching hocphan: $e');
      return null;
    }
  }
}
