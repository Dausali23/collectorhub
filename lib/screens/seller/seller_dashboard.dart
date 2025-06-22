import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/user_model.dart';
import '../../models/listing_model.dart';
import '../../services/firestore_service.dart';
import '../../utils/image_utils.dart';
import 'add_listing_screen.dart';
import 'edit_listing_screen.dart';
import 'create_auction_screen.dart';

class SellerDashboard extends StatefulWidget {
  const SellerDashboard({super.key});

  @override
  State<SellerDashboard> createState() => _SellerDashboardState();
}

class _SellerDashboardState extends State<SellerDashboard> with SingleTickerProviderStateMixin {
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
    final user = Provider.of<UserModel?>(context);
    
    if (user == null) {
      return const Center(child: CircularProgressIndicator());
    }

    // Determine button text based on active tab
    final bool isFixedPriceTab = _tabController.index == 0;
    final String buttonText = isFixedPriceTab ? 'Add Collectible' : 'Create Auction';

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
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // Welcome Card
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Welcome, ${user.displayName ?? 'Collector'}!",
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          "Manage your collectibles and track your auctions from your dashboard.",
                          style: TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Fixed Price Listings Tab
                Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => AddListingScreen(user: user),
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
                      child: _buildListingsTab(user.uid, true),
                    ),
                  ],
                ),
                
                // Auctions Tab
                Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => CreateAuctionScreen(user: user),
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
                      child: _buildListingsTab(user.uid, false),
                    ),
                  ],
                ),
              ],
            ),
          ),
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

  Future<void> _showDeleteConfirmation(String listingId) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Collectible'),
          content: const Text(
              'Are you sure you want to delete this collectible? This action cannot be undone.'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.black54,
              ),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
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
}