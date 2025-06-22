import 'package:cloud_firestore/cloud_firestore.dart';
import 'listing_model.dart';

class CartItem {
  final String id;
  final ListingModel listing;
  final DateTime addedAt;

  CartItem({
    required this.id,
    required this.listing,
    required this.addedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'listingId': listing.id,
      'addedAt': Timestamp.fromDate(addedAt),
    };
  }

  static Future<CartItem?> fromFirestore(
    DocumentSnapshot doc,
    FirebaseFirestore firestore,
  ) async {
    final data = doc.data() as Map<String, dynamic>;
    
    // Get the listing document
    final listingDoc = await firestore
        .collection('listings')
        .doc(data['listingId'])
        .get();
    
    if (!listingDoc.exists) {
      return null;
    }
    
    return CartItem(
      id: doc.id,
      listing: ListingModel.fromFirestore(listingDoc),
      addedAt: (data['addedAt'] as Timestamp).toDate(),
    );
  }
}

class CartModel {
  final String userId;
  final List<CartItem> items;

  CartModel({
    required this.userId,
    required this.items,
  });

  double get totalPrice {
    return items.fold(0, (sum, item) => sum + item.listing.price);
  }
} 