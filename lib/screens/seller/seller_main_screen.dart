import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import 'seller_dashboard.dart';
import 'account_screen.dart';

class SellerMainScreen extends StatefulWidget {
  final UserModel user;
  
  const SellerMainScreen({super.key, required this.user});

  @override
  State<SellerMainScreen> createState() => _SellerMainScreenState();
}

class _SellerMainScreenState extends State<SellerMainScreen> {
  int _selectedIndex = 0;
  
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
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
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
      case 0:
        return const SellerDashboard();
      case 1:
        return _placeholderPage('Messages');
      case 2:
        return _profilePage();
      default:
        return const SellerDashboard();
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