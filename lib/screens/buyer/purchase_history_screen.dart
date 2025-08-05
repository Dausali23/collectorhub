import 'package:flutter/material.dart';
import '../../models/purchase_model.dart';
import '../../models/user_model.dart';
import '../../services/cart_service.dart';
import 'purchase_detail_screen.dart';
import 'dart:developer' as developer;

class PurchaseHistoryScreen extends StatelessWidget {
  final UserModel user;
  
  const PurchaseHistoryScreen({
    super.key,
    required this.user,
  });

  @override
  Widget build(BuildContext context) {
    final CartService cartService = CartService();
    
    return Scaffold(
      backgroundColor: Colors.black87,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('Purchase History'),
        centerTitle: true,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<List<PurchaseModel>>(
        stream: cartService.getBuyerPurchases(user.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (snapshot.hasError) {
            developer.log('Error loading purchases: ${snapshot.error}');
            return Center(
              child: Text(
                'Error loading purchases: ${snapshot.error}',
                style: const TextStyle(color: Colors.white),
              ),
            );
          }
          
          final purchases = snapshot.data ?? [];
          
          if (purchases.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.shopping_bag_outlined,
                    size: 80,
                    color: Colors.grey.shade600,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No purchases yet',
                    style: TextStyle(
                      color: Colors.grey.shade400,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            );
          }
          
          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: purchases.length,
            itemBuilder: (context, index) {
              final purchase = purchases[index];
              return _buildPurchaseCard(context, purchase);
            },
          );
        },
      ),
    );
  }
  
  Widget _buildPurchaseCard(BuildContext context, PurchaseModel purchase) {
    Color statusColor;
    String statusText;
    
    switch (purchase.status) {
      case PurchaseStatus.pending:
        statusColor = Colors.amber;
        statusText = 'Payment Pending';
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
    
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      color: Colors.grey.shade800,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PurchaseDetailScreen(
                purchase: purchase,
                user: user,
              ),
            ),
          );
        },
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
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    '${purchase.createdAt.day}/${purchase.createdAt.month}/${purchase.createdAt.year}',
                    style: TextStyle(
                      color: Colors.grey.shade400,
                      fontSize: 14,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
              
              const Divider(color: Colors.grey),
              
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
                                  color: Colors.grey.shade700,
                                  child: const Icon(
                                    Icons.broken_image,
                                    color: Colors.white,
                                  ),
                                );
                              },
                            )
                          : Container(
                              color: Colors.grey.shade700,
                              child: const Icon(
                                Icons.image_not_supported,
                                color: Colors.white,
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
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Seller: ${purchase.sellerName}',
                          style: TextStyle(
                            color: Colors.grey.shade300,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '\$${purchase.price.toStringAsFixed(2)}',
                          style: const TextStyle(
                            color: Colors.green,
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
                  color: statusColor.withOpacity(0.2),
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
} 