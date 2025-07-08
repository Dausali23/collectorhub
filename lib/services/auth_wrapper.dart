import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:developer' as developer;
import '../models/user_model.dart';
import '../screens/admin/auth/auth_screen.dart';
import '../screens/buyer/buyer_main_screen.dart';
import '../screens/seller/seller_main_screen.dart';
import '../screens/admin/admin_main_screen.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});
  
  @override
  Widget build(BuildContext context) {
    final user = Provider.of<UserModel?>(context);
    
    // Return Auth screen if user is not logged in
    if (user == null) {
      developer.log('User is null, returning to AuthScreen');
      return const AuthScreen();
    } 
    
    // Log the user role for debugging
    developer.log('AuthWrapper: User role is ${user.role}');
    
    // Determine which screen to show based on role
    Widget homeScreen;
    
    // Route based on user role
    switch (user.role) {
      case UserRole.admin:
        developer.log('Navigating to AdminMainScreen');
        homeScreen = AdminMainScreen(user: user);
        break;
      case UserRole.seller:
        developer.log('Navigating to SellerMainScreen');
        homeScreen = SellerMainScreen(user: user);
        break;
      case UserRole.buyer:
        developer.log('Navigating to BuyerMainScreen');
        homeScreen = BuyerMainScreen(user: user);
        break;
    }
    
    return homeScreen;
  }
} 