import 'package:cloud_firestore/cloud_firestore.dart';

enum CollectibleCondition {
  mint, // Perfect condition
  nearMint, // Almost perfect with minor flaws
  excellent, // Minor wear but overall great condition
  good, // Shows wear but still presentable
  poor // Significant wear or damage
}

class ListingModel {
  final String? id;
  final String sellerId;
  final String sellerName;
  final String title;
  final String description;
  final double price;
  final double? marketPrice; // Price from eBay API
  final String category;
  final String subcategory;
  final CollectibleCondition condition;
  final List<String> images;
  final bool isAvailable;
  final bool isFixedPrice; // true for direct sale, false for auction
  final DateTime createdAt;

  ListingModel({
    this.id,
    required this.sellerId,
    required this.sellerName,
    required this.title,
    required this.description,
    required this.price,
    this.marketPrice,
    required this.category,
    required this.subcategory,
    required this.condition,
    required this.images,
    this.isAvailable = true,
    this.isFixedPrice = true,
    required this.createdAt,
  });

  // Convert CollectibleCondition to String
  static String conditionToString(CollectibleCondition condition) {
    switch (condition) {
      case CollectibleCondition.mint:
        return 'Mint';
      case CollectibleCondition.nearMint:
        return 'Near Mint';
      case CollectibleCondition.excellent:
        return 'Excellent';
      case CollectibleCondition.good:
        return 'Good';
      case CollectibleCondition.poor:
        return 'Poor';
    }
  }

  // Convert String to CollectibleCondition
  static CollectibleCondition stringToCondition(String conditionStr) {
    switch (conditionStr.toLowerCase()) {
      case 'mint':
        return CollectibleCondition.mint;
      case 'near mint':
        return CollectibleCondition.nearMint;
      case 'excellent':
        return CollectibleCondition.excellent;
      case 'good':
        return CollectibleCondition.good;
      case 'poor':
        return CollectibleCondition.poor;
      default:
        return CollectibleCondition.good;
    }
  }

  // Convert ListingModel to a Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'sellerId': sellerId,
      'sellerName': sellerName,
      'title': title,
      'description': description,
      'price': price,
      'marketPrice': marketPrice,
      'category': category,
      'subcategory': subcategory,
      'condition': conditionToString(condition),
      'images': images,
      'isAvailable': isAvailable,
      'isFixedPrice': isFixedPrice,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  // Create a ListingModel from a Firestore document
  factory ListingModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ListingModel(
      id: doc.id,
      sellerId: data['sellerId'] ?? '',
      sellerName: data['sellerName'] ?? '',
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      price: (data['price'] ?? 0).toDouble(),
      marketPrice: data['marketPrice']?.toDouble(),
      category: data['category'] ?? '',
      subcategory: data['subcategory'] ?? '',
      condition: stringToCondition(data['condition'] ?? 'Good'),
      images: List<String>.from(data['images'] ?? []),
      isAvailable: data['isAvailable'] ?? true,
      isFixedPrice: data['isFixedPrice'] ?? true,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  // Create a copy of this ListingModel with modified fields
  ListingModel copyWith({
    String? sellerId,
    String? sellerName,
    String? title,
    String? description,
    double? price,
    double? marketPrice,
    String? category,
    String? subcategory,
    CollectibleCondition? condition,
    List<String>? images,
    bool? isAvailable,
    bool? isFixedPrice,
    DateTime? createdAt,
  }) {
    return ListingModel(
      id: id,
      sellerId: sellerId ?? this.sellerId,
      sellerName: sellerName ?? this.sellerName,
      title: title ?? this.title,
      description: description ?? this.description,
      price: price ?? this.price,
      marketPrice: marketPrice ?? this.marketPrice,
      category: category ?? this.category,
      subcategory: subcategory ?? this.subcategory,
      condition: condition ?? this.condition,
      images: images ?? this.images,
      isAvailable: isAvailable ?? this.isAvailable,
      isFixedPrice: isFixedPrice ?? this.isFixedPrice,
      createdAt: createdAt ?? this.createdAt,
    );
  }
} 