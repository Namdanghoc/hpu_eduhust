import 'package:hpu_eduhust/widget/alertDiaLogThongBao.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class AppUser {
  String? id;
  String? email;
  final bool isAdmin;
  String? realname;
  String? namehighschool;
  String? group;
  String? gender;
  String? avatarUrl;
  DateTime? dateOfBirth;
  String? role; // Vai trò (Giảng viên, Sinh viên,...)
  String? maId; 
  String? phoneNumber;

  AppUser({
    this.id,
    this.email,
    this.isAdmin = false,
    this.realname,
    this.namehighschool,
    this.group,
    this.gender,
    this.avatarUrl,
    this.dateOfBirth,
    this.role,
    this.maId,
    this.phoneNumber,
  });

  @override
  String toString() {
    return 'AppUser(id: $id, email: $email, isAdmin: $isAdmin, realname: $realname, role: $role, maId: $maId, phoneNumber: $phoneNumber, namehighschool: $namehighschool, dateOfBirth: $dateOfBirth)';
  }
}

class UserService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final storageRefUser = FirebaseStorage.instance.ref();


  Future<AppUser?> signIn(String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      String userId = result.user!.uid;

      DocumentSnapshot<Map<String, dynamic>> userDoc =
          await _firestore.collection('users').doc(userId).get();

      if (!userDoc.exists) {
        print('User document does not exist for UID: $userId');
        return null;
      }

      Map<String, dynamic>? userData = userDoc.data();

      String? deviceToken = await FirebaseMessaging.instance.getToken();

      if (deviceToken != null) {
        print("Device Token: $deviceToken");

        final response = await http.post(
          Uri.parse('http://10.0.2.2:3000/save-token'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'userId': userId,
            'deviceToken': deviceToken,
          }),
        );

        print('Status code: ${response.statusCode}');
        print('Response body: ${response.body}');

        if (response.statusCode == 200) {
          print("Token saved successfully");
        } else {
          print("Failed to save token: ${response.body}");
        }
      }

      return AppUser(
        id: userId,
        email: email,
        isAdmin: userData?['isAdmin'] ?? false,
        realname: userData?['realname'],
        namehighschool: userData?['namehighschool'],
        group: userData?['group'],
        gender: userData?['gender'],
        dateOfBirth: (userData?['dateofbirth'] as Timestamp?)?.toDate(),
        avatarUrl: userData?['avatarUrl'],
        role: userData?['role'],
        maId: userData?['maId'],
        phoneNumber: userData?['phoneNumber'],
      );
    } catch (e) {
      print('Sign In Error: $e');
      return null;
    }
  }

  Future<AppUser?> loadUserInfo(String userId) async {
    try {
      DocumentSnapshot<Map<String, dynamic>> userDoc =
          await _firestore.collection('users').doc(userId).get();

      if (!userDoc.exists) {
        print('User document does not exist for UID: $userId');
        return null;
      }

      Map<String, dynamic>? userData = userDoc.data();

      return AppUser(
        id: userId,
        email: userData?['email'],
        isAdmin: userData?['isAdmin'] ?? false,
        realname: userData?['realname'],
        namehighschool: userData?['namehighschool'],
        group: userData?['group'],
        gender: userData?['gender'],
        dateOfBirth: (userData?['dateofbirth'] as Timestamp?)?.toDate(),
        avatarUrl: userData?['avatarUrl'],
        role: userData?['role'],
        maId: userData?['maId'],
        phoneNumber: userData?['phoneNumber'],
      );
    } catch (e) {
      print('Error loading user info: $e');
      return null;
    }
  }

  Future<AppUser?> registerUser({
    required String email,
    required String password,
    required String realname,
    required String namehighschool,
    required DateTime dateOfBirth,
    bool isAdmin = false,
    required String group,
    required String role, // Vai trò
    required String maId, // Mã ID
    required String phoneNumber, // Số điện thoại
  }) async {
    try {
      if (!_isValidEmail(email)) {
        print('Invalid email format');
        return null;
      }

      if (password.length < 6) {
        print('Password must be at least 6 characters long');
        return null;
      }

      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (result.user == null) {
        print('User creation failed');
        return null;
      }

      Map<String, dynamic> userData = {
        'email': email,
        'realname': realname,
        'namehighschool': namehighschool,
        'dateofbirth': Timestamp.fromDate(dateOfBirth),
        'isAdmin': isAdmin,
        'role': role, // Lưu vai trò
        'maId': maId, // Lưu mã ID
        'phoneNumber': phoneNumber, // Lưu số điện thoại
        'createdAt': FieldValue.serverTimestamp(),
        'group': group,
      };

      await _firestore.collection('users').doc(result.user!.uid).set(userData);

      return AppUser(
        id: result.user!.uid,
        email: email,
        isAdmin: isAdmin,
        realname: realname,
        namehighschool: namehighschool,
        dateOfBirth: dateOfBirth,
        role: role, // Trả về vai trò
        maId: maId, // Trả về mã ID
        phoneNumber: phoneNumber, // Trả về số điện thoại
      );
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'email-already-in-use':
          print('The email address is already in use.');
          break;
        case 'invalid-email':
          print('The email address is not valid.');
          break;
        case 'operation-not-allowed':
          print('Email/password accounts are not enabled.');
          break;
        case 'weak-password':
          print('The password is too weak.');
          break;
        default:
          print('An undefined Error happened: ${e.code}');
      }
      return null;
    } catch (e) {
      print('Unexpected registration error: $e');
      return null;
    }
  }

  Future<bool> deleteUser(String userId, String email, String password) async {
    try {
      User? user = _auth.currentUser;

      // Xác thực lại người dùng
      if (user != null) {
        AuthCredential credential = EmailAuthProvider.credential(
          email: email,
          password: password,
        );

        await user.reauthenticateWithCredential(credential);
      }

      DocumentReference userRef = _firestore.collection('users').doc(userId);
      DocumentSnapshot userDoc = await userRef.get();
      if (!userDoc.exists) {
        throw Exception('Không tìm thấy người dùng');
      }

      try {
        final avatarRef = storageRefUser.child('avatars/$userId.jpg');
        await avatarRef.delete();
      } catch (e) {
        print('Không tìm thấy ảnh đại diện hoặc lỗi khi xóa: $e');
      }

      try {
        QuerySnapshot userResults = await _firestore
            .collection('test_results')
            .where('userId', isEqualTo: userId)
            .get();

        for (QueryDocumentSnapshot result in userResults.docs) {
          await result.reference.delete();
        }
        print('Đã xóa tất cả kết quả bài thi của người dùng');
      } catch (e) {
        print('Lỗi khi xóa kết quả bài thi: $e');
      }

      await userRef.delete();

      if (user != null && user.uid == userId) {
        await user.delete();
      }

      return true;
    } catch (e) {
      print('Lỗi khi xóa user: $e');
      return false;
    }
  }

  Future<bool> changeAdminStatus(String userId, bool isAdmin) async {
    try {
      // Lấy reference đến document của user
      DocumentReference userRef = _firestore.collection('users').doc(userId);

      // Kiểm tra xem user có tồn tại không
      DocumentSnapshot userDoc = await userRef.get();
      if (!userDoc.exists) {
        throw Exception('Không tìm thấy người dùng');
      }

      // Cập nhật trạng thái admin
      await userRef.update({'isAdmin': isAdmin});

      print(
          'Đã thay đổi quyền admin thành ${isAdmin ? 'true' : 'false'} cho user $userId');
      await AlertDiaLogThongBao(
        tieuDeThongBao: 'Thành công',
        noiDungThongBao: 'Đã cập nhật quyền người dùng',
      );

      return true;
    } catch (e) {
      print('Lỗi khi thay đổi quyền admin: $e');
      await AlertDiaLogThongBao(
        tieuDeThongBao: 'Lỗi',
        noiDungThongBao: 'Không thể thay đổi quyền người dùng: ${e.toString()}',
      );
      return false;
    }
  }

  Future<String> uploadAvatar(File imageFile, String userId) async {
    try {
      final storageRef = storageRefUser.child('avatars/$userId.jpg');
      final uploadTask = await storageRef.putFile(imageFile);

      final imageUrl = await storageRef.getDownloadURL();
      return imageUrl;
    } catch (e) {
      print('Error uploading avatar: $e');
      throw e;
    }
  }

  Future<AppUser?> getUserById(String userId) async {
    try {
      final docSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      if (docSnapshot.exists) {
        final data = docSnapshot.data()!..addAll({'id': docSnapshot.id});

        return AppUser(
          id: data['id'],
          email: data['email'],
          isAdmin: data['isAdmin'] ?? false,
          realname: data['realname'],
          namehighschool: data['namehighschool'],
          group: data['group'],
          gender: data['gender'],
          avatarUrl: data['avatarUrl'],
          dateOfBirth: data['dateOfBirth'] != null
              ? (data['dateOfBirth'] as Timestamp).toDate()
              : null,
          role: data['role'],
          maId: data['maId'],
          phoneNumber: data['phoneNumber'],
        );
      }
      return null;
    } catch (e) {
      print('Error getting user by ID: $e');
      return null;
    }
  }

  bool _isValidEmail(String email) {
    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
    return emailRegex.hasMatch(email);
  }

  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      print('Sign Out Error: $e');
    }
  }

  Future<void> resetPassword(String email) async {
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw Exception(e.message);
    }
  }
}
