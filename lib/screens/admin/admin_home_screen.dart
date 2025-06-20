import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../models/user_model.dart';

class AdminHomeScreen extends StatefulWidget {
  final UserModel user;
  
  const AdminHomeScreen({super.key, required this.user});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  final AuthService _auth = AuthService();
  
  // Sample data
  final List<Map<String, dynamic>> _recentUsers = [
    {
      'name': 'User 1',
      'email': 'user1@example.com',
      'joined': '2 days ago',
    },
    {
      'name': 'User 2',
      'email': 'user2@example.com',
      'joined': '5 days ago',
    },
    {
      'name': 'User 3',
      'email': 'user3@example.com',
      'joined': '1 week ago',
    },
  ];
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await _auth.signOut();
            },
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Admin header info
            Row(
              children: [
                const CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.deepPurple,
                  child: Icon(Icons.admin_panel_settings, size: 30, color: Colors.white),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome, Admin',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      widget.user.email,
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ],
            ),
            
            const Divider(height: 40),
            
            // Dashboard stats
            const Text(
              'Dashboard Overview',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(child: _buildStatCard('Total Users', '124', Icons.people, Colors.blue)),
                const SizedBox(width: 16),
                Expanded(child: _buildStatCard('Collections', '48', Icons.collections, Colors.green)),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _buildStatCard('Items', '1,205', Icons.category, Colors.orange)),
                const SizedBox(width: 16),
                Expanded(child: _buildStatCard('Reports', '5', Icons.flag, Colors.red)),
              ],
            ),
            
            const Divider(height: 40),
            
            // Recent users
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Recent Users',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    // View all users
                  },
                  child: const Text('View All'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // User list
            ..._recentUsers.map((user) => _buildUserListItem(user)),
            
            const Divider(height: 40),
            
            // Action buttons
            ElevatedButton.icon(
              onPressed: () {
                // Implement manage collections
              },
              icon: const Icon(Icons.collections),
              label: const Text('Manage Collections'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                minimumSize: const Size(double.infinity, 50),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                // Implement user management
              },
              icon: const Icon(Icons.people),
              label: const Text('Manage Users'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                minimumSize: const Size(double.infinity, 50),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withAlpha(77), // 0.3 * 255 ≈ 77
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 24, color: color),
            const SizedBox(height: 12),
            Text(
              value,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildUserListItem(Map<String, dynamic> user) {
    return ListTile(
      leading: const CircleAvatar(
        backgroundColor: Colors.deepPurple,
        child: Icon(Icons.person, color: Colors.white),
      ),
      title: Text(user['name']),
      subtitle: Text(user['email']),
      trailing: Text(user['joined']),
      onTap: () {
        // View user details
      },
    );
  }
} 