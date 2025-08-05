import 'package:flutter/material.dart';
import '../../widgets/chat_ui.dart';
import '../../services/chat_service.dart';
import 'dart:developer' as developer;

class ChatScreen extends StatefulWidget {
  final String otherUserId;
  final String currentUserId;
  final String otherUserName;
  
  const ChatScreen({
    Key? key, 
    required this.otherUserId,
    required this.currentUserId,
    required this.otherUserName,
  }) : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ChatService _chatService = ChatService();
  late Future<String> _chatRoomFuture;
  String? _errorMessage;
  
  @override
  void initState() {
    super.initState();
    _createChatRoom();
  }
  
  Future<void> _createChatRoom() async {
    try {
      developer.log('Creating chat room between ${widget.currentUserId} and ${widget.otherUserId}');
      
      // Check if user IDs are valid
      if (widget.currentUserId.isEmpty || widget.otherUserId.isEmpty) {
        setState(() {
          _errorMessage = 'Invalid user IDs. Please try again later.';
        });
        return;
      }
      
      // Create the chat room
      _chatRoomFuture = _chatService.createChatRoom(widget.currentUserId, widget.otherUserId);
      
      // Try to await the future to catch any errors immediately
      await _chatRoomFuture;
    } catch (e) {
      developer.log('Error creating chat room: $e');
      setState(() {
        _errorMessage = 'Error: $e';
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.otherUserName),
      ),
      body: FutureBuilder<String>(
        future: _chatRoomFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (snapshot.hasError) {
            developer.log('Chat room creation error: ${snapshot.error}');
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Could not create chat room'),
                  const SizedBox(height: 8),
                  Text('Error: ${snapshot.error}', style: const TextStyle(fontSize: 12, color: Colors.red)),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _createChatRoom();
                      });
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }
          
          if (!snapshot.hasData) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Could not create chat room'),
                  if (_errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(_errorMessage!, style: const TextStyle(fontSize: 12, color: Colors.red)),
                    ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _createChatRoom();
                      });
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }
          
          final chatRoomId = snapshot.data!;
          developer.log('Chat room created with ID: $chatRoomId');
          
          return ChatUI(
            chatRoomId: chatRoomId,
            currentUserId: widget.currentUserId,
            otherUserId: widget.otherUserId,
            otherUserName: widget.otherUserName,
          );
        },
      ),
    );
  }
}