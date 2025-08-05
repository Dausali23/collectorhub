import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:developer' as developer;

class ChatMessage {
  final String id;
  final String senderId;
  final String receiverId;
  final String content;
  final DateTime timestamp;
  final bool isRead;

  ChatMessage({
    required this.id,
    required this.senderId,
    required this.receiverId, 
    required this.content,
    required this.timestamp,
    this.isRead = false,
  });

  factory ChatMessage.fromMap(Map<String, dynamic> data, String id) {
    return ChatMessage(
      id: id,
      senderId: data['senderId'],
      receiverId: data['receiverId'],
      content: data['content'],
      timestamp: data['timestamp'].toDate(),
      isRead: data['isRead'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'receiverId': receiverId,
      'content': content,
      'timestamp': timestamp,
      'isRead': isRead,
    };
  }
}

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Create or get chat room between two users
  Future<String> createChatRoom(String userId1, String userId2) async {
    try {
      developer.log('Creating chat room between $userId1 and $userId2');
      
      // Validate user IDs
      if (userId1.isEmpty || userId2.isEmpty) {
        throw Exception('Invalid user IDs');
      }
      
      // Sort IDs to ensure consistency
      final sortedIds = [userId1, userId2]..sort();
      final chatRoomId = '${sortedIds[0]}_${sortedIds[1]}';
      
      developer.log('Generated chat room ID: $chatRoomId');
      
      // SIMPLIFIED APPROACH: Just return the chat room ID without creating anything
      // The ChatUI will handle creating messages directly
      return chatRoomId;
    } catch (e) {
      developer.log('Error in createChatRoom: $e');
      throw Exception('Failed to create chat room: $e');
    }
  }

  // Send message - original version for compatibility
  Future<void> sendMessage(String chatRoomId, ChatMessage message) async {
    try {
      await _firestore
          .collection('chat_rooms')
          .doc(chatRoomId)
          .collection('messages')
          .add(message.toMap());
          
      // Update chat room with last message info
      await _firestore.collection('chat_rooms').doc(chatRoomId).update({
        'last_message': message.content,
        'last_message_time': message.timestamp,
      });
    } catch (e) {
      developer.log('Error in sendMessage: $e');
      throw Exception('Failed to send message: $e');
    }
  }
  
  // New version with expanded parameters
  Future<void> sendMessageDirect(String chatRoomId, String senderId, String receiverId, String content) async {
    try {
      developer.log('Sending message in chat room: $chatRoomId');
      developer.log('From: $senderId, To: $receiverId');
      
      final messageData = {
        'senderId': senderId,
        'receiverId': receiverId,
        'content': content,
        'timestamp': FieldValue.serverTimestamp(),
        'isRead': false,
      };
      
      // First check if the chat room document exists
      final chatRoomRef = _firestore.collection('chat_rooms').doc(chatRoomId);
      final chatRoomDoc = await chatRoomRef.get();
      
      if (!chatRoomDoc.exists) {
        developer.log('Chat room document does not exist, creating it');
        // Create the chat room document first
        await chatRoomRef.set({
          'participants': [senderId, receiverId],
          'created_at': FieldValue.serverTimestamp(),
          'last_message': content,
          'last_message_time': FieldValue.serverTimestamp(),
        });
      }
      
      // Add the message to the messages subcollection
      await _firestore
          .collection('chat_rooms')
          .doc(chatRoomId)
          .collection('messages')
          .add(messageData);
          
      // Update chat room with last message info
      await _firestore.collection('chat_rooms').doc(chatRoomId).update({
        'participants': [senderId, receiverId], // Ensure participants are set
        'last_message': content,
        'last_message_time': FieldValue.serverTimestamp(),
      });
      
      developer.log('Message sent successfully');
    } catch (e) {
      developer.log('Error in sendMessageDirect: $e');
      throw Exception('Failed to send message: $e');
    }
  }

  // Get messages stream - returns QuerySnapshot
  Stream<QuerySnapshot> getMessagesRaw(String chatRoomId) {
    return _firestore
        .collection('chat_rooms')
        .doc(chatRoomId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }
  
  // Get messages stream - returns processed ChatMessage objects
  Stream<List<ChatMessage>> getMessages(String chatRoomId) {
    return _firestore
        .collection('chat_rooms')
        .doc(chatRoomId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return ChatMessage.fromMap(doc.data(), doc.id);
          }).toList();
        });
  }

  // Get chat rooms for a user
  Stream<QuerySnapshot> getChatRooms(String userId) {
    // Simplified query that doesn't require a composite index
    return _firestore
        .collection('chat_rooms')
        .where('participants', arrayContains: userId)
        .snapshots();
  }

  // Mark messages as read
  Future<void> markAsRead(String chatRoomId, String currentUserId) async {
    try {
      final messagesQuery = await _firestore
          .collection('chat_rooms')
          .doc(chatRoomId)
          .collection('messages')
          .where('receiverId', isEqualTo: currentUserId)
          .where('isRead', isEqualTo: false)
          .get();

      final batch = _firestore.batch();
      for (var doc in messagesQuery.docs) {
        batch.update(doc.reference, {'isRead': true});
      }
      
      await batch.commit();
    } catch (e) {
      developer.log('Error in markAsRead: $e');
    }
  }
} 