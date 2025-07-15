import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import './buyer_home_screen.dart';
import './shop_screen.dart';
import './activity_screen.dart';
import './account_screen.dart';
import './buyer_events_screen.dart';

class BuyerMainScreen extends StatefulWidget {
  final UserModel user;
  
  const BuyerMainScreen({super.key, required this.user});

  @override
  State<BuyerMainScreen> createState() => _BuyerMainScreenState();
}

class _BuyerMainScreenState extends State<BuyerMainScreen> {
  int _currentIndex = 0;
  late List<Widget> _screens;
  
  @override
  void initState() {
    super.initState();
    _screens = [
      BuyerHomeScreen(user: widget.user),
      ShopScreen(user: widget.user),
      BuyerEventsScreen(user: widget.user),
      ActivityScreen(user: widget.user),
      AccountScreen(user: widget.user),
    ];
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.black87,
          border: Border(
            top: BorderSide(
              color: Colors.grey.shade800,
              width: 0.5,
            ),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.black87,
          selectedItemColor: Colors.white,
          unselectedItemColor: Colors.grey,
          showSelectedLabels: true,
          showUnselectedLabels: true,
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
              icon: Icon(Icons.event),
              label: 'Events',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.notifications_outlined),
              label: 'Activity',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              label: 'Account',
            ),
          ],
        ),
      ),
    );
  }
} 