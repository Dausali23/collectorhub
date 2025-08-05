import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/chat_service.dart';
import 'chat_screen.dart';
import 'dart:developer' as developer;

class ChatListScreen extends StatefulWidget {
  final String currentUserId;

  const ChatListScreen({
    Key? key,
    required this.currentUserId,
  }) : super(key: key);

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  final ChatService _chatService = ChatService();

  @override
  void initState() {
    super.initState();
    developer.log('ChatListScreen initialized for user: ${widget.currentUserId}');
    _checkForExistingChats();
  }
  
  Future<void> _checkForExistingChats() async {
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('chat_rooms')
          .where('participants', arrayContains: widget.currentUserId)
          .get();
          
      developer.log('Found ${querySnapshot.docs.length} chat rooms for user ${widget.currentUserId}');
      
      for (var doc in querySnapshot.docs) {
        developer.log('Chat room ID: ${doc.id}');
        developer.log('Chat room data: ${doc.data()}');
      }
    } catch (e) {
      developer.log('Error checking for existing chats: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _chatService.getChatRooms(widget.currentUserId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (snapshot.hasError) {
            developer.log('Error in chat rooms stream: ${snapshot.error}');
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  const Text('Error loading messages'),
                  const SizedBox(height: 8),
                  Text('${snapshot.error}', style: const TextStyle(fontSize: 12)),
                ],
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            developer.log('No chat rooms found for user: ${widget.currentUserId}');
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.deepPurple.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.chat_bubble_outline,
                      size: 80,
                      color: Colors.deepPurple.withOpacity(0.5),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'No messages yet',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.deepPurple,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'You haven\'t chatted with anyone',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Start a conversation from any item page',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            );
          }

          final chatRooms = snapshot.data!.docs;
          developer.log('Displaying ${chatRooms.length} chat rooms');

          // Sort chat rooms by last_message_time locally
          chatRooms.sort((a, b) {
            final aData = a.data() as Map<String, dynamic>;
            final bData = b.data() as Map<String, dynamic>;
            
            final aTime = aData['last_message_time'] as Timestamp?;
            final bTime = bData['last_message_time'] as Timestamp?;
            
            if (aTime == null && bTime == null) return 0;
            if (aTime == null) return 1; // null times go to the end
            if (bTime == null) return -1;
            
            // Sort in descending order (newest first)
            return bTime.compareTo(aTime);
          });

          return ListView.builder(
            itemCount: chatRooms.length,
            itemBuilder: (context, index) {
              final chatRoom = chatRooms[index].data() as Map<String, dynamic>;
              final chatRoomId = chatRooms[index].id;
              developer.log('Processing chat room: $chatRoomId');
              
              final participants = List<String>.from(chatRoom['participants'] ?? []);
              developer.log('Participants: $participants');
              
              if (participants.isEmpty) {
                developer.log('Empty participants list for chat room: $chatRoomId');
                return const SizedBox.shrink();
              }
              
              // Get the other user ID (not the current user)
              final otherUserId = participants.firstWhere(
                (id) => id != widget.currentUserId,
                orElse: () => '',
              );

              if (otherUserId.isEmpty) {
                developer.log('Could not find other user ID for chat room: $chatRoomId');
                return const SizedBox.shrink();
              }

              developer.log('Other user ID: $otherUserId');

              // Fetch the other user's information
              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection('users')
                    .doc(otherUserId)
                    .get(),
                builder: (context, userSnapshot) {
                  if (!userSnapshot.hasData) {
                    return const ListTile(
                      leading: CircleAvatar(
                        child: Icon(Icons.person),
                      ),
                      title: Text('Loading...'),
                    );
                  }

                  final userData = userSnapshot.data!.data() as Map<String, dynamic>?;
                  // Try different field names for the display name
                  final userName = userData?['displayName'] ?? 
                                  userData?['name'] ?? 
                                  userData?['username'] ?? 
                                  'Unknown User';
                  developer.log('Other user name: $userName');

                  final lastMessage = chatRoom['last_message'] ?? 'Start chatting';
                  final timestamp = chatRoom['last_message_time'] as Timestamp?;
                  final timeString = timestamp != null 
                      ? _formatDate(timestamp.toDate())
                      : '';

                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    elevation: 1,
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.deepPurple.shade100,
                        child: Text(
                          userName.isNotEmpty ? userName[0].toUpperCase() : '?',
                          style: TextStyle(
                            color: Colors.deepPurple.shade800,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      title: Text(
                        userName,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        lastMessage,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          if (timeString.isNotEmpty)
                            Text(
                              timeString,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          const SizedBox(height: 4),
                          const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
                        ],
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ChatScreen(
                              currentUserId: widget.currentUserId,
                              otherUserId: otherUserId,
                              otherUserName: userName,
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    if (date.day == now.day && date.month == now.month && date.year == now.year) {
      return '${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    }
    return '${date.day}/${date.month}';
  }
} 