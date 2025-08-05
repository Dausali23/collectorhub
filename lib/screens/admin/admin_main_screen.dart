import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import 'admin_home_screen.dart';
import 'admin_manage_screen.dart';
import 'admin_events_screen.dart';

class AdminMainScreen extends StatefulWidget {
  final UserModel user;
  final int initialIndex;
  
  const AdminMainScreen({
    super.key, 
    required this.user, 
    this.initialIndex = 0,
  });

  @override
  State<AdminMainScreen> createState() => _AdminMainScreenState();
}

class _AdminMainScreenState extends State<AdminMainScreen> {
  late int _currentIndex;
  late List<Widget> _screens;
  
  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _screens = [
      AdminHomeScreen(user: widget.user),
      AdminManageScreen(user: widget.user),
      AdminEventsScreen(user: widget.user),
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
        backgroundColor: Colors.deepPurple,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white70,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.manage_accounts),
            label: 'Manage',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.event),
            label: 'Events',
          ),
        ],
      ),
    );
  }
} 