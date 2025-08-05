import 'package:flutter/material.dart';
import '../../models/cart_model.dart';
import '../../models/user_model.dart';
import '../../models/purchase_model.dart';
import '../../services/cart_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../chat/chat_screen.dart';

class PaymentCompletionScreen extends StatefulWidget {
  final UserModel user;
  final List<CartItem> cartItems;
  
  const PaymentCompletionScreen({
    super.key,
    required this.user,
    required this.cartItems,
  });

  @override
  State<PaymentCompletionScreen> createState() => _PaymentCompletionScreenState();
}

class _PaymentCompletionScreenState extends State<PaymentCompletionScreen> {
  final CartService _cartService = CartService();
  List<PurchaseModel> _purchases = [];
  bool _isLoading = true;
  
  @override
  void initState() {
    super.initState();
    _loadPurchases();
  }
  
  Future<void> _loadPurchases() async {
    try {
      final buyerId = widget.user.uid;
      
      // Get recent purchases for this user without filtering by status
      // This avoids the need for a composite index
      final purchasesSnapshot = await FirebaseFirestore.instance
          .collection('purchases')
          .where('buyerId', isEqualTo: buyerId)
          .orderBy('createdAt', descending: true)
          .limit(widget.cartItems.length + 5) // Get a few extra just in case
          .get();
      
      if (mounted) {
        // Filter by status on the client side
        final allPurchases = purchasesSnapshot.docs
            .map((doc) => PurchaseModel.fromFirestore(doc))
            .toList();
        
        // Filter for pending purchases only
        final pendingPurchases = allPurchases
            .where((purchase) => purchase.status == PurchaseStatus.pending)
            .toList();
        
        setState(() {
          _purchases = pendingPurchases;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading purchases: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Order Placed'),
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Success icon and message
                  CircleAvatar(
                    backgroundColor: Colors.green.shade100,
                    radius: 40,
                    child: Icon(
                      Icons.check,
                      size: 50,
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Order Successful!',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Please contact the seller to arrange payment.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 32),
                  
                  // Next steps card
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
                            'Next Steps:',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          
                          // Step 1
                          _buildStepRow(
                            number: 1,
                            title: 'Chat with the Seller',
                            description: 'Discuss payment details with the seller.',
                            icon: Icons.chat_bubble_outline,
                            isCompleted: false,
                          ),
                          const SizedBox(height: 12),
                          
                          // Step 2
                          _buildStepRow(
                            number: 2,
                            title: 'Make Payment',
                            description: 'Pay the seller as agreed.',
                            icon: Icons.payments_outlined,
                            isCompleted: false,
                          ),
                          const SizedBox(height: 12),
                          
                          // Step 3
                          _buildStepRow(
                            number: 3,
                            title: 'Mark as Paid',
                            description: 'Once payment is complete, mark as paid.',
                            icon: Icons.check_circle_outline,
                            isCompleted: false,
                          ),
                          const SizedBox(height: 12),
                          
                          // Step 4
                          _buildStepRow(
                            number: 4,
                            title: 'Seller Confirms',
                            description: 'Seller will confirm payment receipt.',
                            icon: Icons.verified_outlined,
                            isCompleted: false,
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Purchased items
                  if (_purchases.isNotEmpty) ...[
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Your Orders',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    ..._purchases.map((purchase) => _buildPurchaseItem(purchase)).toList(),
                  ],
                  
                  const SizedBox(height: 32),
                  
                  // Action buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () {
                          // Close this screen and navigate back to home
                          Navigator.of(context).popUntil((route) => route.isFirst);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepPurple,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: const Icon(Icons.home),
                        label: const Text(
                          'Back to Home',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }
  
  Widget _buildStepRow({
    required int number,
    required String title,
    required String description,
    required IconData icon,
    required bool isCompleted,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Step number circle
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isCompleted ? Colors.green : Colors.grey.shade300,
          ),
          child: Center(
            child: Text(
              number.toString(),
              style: TextStyle(
                color: isCompleted ? Colors.white : Colors.black87,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        
        // Icon
        Icon(
          icon,
          color: isCompleted ? Colors.green : Colors.grey.shade600,
          size: 22,
        ),
        const SizedBox(width: 12),
        
        // Text content
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  decoration: isCompleted ? TextDecoration.lineThrough : null,
                ),
              ),
              Text(
                description,
                style: TextStyle(
                  color: Colors.grey.shade700,
                  fontSize: 12,
                  decoration: isCompleted ? TextDecoration.lineThrough : null,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  Widget _buildPurchaseItem(PurchaseModel purchase) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Item info
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: SizedBox(
                    width: 60,
                    height: 60,
                    child: purchase.listingImages.isNotEmpty
                        ? Image.network(
                            purchase.listingImages.first,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: Colors.grey.shade200,
                                child: Icon(
                                  Icons.error_outline,
                                  color: Colors.grey.shade500,
                                ),
                              );
                            },
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
                        purchase.listingTitle,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        'Seller: ${purchase.sellerName}',
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'RM ${purchase.price.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.deepPurple,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            const Divider(height: 24),
            
            // Action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Chat with seller button
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _navigateToChat(purchase),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    icon: const Icon(
                      Icons.chat_outlined,
                      size: 18,
                    ),
                    label: const Text('Chat Seller'),
                  ),
                ),
                const SizedBox(width: 8),
                
                // Mark payment done button
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _markPaymentDone(purchase),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    icon: const Icon(
                      Icons.check_circle_outlined,
                      size: 18,
                    ),
                    label: const Text('Payment Done'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  void _navigateToChat(PurchaseModel purchase) {
    // Logic to navigate to chat with the seller
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatScreen(
          currentUserId: widget.user.uid,
          otherUserId: purchase.sellerId,
          otherUserName: purchase.sellerName,
        ),
      ),
    );
  }
  
  void _markPaymentDone(PurchaseModel purchase) async {
    try {
      await _cartService.updatePurchaseStatus(
        purchase.id!,
        PurchaseStatus.claimed,
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Payment marked as completed'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Refresh the purchase list
        _loadPurchases();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating payment status: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}