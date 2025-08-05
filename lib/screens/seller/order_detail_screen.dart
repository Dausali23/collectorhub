import 'package:flutter/material.dart';
import '../../models/purchase_model.dart';
import '../../models/user_model.dart';
import '../../services/cart_service.dart';
import 'package:intl/intl.dart';
import 'dart:developer' as developer;

class OrderDetailScreen extends StatefulWidget {
  final PurchaseModel purchase;
  final UserModel user;
  
  const OrderDetailScreen({
    super.key, 
    required this.purchase,
    required this.user,
  });

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  final CartService _cartService = CartService();
  bool _isLoading = false;
  late PurchaseModel _currentPurchase;

  @override
  void initState() {
    super.initState();
    _currentPurchase = widget.purchase;
  }

  // Format date and time
  String _formatDateTime(DateTime? dateTime) {
    if (dateTime == null) return 'N/A';
    return DateFormat('MMM dd, yyyy - hh:mm a').format(dateTime);
  }
  
  // Update purchase status
  Future<void> _updateStatus(PurchaseStatus newStatus) async {
    setState(() => _isLoading = true);
    
    try {
      await _cartService.updatePurchaseStatus(_currentPurchase.id!, newStatus);
      
      // Fetch the updated purchase to get the latest status and timestamps
      final updatedPurchaseDoc = await _cartService.getPurchaseById(_currentPurchase.id!);
      
      if (mounted) {
        setState(() {
          _currentPurchase = updatedPurchaseDoc;
          _isLoading = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Order status updated to ${PurchaseModel.statusToString(newStatus)}')),
        );
      }
    } catch (e) {
      developer.log('Error updating purchase status: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }
  
  // Get appropriate action button based on current status
  Widget _buildActionButton() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    
    switch (_currentPurchase.status) {
      case PurchaseStatus.pending:
        // Add button for seller to confirm payment directly
        return ElevatedButton(
          onPressed: () => _updateStatus(PurchaseStatus.confirmed),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
          ),
          child: const Text(
            'CONFIRM PAYMENT RECEIVED',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
        );
        
      case PurchaseStatus.claimed:
        return ElevatedButton(
          onPressed: () => _updateStatus(PurchaseStatus.confirmed),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
          ),
          child: const Text(
            'CONFIRM PAYMENT',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
        );
        
      case PurchaseStatus.confirmed:
        return ElevatedButton(
          onPressed: () => _updateStatus(PurchaseStatus.completed),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
          ),
          child: const Text(
            'MARK COMPLETED',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
        );
        
      case PurchaseStatus.completed:
        return const Text(
          'Order completed',
          style: TextStyle(
            color: Colors.green,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black87,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text('Order #${_currentPurchase.id!.substring(0, 8)}'),
        centerTitle: true,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Order status card
              Card(
                color: Colors.grey.shade800,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      const Text(
                        'Order Status',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildStatusStepper(),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Product details card
              Card(
                color: Colors.grey.shade800,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Product Details',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Product image and info
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Product image
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: SizedBox(
                              width: 100,
                              height: 100,
                              child: _currentPurchase.listingImages.isNotEmpty
                                  ? Image.network(
                                      _currentPurchase.listingImages.first,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) {
                                        return Container(
                                          color: Colors.grey.shade700,
                                          child: const Icon(
                                            Icons.broken_image,
                                            color: Colors.white,
                                            size: 50,
                                          ),
                                        );
                                      },
                                    )
                                  : Container(
                                      color: Colors.grey.shade700,
                                      child: const Icon(
                                        Icons.image_not_supported,
                                        color: Colors.white,
                                        size: 50,
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
                                  _currentPurchase.listingTitle,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 2,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Order ID: ${_currentPurchase.id}',
                                  style: TextStyle(
                                    color: Colors.grey.shade400,
                                    fontSize: 14,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 2,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Price: \$${_currentPurchase.price.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    color: Colors.green,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Customer details card
              Card(
                color: Colors.grey.shade800,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Customer Details',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildInfoRow('Customer Name', _currentPurchase.buyerName),
                      _buildInfoRow('Customer ID', _currentPurchase.buyerId),
                      _buildInfoRow('Order Date', _formatDateTime(_currentPurchase.createdAt)),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Timeline card
              Card(
                color: Colors.grey.shade800,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Order Timeline',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildTimelineRow('Order Created', _formatDateTime(_currentPurchase.createdAt)),
                      _buildTimelineRow('Payment Claimed', _formatDateTime(_currentPurchase.paymentClaimedAt)),
                      _buildTimelineRow('Payment Confirmed', _formatDateTime(_currentPurchase.confirmedAt)),
                      _buildTimelineRow('Order Completed', _formatDateTime(_currentPurchase.completedAt)),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Action button
              Center(child: _buildActionButton()),
              
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey.shade400,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildTimelineRow(String label, String dateTime) {
    final isCompleted = dateTime != 'N/A';
    
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isCompleted ? Colors.green : Colors.grey.shade700,
          ),
          child: isCompleted
              ? const Icon(Icons.check, size: 14, color: Colors.white)
              : null,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: isCompleted ? Colors.white : Colors.grey.shade400,
                    fontWeight: FontWeight.w500,
                    fontSize: 13,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  dateTime,
                  style: TextStyle(
                    color: isCompleted ? Colors.blue : Colors.grey.shade500,
                    fontSize: 12,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildStatusStepper() {
    final currentStep = _currentPurchase.status.index;
    
    return Stepper(
      currentStep: currentStep,
      controlsBuilder: (context, details) => const SizedBox.shrink(),
      margin: EdgeInsets.zero,
      physics: const NeverScrollableScrollPhysics(),
      steps: [
        _buildStep(
          'Pending',
          'Waiting for payment confirmation',
          0 <= currentStep,
          0 == currentStep,
        ),
        _buildStep(
          'Claimed',
          'Buyer has claimed payment was sent',
          1 <= currentStep,
          1 == currentStep,
        ),
        _buildStep(
          'Confirmed',
          'Payment was confirmed received',
          2 <= currentStep,
          2 == currentStep,
        ),
        _buildStep(
          'Completed',
          'Order has been completed',
          3 <= currentStep,
          3 == currentStep,
        ),
      ],
    );
  }
  
  Step _buildStep(String title, String content, bool isCompleted, bool isActive) {
    return Step(
      title: Text(
        title,
        style: TextStyle(
          color: isCompleted ? Colors.white : Colors.grey.shade400,
          fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          fontSize: 14,
        ),
      ),
      content: Text(
        content,
        style: TextStyle(
          color: isCompleted ? Colors.blue : Colors.grey.shade500,
          fontSize: 12,
        ),
      ),
      isActive: isActive,
      state: isCompleted ? StepState.complete : StepState.indexed,
    );
  }
} 