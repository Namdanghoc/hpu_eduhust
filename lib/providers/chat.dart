import 'package:cloud_firestore/cloud_firestore.dart';

class Message {
  final String senderId;
  final String senderName;
  final String text;
  final DateTime timestamp;
  final String id;

  Message({
    required this.senderId,
    required this.senderName,
    required this.text,
    required this.timestamp,
    required this.id,
  });

  // Convert from Map (from Firebase) to Message object
  factory Message.fromMap(Map<String, dynamic> map, String docId) {
    return Message(
      senderId: map['senderId'] ?? '',
      senderName: map['senderName'] ?? '',
      text: map['text'] ?? '',
      timestamp: (map['timestamp'] != null) 
          ? (map['timestamp'].toDate()) 
          : DateTime.now(),
      id: docId,
    );
  }

  // Convert Message object to Map (for Firebase)
  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'senderName': senderName,
      'text': text,
      'timestamp': timestamp,
    };
  }
}

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  
  Future<String> getRealName(String uid) async {
  final snapshot = await FirebaseFirestore.instance.collection('users').doc(uid).get();
  if (snapshot.exists && snapshot.data()!.containsKey('realname')) {
    return snapshot['realname'];
  } else {
    return 'Unknown';
  }
}
  
  // Lấy ID cuộc trò chuyện giữa 2 người dùng
  String getChatRoomId(String user1Id, String user2Id) {
    // Sắp xếp ID người dùng để đảm bảo ID cuộc trò chuyện nhất quán
    return user1Id.compareTo(user2Id) > 0 
        ? '${user1Id}_$user2Id' 
        : '${user2Id}_$user1Id';
  }
  
  // Gửi tin nhắn đến người dùng cụ thể
  Future<void> sendMessage(String receiverId, Message message) async {
    final chatRoomId = getChatRoomId(message.senderId, receiverId);
    
    await _firestore
        .collection('chat_rooms')
        .doc(chatRoomId)
        .collection('messages')
        .add(message.toMap());
    
    // Cập nhật thông tin cuộc trò chuyện mới nhất
    await _firestore.collection('chat_rooms').doc(chatRoomId).set({
      'lastMessage': message.text,
      'lastMessageTimestamp': message.timestamp,
      'participants': [message.senderId, receiverId],
      'lastSenderId': message.senderId,
    }, SetOptions(merge: true));
  }
  
  // Lấy stream tin nhắn giữa 2 người dùng
  Stream<List<Message>> getMessages(String currentUserId, String otherUserId) {
    final chatRoomId = getChatRoomId(currentUserId, otherUserId);
    
    return _firestore
        .collection('chat_rooms')
        .doc(chatRoomId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return Message.fromMap(doc.data(), doc.id);
      }).toList();
    });
  }
  
  // Lấy danh sách các cuộc trò chuyện của người dùng
  Stream<List<DocumentSnapshot>> getChatRooms(String userId) {
    return _firestore
        .collection('chat_rooms')
        .where('participants', arrayContains: userId)
        .orderBy('lastMessageTimestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs);
  }
  
  // Xóa tin nhắn
  Future<void> deleteMessage(String chatRoomId, String messageId) async {
    await _firestore
        .collection('chat_rooms')
        .doc(chatRoomId)
        .collection('messages')
        .doc(messageId)
        .delete();
  }
  
  // Cập nhật tin nhắn
  Future<void> updateMessage(String chatRoomId, String messageId, String newText) async {
    await _firestore
        .collection('chat_rooms')
        .doc(chatRoomId)
        .collection('messages')
        .doc(messageId)
        .update({
      'text': newText,
    });
  }
}
