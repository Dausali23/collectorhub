import 'package:flutter/material.dart';
import '../../models/purchase_model.dart';
import '../../models/user_model.dart';
import '../../services/cart_service.dart';
import 'order_detail_screen.dart';
import 'dart:developer' as developer;

class OrdersScreen extends StatefulWidget {
  final UserModel user;
  
  const OrdersScreen({super.key, required this.user});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final CartService _cartService = CartService();
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
  
  
  // Action to confirm payment
  void _confirmPayment(PurchaseModel purchase) async {
    try {
      await _cartService.updatePurchaseStatus(purchase.id!, PurchaseStatus.confirmed);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Payment confirmed successfully')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }
  
  // Action to mark as completed
  void _markAsCompleted(PurchaseModel purchase) async {
    try {
      await _cartService.updatePurchaseStatus(purchase.id!, PurchaseStatus.completed);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Order marked as completed')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }
  
  // Build order card widget
  Widget _buildOrderCard(PurchaseModel purchase) {
    Color statusColor;
    
    switch (purchase.status) {
      case PurchaseStatus.pending:
        statusColor = Colors.amber;
        break;
      case PurchaseStatus.claimed:
        statusColor = Colors.blue;
        break;
      case PurchaseStatus.confirmed:
        statusColor = Colors.green;
        break;
      case PurchaseStatus.completed:
        statusColor = Colors.purple;
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
              builder: (context) => OrderDetailScreen(
                purchase: purchase,
                user: widget.user,
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
                          'Buyer: ${purchase.buyerName}',
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
              
              // Status and action button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Status chip
                  Flexible(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Color.fromRGBO(
                          (statusColor.value >> 16) & 0xFF,
                          (statusColor.value >> 8) & 0xFF, 
                          statusColor.value & 0xFF, 
                          0.2
                        ),
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
                            _getStatusText(purchase.status),
                            style: TextStyle(
                              color: statusColor,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  // Action button based on status
                  if (purchase.status == PurchaseStatus.pending)
                    SizedBox(
                      height: 36,
                      child: ElevatedButton(
                        onPressed: () => _confirmPayment(purchase),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Confirm Payment', style: TextStyle(fontSize: 12)),
                      ),
                    )
                  else if (purchase.status == PurchaseStatus.claimed)
                    SizedBox(
                      height: 36,
                      child: ElevatedButton(
                        onPressed: () => _confirmPayment(purchase),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Confirm', style: TextStyle(fontSize: 12)),
                      ),
                    )
                  else if (purchase.status == PurchaseStatus.confirmed)
                    SizedBox(
                      height: 36,
                      child: ElevatedButton(
                        onPressed: () => _markAsCompleted(purchase),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Complete', style: TextStyle(fontSize: 12)),
                      ),
                    )
                  else
                    SizedBox(
                      height: 36,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => OrderDetailScreen(
                                purchase: purchase,
                                user: widget.user,
                              ),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepPurple,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Details', style: TextStyle(fontSize: 12)),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  // Helper methods for status text
  String _getStatusText(PurchaseStatus status) {
    switch (status) {
      case PurchaseStatus.pending:
        return 'Payment Pending';
      case PurchaseStatus.claimed:
        return 'Payment Claimed';
      case PurchaseStatus.confirmed:
        return 'Payment Confirmed';
      case PurchaseStatus.completed:
        return 'Completed';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black87,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('Orders Management'),
        centerTitle: true,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: Colors.blue,
          tabs: const [
            Tab(text: 'All Orders'),
            Tab(text: 'Pending'),
            Tab(text: 'Payment Claimed'),
            Tab(text: 'Confirmed'),
          ],
        ),
      ),
      body: StreamBuilder<List<PurchaseModel>>(
        stream: _cartService.getSellerPurchases(widget.user.uid, status: null),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (snapshot.hasError) {
            developer.log('Error loading orders: ${snapshot.error}');
            return Center(
              child: Text(
                'Error loading orders: ${snapshot.error}',
                style: const TextStyle(color: Colors.white),
              ),
            );
          }
          
          final allPurchases = snapshot.data ?? [];
          
          return TabBarView(
            controller: _tabController,
            children: [
              // All orders tab
              _buildOrdersListView(allPurchases),
              
              // Pending tab - filter in memory
              _buildOrdersListView(allPurchases.where(
                (purchase) => purchase.status == PurchaseStatus.pending
              ).toList()),
              
              // Payment Claimed tab - filter in memory
              _buildOrdersListView(allPurchases.where(
                (purchase) => purchase.status == PurchaseStatus.claimed
              ).toList()),
              
              // Confirmed tab - filter in memory
              _buildOrdersListView(allPurchases.where(
                (purchase) => purchase.status == PurchaseStatus.confirmed
              ).toList()),
            ],
          );
        }
      ),
    );
  }
  
  // Build the list view for filtered orders
  Widget _buildOrdersListView(List<PurchaseModel> purchases) {
    if (purchases.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 40),
            Icon(
              Icons.inbox_outlined,
              size: 80,
              color: Colors.grey.shade600,
            ),
            const SizedBox(height: 16),
            Text(
              'No orders in this category',
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
        return _buildOrderCard(purchase);
      },
    );
  }
} 