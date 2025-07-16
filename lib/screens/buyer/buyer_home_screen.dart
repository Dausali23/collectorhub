import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:developer' as developer;
import '../../models/user_model.dart';
import '../../models/listing_model.dart';
import '../../models/auction_model.dart';
import '../../utils/image_utils.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'shop_screen.dart';
import 'item_detail_screen.dart';
import 'auction_detail_screen.dart';
import '../../widgets/current_bid_display.dart';
import '../../services/firestore_service.dart';

class BuyerHomeScreen extends StatefulWidget {
  final UserModel user;
  
  const BuyerHomeScreen({super.key, required this.user});

  @override
  State<BuyerHomeScreen> createState() => _BuyerHomeScreenState();
}

class _BuyerHomeScreenState extends State<BuyerHomeScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirestoreService _firestoreService = FirestoreService();
  // Add category-related state variables
  final List<String> _categories = [
    'Trading Cards',
    'Comics',
    'Toys',
    'Stamps',
    'Coins',
    'Funko Pops',
    'Action Figures',
    'Vintage Items',
  ];
  
  // Track selected categories for recommendations
  Set<String> _selectedCategories = {};

  @override
  void initState() {
    super.initState();
    _checkImagesInFirestore();
    _loadSavedCategories();
  }
  
  // Load saved category preferences
  Future<void> _loadSavedCategories() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedCategories = prefs.getStringList('user_preferred_categories');
      if (savedCategories != null && savedCategories.isNotEmpty) {
        setState(() {
          _selectedCategories = savedCategories.toSet();
        });
      } else {
        // Default to all categories if none are saved
        setState(() {
          _selectedCategories = _categories.toSet();
        });
      }
    } catch (e) {
      developer.log('Error loading saved categories: $e');
      // Default to all categories
      setState(() {
        _selectedCategories = _categories.toSet();
      });
    }
  }
  
  // Save selected categories
  Future<void> _saveSelectedCategories() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('user_preferred_categories', _selectedCategories.toList());
    } catch (e) {
      developer.log('Error saving categories: $e');
    }
  }

  // Function to check if image URLs are valid
  Future<void> _checkImagesInFirestore() async {
    try {
      final listingsSnapshot = await _firestore
          .collection('listings')
          .where('isAvailable', isEqualTo: true)
          .limit(5)
          .get();
          
      for (var doc in listingsSnapshot.docs) {
        final data = doc.data();
        if (data.containsKey('images')) {
          final images = data['images'] as List<dynamic>?;
          if (images != null && images.isNotEmpty) {
            final url = images.first.toString();
            developer.log('Checking image URL: $url');
            
            if (url.isEmpty) {
              developer.log('Empty image URL found for listing ${doc.id}');
              continue;
            }
            
            // Check if URL is correctly formatted
            final formattedUrl = ImageUtils.formatImageUrl(url);
            developer.log('Formatted URL: $formattedUrl');
            
            // Validate the URL
            final isValid = await ImageUtils.isImageUrlValid(formattedUrl);
            developer.log('URL is ${isValid ? 'valid' : 'invalid'}: $formattedUrl');
          } else {
            developer.log('Empty images array for listing ${doc.id}');
          }
        } else {
          developer.log('No images field found for listing ${doc.id}');
        }
      }
    } catch (e) {
      developer.log('Error checking Firestore images: $e');
    }
  }

  // Build recommendation stream based on selected categories
  Stream<QuerySnapshot> _buildRecommendationsStream() {
    Query query = _firestore
      .collection('listings')
      .where('isAvailable', isEqualTo: true);
      
    // We can only apply one array-contains filter in Firestore
    // So instead, just limit results and filter in the UI if there are selected categories
    return query
      .orderBy('createdAt', descending: true)
      .limit(20)  // Get more items so we have enough after filtering
      .snapshots();
  }
  
  // Show dialog for category filtering
  void _showCategoryFilterDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        // Create a temporary set to hold changes during dialog interaction
        final tempSelectedCategories = Set<String>.from(_selectedCategories);
        
        return AlertDialog(
          title: const Text(
            'Select Categories',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: StatefulBuilder(
              builder: (BuildContext context, StateSetter setState) {
                return SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ListTile(
                        title: const Text('Select All'),
                        trailing: Checkbox(
                          value: tempSelectedCategories.length == _categories.length,
                          onChanged: (bool? value) {
                            setState(() {
                              if (value == true) {
                                tempSelectedCategories.addAll(_categories);
                              } else {
                                tempSelectedCategories.clear();
                              }
                            });
                          },
                        ),
                      ),
                      const Divider(),
                      ...List.generate(_categories.length, (index) {
                        final category = _categories[index];
                        return CheckboxListTile(
                          title: Text(category),
                          value: tempSelectedCategories.contains(category),
                          onChanged: (bool? value) {
                            setState(() {
                              if (value == true) {
                                tempSelectedCategories.add(category);
                              } else {
                                tempSelectedCategories.remove(category);
                              }
                            });
                          },
                        );
                      })
                    ],
                  ),
                );
              },
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('CANCEL'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('APPLY'),
              onPressed: () {
                setState(() {
                  _selectedCategories = tempSelectedCategories;
                });
                _saveSelectedCategories();
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            setState(() {});
            return Future.delayed(const Duration(milliseconds: 1500));
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // App Bar
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.deepPurple.shade400,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.collections_bookmark,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'CollectorHub',
                            style: TextStyle(
                              color: Colors.deepPurple,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.search, color: Colors.deepPurple),
                            onPressed: () {},
                          ),
                          IconButton(
                            icon: const Icon(Icons.notifications_none, color: Colors.deepPurple),
                            onPressed: () {},
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                // Recommendations Section (formerly Featured Collectibles)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Recommended For You',
                        style: TextStyle(
                          color: Colors.black87,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () {
                          _showCategoryFilterDialog();
                        },
                        icon: const Icon(Icons.tune, size: 16),
                        label: const Text('Filter'),
                      ),
                    ],
                  ),
                ),
                
                // Recommendations Stream
                StreamBuilder<QuerySnapshot>(
                  stream: _buildRecommendationsStream(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return const Center(
                        child: Text('Error loading recommendations'),
                      );
                    }

                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(),
                      );
                    }

                    var docs = snapshot.data?.docs ?? [];
                    
                    // Filter by selected categories if any are selected
                    if (_selectedCategories.isNotEmpty && _selectedCategories.length < _categories.length) {
                      docs = docs.where((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        final category = data['category'] as String;
                        return _selectedCategories.contains(category);
                      }).toList();
                    }
                    
                    // Limit to 5 items for display
                    if (docs.length > 5) {
                      docs = docs.sublist(0, 5);
                    }
                    
                    // Check if there are no items
                    if (docs.isEmpty) {
                      return Container(
                        height: 200,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.collections, size: 50, color: Colors.grey.shade400),
                            const SizedBox(height: 16),
                            const Text(
                              'No recommendations available',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Try selecting different categories',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      );
                    }
                    
                    return SizedBox(
                      height: 240,
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        scrollDirection: Axis.horizontal,
                        itemCount: docs.length,
                        itemBuilder: (context, index) {
                          final listing = ListingModel.fromFirestore(docs[index]);
                          return _buildFeaturedCard(listing);
                        },
                      ),
                    );
                  }
                ),
                
                const SizedBox(height: 16),
                
                // Fixed Price Items section
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Fixed Price Items',
                        style: TextStyle(
                          color: Colors.black87,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context, 
                            MaterialPageRoute(
                              builder: (context) => ShopScreen(
                                user: widget.user,
                                initialShowAuctions: false,
                              ),
                            ),
                          );
                        },
                        child: const Text('View All'),
                      ),
                    ],
                  ),
                ),
                
                // Fixed Price Items Stream
                StreamBuilder<QuerySnapshot>(
                  stream: _firestore
                    .collection('listings')
                    .where('isAvailable', isEqualTo: true)
                    .where('isFixedPrice', isEqualTo: true)
                    .orderBy('createdAt', descending: true)
                    .limit(10)
                    .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return const Text('Error loading fixed price items');
                    }

                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(),
                      );
                    }

                    final fixedPriceItems = snapshot.data?.docs ?? [];
                    
                    // Check if no fixed price items are available
                    if (fixedPriceItems.isEmpty) {
                      return Container(
                        height: 200,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.sell, size: 50, color: Colors.grey.shade400),
                            const SizedBox(height: 16),
                            const Text(
                              'No fixed price items available',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Be the first to add an item!',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      );
                    }
                    
                    return SizedBox(
                      height: 200,
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        scrollDirection: Axis.horizontal,
                        itemCount: fixedPriceItems.length,
                        itemBuilder: (context, index) {
                          final listing = ListingModel.fromFirestore(fixedPriceItems[index]);
                          return _buildFixedPriceCard(listing);
                        },
                      ),
                    );
                  }
                ),
                
                const SizedBox(height: 16),
                
                // Auction section
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Live Auctions',
                        style: TextStyle(
                          color: Colors.black87,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ShopScreen(
                                user: widget.user,
                                initialShowAuctions: true,
                              ),
                            ),
                          );
                        },
                        child: const Text('View All'),
                      ),
                    ],
                  ),
                ),
                
                // Live Auction Stream
                StreamBuilder<QuerySnapshot>(
                  stream: _firestore
                    .collection('listings')
                    .where('isAvailable', isEqualTo: true)
                    .where('isFixedPrice', isEqualTo: false)
                    .orderBy('createdAt', descending: true)
                    .limit(10)
                    .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return const Text('Error loading auctions');
                    }

                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(),
                      );
                    }

                    final auctions = snapshot.data?.docs ?? [];
                    
                    // Check if no auctions are available
                    if (auctions.isEmpty) {
                      return Container(
                        height: 200,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.gavel, size: 50, color: Colors.grey.shade400),
                            const SizedBox(height: 16),
                            const Text(
                              'No auctions available',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Be the first to add an item!',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      );
                    }
                    
                    // Get list of active auctions
                    final activeAuctions = [];
                    
                    // Process auctions to check if they're expired
                    for (var doc in auctions) {
                      final listing = ListingModel.fromFirestore(doc);
                      
                      // Check if this auction has associated auction data
                      if (listing.id != null) {
                        // Check auction status
                        _firestoreService.checkAndUpdateAuctionStatus(listing.id!);
                        
                        // Add to list of auctions to display
                        activeAuctions.add(doc);
                      }
                    }
                    
                    return SizedBox(
                      height: 200,
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        scrollDirection: Axis.horizontal,
                        itemCount: activeAuctions.length,
                        itemBuilder: (context, index) {
                          final listing = ListingModel.fromFirestore(activeAuctions[index]);
                          return _buildAuctionCard(listing);
                        },
                      ),
                    );
                  }
                ),
                
                const SizedBox(height: 16),
                
                // Recent Listings
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Recent Listings',
                        style: TextStyle(
                          color: Colors.black87,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextButton(
                        onPressed: () {},
                        child: const Text('View All'),
                      ),
                    ],
                  ),
                ),
                
                // Recent Listings Stream
                StreamBuilder<QuerySnapshot>(
                  stream: _firestore
                    .collection('listings')
                    .where('isAvailable', isEqualTo: true)
                    .limit(6)
                    .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(20.0),
                          child: CircularProgressIndicator(),
                        ),
                      );
                    }
                    
                    if (snapshot.hasError) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(20.0),
                          child: Text('Error loading listings'),
                        ),
                      );
                    }
                    
                    final documents = snapshot.data?.docs ?? [];
                    if (documents.isEmpty) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(20.0),
                          child: Text('No recent listings'),
                        ),
                      );
                    }
                    
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.75,
                          mainAxisSpacing: 16,
                          crossAxisSpacing: 16,
                        ),
                        itemCount: documents.length,
                        itemBuilder: (context, index) {
                          final listing = ListingModel.fromFirestore(documents[index]);
                          return _buildRecentListingCard(listing);
                        },
                      ),
                    );
                  }
                ),
                
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildFeaturedCard(ListingModel listing) {
    return GestureDetector(
      onTap: () {
        // Navigate to item details
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
        width: 180,
        margin: const EdgeInsets.only(left: 4, right: 4, bottom: 8, top: 8),
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
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
                  mainAxisSize: MainAxisSize.min,
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
                    
                    // Optional comparison text row - only show if there's space and it's not an auction
                    if (listing.isFixedPrice && listing.marketPrice != null && listing.marketPrice! > 0)
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
  
  Widget _buildFixedPriceCard(ListingModel listing) {
    return GestureDetector(
      onTap: () {
        // Navigate to item details page
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ItemDetailScreen(
              item: listing,
              currentUser: widget.user,
            ),
          ),
        );
      },
      child: Container(
        width: 150,
        margin: const EdgeInsets.only(right: 12, top: 8, bottom: 8),
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
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Sale tag
            Container(
              color: Colors.blue,
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
              child: const Text(
                'SALE',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 10,
                ),
              ),
            ),
            
            // Image
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
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
            
            // Price
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    listing.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "RM ${listing.price.toStringAsFixed(2)}",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildAuctionCard(ListingModel listing) {
    return GestureDetector(
      onTap: () {
        // Navigate to auction details
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AuctionDetailScreen(
              item: listing,
              currentUser: widget.user,
            ),
          ),
        );
      },
      child: Container(
        width: 150,
        margin: const EdgeInsets.only(right: 12, top: 8, bottom: 8),
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
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Auction tag
            FutureBuilder<AuctionModel?>(
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
                  color: badgeColor,
                  padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                  child: Text(
                    badgeText,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                    ),
                  ),
                );
              },
            ),
            
            // Image
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
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
            
            // Price
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    listing.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  CurrentBidDisplay(
                    listingId: listing.id!,
                    initialPrice: listing.price,
                    showLabel: false,
                    showHighestBidder: true,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildRecentListingCard(ListingModel listing) {
    return GestureDetector(
      onTap: () {
        // Navigate to item details
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
                  mainAxisSize: MainAxisSize.min,
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
                    
                    // Optional comparison text row - only show if there's space and it's not an auction
                    if (listing.isFixedPrice && listing.marketPrice != null && listing.marketPrice! > 0)
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