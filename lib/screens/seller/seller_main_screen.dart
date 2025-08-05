import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import 'seller_dashboard.dart';
import 'seller_collectibles_screen.dart';
import 'seller_events_screen.dart';
import 'account_screen.dart';
import '../chat/chat_list_screen.dart';

class SellerMainScreen extends StatefulWidget {
  final UserModel user;
  final int initialIndex;
  
  const SellerMainScreen({
    super.key, 
    required this.user,
    this.initialIndex = 0,
  });

  @override
  State<SellerMainScreen> createState() => _SellerMainScreenState();
}

class _SellerMainScreenState extends State<SellerMainScreen> {
  int _selectedIndex = 0;
  late List<Widget> _screens;
  
  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
    _screens = [
      SellerDashboard(user: widget.user),
      SellerCollectiblesScreen(user: widget.user),
      SellerEventsScreen(user: widget.user),
      ChatListScreen(currentUserId: widget.user.uid),
      AccountScreen(user: widget.user),
    ];
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.deepPurple,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.collections),
            label: 'Collectibles',
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