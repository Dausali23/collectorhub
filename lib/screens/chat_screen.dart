import 'package:flutter/material.dart';
import 'chat/chat_screen.dart' as new_chat; // Import the new chat implementation

// This is a compatibility layer to redirect to our new chat screen implementation
class ChatScreen extends StatelessWidget {
  final String? chatRoomId; // Make this optional
  final String currentUserId;
  final String otherUserId;
  final String otherUserName;

  const ChatScreen({
    Key? key,
    this.chatRoomId, // Optional parameter
    required this.currentUserId,
    required this.otherUserId,
    required this.otherUserName,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Just delegate to the new implementation
    return new_chat.ChatScreen(
      currentUserId: currentUserId,
      otherUserId: otherUserId, 
      otherUserName: otherUserName,
    );
  }
} 
