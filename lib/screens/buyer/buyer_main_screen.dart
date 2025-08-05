import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import 'buyer_home_screen.dart';
import 'shop_screen.dart';
import '../chat/chat_list_screen.dart';
import 'buyer_events_screen.dart';
import 'account_screen.dart';
import 'activity_screen.dart';

class BuyerMainScreen extends StatefulWidget {
  final UserModel user;
  final int initialIndex;
  
  const BuyerMainScreen({
    super.key, 
    required this.user, 
    this.initialIndex = 0,
  });

  @override
  State<BuyerMainScreen> createState() => _BuyerMainScreenState();
}

class _BuyerMainScreenState extends State<BuyerMainScreen> {
  late int _currentIndex;
  late List<Widget> _screens;
  
  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _screens = [
      BuyerHomeScreen(user: widget.user),
      ShopScreen(user: widget.user),
      ActivityScreen(user: widget.user),
      BuyerEventsScreen(user: widget.user),
      ChatListScreen(currentUserId: widget.user.uid),
      AccountScreen(user: widget.user),
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
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: Colors.deepPurple,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_bag),
            label: 'Shop',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications),
            label: 'Activity',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.event),
            label: 'Events',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.message),
            label: 'Messages',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
} 