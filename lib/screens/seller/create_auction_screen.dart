import 'package:flutter/material.dart';
import '../../models/user_model.dart';

class CreateAuctionScreen extends StatefulWidget {
  final UserModel user;
  
  const CreateAuctionScreen({
    Key? key,
    required this.user,
  }) : super(key: key);

  @override
  State<CreateAuctionScreen> createState() => _CreateAuctionScreenState();
}

class _CreateAuctionScreenState extends State<CreateAuctionScreen> {
  // This is a placeholder for the future implementation
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Auction'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: const Center(
        child: Text('Auction creation functionality coming soon'),
      ),
    );
  }
} 