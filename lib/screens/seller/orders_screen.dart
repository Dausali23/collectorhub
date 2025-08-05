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
  bool _isProcessing = false;
  bool _isRefreshing = false;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    // Check for orders immediately on screen load
    _refreshOrders();
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // New method to manually refresh orders
  Future<void> _refreshOrders() async {
    if (_isRefreshing) return;
    
    setState(() {
      _isRefreshing = true;
    });
    
    try {
      // Force a refresh of the seller's purchases by getting them once
      await _cartService.getSellerPurchasesOnce(widget.user.uid);
      
      if (mounted) {
        setState(() {
          _isRefreshing = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Orders refreshed'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isRefreshing = false;
        });
        
        developer.log('Error refreshing orders: $e');
      }
    }
  }
  
  // Action to confirm payment
  void _confirmPayment(PurchaseModel purchase) async {
    setState(() {
      _isProcessing = true;
    });
    
    try {
      await _cartService.updatePurchaseStatus(purchase.id!, PurchaseStatus.confirmed);
      
      if (!mounted) return;
      
      // Refresh the UI
      setState(() {
        _isProcessing = false;
      });
      
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Payment confirmed successfully'),
          backgroundColor: Colors.green,
        ),
      );
      
      // Automatically switch to the "Confirmed" tab
      _tabController.animateTo(3); // Index 3 is the "Confirmed" tab
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isProcessing = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  
  // Action to mark as completed
  void _markAsCompleted(PurchaseModel purchase) async {
    setState(() {
      _isProcessing = true;
    });
    
    try {
      await _cartService.updatePurchaseStatus(purchase.id!, PurchaseStatus.completed);
      
      if (!mounted) return;
      
      // Refresh the UI
      setState(() {
        _isProcessing = false;
      });
      
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Order marked as completed'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isProcessing = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
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
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
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
                  if (_isProcessing)
                    const SizedBox(
                      height: 36,
                      width: 36,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  else if (purchase.status == PurchaseStatus.pending)
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
        actions: [
          // Add refresh button
          IconButton(
            icon: _isRefreshing 
                ? const SizedBox(
                    width: 20, 
                    height: 20, 
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Icon(Icons.refresh),
            onPressed: _isRefreshing ? null : _refreshOrders,
            tooltip: 'Refresh Orders',
          ),
        ],
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
          if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (snapshot.hasError) {
            developer.log('Error loading orders: ${snapshot.error}');
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Error loading orders: ${snapshot.error}',
                    style: const TextStyle(color: Colors.white),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _refreshOrders,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }
          
          final allPurchases = snapshot.data ?? [];
          
          if (allPurchases.isEmpty && !_isRefreshing) {
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
                    'No orders yet',
                    style: TextStyle(
                      color: Colors.grey.shade400,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _refreshOrders,
                    child: const Text('Refresh'),
                  ),
                ],
              ),
            );
          }
          
          // Debug info
          developer.log('Seller ID: ${widget.user.uid}');
          developer.log('Total orders found: ${allPurchases.length}');
          for (var purchase in allPurchases) {
            developer.log('Purchase ID: ${purchase.id}, Seller: ${purchase.sellerId}, Status: ${purchase.status}');
          }
          
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
            Icon(
              Icons.shopping_bag_outlined,
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
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: purchases.length,
      itemBuilder: (context, index) {
        return _buildOrderCard(purchases[index]);
      },
    );
  }
} 