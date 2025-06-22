import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../models/purchase_model.dart';
import '../../services/cart_service.dart';

class ActivityScreen extends StatefulWidget {
  final UserModel user;
  
  const ActivityScreen({super.key, required this.user});

  @override
  State<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends State<ActivityScreen> {
  final CartService _cartService = CartService();
  
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
              onTap: () => _navigateToOrderHistory(),
              hasSubItems: true,
              subItems: [
                _buildOrderStatusItem(
                  title: 'To Pay',
                  icon: Icons.payment,
                  count: 0,
                  onTap: () => _navigateToOrderHistory(filter: 'pending'),
                ),
                _buildOrderStatusItem(
                  title: 'Completed',
                  icon: Icons.check_circle_outline,
                  count: 0,
                  onTap: () => _navigateToOrderHistory(filter: 'completed'),
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
              onTap: () => _navigateToChats(),
            ),
            
            const SizedBox(height: 16),
            
            // Auctions section
            _buildSection(
              title: 'Auctions',
              subtitle: 'Your active, watched and past auctions',
              icon: Icons.gavel,
              iconColor: Colors.pink,
              onTap: () => _navigateToAuctions(),
            ),
            
            const SizedBox(height: 16),
            
            // Wishlist section
            _buildSection(
              title: 'Wishlist',
              subtitle: 'Your likes, favourites items and saved searches',
              icon: Icons.favorite,
              iconColor: Colors.red,
              onTap: () => _navigateToWishlist(),
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
            
            // Updates - Connect to Firebase
            StreamBuilder<List<PurchaseModel>>(
              stream: _cartService.getBuyerPurchases(widget.user.uid),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }
                
                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Error loading purchases: ${snapshot.error}',
                      style: TextStyle(color: Colors.red),
                    ),
                  );
                }
                
                final purchases = snapshot.data ?? [];
                
                if (purchases.isEmpty) {
                  // Empty state
                  return SizedBox(
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
                          'No Recent Activities',
                          style: TextStyle(
                            color: Colors.grey.shade400,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Your purchase history will appear here',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 40),
                      ],
                    ),
                  );
                }
                
                // Show the most recent 3 purchases
                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: purchases.length > 3 ? 3 : purchases.length,
                  itemBuilder: (context, index) {
                    final purchase = purchases[index];
                    return _buildPurchaseItem(purchase);
                  },
                );
              },
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
                    color: iconColor.withAlpha(51),
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
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
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
      ),
    );
  }
  
  Widget _buildPurchaseItem(PurchaseModel purchase) {
    // Get status color
    Color statusColor;
    String statusText;
    
    switch(purchase.status) {
      case PurchaseStatus.pending:
        statusColor = Colors.amber;
        statusText = 'Awaiting Payment';
        break;
      case PurchaseStatus.claimed:
        statusColor = Colors.blue;
        statusText = 'Payment Claimed';
        break;
      case PurchaseStatus.confirmed:
        statusColor = Colors.green;
        statusText = 'Payment Confirmed';
        break;
      case PurchaseStatus.completed:
        statusColor = Colors.purple;
        statusText = 'Completed';
        break;
    }
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: () => _navigateToPurchaseDetails(purchase),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey.shade900,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Item image
                  if (purchase.listingImages.isNotEmpty)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: SizedBox(
                        width: 60,
                        height: 60,
                        child: Image.network(
                          purchase.listingImages.first,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color: Colors.grey.shade800,
                            child: Icon(
                              Icons.image_not_supported,
                              color: Colors.grey.shade400,
                            ),
                          ),
                        ),
                      ),
                    )
                  else
                    Container(
                      width: 60,
                      height: 60,
                      color: Colors.grey.shade800,
                      child: Icon(
                        Icons.image_not_supported,
                        color: Colors.grey.shade400,
                      ),
                    ),
                  const SizedBox(width: 12),
                  
                  // Item details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          purchase.listingTitle,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'RM ${purchase.price.toStringAsFixed(2)}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Seller: ${purchase.sellerName}',
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Status
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withAlpha(30),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  statusText,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  // Navigation methods
  void _navigateToOrderHistory({String? filter}) {
    // TODO: Navigate to order history screen with optional filter
    // Currently just shows a modal
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Order History ${filter != null ? '(Filter: $filter)' : ''}',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            const Text('Order history will be implemented in a future update'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      ),
    );
  }
  
  void _navigateToChats() {
    // TODO: Navigate to chats screen
  }
  
  void _navigateToAuctions() {
    // TODO: Navigate to auctions screen
  }
  
  void _navigateToWishlist() {
    // TODO: Navigate to wishlist screen
  }
  
  void _navigateToPurchaseDetails(PurchaseModel purchase) {
    // TODO: Navigate to purchase details screen
  }
} 