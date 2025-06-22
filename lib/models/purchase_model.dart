import 'package:cloud_firestore/cloud_firestore.dart';
import 'listing_model.dart';

enum PurchaseStatus {
  pending,     // Buyer clicked "Buy Now" but payment not confirmed
  claimed,     // Buyer claimed payment is done
  confirmed,   // Seller confirmed payment received
  completed    // Transaction fully completed
}

class PurchaseModel {
  final String? id;
  final String buyerId;
  final String buyerName;
  final String sellerId;
  final String sellerName;
  final String listingId;
  final String listingTitle;
  final List<String> listingImages;
  final double price;
  final PurchaseStatus status;
  final DateTime createdAt;
  final DateTime? paymentClaimedAt;
  final DateTime? confirmedAt;
  final DateTime? completedAt;

  PurchaseModel({
    this.id,
    required this.buyerId,
    required this.buyerName,
    required this.sellerId,
    required this.sellerName,
    required this.listingId,
    required this.listingTitle,
    required this.listingImages,
    required this.price,
    required this.status,
    required this.createdAt,
    this.paymentClaimedAt,
    this.confirmedAt,
    this.completedAt,
  });

  // Convert status to string
  static String statusToString(PurchaseStatus status) {
    switch (status) {
      case PurchaseStatus.pending:
        return 'pending';
      case PurchaseStatus.claimed:
        return 'claimed';
      case PurchaseStatus.confirmed:
        return 'confirmed';
      case PurchaseStatus.completed:
        return 'completed';
    }
  }

  // Convert string to status
  static PurchaseStatus stringToStatus(String statusStr) {
    switch (statusStr.toLowerCase()) {
      case 'pending':
        return PurchaseStatus.pending;
      case 'claimed':
        return PurchaseStatus.claimed;
      case 'confirmed':
        return PurchaseStatus.confirmed;
      case 'completed':
        return PurchaseStatus.completed;
      default:
        return PurchaseStatus.pending;
    }
  }

  // Create purchase from listing
  static PurchaseModel fromListing({
    required ListingModel listing,
    required String buyerId,
    required String buyerName,
  }) {
    return PurchaseModel(
      buyerId: buyerId,
      buyerName: buyerName,
      sellerId: listing.sellerId,
      sellerName: listing.sellerName,
      listingId: listing.id!,
      listingTitle: listing.title,
      listingImages: listing.images,
      price: listing.price,
      status: PurchaseStatus.pending,
      createdAt: DateTime.now(),
    );
  }

  // Convert to map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'buyerId': buyerId,
      'buyerName': buyerName,
      'sellerId': sellerId,
      'sellerName': sellerName,
      'listingId': listingId,
      'listingTitle': listingTitle,
      'listingImages': listingImages,
      'price': price,
      'status': statusToString(status),
      'createdAt': Timestamp.fromDate(createdAt),
      'paymentClaimedAt': paymentClaimedAt != null ? Timestamp.fromDate(paymentClaimedAt!) : null,
      'confirmedAt': confirmedAt != null ? Timestamp.fromDate(confirmedAt!) : null,
      'completedAt': completedAt != null ? Timestamp.fromDate(completedAt!) : null,
    };
  }

  // Create from Firestore document
  factory PurchaseModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return PurchaseModel(
      id: doc.id,
      buyerId: data['buyerId'] ?? '',
      buyerName: data['buyerName'] ?? '',
      sellerId: data['sellerId'] ?? '',
      sellerName: data['sellerName'] ?? '',
      listingId: data['listingId'] ?? '',
      listingTitle: data['listingTitle'] ?? '',
      listingImages: List<String>.from(data['listingImages'] ?? []),
      price: (data['price'] ?? 0).toDouble(),
      status: stringToStatus(data['status'] ?? 'pending'),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      paymentClaimedAt: data['paymentClaimedAt'] != null 
          ? (data['paymentClaimedAt'] as Timestamp).toDate() 
          : null,
      confirmedAt: data['confirmedAt'] != null 
          ? (data['confirmedAt'] as Timestamp).toDate() 
          : null,
      completedAt: data['completedAt'] != null 
          ? (data['completedAt'] as Timestamp).toDate() 
          : null,
    );
  }

  // Create a copy with modified fields
  PurchaseModel copyWith({
    String? buyerId,
    String? buyerName,
    String? sellerId,
    String? sellerName,
    String? listingId,
    String? listingTitle,
    List<String>? listingImages,
    double? price,
    PurchaseStatus? status,
    DateTime? createdAt,
    DateTime? paymentClaimedAt,
    DateTime? confirmedAt,
    DateTime? completedAt,
  }) {
    return PurchaseModel(
      id: id,
      buyerId: buyerId ?? this.buyerId,
      buyerName: buyerName ?? this.buyerName,
      sellerId: sellerId ?? this.sellerId,
      sellerName: sellerName ?? this.sellerName,
      listingId: listingId ?? this.listingId,
      listingTitle: listingTitle ?? this.listingTitle,
      listingImages: listingImages ?? this.listingImages,
      price: price ?? this.price,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      paymentClaimedAt: paymentClaimedAt ?? this.paymentClaimedAt,
      confirmedAt: confirmedAt ?? this.confirmedAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }
} 