import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/listing_model.dart';
import '../models/user_model.dart';
import '../models/auction_model.dart';
import '../models/event_model.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Collection references
  final CollectionReference _usersCollection = 
      FirebaseFirestore.instance.collection('users');
  final CollectionReference _listingsCollection = 
      FirebaseFirestore.instance.collection('listings');
  final CollectionReference _auctionsCollection = 
      FirebaseFirestore.instance.collection('auctions');
  final CollectionReference _bidsCollection = 
      FirebaseFirestore.instance.collection('bids');
  final CollectionReference _eventsCollection =
      FirebaseFirestore.instance.collection('events');
  
  // Save user data to Firestore
  Future<void> saveUserData(UserModel user) async {
    return await _usersCollection.doc(user.uid).set({
      'email': user.email,
      'role': user.role.toString().split('.').last,
      'displayName': user.displayName,
      'phoneNumber': user.phoneNumber,
      'photoUrl': user.photoUrl,
    });
  }

  // Get user data from Firestore
  Future<UserModel?> getUserData(String uid) async {
    DocumentSnapshot doc = await _usersCollection.doc(uid).get();
    if (!doc.exists) {
      return null;
    }
    
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      uid: uid,
      email: data['email'] ?? '',
      role: _parseUserRole(data['role'] ?? 'buyer'),
      displayName: data['displayName'],
      phoneNumber: data['phoneNumber'],
      photoUrl: data['photoUrl'],
    );
  }

  // Parse string to UserRole enum
  UserRole _parseUserRole(String roleStr) {
    switch (roleStr.toLowerCase()) {
      case 'seller':
        return UserRole.seller;
      case 'admin':
        return UserRole.admin;
      default:
        return UserRole.buyer;
    }
  }
  
  // Add a new listing
  Future<String> addListing(ListingModel listing) async {
    try {
      DocumentReference docRef = await _listingsCollection.add(listing.toMap());
      
      // Create auction if this is an auction listing
      if (!listing.isFixedPrice) {
        await _createAuctionForListing(docRef.id, listing);
      }
      
      return docRef.id;
    } catch (e) {
      print('Error adding listing: $e');
      rethrow;
    }
  }
  
  // Create an auction entry for a listing
  Future<void> _createAuctionForListing(String listingId, ListingModel listing) async {
    // Default auction duration - 7 days
    DateTime endTime = DateTime.now().add(const Duration(days: 7));
    
    await _auctionsCollection.doc(listingId).set({
      'listingId': listingId,
      'sellerId': listing.sellerId,
      'startingPrice': listing.price,
      'currentPrice': listing.price,
      'startTime': Timestamp.fromDate(listing.createdAt),
      'endTime': Timestamp.fromDate(endTime),
      'status': 'active',
      'bidCount': 0,
      'topBidderId': null,
    });
  }
  
  // Add a new auction with custom parameters
  Future<String> createAuction({
    required String title,
    required String description,
    required String sellerId,
    required String sellerName,
    required double startingPrice,
    required double bidIncrement,
    required DateTime startTime,
    required DateTime endTime,
    required String category,
    required String subcategory,
    required CollectibleCondition condition,
    required List<String> images,
  }) async {
    try {
      // First create the listing with isFixedPrice set to false
      ListingModel listing = ListingModel(
        sellerId: sellerId,
        sellerName: sellerName,
        title: title,
        description: description,
        price: startingPrice,
        category: category,
        subcategory: subcategory,
        condition: condition,
        images: images,
        isFixedPrice: false,
        createdAt: DateTime.now(),
      );
      
      // Add the listing to Firestore
      DocumentReference listingRef = await _listingsCollection.add(listing.toMap());
      String listingId = listingRef.id;
      
      // Create the auction with custom parameters
      AuctionModel auction = AuctionModel(
        listingId: listingId,
        sellerId: sellerId,
        sellerName: sellerName,
        startingPrice: startingPrice,
        currentPrice: startingPrice,
        bidIncrement: bidIncrement,
        startTime: startTime,
        endTime: endTime,
        status: startTime.isAfter(DateTime.now()) ? AuctionStatus.pending : AuctionStatus.active,
        bidCount: 0,
      );
      
      // Save the auction to Firestore
      await _auctionsCollection.doc(listingId).set(auction.toMap());
      
      return listingId;
    } catch (e) {
      print('Error creating auction: $e');
      rethrow;
    }
  }
  
  // Update an existing listing
  Future<void> updateListing(ListingModel listing) async {
    if (listing.id == null) {
      throw ArgumentError('Listing ID cannot be null for updates');
    }
    
    try {
      await _listingsCollection.doc(listing.id).update(listing.toMap());
      
      // Update or create auction if necessary
      DocumentSnapshot auctionDoc = await _auctionsCollection.doc(listing.id).get();
      
      if (!listing.isFixedPrice && !auctionDoc.exists) {
        // Create new auction for a listing that was converted to auction
        await _createAuctionForListing(listing.id!, listing);
      } else if (listing.isFixedPrice && auctionDoc.exists) {
        // Remove auction for a listing that was converted to fixed price
        await _auctionsCollection.doc(listing.id).delete();
      }
    } catch (e) {
      print('Error updating listing: $e');
      rethrow;
    }
  }
  
  // Update an existing auction
  Future<void> updateAuction(AuctionModel auction) async {
    if (auction.id == null) {
      throw ArgumentError('Auction ID cannot be null for updates');
    }
    
    try {
      await _auctionsCollection.doc(auction.id).update(auction.toMap());
    } catch (e) {
      print('Error updating auction: $e');
      rethrow;
    }
  }
  
  // Delete a listing
  Future<void> deleteListing(String listingId) async {
    try {
      // Transaction to delete listing and related auction data
      await _firestore.runTransaction((transaction) async {
        // Delete the listing
        transaction.delete(_listingsCollection.doc(listingId));
        
        // Check if there's an auction for this listing
        DocumentSnapshot auctionSnapshot = await _auctionsCollection.doc(listingId).get();
        if (auctionSnapshot.exists) {
          transaction.delete(_auctionsCollection.doc(listingId));
          
          // Delete related bids
          QuerySnapshot bidsSnapshot = await _bidsCollection
              .where('listingId', isEqualTo: listingId)
              .get();
          
          for (var doc in bidsSnapshot.docs) {
            transaction.delete(doc.reference);
          }
        }
      });
    } catch (e) {
      print('Error deleting listing: $e');
      rethrow;
    }
  }
  
  // Get a specific listing by ID
  Future<ListingModel?> getListing(String listingId) async {
    try {
      DocumentSnapshot doc = await _listingsCollection.doc(listingId).get();
      if (!doc.exists) {
        return null;
      }
      return ListingModel.fromFirestore(doc);
    } catch (e) {
      print('Error getting listing: $e');
      rethrow;
    }
  }
  
  // Get a specific listing by ID (alias for getListing)
  Future<ListingModel> getListingById(String listingId) async {
    final listing = await getListing(listingId);
    if (listing == null) {
      throw Exception('Listing not found');
    }
    return listing;
  }
  
  // Get all listings (with enhanced filters for collectibles)
  Stream<List<ListingModel>> getListings({
    String? category,
    String? subcategory,
    String? sellerId,
    CollectibleCondition? condition,
    bool? isFixedPrice,
    bool onlyAvailable = true,
  }) {
    Query query = _listingsCollection;
    
    if (category != null) {
      query = query.where('category', isEqualTo: category);
    }
    
    if (subcategory != null) {
      query = query.where('subcategory', isEqualTo: subcategory);
    }
    
    if (sellerId != null) {
      query = query.where('sellerId', isEqualTo: sellerId);
    }
    
    if (condition != null) {
      query = query.where('condition', isEqualTo: ListingModel.conditionToString(condition));
    }
    
    if (isFixedPrice != null) {
      query = query.where('isFixedPrice', isEqualTo: isFixedPrice);
    }
    
    if (onlyAvailable) {
      query = query.where('isAvailable', isEqualTo: true);
    }
    
    return query
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ListingModel.fromFirestore(doc))
            .toList());
  }
  
  // Get auction listings only
  Stream<List<ListingModel>> getAuctionListings({
    String? category,
    String? subcategory,
    String? sellerId,
  }) {
    return getListings(
      category: category,
      subcategory: subcategory,
      sellerId: sellerId,
      isFixedPrice: false,
      onlyAvailable: true,
    );
  }
  
  // Get fixed price listings only
  Stream<List<ListingModel>> getFixedPriceListings({
    String? category,
    String? subcategory,
    String? sellerId,
  }) {
    return getListings(
      category: category,
      subcategory: subcategory,
      sellerId: sellerId,
      isFixedPrice: true,
      onlyAvailable: true,
    );
  }

  // Get a specific auction by ID
  Future<AuctionModel?> getAuction(String auctionId) async {
    try {
      DocumentSnapshot doc = await _auctionsCollection.doc(auctionId).get();
      if (!doc.exists) {
        return null;
      }
      return AuctionModel.fromFirestore(doc);
    } catch (e) {
      print('Error getting auction: $e');
      rethrow;
    }
  }
  
  // Get a stream of a specific auction by ID
  Stream<AuctionModel?> getAuctionStream(String auctionId) {
    return _auctionsCollection.doc(auctionId).snapshots().map((doc) {
      if (!doc.exists) {
        return null;
      }
      return AuctionModel.fromFirestore(doc);
    });
  }
  
  // Get all auctions with filters
  Stream<List<AuctionModel>> getAuctions({
    String? sellerId,
    AuctionStatus? status,
  }) {
    Query query = _auctionsCollection;
    
    if (sellerId != null) {
      query = query.where('sellerId', isEqualTo: sellerId);
    }
    
    if (status != null) {
      query = query.where('status', isEqualTo: AuctionModel.statusToString(status));
    }
    
    return query
        .orderBy('endTime')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => AuctionModel.fromFirestore(doc))
            .toList());
  }
  
  // Get active auctions
  Stream<List<AuctionModel>> getActiveAuctions({String? sellerId}) {
    return getAuctions(
      sellerId: sellerId,
      status: AuctionStatus.active,
    );
  }
  
  // Get pending auctions
  Stream<List<AuctionModel>> getPendingAuctions({String? sellerId}) {
    return getAuctions(
      sellerId: sellerId,
      status: AuctionStatus.pending,
    );
  }
  
  // Place a bid on an auction
  Future<void> placeBid(String auctionId, String bidderId, String bidderName, double bidAmount) async {
    try {
      // Get the current auction state
      DocumentSnapshot auctionDoc = await _auctionsCollection.doc(auctionId).get();
      if (!auctionDoc.exists) {
        throw Exception('Auction not found');
      }
      
      AuctionModel auction = AuctionModel.fromFirestore(auctionDoc);
      
      // Validate the bid
      if (auction.status != AuctionStatus.active) {
        throw Exception('Auction is not active');
      }
      
      if (bidAmount <= auction.currentPrice) {
        throw Exception('Bid amount must be higher than current price');
      }
      
      if ((bidAmount - auction.currentPrice) < auction.bidIncrement) {
        throw Exception('Bid increment must be at least ${auction.bidIncrement}');
      }
      
      // Use a transaction to ensure data consistency
      await _firestore.runTransaction((transaction) async {
        // Record the bid
        DocumentReference bidRef = _bidsCollection.doc();
        transaction.set(bidRef, {
          'auctionId': auctionId,
          'listingId': auction.listingId,
          'bidderId': bidderId,
          'bidderName': bidderName,
          'amount': bidAmount,
          'timestamp': FieldValue.serverTimestamp(),
        });
        
        // Update the auction
        transaction.update(_auctionsCollection.doc(auctionId), {
          'currentPrice': bidAmount,
          'bidCount': FieldValue.increment(1),
          'topBidderId': bidderId,
          'topBidderName': bidderName,
        });
      });
    } catch (e) {
      print('Error placing bid: $e');
      rethrow;
    }
  }

  // Get recommended listings based on user preferences (rule-based)
  Future<List<ListingModel>> getRecommendedListings(UserModel user, {int limit = 10}) async {
    // In a real implementation, this would use the rule-based recommendation system
    // For now, we'll just fetch recent listings in categories the user might be interested in
    
    try {
      QuerySnapshot snapshot = await _listingsCollection
          .where('isAvailable', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();
      
      return snapshot.docs.map((doc) => ListingModel.fromFirestore(doc)).toList();
    } catch (e) {
      print('Error getting recommended listings: $e');
      return [];
    }
  }
  
  // Search listings by title (for collectibles search functionality)
  Future<List<ListingModel>> searchListings(String searchTerm) async {
    try {
      // Firestore doesn't support full text search, so this is a simple contains search
      // In a production app, you might want to use Algolia or another search service
      QuerySnapshot snapshot = await _listingsCollection
          .where('isAvailable', isEqualTo: true)
          .get();
      
      List<ListingModel> results = snapshot.docs
          .map((doc) => ListingModel.fromFirestore(doc))
          .where((listing) => 
              listing.title.toLowerCase().contains(searchTerm.toLowerCase()) ||
              listing.description.toLowerCase().contains(searchTerm.toLowerCase()))
          .toList();
      
      return results;
    } catch (e) {
      print('Error searching listings: $e');
      return [];
    }
  }

  // Check and update auction status
  Future<void> checkAndUpdateAuctionStatus(String auctionId) async {
    try {
      // Get the auction
      DocumentSnapshot doc = await _auctionsCollection.doc(auctionId).get();
      if (!doc.exists) {
        return;
      }
      
      AuctionModel auction = AuctionModel.fromFirestore(doc);
      final now = DateTime.now();
      
      // If auction is expired but still active, update to ended
      if (auction.status == AuctionStatus.active && auction.endTime.isBefore(now)) {
        await _auctionsCollection.doc(auctionId).update({
          'status': AuctionModel.statusToString(AuctionStatus.ended)
        });
      }
      
      // If auction was pending but start time has passed, update to active
      if (auction.status == AuctionStatus.pending && auction.startTime.isBefore(now)) {
        await _auctionsCollection.doc(auctionId).update({
          'status': AuctionModel.statusToString(AuctionStatus.active)
        });
      }
    } catch (e) {
      print('Error checking/updating auction status: $e');
      rethrow;
    }
  }

  // EVENTS METHODS
  
  // Create a new event
  Future<String> createEvent(EventModel event) async {
    try {
      DocumentReference docRef = await _eventsCollection.add(event.toMap());
      return docRef.id;
    } catch (e) {
      print('Error creating event: $e');
      rethrow;
    }
  }
  
  // Get a specific event by ID
  Future<EventModel?> getEvent(String eventId) async {
    try {
      DocumentSnapshot doc = await _eventsCollection.doc(eventId).get();
      if (!doc.exists) {
        return null;
      }
      return EventModel.fromFirestore(doc);
    } catch (e) {
      print('Error getting event: $e');
      rethrow;
    }
  }
  
  // Get a stream of events
  Stream<List<EventModel>> getEvents({
    String? createdBy,
    EventStatus? status,
    bool onlyUpcoming = true,
  }) {
    Query query = _eventsCollection;
    
    if (createdBy != null) {
      query = query.where('createdBy', isEqualTo: createdBy);
    }
    
    if (status != null) {
      query = query.where('status', isEqualTo: EventModel.statusToString(status));
    }
    
    if (onlyUpcoming) {
      // Only show events whose date is in the future
      query = query.where('eventDate', isGreaterThan: Timestamp.fromDate(DateTime.now()));
    }
    
    return query
        .orderBy('eventDate')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => EventModel.fromFirestore(doc))
            .toList());
  }
  
  // Update an event
  Future<void> updateEvent(EventModel event) async {
    try {
      await _eventsCollection.doc(event.id).update(event.toMap());
    } catch (e) {
      print('Error updating event: $e');
      rethrow;
    }
  }
  
  // Delete an event
  Future<void> deleteEvent(String eventId) async {
    try {
      await _eventsCollection.doc(eventId).delete();
    } catch (e) {
      print('Error deleting event: $e');
      rethrow;
    }
  }
  
  // Join an event (add user to attendees list)
  Future<void> joinEvent(String eventId, String userId) async {
    try {
      // Start a Firestore transaction for atomic operations
      await _firestore.runTransaction((transaction) async {
        // Get the current event data
        DocumentSnapshot eventSnapshot = await transaction.get(_eventsCollection.doc(eventId));
        if (!eventSnapshot.exists) {
          throw Exception("Event not found");
        }
        
        final eventData = eventSnapshot.data() as Map<String, dynamic>;
        final int currentAttendees = eventData['currentAttendees'] ?? 0;
        final int minAttendees = eventData['minAttendees'] ?? 0;
        final String status = eventData['status'] ?? 'pending';
        
        // Check if user is already in the attendees list
        final List<dynamic> attendees = eventData['attendees'] ?? [];
        if (attendees.contains(userId)) {
          return; // User already joined
        }
        
        // Update the event with the new attendee
        final int newAttendeeCount = currentAttendees + 1;
        
        // Update status to 'confirmed' if meeting minimum requirements
        String newStatus = status;
        if (status.toLowerCase() == 'pending' && newAttendeeCount >= minAttendees) {
          newStatus = 'confirmed';
        }
        
        // Update the document
        transaction.update(_eventsCollection.doc(eventId), {
          'attendees': FieldValue.arrayUnion([userId]),
          'currentAttendees': newAttendeeCount,
          'status': newStatus,
        });
      });
    } catch (e) {
      print('Error joining event: $e');
      rethrow;
    }
  }
  
  // Leave an event (remove user from attendees list)
  Future<void> leaveEvent(String eventId, String userId) async {
    try {
      // Start a Firestore transaction for atomic operations
      await _firestore.runTransaction((transaction) async {
        // Get the current event data
        DocumentSnapshot eventSnapshot = await transaction.get(_eventsCollection.doc(eventId));
        if (!eventSnapshot.exists) {
          throw Exception("Event not found");
        }
        
        final eventData = eventSnapshot.data() as Map<String, dynamic>;
        final int currentAttendees = eventData['currentAttendees'] ?? 0;
        final int minAttendees = eventData['minAttendees'] ?? 0;
        final String status = eventData['status'] ?? 'pending';
        
        // Check if user is in the attendees list
        final List<dynamic> attendees = eventData['attendees'] ?? [];
        if (!attendees.contains(userId)) {
          return; // User not in attendee list
        }
        
        // Update the event removing the attendee
        final int newAttendeeCount = currentAttendees > 0 ? currentAttendees - 1 : 0;
        
        // Update status back to 'pending' if falling below minimum requirements
        String newStatus = status;
        if (status.toLowerCase() == 'confirmed' && newAttendeeCount < minAttendees) {
          newStatus = 'pending';
        }
        
        // Update the document
        transaction.update(_eventsCollection.doc(eventId), {
          'attendees': FieldValue.arrayRemove([userId]),
          'currentAttendees': newAttendeeCount,
          'status': newStatus,
        });
      });
    } catch (e) {
      print('Error leaving event: $e');
      rethrow;
    }
  }
  
  // Get all events a user is attending
  Stream<List<EventModel>> getUserAttendingEvents(String userId) {
    return _eventsCollection
      .where('attendees', arrayContains: userId)
      .orderBy('eventDate')
      .snapshots()
      .map((snapshot) => snapshot.docs
        .map((doc) => EventModel.fromFirestore(doc))
        .toList());
  }
  
  // Check and update events with passed registration deadlines
  Future<void> checkAndUpdatePendingEvents() async {
    try {
      final now = DateTime.now();
      
      // Query for pending events with passed deadlines
      final querySnapshot = await _eventsCollection
        .where('status', isEqualTo: EventModel.statusToString(EventStatus.pending))
        .where('registrationDeadline', isLessThan: Timestamp.fromDate(now))
        .get();
        
      // Batch updates for better performance
      final batch = _firestore.batch();
      int updatedCount = 0;
      
      // Process each pending event with passed deadline
      for (final doc in querySnapshot.docs) {
        final Map<String, dynamic>? eventData = doc.data() as Map<String, dynamic>?;
        if (eventData != null) {
          final int currentAttendees = eventData['currentAttendees'] as int? ?? 0;
          final int minAttendees = eventData['minAttendees'] as int? ?? 0;
          
          // If minimum attendance not met, cancel the event
          if (currentAttendees < minAttendees) {
            batch.update(doc.reference, {
              'status': EventModel.statusToString(EventStatus.canceled)
            });
            updatedCount++;
          }
        }
      }
      
      // Commit the batch if there are updates
      if (updatedCount > 0) {
        await batch.commit();
        print('Updated $updatedCount events to canceled status');
      }
      
      return;
    } catch (e) {
      print('Error checking/updating events: $e');
      rethrow;
    }
  }
} 