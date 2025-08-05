import 'package:cloud_firestore/cloud_firestore.dart';

class BidModel {
  final String? id;
  final String auctionId;
  final String listingId;
  final String bidderId;
  final String bidderName;
  final double amount;
  final DateTime timestamp;

  BidModel({
    this.id,
    required this.auctionId,
    required this.listingId,
    required this.bidderId,
    required this.bidderName,
    required this.amount,
    required this.timestamp,
  });

  // Convert BidModel to a Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'auctionId': auctionId,
      'listingId': listingId,
      'bidderId': bidderId,
      'bidderName': bidderName,
      'amount': amount,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }

  // Create a BidModel from a Firestore document
  factory BidModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return BidModel(
      id: doc.id,
      auctionId: data['auctionId'] ?? '',
      listingId: data['listingId'] ?? '',
      bidderId: data['bidderId'] ?? '',
      bidderName: data['bidderName'] ?? '',
      amount: (data['amount'] ?? 0).toDouble(),
      timestamp: (data['timestamp'] as Timestamp).toDate(),
    );
  }

  // Create a copy of this BidModel with modified fields
  BidModel copyWith({
    String? auctionId,
    String? listingId,
    String? bidderId,
    String? bidderName,
    double? amount,
    DateTime? timestamp,
  }) {
    return BidModel(
      id: id,
      auctionId: auctionId ?? this.auctionId,
      listingId: listingId ?? this.listingId,
      bidderId: bidderId ?? this.bidderId,
      bidderName: bidderName ?? this.bidderName,
      amount: amount ?? this.amount,
      timestamp: timestamp ?? this.timestamp,
    );
  }
} 