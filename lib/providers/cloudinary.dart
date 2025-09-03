import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:http_parser/http_parser.dart';

const String apiKey = '954479468291293';
const String cloudName = 'dsbivhlhf';

class CloudinaryService {
  final String cloudName = 'dsbivhlhf';
  final String uploadPreset = 'postimg'; // Unsigned upload preset
  final String apiKey = '954479468291293';

  final Dio _dio = Dio();

  Future<String?> uploadImage(File imageFile) async {
    try {
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          imageFile.path,
          contentType: MediaType('image', 'jpeg'),
        ),
        'upload_preset': uploadPreset,
        'api_key': apiKey,
      });

      // URL upload của Cloudinary
      final uploadUrl =
          'https://api.cloudinary.com/v1_1/$cloudName/image/upload';

      // Thực hiện request
      final response = await _dio.post(
        uploadUrl,
        data: formData,
        options: Options(
          headers: {
            'Content-Type': 'multipart/form-data',
          },
        ),
      );

      if (response.statusCode == 200) {
        return response.data['secure_url'];
      } else {
        debugPrint('Upload lỗi: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      debugPrint('Lỗi khi upload ảnh: $e');
      return null;
    }
  }
}
