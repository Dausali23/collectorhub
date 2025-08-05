import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/chat_service.dart';
import 'dart:developer' as developer;

class ChatUI extends StatefulWidget {
  final String chatRoomId;
  final String currentUserId;
  final String otherUserId;
  final String otherUserName;

  const ChatUI({
    Key? key,
    required this.chatRoomId,
    required this.currentUserId,
    required this.otherUserId,
    required this.otherUserName,
  }) : super(key: key);

  @override
  State<ChatUI> createState() => _ChatUIState();
}

class _ChatUIState extends State<ChatUI> {
  final TextEditingController _messageController = TextEditingController();
  final ChatService _chatService = ChatService();
  bool _isSending = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    // Mark messages as read when screen opens
    _markMessagesAsRead();
    developer.log('ChatUI initialized with room ID: ${widget.chatRoomId}');
    developer.log('Current user: ${widget.currentUserId}, Other user: ${widget.otherUserId}');
    
    // Check if chat room exists
    _checkChatRoomExists();
  }

  Future<void> _markMessagesAsRead() async {
    try {
      await _chatService.markAsRead(widget.chatRoomId, widget.currentUserId);
    } catch (e) {
      developer.log('Error marking messages as read: $e');
    }
  }

  Future<void> _checkChatRoomExists() async {
    try {
      final chatRoomRef = FirebaseFirestore.instance.collection('chat_rooms').doc(widget.chatRoomId);
      final chatRoomDoc = await chatRoomRef.get();
      
      if (chatRoomDoc.exists) {
        developer.log('Chat room exists: ${chatRoomDoc.data()}');
      } else {
        developer.log('Chat room does not exist yet');
      }
    } catch (e) {
      developer.log('Error checking chat room: $e');
    }
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;
    
    final messageContent = _messageController.text.trim();
    _messageController.clear();
    
    setState(() {
      _isSending = true;
      _errorMessage = null;
    });
    
    try {
      // First, ensure the chat room document exists
      final chatRoomRef = FirebaseFirestore.instance.collection('chat_rooms').doc(widget.chatRoomId);
      final chatRoomDoc = await chatRoomRef.get();
      
      // If chat room doesn't exist, create it
      if (!chatRoomDoc.exists) {
        developer.log('Chat room document does not exist, creating it');
        await chatRoomRef.set({
          'participants': [widget.currentUserId, widget.otherUserId],
          'created_at': FieldValue.serverTimestamp(),
          'last_message': messageContent,
          'last_message_time': FieldValue.serverTimestamp(),
        });
      }
      
      // Now send the message
      await _chatService.sendMessageDirect(
        widget.chatRoomId,
        widget.currentUserId,
        widget.otherUserId,
        messageContent,
      );
    } catch (e) {
      developer.log('Error sending message: $e');
      setState(() {
        _errorMessage = 'Failed to send message. Try again.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Error message if any
        if (_errorMessage != null)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            color: Colors.red.shade100,
            width: double.infinity,
            child: Text(
              _errorMessage!,
              style: TextStyle(color: Colors.red.shade800),
            ),
          ),
          
        // Messages list
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: _chatService.getMessagesRaw(widget.chatRoomId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              
              if (snapshot.hasError) {
                developer.log('Error loading messages: ${snapshot.error}');
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Could not load messages'),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: () {
                          setState(() {});
                        },
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                );
              }
              
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(child: Text('No messages yet'));
              }

              final messages = snapshot.data!.docs;
              
              return ListView.builder(
                reverse: true,
                padding: const EdgeInsets.all(10),
                itemCount: messages.length,
                itemBuilder: (context, index) {
                  final messageData = messages[index].data() as Map<String, dynamic>;
                  final isMe = messageData['senderId'] == widget.currentUserId;
                  final messageContent = messageData['content'] as String;
                  
                  final timestamp = messageData['timestamp'] as Timestamp?;
                  final timeString = timestamp != null 
                      ? '${timestamp.toDate().hour}:${timestamp.toDate().minute.toString().padLeft(2, '0')}' 
                      : '';
                  
                  return Align(
                    alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isMe ? Colors.deepPurple : Colors.grey[300],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            messageContent,
                            style: TextStyle(
                              color: isMe ? Colors.white : Colors.black,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            timeString,
                            style: TextStyle(
                              fontSize: 10,
                              color: isMe ? Colors.white70 : Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
        
        // Message input
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _messageController,
                  decoration: const InputDecoration(
                    hintText: 'Type a message',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(24)),
                    ),
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                  enabled: !_isSending,
                ),
              ),
              const SizedBox(width: 8),
              CircleAvatar(
                backgroundColor: _isSending ? Colors.grey : Colors.deepPurple,
                child: _isSending 
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : IconButton(
                      icon: const Icon(Icons.send, color: Colors.white),
                      onPressed: _sendMessage,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }
} 