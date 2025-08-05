import 'package:flutter/material.dart';
import '../../models/listing_model.dart';
import '../../models/user_model.dart';
import '../../models/auction_model.dart';
import '../../services/firestore_service.dart';
import '../../utils/image_utils.dart';
import '../chat/chat_screen.dart';
import 'dart:developer' as developer;

class AuctionDetailScreen extends StatefulWidget {
  final ListingModel item;
  final UserModel currentUser;
  
  const AuctionDetailScreen({
    super.key,
    required this.item,
    required this.currentUser,
  });

  @override
  State<AuctionDetailScreen> createState() => _AuctionDetailScreenState();
}

class _AuctionDetailScreenState extends State<AuctionDetailScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  bool _isPlacingBid = false;
  AuctionModel? _auction;
  final TextEditingController _customBidController = TextEditingController();
  
  @override
  void initState() {
    super.initState();
    _loadAuctionData();
  }
  
  @override
  void dispose() {
    _customBidController.dispose();
    super.dispose();
  }
  
  Future<void> _loadAuctionData() async {
    try {
      final auction = await _firestoreService.getAuction(widget.item.id!);
      if (mounted) {
        setState(() {
          _auction = auction;
        });
        
        // Check if auction has expired but still marked as active
        if (_auction != null && 
            _auction!.status == AuctionStatus.active && 
            _auction!.endTime.isBefore(DateTime.now())) {
          // Update the auction status to ended
          await _firestoreService.updateAuction(
            _auction!.copyWith(status: AuctionStatus.ended)
          );
          
          // Reload the auction data after updating
          final updatedAuction = await _firestoreService.getAuction(widget.item.id!);
          if (mounted) {
            setState(() {
              _auction = updatedAuction;
            });
          }
        }
      }
    } catch (e) {
      developer.log('Error loading auction data: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading auction data: $e'),
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
              
              // Auction details
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title and auction badge
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
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
                          const SizedBox(width: 8),
                          _auction != null
                          ? Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: _auction!.status == AuctionStatus.ended ? Colors.grey.shade600 : Colors.red,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                _auction!.status == AuctionStatus.ended ? 'ENDED' : 'AUCTION',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            )
                          : Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'AUCTION',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                        ],
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Current price info
                      if (_auction != null)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Text(
                                  'Current Bid:',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  'RM ${_auction!.currentPrice.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.red,
                                  ),
                                ),
                              ],
                            ),
                            
                            // Highest bidder
                            if (_auction!.topBidderName != null && _auction!.topBidderName!.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Row(
                                  children: [
                                    const Text(
                                      'Highest Bidder:',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const Spacer(),
                                    Text(
                                      _auction!.topBidderName!,
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.deepPurple.shade700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            
                            const SizedBox(height: 8),
                            
                            // Starting price
                            Text(
                              'Starting Price: RM ${_auction!.startingPrice.toStringAsFixed(2)}',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade700,
                              ),
                            ),
                            
                            // Bid increment
                            Text(
                              'Bid Increment: RM ${_auction!.bidIncrement.toStringAsFixed(2)}',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade700,
                              ),
                            ),
                            
                            // Number of bids
                            Text(
                              'Bids: ${_auction!.bidCount}',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade700,
                              ),
                            ),
                            
                            // Auction end time
                            const SizedBox(height: 12),
                            Text(
                              'Auction ends: ${_formatDateTime(_auction!.endTime)}',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        )
                      else
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(16.0),
                            child: CircularProgressIndicator(),
                          ),
                        ),
                        
                      const SizedBox(height: 24),
                      
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
          if (_auction != null)
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
                      color: Colors.grey.withAlpha(51),
                      spreadRadius: 1,
                      blurRadius: 10,
                      offset: const Offset(0, -3),
                    ),
                  ],
                ),
                child: SafeArea(
                  child: Row(
                    children: [
                      // Custom bid button
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _isPlacingBid || _auction!.status != AuctionStatus.active
                              ? null
                              : () => _showCustomBidDialog(),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            side: BorderSide(color: Colors.red.shade300),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Custom Bid',
                            style: TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      
                      const SizedBox(width: 12),
                      
                      // Quick bid button (current + increment)
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _isPlacingBid || _auction!.status != AuctionStatus.active
                              ? null
                              : () => _showBidConfirmationDialog(_auction!.currentPrice + _auction!.bidIncrement),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            disabledBackgroundColor: Colors.red.withAlpha(128),
                          ),
                          child: _isPlacingBid
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : Text(
                                  'Bid RM ${(_auction!.currentPrice + _auction!.bidIncrement).toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
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
  
  String _formatDateTime(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
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

  void _showCustomBidDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Enter Custom Bid Amount'),
          content: TextField(
            controller: _customBidController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              hintText: 'Enter amount in RM',
              helperText: 'Min. bid: RM ${(_auction!.currentPrice + _auction!.bidIncrement).toStringAsFixed(2)}',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                double? amount = double.tryParse(_customBidController.text);
                if (amount != null && amount >= _auction!.currentPrice + _auction!.bidIncrement) {
                  Navigator.pop(context);
                  _showBidConfirmationDialog(amount);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Bid must be at least RM ${(_auction!.currentPrice + _auction!.bidIncrement).toStringAsFixed(2)}'
                      ),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: const Text('Proceed'),
            ),
          ],
        );
      },
    );
  }
  
  void _showBidConfirmationDialog(double bidAmount) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Your Bid'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('You are about to place a bid of:'),
            const SizedBox(height: 12),
            Center(
              child: Text(
                'RM ${bidAmount.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                  color: Colors.red,
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'This action cannot be undone. Are you sure you want to proceed?',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('Cancel'),
          ),
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: Colors.white,
              backgroundColor: Colors.red,
            ),
            onPressed: () {
              Navigator.of(context).pop();
              _placeBid(bidAmount);
            },
            child: const Text('Confirm Bid'),
          ),
        ],
      ),
    );
  }
  
  Future<void> _placeBid(double bidAmount) async {
    setState(() {
      _isPlacingBid = true;
    });
    
    try {
      await _firestoreService.placeBid(
        widget.item.id!,
        widget.currentUser.uid,
        widget.currentUser.displayName ?? 'Unknown User',
        bidAmount,
      );
      
      // Reload auction data
      await _loadAuctionData();
      
      if (mounted) {
        setState(() {
          _isPlacingBid = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Bid placed successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      developer.log('Error placing bid: $e');
      
      if (mounted) {
        setState(() {
          _isPlacingBid = false;
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