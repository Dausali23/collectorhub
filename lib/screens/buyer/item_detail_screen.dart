import 'package:flutter/material.dart';
import '../../models/listing_model.dart';
import '../../models/user_model.dart';
import '../../services/cart_service.dart';
import '../../utils/image_utils.dart';
import '../chat/chat_screen.dart';
import 'purchase_confirmation_screen.dart';
import '../../models/cart_model.dart';
import 'dart:developer' as developer;

class ItemDetailScreen extends StatefulWidget {
  final ListingModel item;
  final UserModel currentUser;
  
  const ItemDetailScreen({
    super.key,
    required this.item,
    required this.currentUser,
  });

  @override
  State<ItemDetailScreen> createState() => _ItemDetailScreenState();
}

class _ItemDetailScreenState extends State<ItemDetailScreen> {
  final CartService _cartService = CartService();
  bool _isAddingToCart = false;
  bool _isPurchasing = false;
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Content
          CustomScrollView(
            slivers: [
              // App bar with image
              SliverAppBar(
                expandedHeight: 300,
                pinned: true,
                backgroundColor: Colors.white,
                flexibleSpace: FlexibleSpaceBar(
                  background: widget.item.images.isNotEmpty
                      ? ImageUtils.getImageWidget(
                          ImageUtils.formatImageUrl(widget.item.images.first) ?? widget.item.images.first,
                          fit: BoxFit.cover,
                        )
                      : Container(
                          color: Colors.grey.shade200,
                          child: const Icon(
                            Icons.image_not_supported,
                            size: 70,
                            color: Colors.grey,
                          ),
                        ),
                ),
                actions: [
                  // Favorite button
                  CircleAvatar(
                    backgroundColor: Colors.white,
                    child: IconButton(
                      icon: const Icon(
                        Icons.favorite_border,
                        color: Colors.black,
                      ),
                      onPressed: () {
                        // Favorite functionality to be added later
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
              ),
              
              // Item details
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title and price
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              widget.item.title,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Text(
                            'RM ${widget.item.price.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.deepPurple,
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 8),
                      
                      // Market price comparison if available
                      if (widget.item.marketPrice != null && widget.item.marketPrice! > 0)
                        Row(
                          children: [
                            Text(
                              'Market Price: RM ${widget.item.marketPrice!.toStringAsFixed(2)}',
                              style: TextStyle(
                                fontSize: 14,
                                color: _getPriceComparisonColor(widget.item.price, widget.item.marketPrice!),
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              _getPriceComparisonIcon(widget.item.price, widget.item.marketPrice!),
                              size: 16,
                              color: _getPriceComparisonColor(widget.item.price, widget.item.marketPrice!),
                            ),
                          ],
                        ),
                      
                      const SizedBox(height: 16),
                      
                      // Seller info
                      Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: Colors.deepPurple.shade100,
                            radius: 20,
                            child: Text(
                              widget.item.sellerName[0].toUpperCase(),
                              style: TextStyle(
                                color: Colors.deepPurple.shade700,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.item.sellerName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              Text(
                                'Seller',
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                          const Spacer(),
                          OutlinedButton(
                            onPressed: () => _navigateToChat(),
                            style: OutlinedButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              side: BorderSide(color: Colors.grey.shade400),
                            ),
                            child: const Text('Message'),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Item details section
                      const Text(
                        'Item Details',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      
                      const SizedBox(height: 8),
                      
                      // Category and condition
                      _buildDetailRow(
                        'Category',
                        '${widget.item.category} > ${widget.item.subcategory}',
                      ),
                      
                      _buildDetailRow(
                        'Condition',
                        ListingModel.conditionToString(widget.item.condition),
                      ),
                      
                      _buildDetailRow(
                        'Listed Date',
                        _formatDate(widget.item.createdAt),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Description
                      const Text(
                        'Description',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      
                      const SizedBox(height: 8),
                      
                      Text(
                        widget.item.description,
                        style: const TextStyle(fontSize: 16),
                      ),
                      
                      // Add more spacing at bottom to account for action buttons
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),
            ],
          ),
          
          // Bottom action buttons
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withAlpha(51), // ~0.2 opacity
                    spreadRadius: 1,
                    blurRadius: 10,
                    offset: const Offset(0, -3),
                  ),
                ],
              ),
              child: SafeArea(
                child: Row(
                  children: [
                    // Add to cart button
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _isAddingToCart || _isPurchasing
                            ? null
                            : () => _addToCart(),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          side: BorderSide(color: Colors.deepPurple.shade300),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isAddingToCart
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text(
                                'Add to Cart',
                                style: TextStyle(
                                  color: Colors.deepPurple,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                    
                    const SizedBox(width: 12),
                    
                    // Buy now button
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isAddingToCart || _isPurchasing
                            ? null
                            : () => _buyNow(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepPurple,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          disabledBackgroundColor: Colors.deepPurple.withAlpha(128), // ~0.5 opacity
                        ),
                        child: _isPurchasing
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : const Text(
                                'Buy Now',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey.shade700,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
  
  Color _getPriceComparisonColor(double price, double marketPrice) {
    if (price < marketPrice * 0.9) {
      return Colors.green;
    } else if (price > marketPrice * 1.1) {
      return Colors.red;
    } else {
      return Colors.orange;
    }
  }
  
  IconData _getPriceComparisonIcon(double price, double marketPrice) {
    if (price < marketPrice * 0.9) {
      return Icons.trending_down;
    } else if (price > marketPrice * 1.1) {
      return Icons.trending_up;
    } else {
      return Icons.remove;
    }
  }
  
  void _navigateToChat() {
    developer.log('Navigating to chat with seller: ${widget.item.sellerId} (${widget.item.sellerName})');
    developer.log('Current user: ${widget.currentUser.uid}');
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatScreen(
          currentUserId: widget.currentUser.uid,
          otherUserId: widget.item.sellerId,
          otherUserName: widget.item.sellerName,
        ),
      ),
    );
  }
  
  Future<void> _addToCart() async {
    setState(() {
      _isAddingToCart = true;
    });
    
    try {
      if (widget.item.id == null) {
        throw Exception('Item ID is missing');
      }
      
      await _cartService.addToCart(widget.currentUser.uid, widget.item.id!);
      
      if (mounted) {
        setState(() {
          _isAddingToCart = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Item added to cart'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      developer.log('Error adding to cart: $e');
      
      if (mounted) {
        setState(() {
          _isAddingToCart = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error adding to cart: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  Future<void> _buyNow() async {
    setState(() {
      _isPurchasing = true;
    });
    
    try {
      // Log the seller information for debugging
      developer.log('Preparing purchase for item: ${widget.item.id}');
      developer.log('Seller ID: ${widget.item.sellerId}');
      developer.log('Seller Name: ${widget.item.sellerName}');
      
      // Verify seller information is present
      if (widget.item.sellerId.isEmpty) {
        throw Exception('Seller information is missing. Cannot proceed with purchase.');
      }
      
      // Create a cart item to pass to confirmation screen
      final cartItem = CartItem(
        id: 'temp-${widget.item.id}',
        listing: widget.item,
        addedAt: DateTime.now(),
      );
      
      if (mounted) {
        setState(() {
          _isPurchasing = false;
        });
        
        // Navigate to purchase confirmation
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PurchaseConfirmationScreen(
              user: widget.currentUser,
              cartItems: [cartItem],
            ),
          ),
        );
      }
    } catch (e) {
      developer.log('Error preparing purchase: $e');
      
      if (mounted) {
        setState(() {
          _isPurchasing = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}