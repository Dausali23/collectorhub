import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import 'orders_screen.dart';
import 'seller_events_screen.dart';
import '../chat/chat_list_screen.dart';

class ActivityScreen extends StatefulWidget {
  final UserModel user;
  
  const ActivityScreen({super.key, required this.user});

  @override
  State<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends State<ActivityScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black87,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('Activity'),
        centerTitle: true,
        elevation: 0,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Orders section
            _buildSection(
              title: 'Orders',
              subtitle: 'Your order status and history',
              icon: Icons.receipt_long,
              iconColor: Colors.blue,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => OrdersScreen(user: widget.user),
                  ),
                );
              },
              hasSubItems: true,
              subItems: [
                _buildOrderStatusItem(
                  title: 'To Pay',
                  icon: Icons.payment,
                  count: 0,
                ),
                _buildOrderStatusItem(
                  title: 'To Ship',
                  icon: Icons.inventory_2,
                  count: 0,
                ),
                _buildOrderStatusItem(
                  title: 'To Receive',
                  icon: Icons.local_shipping,
                  count: 0,
                ),
                _buildOrderStatusItem(
                  title: 'Completed',
                  icon: Icons.check_circle_outline,
                  count: 0,
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Messages section
            _buildSection(
              title: 'Messages',
              subtitle: 'Your chat messages with sellers',
              icon: Icons.message,
              iconColor: Colors.blue,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ChatListScreen(
                      currentUserId: widget.user.uid,
                    ),
                  ),
                );
              },
            ),
            
            const SizedBox(height: 16),
            
            // Events section
            _buildSection(
              title: 'Events',
              subtitle: 'Upcoming and past events',
              icon: Icons.event,
              iconColor: Colors.pink,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SellerEventsScreen(user: widget.user),
                  ),
                );
              },
            ),
            
            const SizedBox(height: 24),
            
            // Overview Updates section
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Overview Updates',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            
            // Empty state
            SizedBox(
              width: double.infinity,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade800.withAlpha(128),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.notifications_none,
                      size: 48,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Nothing Here - Yet!',
                    style: TextStyle(
                      color: Colors.grey.shade400,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSection({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required VoidCallback onTap,
    bool hasSubItems = false,
    List<Widget> subItems = const [],
  }) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: iconColor.withAlpha(51), // 0.2 * 255 ≈ 51
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: iconColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: Colors.grey.shade400,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right,
                  color: Colors.grey,
                ),
              ],
            ),
          ),
        ),
        
        if (hasSubItems) ...[
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: subItems,
            ),
          ),
        ],
        
        const Divider(color: Colors.grey),
      ],
    );
  }
  
  Widget _buildOrderStatusItem({
    required String title,
    required IconData icon,
    required int count,
  }) {
    return Expanded(
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.grey.shade800,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              color: Colors.grey.shade300,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
} 