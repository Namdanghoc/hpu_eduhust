import 'dart:convert';
import 'dart:io';
import 'package:hpu_eduhust/components/text_box.dart';
import 'package:hpu_eduhust/providers/auth.dart';
import 'package:hpu_eduhust/providers/post.dart';
import 'package:hpu_eduhust/screens/createpostscreen.dart';
import 'package:hpu_eduhust/screens/loginscreens.dart';
import 'package:hpu_eduhust/utils/Colors.dart';
import 'package:hpu_eduhust/utils/textstyle.dart';
import 'package:hpu_eduhust/widget/drawerwidget.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ionicons/ionicons.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;

class Profilescreens extends StatefulWidget {
  final AppUser user;
  const Profilescreens({super.key, required this.user});

  @override
  State<Profilescreens> createState() => _ProfilescreensState();
}

class _ProfilescreensState extends State<Profilescreens> {
  final _auth = FirebaseAuth.instance;
  final currentUser = FirebaseAuth.instance.currentUser!;
  bool isLoading = true;
  File? _imageFile;
  String? _imageUrl;
  final PostService _postService = PostService();
  List<Post> _posts = [];
  bool _isLoading = true;

  void _checkAuthStatus() {
    if (_auth.currentUser == null) {
      _navigateToLogin();
    }
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

  void _loadScreen() async {
    await Future.delayed(const Duration(seconds: 2));
    setState(() {
      isLoading = false;
    });
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? pickedFile =
        await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
      await _uploadImage();
    }
  }

  Future<void> _uploadImage() async {
    if (_imageFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an image first!')),
      );
      return;
    }
    final url = Uri.parse('https://api.cloudinary.com/v1_1/dsbivhlhf/upload');
    final request = http.MultipartRequest('POST', url)
      ..fields['upload_preset'] = 'avatars'
      ..files.add(await http.MultipartFile.fromPath('file', _imageFile!.path));
    final response = await request.send();
    if (response.statusCode == 200) {
      final responseData = await response.stream.toBytes();
      final responseString = String.fromCharCodes(responseData);
      final jsonMap = jsonDecode(responseString);
      setState(() {
        _imageUrl = jsonMap['url'];
        widget.user.avatarUrl = _imageUrl;
      });
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.user.id)
          .update({'avatarUrl': _imageUrl});
    }
  }

  String formatDate(DateTime date) {
    return DateFormat('dd-MM-yyyy').format(date);
  }

  Future<void> editInfor(String fieldName, String firestoreKey) async {
    String newText = "";
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: mainColor,
        title: Text('Edit $fieldName', style: textsimplewhite),
        content: TextField(
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: "Enter new $fieldName",
            hintStyle: const TextStyle(color: Colors.white),
          ),
          onChanged: (value) {
            newText = value;
          },
        ),
        actions: [
          TextButton(
            child: const Text("Save", style: TextStyle(color: Colors.white)),
            onPressed: () async {
              if (newText.isNotEmpty) {
                await FirebaseFirestore.instance
                    .collection('users')
                    .doc(widget.user.id)
                    .update({firestoreKey: newText});
                setState(() {
                  switch (firestoreKey) {
                    case 'realname':
                      widget.user.realname = newText;
                      break;
                    case 'gender':
                      widget.user.gender = newText;
                      break;
                    case 'namehighschool':
                      widget.user.namehighschool = newText;
                      break;
                    case 'group':
                      widget.user.group = newText;
                      break;
                    case 'phoneNumber':
                      widget.user.phoneNumber = newText;
                      break;
                    case 'maId':
                      widget.user.maId = newText;
                      break;
                    case 'role':
                      widget.user.role = newText;
                      break;
                  }
                });
              }
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
    _loadScreen();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Profile page',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        backgroundColor: mainColor,
        elevation: 4,
      ),
      drawer: Mydrawer(
        onSignoutTap: _signOut,
        onCreateTap: _createPost,
        user: widget.user,
      ),
      body: Stack(
        children: [
          Container(
            color: backgroundColor,
            child: ListView(
              children: [
                const SizedBox(height: 50),
                Center(
                  child: widget.user.avatarUrl != null
                      ? CircleAvatar(
                          radius: 80,
                          backgroundImage: NetworkImage(widget.user.avatarUrl!),
                          backgroundColor: Colors.grey[300],
                        )
                      : const Icon(
                          Icons.person,
                          color: Colors.white,
                          size: 72,
                        ),
                ),
                const SizedBox(height: 10),
                Text(
                  currentUser.email!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: mainColor,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                const Padding(
                  padding: EdgeInsets.only(left: 25),
                  child: Text(
                    'My detail',
                    style: TextStyle(color: mainColor, fontSize: 16),
                  ),
                ),
                MyTextBox(
                  text: widget.user.realname ?? 'Unknown',
                  sectionName: 'Real name',
                  onPressed: () => editInfor('Name', 'realname'),
                  icon: Ionicons.person_circle_outline,
                ),
                MyTextBox(
                  text: widget.user.gender ?? 'Unknown',
                  sectionName: 'Gender',
                  onPressed: () => editInfor('Gender', 'gender'),
                  icon: Ionicons.male_female_outline,
                ),
                MyTextBox(
                  text: widget.user.dateOfBirth != null
                      ? formatDate(widget.user.dateOfBirth!)
                      : 'Unknown',
                  sectionName: 'Date of Birth',
                  onPressed: () {}, // Not editable for now
                  icon: Icons.cake,
                ),
                MyTextBox(
                  text: widget.user.namehighschool ?? 'Unknown',
                  sectionName: 'Name school',
                  onPressed: () => editInfor('School Name', 'namehighschool'),
                  icon: Ionicons.school,
                ),
                MyTextBox(
                  text: widget.user.group ?? 'Unknown',
                  sectionName: 'Name group',
                  onPressed: () => editInfor('Group Name', 'group'),
                  icon: Ionicons.people,
                ),
                MyTextBox(
                  text: widget.user.phoneNumber ?? 'Unknown',
                  sectionName: 'Phone Number',
                  onPressed: () => editInfor('Phone Number', 'phoneNumber'),
                  icon: Ionicons.call,
                ),
                MyTextBox(
                  text: widget.user.maId ?? 'Unknown',
                  sectionName: 'Code ID',
                  onPressed: () => editInfor('Code ID', 'maId'),
                  icon: Ionicons.card,
                ),
                MyTextBox(
                  text: widget.user.role ?? 'Unknown',
                  sectionName: 'Role',
                  //onPressed: () => editInfor('Role', 'role'),
                  onPressed: () {},
                  icon: Ionicons.accessibility,
                ),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 25, vertical: 10),
                  child: ElevatedButton(
                    onPressed: _pickImage,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: mainColor,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text(
                      'Change Avatar',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (isLoading)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(
                child: CircularProgressIndicator(
                  color: mainColor,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
