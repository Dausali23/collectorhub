import 'package:flutter/material.dart';
import 'dart:developer' as developer;
import '../../models/user_model.dart';
import '../../models/listing_model.dart';
import '../../models/purchase_model.dart';
import '../../services/auth_service.dart';
import '../edit_profile_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AccountScreen extends StatefulWidget {
  final UserModel user;
  
  const AccountScreen({super.key, required this.user});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  final AuthService _auth = AuthService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isLoading = false;
  UserModel? _refreshedUser;
  
  @override
  void initState() {
    super.initState();
    // Load the most current user data
    _refreshUserData();
  }
  
  Future<void> _refreshUserData() async {
    try {
      // Get fresh user data from Firestore
      final userDoc = await _firestore.collection('users').doc(widget.user.uid).get();
      
      if (userDoc.exists && mounted) {
        final userData = userDoc.data() as Map<String, dynamic>;
        setState(() {
          _refreshedUser = UserModel(
            uid: widget.user.uid,
            email: widget.user.email,
            role: widget.user.role,
            displayName: userData['displayName'] ?? widget.user.displayName,
            phoneNumber: userData['phoneNumber'], // Get the phone number directly from Firestore
            photoUrl: widget.user.photoUrl,
          );
        });
      }
    } catch (e) {
      // If there's an error, we'll use the original user model
      developer.log('Error refreshing user data: $e');
    }
  }

  void _navigateToEditProfile() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditProfileScreen(user: _refreshedUser ?? widget.user),
      ),
    );
    
    if (result == true) {
      // If profile was updated, refresh the UI
      _refreshUserData();
    }
  }

  Future<void> _logout() async {
    setState(() {
      _isLoading = true;
    });
    
      try {
    await _auth.signOut();
  } catch (e) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error signing out: $e')),
      );
    }
  } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Use the refreshed user data if available, otherwise use the original
    final UserModel userToDisplay = _refreshedUser ?? widget.user;
    
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('Seller Profile'),
        centerTitle: true,
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Profile header with edit button
              Container(
                padding: const EdgeInsets.all(24),
                decoration: const BoxDecoration(
                  color: Colors.deepPurple,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(30),
                    bottomRight: Radius.circular(30),
                  ),
                ),
                child: Column(
                  children: [
                    // Profile picture
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.white,
                      backgroundImage: userToDisplay.photoUrl != null
                          ? NetworkImage(userToDisplay.photoUrl!)
                          : null,
                      child: userToDisplay.photoUrl == null
                          ? const Icon(Icons.person, size: 50, color: Colors.grey)
                          : null,
                    ),
                    const SizedBox(height: 12),
                    
                    // User name
                    Text(
                      userToDisplay.displayName ?? 'Collector',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    
                    // User email
                    Text(
                      userToDisplay.email,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white.withAlpha(200),
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Edit profile button
                    ElevatedButton.icon(
                      onPressed: _navigateToEditProfile,
                      icon: const Icon(Icons.edit, size: 16),
                      label: const Text('Edit Profile'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.deepPurple,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Seller stats card
              _buildCard(
                title: 'Seller Dashboard',
                children: [
                  _buildStatsRow(),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Account details card
              _buildCard(
                title: 'Account Details',
                children: [
                  _buildDetailItem(
                    icon: Icons.phone,
                    title: 'Phone',
                    value: userToDisplay.phoneNumber ?? 'Not set',
                  ),
                  _buildDetailItem(
                    icon: Icons.person,
                    title: 'Role',
                    value: userToDisplay.role.toString().split('.').last.toUpperCase(),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Logout button
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _logout,
                  icon: const Icon(Icons.logout),
                  label: const Text('Logout'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade300,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 32),
              
              // App version
              Center(
                child: Text(
                  'CollectorHub v1.0.0',
                  style: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: 12,
                  ),
                ),
              ),
              
              const SizedBox(height: 32),
            ],
          ),
        ),
    );
  }
  
  Widget _buildStatsRow() {
    // Get the current user to display
    final UserModel user = _refreshedUser ?? widget.user;
    
    return StreamBuilder<List<ListingModel>>(
      stream: _firestore.collection('listings')
          .where('sellerId', isEqualTo: user.uid)
          .where('isAvailable', isEqualTo: true)
          .snapshots()
          .map((snapshot) => snapshot.docs
              .map((doc) => ListingModel.fromFirestore(doc))
              .toList()),
      builder: (context, listingsSnapshot) {
        // Handle loading state
        if (listingsSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        // Get the listings that are available
        final allListings = listingsSnapshot.data ?? [];
        
        // Filter fixed price listings and auctions with null safety
        final fixedPriceListings = allListings
            .where((listing) => listing.isFixedPrice == true)
            .toList();
        final auctions = allListings
            .where((listing) => listing.isFixedPrice == false)
            .toList();
        
        // Fetch completed sales
        return StreamBuilder<List<PurchaseModel>>(
          stream: _firestore.collection('purchases')
              .where('sellerId', isEqualTo: user.uid)
              .where('status', isEqualTo: PurchaseModel.statusToString(PurchaseStatus.completed))
              .snapshots()
              .map((snapshot) => snapshot.docs
                  .map((doc) => PurchaseModel.fromFirestore(doc))
                  .toList()),
          builder: (context, salesSnapshot) {
            // Handle loading state for sales
            if (salesSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            
            final completedSales = salesSnapshot.data ?? [];
            
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildStatItem(
                    value: fixedPriceListings.length.toString(),
                    label: 'Active Listings',
                    iconData: Icons.local_offer,
                    color: Colors.blue,
                  ),
                  _buildStatItem(
                    value: auctions.length.toString(),
                    label: 'Auctions',
                    iconData: Icons.gavel,
                    color: Colors.orange,
                  ),
                  _buildStatItem(
                    value: completedSales.length.toString(),
                    label: 'Sales',
                    iconData: Icons.shopping_cart,
                    color: Colors.green,
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
  
  Widget _buildStatItem({
    required String value,
    required String label,
    required IconData iconData,
    required Color color,
  }) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withAlpha(30),
            shape: BoxShape.circle,
          ),
          child: Icon(
            iconData,
            color: color,
            size: 24,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }
  
  Widget _buildCard({required String title, required List<Widget> children}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade300,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }
  
  Widget _buildDetailItem({
    required IconData icon, 
    required String title, 
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.deepPurple.shade50,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: Colors.deepPurple,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
} 