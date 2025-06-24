import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../models/listing_model.dart';
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
              margin: const EdgeInsets.only(bottom: 16),
              clipBehavior: Clip.antiAlias,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Listing image
                  if (listing.images.isNotEmpty)
                    AspectRatio(
                      aspectRatio: 16 / 9,
                      child: _getNetworkImage(
                        listing.images.first,
                        fit: BoxFit.cover,
                      ),
                    )
                  else
                    AspectRatio(
                      aspectRatio: 16 / 9,
                      child: Container(
                        color: Colors.grey[300],
                        child: const Center(
                          child: Icon(Icons.image, size: 64, color: Colors.grey),
                        ),
                      ),
                    ),
                  
                  // Listing details
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
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
                            Text(
                              "\$${listing.price.toStringAsFixed(2)}",
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          listing.description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: Colors.grey[700]),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          children: [
                            Chip(
                              label: Text(listing.category),
                              backgroundColor: Color.fromRGBO(
                                (Theme.of(context).colorScheme.primary.value >> 16) & 0xFF,
                                (Theme.of(context).colorScheme.primary.value >> 8) & 0xFF,
                                Theme.of(context).colorScheme.primary.value & 0xFF,
                                0.2
                              ),
                              padding: EdgeInsets.zero,
                              visualDensity: VisualDensity.compact,
                            ),
                            Chip(
                              label: Text(ListingModel.conditionToString(listing.condition)),
                              backgroundColor: Color.fromRGBO(
                                (Theme.of(context).colorScheme.secondary.value >> 16) & 0xFF,
                                (Theme.of(context).colorScheme.secondary.value >> 8) & 0xFF,
                                Theme.of(context).colorScheme.secondary.value & 0xFF,
                                0.2
                              ),
                              padding: EdgeInsets.zero,
                              visualDensity: VisualDensity.compact,
                            ),
                            if (!listing.isFixedPrice)
                              Chip(
                                label: const Text("Auction"),
                                backgroundColor: Color.fromRGBO(
                                  (Colors.amber.value >> 16) & 0xFF,
                                  (Colors.amber.value >> 8) & 0xFF,
                                  Colors.amber.value & 0xFF,
                                  0.2
                                ),
                                padding: EdgeInsets.zero,
                                visualDensity: VisualDensity.compact,
                              ),
                          ],
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // Management buttons
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            ElevatedButton.icon(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => EditListingScreen(
                                      listingId: listing.id!,
                                    ),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.edit, size: 18),
                              label: const Text('Edit'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Theme.of(context).colorScheme.primary,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              ),
                            ),
                            ElevatedButton.icon(
                              onPressed: () {
                                _showDeleteConfirmation(listing.id!);
                              },
                              icon: const Icon(Icons.delete, size: 18),
                              label: const Text('Delete'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.redAccent,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
} 