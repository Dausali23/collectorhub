import 'package:flutter/material.dart';
import '../screens/chat/chat_screen.dart';

class ChatButton extends StatelessWidget {
  final String currentUserId;
  final String otherUserId;
  final String otherUserName;
  final Color? backgroundColor;
  final Color? textColor;

  const ChatButton({
    Key? key,
    required this.currentUserId,
    required this.otherUserId,
    required this.otherUserName,
    this.backgroundColor = Colors.deepPurple,
    this.textColor = Colors.white,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      icon: const Icon(Icons.chat),
      label: const Text('Chat'),
      style: ElevatedButton.styleFrom(
        backgroundColor: backgroundColor,
        foregroundColor: textColor,
      ),
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatScreen(
              currentUserId: currentUserId,
              otherUserId: otherUserId,
              otherUserName: otherUserName,
            ),
          ),
        );
      },
    );
  }
} 