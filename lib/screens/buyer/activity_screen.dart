import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../models/purchase_model.dart';
import '../../services/cart_service.dart';
import '../chat/chat_list_screen.dart';
import 'buyer_events_screen.dart';
import 'purchase_detail_screen.dart';
import 'dart:developer' as developer;

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
      backgroundColor: Colors.grey.shade100,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            setState(() {});
            return Future.delayed(const Duration(milliseconds: 1500));
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // App Bar
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.deepPurple.shade400,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.notifications,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Activity',
                            style: TextStyle(
                              color: Colors.deepPurple,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.refresh, color: Colors.deepPurple),
                        onPressed: () {
                          setState(() {});
                        },
                      ),
                    ],
                  ),
                ),
                
                // Activity categories
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      _buildActivityCategory(
                        title: 'Orders',
                        icon: Icons.shopping_bag,
                        onTap: () {
                          // Show orders section
                          // Already visible below
                        },
                      ),
                      _buildActivityCategory(
                        title: 'Messages',
                        icon: Icons.chat_bubble_outline,
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
                      _buildActivityCategory(
                        title: 'Favorites',
                        icon: Icons.favorite_outline,
                        onTap: () {
                          // Navigate to favorites
                        },
                      ),
                      _buildActivityCategory(
                        title: 'Events',
                        icon: Icons.event,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => BuyerEventsScreen(
                                user: widget.user,
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Pending Orders Section
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Pending Orders',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      Icon(
                        Icons.pending_actions,
                        color: Colors.amber.shade700,
                        size: 20,
                      ),
                    ],
                  ),
                ),
                
                // Pending Orders List
                _buildPurchasesList(PurchaseStatus.pending),
                
                const SizedBox(height: 16),
                
                // Confirmed Orders Section
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Confirmed Orders',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      Icon(
                        Icons.check_circle_outline,
                        color: Colors.green.shade700,
                        size: 20,
                      ),
                    ],
                  ),
                ),
                
                // Confirmed Orders List
                _buildPurchasesList(PurchaseStatus.confirmed),
                
                const SizedBox(height: 16),
                
                // Completed Orders Section
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Completed Orders',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      Icon(
                        Icons.task_alt,
                        color: Colors.purple.shade700,
                        size: 20,
                      ),
                    ],
                  ),
                ),
                
                // Completed Orders List
                _buildPurchasesList(PurchaseStatus.completed),
                
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPurchasesList(PurchaseStatus status) {
    return StreamBuilder<List<PurchaseModel>>(
      stream: _cartService.getBuyerPurchases(widget.user.uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24.0),
              child: CircularProgressIndicator(),
            ),
          );
        }
        
        if (snapshot.hasError) {
          developer.log('Error loading purchases: ${snapshot.error}');
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 16.0),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withValues(alpha: 0.1),
                  spreadRadius: 1,
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              'Error loading purchases: ${snapshot.error}',
              style: TextStyle(color: Colors.red.shade700),
            ),
          );
        }
        
        final purchases = snapshot.data ?? [];
        final filteredPurchases = purchases.where((p) => p.status == status).toList();
        
        if (filteredPurchases.isEmpty) {
          return Container(
            width: double.infinity,
            margin: const EdgeInsets.symmetric(horizontal: 16.0),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withValues(alpha: 0.1),
                  spreadRadius: 1,
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                Icon(
                  status == PurchaseStatus.pending ? Icons.pending_actions :
                  status == PurchaseStatus.confirmed ? Icons.check_circle_outline :
                  Icons.task_alt,
                  color: status == PurchaseStatus.pending ? Colors.amber.shade700 :
                         status == PurchaseStatus.confirmed ? Colors.green.shade700 :
                         Colors.purple.shade700,
                  size: 48,
                ),
                const SizedBox(height: 12),
                Text(
                  'No ${status.toString().split('.').last} orders',
                  style: const TextStyle(
                    color: Colors.black87,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  status == PurchaseStatus.pending ? 'Pending orders will appear here' :
                  status == PurchaseStatus.confirmed ? 'Confirmed orders will appear here' :
                  'Completed orders will appear here',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          );
        }
        
        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          itemCount: filteredPurchases.length,
          itemBuilder: (context, index) {
            final purchase = filteredPurchases[index];
            return _buildPurchaseCard(context, purchase);
          },
        );
      },
    );
  }
  
  Widget _buildPurchaseCard(BuildContext context, PurchaseModel purchase) {
    Color statusColor;
    String statusText;
    
    switch (purchase.status) {
      case PurchaseStatus.pending:
        statusColor = Colors.amber.shade700;
        statusText = 'Payment Pending';
        break;
      case PurchaseStatus.claimed:
        statusColor = Colors.blue.shade700;
        statusText = 'Payment Claimed';
        break;
      case PurchaseStatus.confirmed:
        statusColor = Colors.green.shade700;
        statusText = 'Payment Confirmed';
        break;
      case PurchaseStatus.completed:
        statusColor = Colors.purple.shade700;
        statusText = 'Completed';
        break;
    }
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PurchaseDetailScreen(
                purchase: purchase,
                user: widget.user,
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Order header with ID and date
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Text(
                      'Order #${purchase.id!.substring(0, 8)}',
                      style: const TextStyle(
                        color: Colors.black87,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    '${purchase.createdAt.day}/${purchase.createdAt.month}/${purchase.createdAt.year}',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 14,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
              
              const Divider(),
              
              // Product info
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Product image
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: SizedBox(
                      width: 80,
                      height: 80,
                      child: purchase.listingImages.isNotEmpty
                          ? Image.network(
                              purchase.listingImages.first,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: Colors.grey.shade200,
                                  child: Icon(
                                    Icons.broken_image,
                                    color: Colors.grey.shade400,
                                  ),
                                );
                              },
                            )
                          : Container(
                              color: Colors.grey.shade200,
                              child: Icon(
                                Icons.image_not_supported,
                                color: Colors.grey.shade400,
                              ),
                            ),
                    ),
                  ),
                  
                  const SizedBox(width: 16),
                  
                  // Product details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          purchase.listingTitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.black87,
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Seller: ${purchase.sellerName}',
                          style: TextStyle(
                            color: Colors.grey.shade700,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '\$${purchase.price.toStringAsFixed(2)}',
                          style: TextStyle(
                            color: Colors.green.shade700,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Status chip
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.circle,
                      size: 12,
                      color: statusColor,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      statusText,
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActivityCategory({
    required String title,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: MediaQuery.of(context).size.width / 2 - 22,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withValues(alpha: 0.1),
              spreadRadius: 1,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.deepPurple.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: Colors.deepPurple,
                size: 24,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                color: Colors.black87,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
} 
