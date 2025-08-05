# Chat Feature Implementation

This document explains how to use the chat functionality in your CollectorHub app.

## Components Added

1. `ChatService`: A service class that interacts with Firestore to manage chat functionality.
2. `ChatUI`: A reusable UI widget that provides the chat interface.
3. `ChatScreen`: A screen that displays a chat conversation.
4. `ChatListScreen`: A screen that shows a list of all active conversations.
5. `ChatButton`: A button widget that can be added to any screen to initiate a chat.

## How to Use

### 1. Add a Chat Button to Any Screen

To add a "Chat with User" button to any screen (like a product detail page):

```dart
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/chat_button.dart';

// Inside your build method
final currentUser = FirebaseAuth.instance.currentUser;
if (currentUser != null) {
  ChatButton(
    currentUserId: currentUser.uid,
    otherUserId: sellerUserId, // The ID of the user to chat with
    otherUserName: sellerName, // The name of the user to chat with
  ),
}
```

### 2. Add Chat List to Navigation

To add a chat/messages tab to your bottom navigation:

```dart
// In your main navigation screen
class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  late List<Widget> _screens;
  
  @override
  void initState() {
    super.initState();
    final currentUser = FirebaseAuth.instance.currentUser;
    _screens = [
      HomeScreen(),
      ExploreScreen(),
      // Add the chat list screen
      currentUser != null
          ? ChatListScreen(currentUserId: currentUser.uid)
          : LoginScreen(), // Handle case when user is not logged in
      ProfileScreen(),
    ];
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Explore'),
          BottomNavigationBarItem(icon: Icon(Icons.chat), label: 'Messages'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}
```

### 3. Firestore Structure

The chat feature uses the following Firestore structure:

- `chat_rooms` collection
  - Each document is a chat room with ID: `user1Id_user2Id` (sorted alphabetically)
  - Fields:
    - `participants`: Array of user IDs
    - `created_at`: Timestamp
    - `last_message`: String (content of last message)
    - `last_message_time`: Timestamp
  - `messages` subcollection
    - Each document is a message
    - Fields:
      - `senderId`: User ID of sender
      - `receiverId`: User ID of receiver
      - `content`: Message text
      - `timestamp`: Timestamp
      - `isRead`: Boolean

### 4. Customization

You can customize the appearance of the chat UI by modifying the `ChatUI` widget in `lib/widgets/chat_ui.dart`.

## Security Rules

Recommended Firestore security rules for your chat functionality:

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Chat rooms - accessible by participants only
    match /chat_rooms/{chatRoomId} {
      allow read, write: if request.auth != null && 
        request.auth.uid in resource.data.participants;
      
      // Messages in chat rooms
      match /messages/{messageId} {
        allow read, write: if request.auth != null && 
          request.auth.uid in get(/databases/$(database)/documents/chat_rooms/$(chatRoomId)).data.participants;
      }
    }
  }
}
```

## Next Steps

To enhance your chat functionality, consider adding:

1. Push notifications for new messages
2. "Typing..." indicators
3. Read receipts
4. Image/file sharing
5. Message status indicators (sent/delivered) 