import 'package:flutter/material.dart';
import 'package:hpu_eduhust/providers/chat.dart';
import 'package:intl/intl.dart';


class MessageBubble extends StatelessWidget {
  final Message message;
  final bool isMe;
  final VoidCallback? onDelete;

  const MessageBubble({
    required this.message,
    required this.isMe,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isMe) ...[
          
            CircleAvatar(
              child: Text(message.senderName[0].toUpperCase()),
              radius: 16,
            ),
            SizedBox(width: 8),
          ],
          GestureDetector(
            onLongPress: onDelete != null ? () {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: Text('Xóa tin nhắn'),
                  content: Text('Bạn có muốn xóa tin nhắn này không?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      child: Text('Hủy'),
                    ),
                    TextButton(
                      onPressed: () {
                        onDelete!();
                        Navigator.of(ctx).pop();
                      },
                      child: Text('Xóa'),
                    ),
                  ],
                ),
              );
            } : null,
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.7,
              ),
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isMe ? Theme.of(context).primaryColor : Colors.grey[300],
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!isMe)
                    Text(
                      message.senderName,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isMe ? Colors.white : Colors.black87,
                        fontSize: 12,
                      ),
                    ),
                  Text(
                    message.text,
                    style: TextStyle(
                      color: isMe ? Colors.white : Colors.black87,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    DateFormat('HH:mm').format(message.timestamp),
                    style: TextStyle(
                      fontSize: 10,
                      color: isMe ? Colors.white70 : Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
