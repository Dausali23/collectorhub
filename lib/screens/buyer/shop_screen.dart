import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/user_model.dart';
import '../../models/listing_model.dart';
import '../../utils/image_utils.dart';
import '../../services/firestore_service.dart';
import 'item_detail_screen.dart';
import 'auction_detail_screen.dart';
import 'cart_screen.dart';
import '../../widgets/current_bid_display.dart';
import '../../models/auction_model.dart';

class ShopScreen extends StatefulWidget {
  final UserModel user;
  final bool initialShowAuctions;
  
  const ShopScreen({
    super.key, 
    required this.user,
    this.initialShowAuctions = false,
  });

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirestoreService _firestoreService = FirestoreService();
  bool _showAuctions = false;
  String _selectedCategory = 'All Categories';
  final TextEditingController _searchController = TextEditingController();

  final List<String> categories = [
    'All Categories',
    'Trading Cards',
    'Comics',
    'Toys',
    'Figures',
    'Memorabilia',
  ];
  
  @override
  void initState() {
    super.initState();
    _showAuctions = widget.initialShowAuctions;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search bar
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(25),
                      ),
                      child: TextField(
                        controller: _searchController,
                        decoration: const InputDecoration(
                          hintText: 'Search collectibles',
                          prefixIcon: Icon(Icons.search),
                          border: InputBorder.none,
                        ),
                        onSubmitted: (value) {
                          setState(() {});
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: () {
                      // Navigate to cart screen
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CartScreen(user: widget.user),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(25),
                      ),
                      child: const Icon(Icons.shopping_cart),
                    ),
                  ),
                ],
              ),
            ),
            
            // Category filter
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: categories.map((category) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: ChoiceChip(
                        label: Text(category),
                        selected: _selectedCategory == category,
                        onSelected: (selected) {
                          setState(() {
                            _selectedCategory = category;
                          });
                        },
                        backgroundColor: Colors.grey.shade200,
                        selectedColor: Colors.deepPurple.shade100,
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            
            // Toggle buttons
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _showAuctions = false;
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: !_showAuctions 
                            ? Colors.deepPurple 
                            : Colors.grey.shade300,
                        foregroundColor: !_showAuctions
                            ? Colors.white
                            : Colors.black,
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(20),
                            bottomLeft: Radius.circular(20),
                          ),
                        ),
                        minimumSize: const Size(0, 45),
                      ),
                      child: const Text('Shop Items'),
                    ),
                  ),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _showAuctions = true;
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _showAuctions
                            ? Colors.deepPurple
                            : Colors.grey.shade300,
                        foregroundColor: _showAuctions
                            ? Colors.white
                            : Colors.black,
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.only(
                            topRight: Radius.circular(20),
                            bottomRight: Radius.circular(20),
                          ),
                        ),
                        minimumSize: const Size(0, 45),
                      ),
                      child: const Text('Auctions'),
                    ),
                  ),
                ],
              ),
            ),
            
            // Collectibles list
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _buildCollectiblesStream(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }
                  
                  if (snapshot.hasError) {
                    return Center(
                      child: Text('Error: ${snapshot.error}'),
                    );
                  }
                  
                  var documents = snapshot.data?.docs ?? [];
                  
                  // Apply search filter in the UI if needed
                  final searchText = _searchController.text.trim().toLowerCase();
                  if (searchText.isNotEmpty) {
                    documents = documents.where((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      final title = (data['title'] ?? '').toString().toLowerCase();
                      final description = (data['description'] ?? '').toString().toLowerCase();
                      final category = (data['category'] ?? '').toString().toLowerCase();
                      
                      return title.contains(searchText) || 
                             description.contains(searchText) || 
                             category.contains(searchText);
                    }).toList();
                  }
                  
                  // Process auctions to check if they're expired
                  final validDocuments = <DocumentSnapshot>[];
                  
                  for (var doc in documents) {
                    final data = doc.data() as Map<String, dynamic>;
                    final isFixedPrice = data['isFixedPrice'] ?? true;
                    
                    // If this is an auction, check its status
                    if (!isFixedPrice) {
                      _firestoreService.checkAndUpdateAuctionStatus(doc.id);
                    }
                    
                    validDocuments.add(doc);
                  }
                  
                  if (validDocuments.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _showAuctions ? Icons.gavel : Icons.collections,
                            size: 70,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 24),
                          Text(
                            _showAuctions ? 'No auctions available' : 'No items available',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _showAuctions
                                ? 'Check back later for upcoming auctions'
                                : 'Be the first to add a collectible!',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey.shade600,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    );
                  }
                  
                  return RefreshIndicator(
                    onRefresh: () async {
                      setState(() {});
                      return Future.delayed(const Duration(milliseconds: 1000));
                    },
                    child: GridView.builder(
                      padding: const EdgeInsets.all(16),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 0.7,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                      ),
                      itemCount: validDocuments.length,
                      itemBuilder: (context, index) {
                        final listing = ListingModel.fromFirestore(validDocuments[index]);
                        return _buildListingCard(listing);
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Stream<QuerySnapshot> _buildCollectiblesStream() {
    Query query = _firestore.collection('listings')
      .where('isAvailable', isEqualTo: true);
    
    // Apply fixed price filter
    if (_showAuctions) {
      query = query.where('isFixedPrice', isEqualTo: false);
    } else {
      query = query.where('isFixedPrice', isEqualTo: true);
    }
    
    // Apply category filter if not "All Categories" and it's supported by Firestore
    if (_selectedCategory != 'All Categories') {
      query = query.where('category', isEqualTo: _selectedCategory);
    }
    
    // Use ordering that matches our existing index
    query = query.orderBy('createdAt', descending: true);
    
    // Get the base stream - we'll filter for search terms in the UI if needed
    return query.snapshots();
  }
  
  Widget _buildListingCard(ListingModel listing) {
    return GestureDetector(
      onTap: () {
        // Navigate to details page
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => listing.isFixedPrice
                ? ItemDetailScreen(
                    item: listing,
                    currentUser: widget.user,
                  )
                : AuctionDetailScreen(
              item: listing,
              currentUser: widget.user,
            ),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withAlpha(51),
              spreadRadius: 1,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image with sale/auction badge
            Stack(
              children: [
                // Image container with fixed height
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                  child: SizedBox(
                    height: 110,
                    width: double.infinity,
                    child: listing.images.isNotEmpty
                        ? ImageUtils.getImageWidget(
                            ImageUtils.formatImageUrl(listing.images.first) ?? listing.images.first,
                            fit: BoxFit.cover,
                          )
                        : Container(
                            color: Colors.grey.shade200,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.image_not_supported,
                                  size: 40,
                                  color: Colors.grey.shade500,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'No image',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                  ),
                ),
                
                // Sale/Auction badge
                Positioned(
                  top: 8,
                  left: 8,
                  child: listing.isFixedPrice 
                  ? Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 2,
                        horizontal: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'SALE',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    )
                  : FutureBuilder<AuctionModel?>(
                      future: _firestoreService.getAuction(listing.id!),
                      builder: (context, snapshot) {
                        Color badgeColor = Colors.red;
                        String badgeText = 'AUCTION';
                        
                        if (snapshot.hasData && snapshot.data != null) {
                          final auction = snapshot.data!;
                          if (auction.status == AuctionStatus.ended) {
                            badgeColor = Colors.grey.shade600;
                            badgeText = 'ENDED';
                          }
                        }
                        
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            vertical: 2,
                            horizontal: 8,
                          ),
                          decoration: BoxDecoration(
                            color: badgeColor,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            badgeText,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        );
                      },
                    ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.favorite_border,
                      size: 16,
                    ),
                  ),
                ),
              ],
            ),
            
            // Content with Expanded to use remaining space
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Seller info
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 8,
                          backgroundColor: Colors.deepPurple.shade300,
                          child: const Text(
                            'S',
                            style: TextStyle(
                              fontSize: 8,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            listing.sellerName,
                            style: const TextStyle(fontSize: 10),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    
                    // Item title
                    Text(
                      listing.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    
                    // Condition and category
                    Text(
                      '${ListingModel.conditionToString(listing.condition)} • ${listing.category}',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey.shade600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    
                    // Push price to bottom with spacer
                    const Spacer(),
                    
                    // Price
                    Row(
                      children: [
                        listing.isFixedPrice
                        ? Text(
                          "RM ${listing.price.toStringAsFixed(2)}",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                          )
                        : Expanded(
                            child: CurrentBidDisplay(
                              listingId: listing.id!,
                              initialPrice: listing.price,
                              showLabel: false,
                              showHighestBidder: true,
                            ),
                        ),
                        if (listing.isFixedPrice) const Spacer(),
                        // Market price comparison if available
                        if (listing.marketPrice != null && listing.marketPrice! > 0)
                          Icon(
                            _getPriceComparisonIcon(listing.price, listing.marketPrice!),
                            size: 12,
                            color: _getPriceComparisonColor(listing.price, listing.marketPrice!),
                          ),
                      ],
                    ),
                    
                    // Optional comparison text row - only show if there's space
                    if (listing.marketPrice != null && listing.marketPrice! > 0)
                      Text(
                        "Market: RM ${listing.marketPrice!.toStringAsFixed(2)}",
                        style: TextStyle(
                          fontSize: 10,
                          color: _getPriceComparisonColor(listing.price, listing.marketPrice!),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
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
} 