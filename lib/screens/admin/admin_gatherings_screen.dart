import 'package:flutter/material.dart';
import '../../models/user_model.dart';

class AdminGatheringsScreen extends StatefulWidget {
  final UserModel user;
  
  const AdminGatheringsScreen({super.key, required this.user});

  @override
  State<AdminGatheringsScreen> createState() => _AdminGatheringsScreenState();
}

class _AdminGatheringsScreenState extends State<AdminGatheringsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gatherings'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.event,
              size: 80,
              color: Colors.deepPurple.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            const Text(
              'Gatherings Feature Coming Soon',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                'This feature will allow you to create and manage collector gatherings and events.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('This feature is not yet implemented'),
                  ),
                );
              },
              icon: const Icon(Icons.notifications_active),
              label: const Text('Get Notified When Available'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 