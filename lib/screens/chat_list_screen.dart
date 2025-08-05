import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/chat_service.dart';
import 'chat_screen.dart';

class ChatListScreen extends StatelessWidget {
  final String currentUserId;

  const ChatListScreen({Key? key, required this.currentUserId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final ChatService _chatService = ChatService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _chatService.getChatRooms(currentUserId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No conversations yet'));
          }

          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final chatRoom = snapshot.data!.docs[index];
              final participants = List<String>.from(chatRoom['participants']);
              
              // Get the other user's ID
              final otherUserId = participants.firstWhere(
                (id) => id != currentUserId,
                orElse: () => '',
              );

              if (otherUserId.isEmpty) return const SizedBox.shrink();

              // Get user data for display
              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection('users')
                    .doc(otherUserId)
                    .get(),
                builder: (context, userSnapshot) {
                  if (!userSnapshot.hasData) {
                    return const ListTile(
                      leading: CircleAvatar(child: Icon(Icons.person)),
                      title: Text('Loading...'),
                    );
                  }

                  final userData = userSnapshot.data!.data() as Map<String, dynamic>?;
                  final userName = userData?['name'] ?? 'Unknown User';

                  return ListTile(
                    leading: const CircleAvatar(child: Icon(Icons.person)),
                    title: Text(userName),
                    subtitle: Text(
                      chatRoom['last_message'] ?? 'Start chatting',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: chatRoom['last_message_time'] != null
                        ? Text(_formatDate(chatRoom['last_message_time'].toDate()))
                        : null,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ChatScreen(
                            currentUserId: currentUserId,
                            otherUserId: otherUserId,
                            otherUserName: userName,
                          ),
                        ),
                      );
                    },
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