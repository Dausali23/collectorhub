import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:developer' as developer;
import '../../models/user_model.dart';
import '../../models/listing_model.dart';
import '../../utils/image_utils.dart';

class BuyerHomeScreen extends StatefulWidget {
  final UserModel user;
  
  const BuyerHomeScreen({super.key, required this.user});

  @override
  State<BuyerHomeScreen> createState() => _BuyerHomeScreenState();
}

class _BuyerHomeScreenState extends State<BuyerHomeScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _checkImagesInFirestore();
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
                
                // Featured Collectibles
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text(
                    'Featured Collectibles',
                    style: TextStyle(
                      color: Colors.black87,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                
                // Featured Collectibles Stream
                StreamBuilder<QuerySnapshot>(
                  stream: _firestore
                    .collection('listings')
                    .where('isAvailable', isEqualTo: true)
                    .limit(5)
                    .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return const Center(
                        child: Text('Error loading collectibles'),
                      );
                    }

                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(),
                      );
                    }

                    final docs = snapshot.data?.docs ?? [];
                    
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
                              'No collectibles available',
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
                        onPressed: () {},
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
                    .where('isAuction', isEqualTo: true)
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
                              'Check back later for upcoming auctions',
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
                        itemCount: auctions.length,
                        itemBuilder: (context, index) {
                          final listing = ListingModel.fromFirestore(auctions[index]);
                          return _buildAuctionCard(listing);
                        },
                      ),
                    );
                  }
                ),
                
                const SizedBox(height: 16),
                
                // Categories section
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Browse Categories',
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
                
                // Categories Grid
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 3,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    children: [
                      _buildCategoryCard('Trading Cards', Icons.style),
                      _buildCategoryCard('Comics', Icons.book),
                      _buildCategoryCard('Toys', Icons.toys),
                      _buildCategoryCard('Figures', Icons.sports_handball),
                      _buildCategoryCard('Memorabilia', Icons.stars),
                      _buildCategoryCard('Other', Icons.category),
                    ],
                  ),
                ),
                
                const SizedBox(height: 20),
                
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
            // Image
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: listing.images.isNotEmpty
                    ? ImageUtils.getImageWidget(
                        ImageUtils.formatImageUrl(listing.images.first) ?? listing.images.first,
                        fit: BoxFit.cover,
                        width: double.infinity,
                      )
                    : Container(
                        color: Colors.grey.shade200,
                        child: const Center(
                          child: Icon(
                            Icons.image,
                            color: Colors.grey,
                            size: 40,
                          ),
                        ),
                      ),
              ),
            ),
            
            // Info
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    listing.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    listing.category,
                    style: TextStyle(
                      color: Colors.deepPurple.shade400,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "RM ${listing.price.toStringAsFixed(2)}",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
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
            // Live tag
            Container(
              color: Colors.red,
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
              child: const Text(
                'LIVE AUCTION',
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
  
  Widget _buildCategoryCard(String title, IconData icon) {
    return GestureDetector(
      onTap: () {
        // Navigate to category page
      },
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              backgroundColor: Colors.deepPurple.shade100,
              radius: 25,
              child: Icon(
                icon,
                color: Colors.deepPurple,
                size: 30,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w500),
              textAlign: TextAlign.center,
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
        child: SizedBox(
          height: 215,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image with sale/auction badge
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(12),
                      topRight: Radius.circular(12),
                    ),
                    child: listing.images.isNotEmpty
                        ? ImageUtils.getImageWidget(
                            ImageUtils.formatImageUrl(listing.images.first) ?? listing.images.first,
                            fit: BoxFit.cover,
                            width: double.infinity,
                          )
                        : Container(
                            color: Colors.grey.shade200,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.broken_image,
                                  size: 40,
                                  color: Colors.grey.shade500,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Image error',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                  ),
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 2,
                        horizontal: 8,
                      ),
                      decoration: BoxDecoration(
                        color: listing.isFixedPrice ? Colors.blue : Colors.red,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        listing.isFixedPrice ? 'SALE' : 'AUCTION',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      listing.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
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
                    const SizedBox(height: 4),
                    Text(
                      ListingModel.conditionToString(listing.condition),
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const Spacer(),
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
      ),
    );
  }
} 