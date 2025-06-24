import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../models/listing_model.dart';
import '../../models/purchase_model.dart';
import '../../services/firestore_service.dart';
import '../../services/cart_service.dart';
import '../../utils/image_utils.dart';
import 'dart:developer' as developer;
import 'add_listing_screen.dart';
import 'edit_listing_screen.dart';
import 'create_auction_screen.dart';
import 'orders_screen.dart';
import 'order_detail_screen.dart';
import 'seller_main_screen.dart';

class SellerDashboard extends StatefulWidget {
  final UserModel user;
  
  const SellerDashboard({super.key, required this.user});

  @override
  State<SellerDashboard> createState() => _SellerDashboardState();
}

class _SellerDashboardState extends State<SellerDashboard> with SingleTickerProviderStateMixin {
  final FirestoreService _firestoreService = FirestoreService();
  final CartService _cartService = CartService();
  late TabController _tabController;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      // Force rebuild when tab changes to update button label
      if (_tabController.indexIsChanging) {
        developer.log("Tab changing to index: ${_tabController.index}");
        setState(() {});
      }
    });
  }
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    developer.log("Current tab index: ${_tabController.index}");
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

    // Define each tab view separately for clarity
    // Removed unused variable
    Column(
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

    // Removed unused variable
    Column(
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
        title: const Text("Order Management"),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Padding(
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
                        "Welcome, ${widget.user.displayName ?? 'Collector'}!",
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                        "Manage your orders and track your sales from your dashboard.",
                          style: TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                  ),
              ),
              
              const SizedBox(height: 16),
              
              // Orders Summary Card
              _buildOrdersSummaryCard(widget.user),
              
              const SizedBox(height: 24),
              
              // Orders Activity Card
              _buildOrdersActivityCard(),
              
              const SizedBox(height: 16),
              
              // Quick Actions Card
              _buildQuickActionsCard(),
            ],
          ),
        ),
      ),
    );
  }
  
  // Build orders summary card with counts of each status
  Widget _buildOrdersSummaryCard(UserModel user) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Orders Management",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => OrdersScreen(user: user),
                      ),
                    );
                  },
                  child: const Text("View All"),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Order status counts
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildOrderStatusCounter(
                  user, 
                  PurchaseStatus.pending,
                  "Pending",
                  Colors.amber,
                ),
                _buildOrderStatusCounter(
                  user, 
                  PurchaseStatus.claimed,
                  "Claimed",
                  Colors.blue,
                ),
                _buildOrderStatusCounter(
                  user, 
                  PurchaseStatus.confirmed,
                  "Confirmed",
                  Colors.green,
                ),
                _buildOrderStatusCounter(
                  user, 
                  PurchaseStatus.completed,
                  "Completed",
                  Colors.purple,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  // Build orders activity card
  Widget _buildOrdersActivityCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Recent Orders",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            
            const SizedBox(height: 16),
            
            StreamBuilder<List<PurchaseModel>>(
              stream: _cartService.getSellerPurchases(
                widget.user.uid, 
                status: null,
              ),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                final purchases = snapshot.data ?? [];
                if (purchases.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text(
                        "No orders yet",
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  );
                }
                
                // Show the most recent 3 orders
                final recentOrders = purchases.take(3).toList();
                
                return Column(
                  children: recentOrders.map((purchase) => 
                    _buildOrderListTile(purchase)
                  ).toList(),
                );
              },
            ),
            
            const SizedBox(height: 16),
            
            Center(
              child: TextButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => OrdersScreen(user: widget.user),
                    ),
                  );
                },
                icon: const Icon(Icons.list_alt),
                label: const Text("View All Orders"),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  // Build order list tile
  Widget _buildOrderListTile(PurchaseModel purchase) {
    Color statusColor;
    IconData statusIcon;
    
    switch (purchase.status) {
      case PurchaseStatus.pending:
        statusColor = Colors.amber;
        statusIcon = Icons.access_time;
        break;
      case PurchaseStatus.claimed:
        statusColor = Colors.blue;
        statusIcon = Icons.paid;
        break;
      case PurchaseStatus.confirmed:
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case PurchaseStatus.completed:
        statusColor = Colors.purple;
        statusIcon = Icons.verified;
        break;
    }
    
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
      visualDensity: VisualDensity.compact,
      leading: purchase.listingImages.isNotEmpty 
                  ? ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              purchase.listingImages.first,
              width: 48,
              height: 48,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  width: 48,
                  height: 48,
                  color: Colors.grey.shade300,
                  child: const Icon(Icons.broken_image, color: Colors.grey),
                );
              },
            ),
          )
        : Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.image_not_supported),
          ),
      title: Text(
        purchase.listingTitle,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontSize: 13),
      ),
      subtitle: Text(
        '${purchase.buyerName} • \$${purchase.price.toStringAsFixed(2)}',
        style: const TextStyle(fontSize: 11),
      ),
      trailing: Icon(
        statusIcon,
        color: statusColor,
        size: 20,
      ),
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
    );
  }
  
  // Build quick actions card
  Widget _buildQuickActionsCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Quick Actions",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            
            const SizedBox(height: 16),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildQuickActionButton(
                  icon: Icons.inventory,
                  label: "Orders",
                  color: Colors.blue,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => OrdersScreen(user: widget.user),
                      ),
                    );
                  },
                ),
                _buildQuickActionButton(
                  icon: Icons.pending_actions,
                  label: "Pending",
                  color: Colors.amber,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => OrdersScreen(user: widget.user),
                      ),
                    );
                  },
                ),
                _buildQuickActionButton(
                  icon: Icons.shopping_bag,
                  label: "Products",
                  color: Colors.green,
                  onTap: () {
                    // Navigate to collectibles tab
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => SellerMainScreen(
                          user: widget.user,
                          initialIndex: 1,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  // Build quick action button
  Widget _buildQuickActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 70,
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Column(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Color.fromRGBO(
                  (color.value >> 16) & 0xFF, 
                  (color.value >> 8) & 0xFF, 
                  color.value & 0xFF, 
                  0.1
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: color,
                size: 24,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: color,
            ),
          ),
        ],
        ),
      ),
    );
  }

  // Build order status counter with count badge
  Widget _buildOrderStatusCounter(
    UserModel user,
    PurchaseStatus status,
    String label,
    Color color,
  ) {
    return StreamBuilder<List<PurchaseModel>>(
      stream: _cartService.getSellerPurchases(
        user.uid, 
        status: status,
      ),
      builder: (context, snapshot) {
        final count = snapshot.hasData ? snapshot.data!.length : 0;
        
        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => OrdersScreen(user: user),
              ),
            );
          },
          child: Column(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Color.fromRGBO(
                    (color.value >> 16) & 0xFF, 
                    (color.value >> 8) & 0xFF, 
                    color.value & 0xFF, 
                    0.1
                  ),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    count.toString(),
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: color,
                ),
              ),
            ],
          ),
        );
      },
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
      builder: (BuildContext dialogContext) { // Use a separate context for the dialog
        return AlertDialog(
          title: const Text('Delete Collectible'),
          content: const Text(
              'Are you sure you want to delete this collectible? This action cannot be undone.'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(); // Use dialogContext
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.black54,
              ),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(dialogContext).pop(); // Use dialogContext
                try {
                  await _firestoreService.deleteListing(listingId);
                  if (!mounted) return;
                  
                  // Now it's safe to use context because we checked mounted
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Collectible deleted successfully'),
                    ),
                  );
                } catch (e) {
                  if (!mounted) return;
                  
                  // Now it's safe to use context because we checked mounted
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