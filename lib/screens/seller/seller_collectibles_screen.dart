import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../models/listing_model.dart';
import '../../models/auction_model.dart';
import '../../services/firestore_service.dart';
import '../../utils/image_utils.dart';
import 'add_listing_screen.dart';
import 'edit_listing_screen.dart';
import 'create_auction_screen.dart';

class SellerCollectiblesScreen extends StatefulWidget {
  final UserModel user;
  
  const SellerCollectiblesScreen({super.key, required this.user});

  @override
  State<SellerCollectiblesScreen> createState() => _SellerCollectiblesScreenState();
}

class _SellerCollectiblesScreenState extends State<SellerCollectiblesScreen> with SingleTickerProviderStateMixin {
  final FirestoreService _firestoreService = FirestoreService();
  late TabController _tabController;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      // Force rebuild when tab changes to update button label
      if (_tabController.indexIsChanging) {
        setState(() {});
      }
    });
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // Delete confirmation dialog
  Future<void> _showDeleteConfirmation(String listingId) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Delete Collectible'),
          content: const Text(
              'Are you sure you want to delete this collectible? This action cannot be undone.'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.black54,
              ),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                try {
                  await _firestoreService.deleteListing(listingId);
                  if (!mounted) return;
                  
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Collectible deleted successfully'),
                    ),
                  );
                } catch (e) {
                  if (!mounted) return;
                  
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to delete collectible: $e'),
                    ),
                  );
                }
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  // Add image handling method (handles both network and base64 images)
  Widget _getNetworkImage(
    String? imageUrl, {
    BoxFit fit = BoxFit.cover,
    double? width,
    double? height,
  }) {
    if (imageUrl == null || imageUrl.isEmpty) {
      return Container(
        width: width,
        height: height,
        color: Colors.grey[300],
        child: const Center(
          child: Icon(Icons.image, size: 64, color: Colors.grey),
        ),
      );
    }

    return ImageUtils.getImageWidget(
      imageUrl,
      width: width,
      height: height,
      fit: fit,
    );
  }

  @override
  Widget build(BuildContext context) {
    // Define each tab view separately for clarity
    final Widget fixedPriceTab = Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AddListingScreen(user: widget.user),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 50),
            ),
            icon: const Icon(Icons.add),
            label: const Text('Add Collectible'),
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: _buildListingsTab(widget.user.uid, true),
        ),
      ],
    );

    final Widget auctionsTab = Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CreateAuctionScreen(user: widget.user),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 50),
            ),
            icon: const Icon(Icons.add),
            label: const Text('Create Auction'),
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: _buildListingsTab(widget.user.uid, false),
        ),
      ],
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text("My Collectibles"),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: "Fixed Price"),
            Tab(text: "Auctions"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Fixed Price Listings Tab with Add Collectible button
          fixedPriceTab,
          
          // Auctions Tab with Create Auction button
          auctionsTab,
        ],
      ),
    );
  }
  
  Widget _buildListingsTab(String userId, bool isFixedPrice) {
    return StreamBuilder<List<ListingModel>>(
      stream: isFixedPrice
          ? _firestoreService.getFixedPriceListings(sellerId: userId)
          : _firestoreService.getAuctionListings(sellerId: userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text("Error: ${snapshot.error}"),
          );
        }

        final listings = snapshot.data ?? [];

        if (listings.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isFixedPrice ? Icons.monetization_on_outlined : Icons.gavel,
                  size: 64,
                  color: Colors.grey,
                ),
                const SizedBox(height: 16),
                Text(
                  "You don't have any ${isFixedPrice ? 'fixed price listings' : 'auctions'} yet.",
                  style: const TextStyle(fontSize: 16),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16.0),
          itemCount: listings.length,
          itemBuilder: (context, index) {
            final listing = listings[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 16.0),
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Image section
                  Container(
                    height: 150,
                    width: double.infinity,
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(12),
                      ),
                    ),
                    child: _getNetworkImage(
                      listing.images.isNotEmpty ? listing.images[0] : null,
                      width: double.infinity,
                      height: 150,
                    ),
                  ),
                  
                  // Content section
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title and price row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                listing.title,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.primaryContainer,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Text(
                                "RM${listing.price.toStringAsFixed(2)}",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 8),
                        
                        // Category and condition
                        Row(
                          children: [
                            Chip(
                              label: Text(
                                '${listing.category} > ${listing.subcategory}',
                                style: const TextStyle(fontSize: 12),
                              ),
                              backgroundColor: Colors.grey.shade200,
                              padding: EdgeInsets.zero,
                              visualDensity: VisualDensity.compact,
                            ),
                            const SizedBox(width: 8),
                            Chip(
                              label: Text(
                                ListingModel.conditionToString(listing.condition),
                                style: const TextStyle(fontSize: 12),
                              ),
                              backgroundColor: _getConditionColor(listing.condition),
                              padding: EdgeInsets.zero,
                              visualDensity: VisualDensity.compact,
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 8),
                        
                        // Brief description
                        Text(
                          listing.description,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.black87,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        
                        // Add auction-specific information for auction listings
                        if (!listing.isFixedPrice)
                          FutureBuilder<AuctionModel?>(
                            future: _firestoreService.getAuction(listing.id!),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState == ConnectionState.waiting) {
                                return const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 8.0),
                                  child: Center(
                                    child: SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    ),
                                  ),
                                );
                              }
                              
                              if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
                                return const SizedBox.shrink();
                              }
                              
                              final auction = snapshot.data!;
                              
                              return Padding(
                                padding: const EdgeInsets.only(top: 16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Divider
                                    const Divider(height: 1),
                                    const SizedBox(height: 12),
                                    
                                    // Auction status
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'Status: ',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey.shade700,
                                          ),
                                        ),
                                        _buildStatusChip(auction.status),
                                      ],
                                    ),
                                    
                                    const SizedBox(height: 8),
                                    
                                    // Current bid
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'Current Bid:',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey.shade700,
                                          ),
                                        ),
                                        Text(
                                          'RM ${auction.currentPrice.toStringAsFixed(2)}',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.red,
                                          ),
                                        ),
                                      ],
                                    ),
                                    
                                    const SizedBox(height: 8),
                                    
                                    // Number of bids
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'Total Bids:',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey.shade700,
                                          ),
                                        ),
                                        Text(
                                          '${auction.bidCount}',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                    
                                    const SizedBox(height: 8),
                                    
                                                                        // Highest bidder
                                    if (auction.topBidderName != null && auction.topBidderName!.isNotEmpty)
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            'Highest Bidder:',
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: Colors.grey.shade700,
                                            ),
                                          ),
                                          Row(
                                            children: [
                                              Text(
                                                auction.topBidderName!,
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.deepPurple.shade700,
                                                ),
                                              ),
                                              // Message button - only shown for ended auctions
                                              if (auction.status == AuctionStatus.ended && auction.topBidderId != null)
                                                Padding(
                                                  padding: const EdgeInsets.only(left: 8.0),
                                                  child: InkWell(
                                                    onTap: () {
                                                      // Message functionality placeholder for now
                                                      ScaffoldMessenger.of(context).showSnackBar(
                                                        const SnackBar(
                                                          content: Text('Message functionality coming soon'),
                                                        ),
                                                      );
                                                    },
                                                    child: Container(
                                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                      decoration: BoxDecoration(
                                                        color: Colors.blue.shade100,
                                                        borderRadius: BorderRadius.circular(12),
                                                      ),
                                                      child: Row(
                                                        mainAxisSize: MainAxisSize.min,
                                                        children: [
                                                          Icon(
                                                            Icons.message_outlined, 
                                                            size: 16, 
                                                            color: Colors.blue.shade700,
                                                          ),
                                                          const SizedBox(width: 4),
                                                          Text(
                                                            'Message',
                                                            style: TextStyle(
                                                              fontSize: 12,
                                                              fontWeight: FontWeight.bold,
                                                              color: Colors.blue.shade700,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ],
                                      ),
                                  ],
                                ),
                              );
                            },
                          ),
                        
                        const SizedBox(height: 16),
                        
                        // Action buttons
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton.icon(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => EditListingScreen(listingId: listing.id!),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.edit),
                              label: const Text('Edit'),
                            ),
                            const SizedBox(width: 8),
                            TextButton.icon(
                              onPressed: () {
                                _showDeleteConfirmation(listing.id!);
                              },
                              icon: const Icon(Icons.delete_outline),
                              label: const Text('Delete'),
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.red,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
  
  // Add this helper method to build status chips for auctions
  Widget _buildStatusChip(AuctionStatus status) {
    String text;
    Color bgColor;
    Color textColor;
    
    switch (status) {
      case AuctionStatus.active:
        text = 'ACTIVE';
        bgColor = Colors.green.shade100;
        textColor = Colors.green.shade700;
        break;
      case AuctionStatus.pending:
        text = 'PENDING';
        bgColor = Colors.orange.shade100;
        textColor = Colors.orange.shade700;
        break;
      case AuctionStatus.ended:
        text = 'ENDED';
        bgColor = Colors.grey.shade200;
        textColor = Colors.grey.shade700;
        break;
      case AuctionStatus.cancelled:
        text = 'CANCELLED';
        bgColor = Colors.red.shade100;
        textColor = Colors.red.shade700;
        break;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: textColor,
        ),
      ),
    );
  }
  
  Color _getConditionColor(CollectibleCondition condition) {
    switch (condition) {
      case CollectibleCondition.mint:
        return Colors.green.shade100;
      case CollectibleCondition.nearMint:
        return Colors.lightGreen.shade100;
      case CollectibleCondition.excellent:
        return Colors.lime.shade100;
      case CollectibleCondition.good:
        return Colors.amber.shade100;
      case CollectibleCondition.poor:
        return Colors.orange.shade100;
    }
  }
} 