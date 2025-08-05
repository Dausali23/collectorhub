import 'package:flutter/material.dart';
import '../../models/cart_model.dart';
import '../../models/user_model.dart';
import '../../services/cart_service.dart';
import '../../utils/image_utils.dart';
import 'payment_completion_screen.dart';
import 'dart:developer' as developer;

class PurchaseConfirmationScreen extends StatefulWidget {
  final UserModel user;
  final List<CartItem> cartItems;
  
  const PurchaseConfirmationScreen({
    super.key,
    required this.user,
    required this.cartItems,
  });

  @override
  State<PurchaseConfirmationScreen> createState() => _PurchaseConfirmationScreenState();
}

class _PurchaseConfirmationScreenState extends State<PurchaseConfirmationScreen> {
  final CartService _cartService = CartService();
  bool _isProcessing = false;
  
  @override
  Widget build(BuildContext context) {
    // Calculate total price
    final totalPrice = widget.cartItems.fold<double>(
      0, (sum, item) => sum + item.listing.price);
    
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Confirm Purchase'),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isProcessing
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 24),
                  Text(
                    'Processing your order...',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Order summary section
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Order Summary',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 16),
                              
                              // List of items
                              ...widget.cartItems.map((item) => Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Item image
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: SizedBox(
                                        width: 60,
                                        height: 60,
                                        child: item.listing.images.isNotEmpty
                                            ? ImageUtils.getImageWidget(
                                                ImageUtils.formatImageUrl(item.listing.images.first) 
                                                  ?? item.listing.images.first,
                                                fit: BoxFit.cover,
                                              )
                                            : Container(
                                                color: Colors.grey.shade200,
                                                child: Icon(
                                                  Icons.image_not_supported,
                                                  color: Colors.grey.shade500,
                                                ),
                                              ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    
                                    // Item details
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            item.listing.title,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          Text(
                                            'Seller: ${item.listing.sellerName}',
                                            style: TextStyle(
                                              color: Colors.grey.shade700,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    
                                    // Price
                                    Text(
                                      'RM ${item.listing.price.toStringAsFixed(2)}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              )).toList(),
                              
                              const Divider(),
                              
                              // Total
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Total:',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  Text(
                                    'RM ${totalPrice.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: Colors.deepPurple,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        
                        const SizedBox(height: 24),
                        
                        // Payment instructions
                        const Text(
                          'Payment Instructions',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Card(
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  '1. After clicking "Buy Now", you\'ll be connected with the seller to arrange payment.',
                                  style: TextStyle(fontSize: 14),
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  '2. You can chat with the seller to discuss payment methods and details.',
                                  style: TextStyle(fontSize: 14),
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  '3. Once payment is complete, click "Mark Payment as Done".',
                                  style: TextStyle(fontSize: 14),
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  '4. The seller will confirm receipt of payment to complete the transaction.',
                                  style: TextStyle(fontSize: 14),
                                ),
                                const SizedBox(height: 16),
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.yellow.shade100,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Colors.yellow.shade700),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.info_outline,
                                        color: Colors.yellow.shade800,
                                      ),
                                      const SizedBox(width: 8),
                                      const Expanded(
                                        child: Text(
                                          'CollectorHub does not handle payments directly. All payments are arranged between buyers and sellers.',
                                          style: TextStyle(fontSize: 13),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                // Action buttons
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        spreadRadius: 1,
                        blurRadius: 5,
                        offset: const Offset(0, -3),
                      ),
                    ],
                  ),
                  child: SafeArea(
                    child: Row(
                      children: [
                        // Cancel button
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              side: BorderSide(color: Colors.grey.shade400),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              'Cancel',
                              style: TextStyle(
                                color: Colors.black87,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        
                        // Buy now button
                        Expanded(
                          flex: 2,
                          child: ElevatedButton(
                            onPressed: _processPurchase,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.deepPurple,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              'Buy Now',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
  
  Future<void> _processPurchase() async {
    if (_isProcessing) return;
    
    setState(() {
      _isProcessing = true;
    });
    
    try {
      // For direct purchases (not from cart), use purchaseItem method instead
      if (widget.cartItems.length == 1 && widget.cartItems[0].id.startsWith('temp-')) {
        // This is a direct purchase from the item detail screen
        developer.log('Processing direct purchase for item: ${widget.cartItems[0].listing.id}');
        await _cartService.purchaseItem(widget.user, widget.cartItems[0].listing);
      } else {
        // Process checkout from cart
        developer.log('Processing checkout for ${widget.cartItems.length} items');
        await _cartService.checkout(widget.user);
      }
      
      if (mounted) {
        // Navigate to payment completion screen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => PaymentCompletionScreen(
              user: widget.user,
              cartItems: widget.cartItems,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error processing purchase: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}