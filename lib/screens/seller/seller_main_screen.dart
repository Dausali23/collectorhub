import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import 'seller_dashboard.dart';
import 'account_screen.dart';
import 'seller_collectibles_screen.dart';
import 'seller_events_screen.dart';

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
  late int _selectedIndex;
  
  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _getPage(_selectedIndex),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: Colors.grey,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
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
            icon: Icon(Icons.chat),
            label: 'Messages',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_circle),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
  
  Widget _getPage(int index) {
    switch (index) {
      case 0: // Dashboard with orders
        return SellerDashboard(user: widget.user);
      case 1: // Collectibles 
        return SellerCollectiblesScreen(user: widget.user);
      case 2: // Events
        return SellerEventsScreen(user: widget.user);
      case 3: // Messages
        return _placeholderPage('Messages');
      case 4: // Profile
        return _profilePage();
      default:
        return SellerDashboard(user: widget.user);
    }
  }
  
  Widget _placeholderPage(String title) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          const Text('This feature is coming soon!'),
        ],
      ),
    );
  }
  
  Widget _profilePage() {
    return AccountScreen(user: widget.user);
  }
} 