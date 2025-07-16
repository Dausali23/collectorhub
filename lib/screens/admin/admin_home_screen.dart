import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/auth_service.dart';
import '../../models/user_model.dart';
import 'admin_main_screen.dart'; // Added import for AdminMainScreen

class AdminHomeScreen extends StatefulWidget {
  final UserModel user;
  
  const AdminHomeScreen({super.key, required this.user});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuthService _auth = AuthService();
  
  // Statistics
  int _totalUsers = 0;
  int _totalBuyers = 0;
  int _totalSellers = 0;
  int _totalItems = 0;
  int _totalAuctions = 0;
  int _totalEvents = 0;
  bool _isLoading = true;
  
  // Sample data for recent users
  final List<Map<String, dynamic>> _recentUsers = [];
  
  @override
  void initState() {
    super.initState();
    _loadStatistics();
  }
  
  Future<void> _loadStatistics() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Get user counts
      final usersQuery = await _firestore.collection('users').get();
      _totalUsers = usersQuery.docs.length;
      
      _totalBuyers = usersQuery.docs.where((doc) {
        final data = doc.data();
        return data['role'] == 'buyer';
      }).length;
      
      _totalSellers = usersQuery.docs.where((doc) {
        final data = doc.data();
        return data['role'] == 'seller';
      }).length;
      
      // Get items count
      final itemsQuery = await _firestore.collection('listings')
          .where('isFixedPrice', isEqualTo: true)
          .get();
      _totalItems = itemsQuery.docs.length;
      
      // Get auctions count
      final auctionsQuery = await _firestore.collection('listings')
          .where('isFixedPrice', isEqualTo: false)
          .get();
      _totalAuctions = auctionsQuery.docs.length;
      
      // Get total events count
      final eventsQuery = await _firestore.collection('events').get();
      _totalEvents = eventsQuery.docs.length;
      
      // Get recent users
      final recentUsersQuery = await _firestore.collection('users')
          .orderBy('createdAt', descending: true)
          .limit(5)
          .get();
      
      final List<Map<String, dynamic>> loadedUsers = [];
      
      for (var doc in recentUsersQuery.docs) {
        final data = doc.data();
        
        // Skip the current admin user
        if (doc.id == widget.user.uid) continue;
        
        final createdAt = data['createdAt'] as Timestamp?;
        String joinedDate = 'Unknown date';
        
        if (createdAt != null) {
          final now = DateTime.now();
          final joinDate = createdAt.toDate();
          final difference = now.difference(joinDate);
          
          if (difference.inDays > 0) {
            joinedDate = '${difference.inDays} ${difference.inDays == 1 ? 'day' : 'days'} ago';
          } else if (difference.inHours > 0) {
            joinedDate = '${difference.inHours} ${difference.inHours == 1 ? 'hour' : 'hours'} ago';
          } else {
            joinedDate = '${difference.inMinutes} ${difference.inMinutes == 1 ? 'minute' : 'minutes'} ago';
          }
        }
        
        loadedUsers.add({
          'name': data['displayName'] ?? 'Unknown',
          'email': data['email'] ?? 'No email',
          'joined': joinedDate,
          'role': data['role'] ?? 'buyer',
        });
      }
      
      setState(() {
        _recentUsers.clear();
        _recentUsers.addAll(loadedUsers);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading statistics: $e')),
      );
    }
  }
  
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadStatistics,
              child: SingleChildScrollView(
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
                    
                    // Users statistics
                    _buildSectionTitle('Users'),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(child: _buildStatCard('Total Users', _totalUsers.toString(), Icons.people, Colors.blue)),
                        const SizedBox(width: 16),
                        Expanded(child: _buildStatCard('Buyers', _totalBuyers.toString(), Icons.shopping_cart, Colors.green)),
                        const SizedBox(width: 16),
                        Expanded(child: _buildStatCard('Sellers', _totalSellers.toString(), Icons.store, Colors.orange)),
                      ],
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Items & Activities statistics
                    _buildSectionTitle('Content'),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(child: _buildStatCard('Items', _totalItems.toString(), Icons.category, Colors.purple)),
                        const SizedBox(width: 16),
                        Expanded(child: _buildStatCard('Auctions', _totalAuctions.toString(), Icons.gavel, Colors.red)),
                        const SizedBox(width: 16),
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              // Navigate to events screen when tapped
                              Navigator.of(context).pushReplacement(
                                MaterialPageRoute(
                                  builder: (_) => AdminMainScreen(
                                    user: widget.user,
                                    initialIndex: 2, // Events tab index
                                  ),
                                ),
                              );
                            },
                            child: _buildStatCard('Events', _totalEvents.toString(), Icons.event, Colors.teal),
                          ),
                        ),
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
                        TextButton.icon(
                          onPressed: () {
                            // Switch to manage users tab
                            // This will be handled by bottom navigation now
                          },
                          icon: const Icon(Icons.people),
                          label: const Text('View All'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    // User list
                    if (_recentUsers.isEmpty)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Text('No recent users found'),
                        ),
                      )
                    else
                      ...(_recentUsers.map((user) => _buildUserListItem(user))),
                  ],
                ),
              ),
            ),
    );
  }
  
  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: Colors.grey,
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
            color: Colors.grey.withOpacity(0.3),
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
    final String role = user['role'] ?? 'buyer';
    final Color roleColor = _getRoleColor(role);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: roleColor.withOpacity(0.2),
          child: Icon(Icons.person, color: roleColor),
        ),
        title: Text(user['name']),
        subtitle: Text(user['email']),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              user['joined'],
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: roleColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                role.toUpperCase(),
                style: TextStyle(
                  color: roleColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 10,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Color _getRoleColor(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return Colors.red;
      case 'seller':
        return Colors.blue;
      case 'buyer':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
} 