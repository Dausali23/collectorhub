import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';

class AccountScreen extends StatefulWidget {
  final UserModel user;
  
  const AccountScreen({super.key, required this.user});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  final AuthService _auth = AuthService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black87,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('Account'),
        centerTitle: true,
        elevation: 0,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User profile header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.deepPurple,
                    backgroundImage: widget.user.photoUrl != null
                        ? NetworkImage(widget.user.photoUrl!)
                        : null,
                    child: widget.user.photoUrl == null
                        ? const Icon(Icons.person, size: 30, color: Colors.white)
                        : null,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Hi, ${widget.user.displayName ?? widget.user.email.split('@')[0]}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const CircleAvatar(
                              radius: 10,
                              backgroundColor: Colors.amber,
                              child: Icon(Icons.person, size: 10, color: Colors.white),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '2 Followers',
                              style: TextStyle(
                                color: Colors.grey.shade400,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right, color: Colors.white),
                    onPressed: () {},
                  ),
                ],
              ),
            ),
            
            // Invite friends card
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.deepPurple,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(51),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.card_giftcard,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Invite Your Friends',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          'Earn credits when they sign up and make a purchase',
                          style: TextStyle(
                            color: Colors.white.withAlpha(204),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            // Seller Dashboard section
            _buildSectionHeader('Seller Dashboard'),
            _buildLinkItem(
              icon: Icons.store,
              title: 'Become a Seller',
              onTap: () {},
            ),
            
            // Account section
            _buildSectionHeader('Account'),
            _buildLinkItem(
              icon: Icons.credit_card,
              title: 'Payment Methods',
              onTap: () {},
            ),
            _buildLinkItem(
              icon: Icons.local_shipping,
              title: 'Delivery Address',
              onTap: () {},
            ),
            _buildLinkItem(
              icon: Icons.redeem,
              title: 'Redeem Code',
              onTap: () {},
            ),
            _buildLinkItem(
              icon: Icons.login,
              title: 'Account Login',
              onTap: () {},
            ),
            _buildLinkItem(
              icon: Icons.block,
              title: 'Blocked Users',
              onTap: () {},
            ),
            _buildLinkItem(
              icon: Icons.logout,
              title: 'Logout',
              onTap: () async {
                await _auth.signOut();
              },
            ),
            
            // Settings section
            _buildSectionHeader('Settings'),
            _buildLinkItem(
              icon: Icons.settings,
              title: 'App Settings',
              onTap: () {},
            ),
            
            // Support section
            _buildSectionHeader('Support'),
            _buildLinkItem(
              icon: Icons.help_outline,
              title: 'Help Center',
              onTap: () {},
            ),
            _buildLinkItem(
              icon: Icons.support_agent,
              title: 'Contact Support',
              onTap: () {},
            ),
            _buildLinkItem(
              icon: Icons.feedback,
              title: 'Send Feedback',
              onTap: () {},
            ),
            
            // App info
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Text(
                  'Version 1.0.0',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 16, top: 20, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
  
  Widget _buildLinkItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Widget? trailing,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: Colors.grey.shade800,
              width: 1,
            ),
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
            ),
            trailing ?? const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }
} 