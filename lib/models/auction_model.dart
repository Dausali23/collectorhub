import 'package:cloud_firestore/cloud_firestore.dart';

enum AuctionStatus {
  pending, // Not yet started
  active, // Currently running
  ended, // Auction has ended
  cancelled, // Cancelled by seller
}

class AuctionModel {
  final String? id;
  final String listingId;
  final String sellerId;
  final String sellerName;
  final double startingPrice;
  final double currentPrice;
  final double bidIncrement;
  final DateTime startTime;
  final DateTime endTime;
  final AuctionStatus status;
  final int bidCount;
  final String? topBidderId;
  final String? topBidderName;

  AuctionModel({
    this.id,
    required this.listingId,
    required this.sellerId,
    required this.sellerName,
    required this.startingPrice,
    required this.currentPrice,
    required this.bidIncrement,
    required this.startTime,
    required this.endTime,
    required this.status,
    this.bidCount = 0,
    this.topBidderId,
    this.topBidderName,
  });

  // Convert AuctionStatus to String
  static String statusToString(AuctionStatus status) {
    switch (status) {
      case AuctionStatus.pending:
        return 'pending';
      case AuctionStatus.active:
        return 'active';
      case AuctionStatus.ended:
        return 'ended';
      case AuctionStatus.cancelled:
        return 'cancelled';
    }
  }

  // Convert String to AuctionStatus
  static AuctionStatus stringToStatus(String statusStr) {
    switch (statusStr.toLowerCase()) {
      case 'pending':
        return AuctionStatus.pending;
      case 'active':
        return AuctionStatus.active;
      case 'ended':
        return AuctionStatus.ended;
      case 'cancelled':
        return AuctionStatus.cancelled;
      default:
        return AuctionStatus.pending;
    }
  }

  // Convert AuctionModel to a Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'listingId': listingId,
      'sellerId': sellerId,
      'sellerName': sellerName,
      'startingPrice': startingPrice,
      'currentPrice': currentPrice,
      'bidIncrement': bidIncrement,
      'startTime': Timestamp.fromDate(startTime),
      'endTime': Timestamp.fromDate(endTime),
      'status': statusToString(status),
      'bidCount': bidCount,
      'topBidderId': topBidderId,
      'topBidderName': topBidderName,
    };
  }

  // Create an AuctionModel from a Firestore document
  factory AuctionModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AuctionModel(
      id: doc.id,
      listingId: data['listingId'] ?? '',
      sellerId: data['sellerId'] ?? '',
      sellerName: data['sellerName'] ?? '',
      startingPrice: (data['startingPrice'] ?? 0).toDouble(),
      currentPrice: (data['currentPrice'] ?? 0).toDouble(),
      bidIncrement: (data['bidIncrement'] ?? 1.0).toDouble(),
      startTime: (data['startTime'] as Timestamp).toDate(),
      endTime: (data['endTime'] as Timestamp).toDate(),
      status: stringToStatus(data['status'] ?? 'pending'),
      bidCount: data['bidCount'] ?? 0,
      topBidderId: data['topBidderId'],
      topBidderName: data['topBidderName'],
    );
  }

  // Create a copy of this AuctionModel with modified fields
  AuctionModel copyWith({
    String? listingId,
    String? sellerId,
    String? sellerName,
    double? startingPrice,
    double? currentPrice,
    double? bidIncrement,
    DateTime? startTime,
    DateTime? endTime,
    AuctionStatus? status,
    int? bidCount,
    String? topBidderId,
    String? topBidderName,
  }) {
    return AuctionModel(
      id: id,
      listingId: listingId ?? this.listingId,
      sellerId: sellerId ?? this.sellerId,
      sellerName: sellerName ?? this.sellerName,
      startingPrice: startingPrice ?? this.startingPrice,
      currentPrice: currentPrice ?? this.currentPrice,
      bidIncrement: bidIncrement ?? this.bidIncrement,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      status: status ?? this.status,
      bidCount: bidCount ?? this.bidCount,
      topBidderId: topBidderId ?? this.topBidderId,
      topBidderName: topBidderName ?? this.topBidderName,
    );
  }
} 