import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/cart_model.dart';
import '../models/listing_model.dart';
import '../models/user_model.dart';
import '../models/purchase_model.dart';
import 'dart:developer' as developer;

class CartService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final CollectionReference _purchasesCollection;
  
  CartService() : _purchasesCollection = FirebaseFirestore.instance.collection('purchases');
  
  // Helper method to get cart items collection
  CollectionReference _getCartItemsCollection(String userId) {
    return _firestore.collection('users').doc(userId).collection('cart');
  }
  
  // Add item to cart
  Future<void> addToCart(String userId, String listingId) async {
    try {
      // Check if listing exists and is available
      final listingDoc = await _firestore.collection('listings').doc(listingId).get();
      
      if (!listingDoc.exists) {
        throw Exception('Listing does not exist');
      }
      
      final listingData = listingDoc.data() as Map<String, dynamic>;
      
      if (!(listingData['isAvailable'] ?? false)) {
        throw Exception('Listing is not available');
      }
      
      // Check if item is already in cart
      final cartQuery = await _getCartItemsCollection(userId)
          .where('listingId', isEqualTo: listingId)
          .get();
      
      if (cartQuery.docs.isNotEmpty) {
        throw Exception('Item is already in your cart');
      }
      
      // Add to cart
      await _getCartItemsCollection(userId).add({
        'listingId': listingId,
        'addedAt': FieldValue.serverTimestamp(),
      });
      
      developer.log('Item added to cart');
    } catch (e) {
      developer.log('Error adding to cart: $e');
      rethrow;
    }
  }
  
  // Remove item from cart
  Future<void> removeFromCart(String userId, String cartItemId) async {
    try {
      await _getCartItemsCollection(userId).doc(cartItemId).delete();
      developer.log('Item removed from cart');
    } catch (e) {
      developer.log('Error removing from cart: $e');
      rethrow;
    }
  }
  
  // Clear cart
  Future<void> clearCart(String userId) async {
    try {
      // Get all cart items
      final cartItems = await _getCartItemsCollection(userId).get();
      
      // Delete each item
      final batch = _firestore.batch();
      for (var item in cartItems.docs) {
        batch.delete(item.reference);
      }
      
      await batch.commit();
      developer.log('Cart cleared');
    } catch (e) {
      developer.log('Error clearing cart: $e');
      rethrow;
    }
  }

  // Get cart items stream
  Stream<List<CartItem>> getCartItems(String userId) {
    return _getCartItemsCollection(userId)
        .orderBy('addedAt', descending: true)
        .snapshots()
        .asyncMap((snapshot) async {
          final items = <CartItem>[];
          
          for (var doc in snapshot.docs) {
            final cartItem = await CartItem.fromFirestore(doc, _firestore);
            if (cartItem != null) {
              items.add(cartItem);
            }
          }
          
          return items;
        });
  }

  // Checkout - Convert cart items to purchases
  Future<void> checkout(UserModel user) async {
    try {
      // Get all cart items
      final cartItemsSnapshot = await _getCartItemsCollection(user.uid).get();
      
      if (cartItemsSnapshot.docs.isEmpty) {
        developer.log('Cart is empty');
        return;
      }
      
      // Start a batch write
      final batch = _firestore.batch();
      final createdPurchaseIds = <String>[];
      
      // For each cart item, create a purchase and update the listing
      for (var doc in cartItemsSnapshot.docs) {
        final cartItem = await CartItem.fromFirestore(doc, _firestore);
        
        if (cartItem != null) {
          developer.log('Creating purchase for listing ${cartItem.listing.id}, seller: ${cartItem.listing.sellerId}');
          
          // Verify seller ID is valid
          if (cartItem.listing.sellerId.isEmpty) {
            developer.log('WARNING: Empty seller ID for listing ${cartItem.listing.id}');
            continue;
          }
          
          // Create purchase
          final purchase = PurchaseModel.fromListing(
            listing: cartItem.listing,
            buyerId: user.uid,
            buyerName: user.displayName ?? 'Unknown User',
          );
          
          // Add purchase to Firestore with explicit ID
          final purchaseRef = _purchasesCollection.doc();
          createdPurchaseIds.add(purchaseRef.id);
          batch.set(purchaseRef, purchase.toMap());
          
          // Update listing availability
          final listingRef = _firestore.collection('listings').doc(cartItem.listing.id);
          batch.update(listingRef, {'isAvailable': false});
          
          // Remove item from cart
          batch.delete(doc.reference);
        }
      }
      
      // Commit the batch
      await batch.commit();
      developer.log('Checkout completed, created purchase IDs: $createdPurchaseIds');
    } catch (e) {
      developer.log('Error during checkout: $e');
      rethrow;
    }
  }

  // Purchase a single item directly
  Future<void> purchaseItem(UserModel user, ListingModel listing) async {
    try {
      // Start a batch write
      final batch = _firestore.batch();
      
      // Create purchase
      final purchase = PurchaseModel.fromListing(
        listing: listing,
        buyerId: user.uid,
        buyerName: user.displayName ?? 'Unknown User',
      );
      
      // Add purchase to Firestore
      final purchaseRef = _purchasesCollection.doc();
      batch.set(purchaseRef, purchase.toMap());
      
      // Update listing availability
      final listingRef = _firestore.collection('listings').doc(listing.id);
      batch.update(listingRef, {'isAvailable': false});
      
      // Commit the batch
      await batch.commit();
      developer.log('Item purchased directly');
    } catch (e) {
      developer.log('Error purchasing item: $e');
      rethrow;
    }
  }

  // Get purchase by ID
  Future<PurchaseModel> getPurchaseById(String purchaseId) async {
    try {
      final purchaseDoc = await _purchasesCollection.doc(purchaseId).get();
      
      if (!purchaseDoc.exists) {
        throw Exception('Purchase not found');
      }
      
      return PurchaseModel.fromFirestore(purchaseDoc);
    } catch (e) {
      developer.log('Error getting purchase by ID: $e');
      rethrow;
    }
  }

  // Update purchase status
  Future<void> updatePurchaseStatus(String purchaseId, PurchaseStatus newStatus) async {
    try {
      final purchaseRef = _purchasesCollection.doc(purchaseId);
      final purchaseDoc = await purchaseRef.get();
      
      if (!purchaseDoc.exists) {
        developer.log('Purchase does not exist');
        return;
      }
      
      final purchase = PurchaseModel.fromFirestore(purchaseDoc);
      
      // Prepare update data
      final updateData = <String, dynamic>{
        'status': PurchaseModel.statusToString(newStatus),
      };
      
      // Add timestamps based on the new status
      if (newStatus == PurchaseStatus.claimed && purchase.paymentClaimedAt == null) {
        updateData['paymentClaimedAt'] = FieldValue.serverTimestamp();
      } else if (newStatus == PurchaseStatus.confirmed && purchase.confirmedAt == null) {
        updateData['confirmedAt'] = FieldValue.serverTimestamp();
        
        // Update the listing to mark it as sold
        final listingRef = _firestore.collection('listings').doc(purchase.listingId);
        await listingRef.update({
          'isAvailable': false,
          'soldAt': FieldValue.serverTimestamp(),
          'soldTo': purchase.buyerId,
          'soldToName': purchase.buyerName,
        });
        
        developer.log('Listing marked as sold to ${purchase.buyerName}');
      } else if (newStatus == PurchaseStatus.completed && purchase.completedAt == null) {
        updateData['completedAt'] = FieldValue.serverTimestamp();
      }
      
      await purchaseRef.update(updateData);
      developer.log('Purchase status updated to ${PurchaseModel.statusToString(newStatus)}');
    } catch (e) {
      developer.log('Error updating purchase status: $e');
      rethrow;
    }
  }

  // Get purchases for buyer
  Stream<List<PurchaseModel>> getBuyerPurchases(String userId) {
    return _purchasesCollection
        .where('buyerId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => PurchaseModel.fromFirestore(doc))
            .toList());
  }
  
  // Get purchases for seller
  Stream<List<PurchaseModel>> getSellerPurchases(String userId, {PurchaseStatus? status}) {
    // First, get all the seller's purchases
    Query query = _purchasesCollection
        .where('sellerId', isEqualTo: userId)
        .orderBy('createdAt', descending: true);
    
    // Instead of using a where clause for status filtering (which requires a composite index),
    // we'll filter the results on the client side to avoid the index requirement
    return query.snapshots()
        .map((snapshot) {
          final allPurchases = snapshot.docs
              .map((doc) => PurchaseModel.fromFirestore(doc))
              .toList();
          
          // If no status filter is provided, return all purchases
          if (status == null) {
            return allPurchases;
          }
          
          // Otherwise, filter on the client side
          return allPurchases.where(
            (purchase) => purchase.status == status
          ).toList();
        });
  }
  
  // Get purchases for seller once (not a stream) - for manual refresh
  Future<List<PurchaseModel>> getSellerPurchasesOnce(String sellerId) async {
    try {
      developer.log('Fetching purchases for seller $sellerId');
      
      final snapshot = await _purchasesCollection
          .where('sellerId', isEqualTo: sellerId)
          .orderBy('createdAt', descending: true)
          .get();
      
      final purchases = snapshot.docs
          .map((doc) => PurchaseModel.fromFirestore(doc))
          .toList();
      
      developer.log('Found ${purchases.length} purchases for seller $sellerId');
      
      return purchases;
    } catch (e) {
      developer.log('Error getting seller purchases: $e');
      rethrow;
    }
  }
} 