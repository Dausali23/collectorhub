import 'package:flutter/material.dart';
import '../models/auction_model.dart';
import '../services/firestore_service.dart';

class CurrentBidDisplay extends StatefulWidget {
  final String listingId;
  final double initialPrice;
  final bool showLabel;
  final bool showHighestBidder;

  const CurrentBidDisplay({
    super.key,
    required this.listingId,
    required this.initialPrice,
    this.showLabel = true,
    this.showHighestBidder = false,
  });

  @override
  State<CurrentBidDisplay> createState() => _CurrentBidDisplayState();
}

class _CurrentBidDisplayState extends State<CurrentBidDisplay> {
  final FirestoreService _firestoreService = FirestoreService();
  late Stream<AuctionModel?> _auctionStream;

  @override
  void initState() {
    super.initState();
    _auctionStream = _firestoreService.getAuctionStream(widget.listingId);
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuctionModel?>(
      stream: _auctionStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.showLabel)
                const Text(
                  'Current bid: ',
                  style: TextStyle(fontSize: 12),
                ),
              Text(
                'RM ${widget.initialPrice.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Colors.red,
                ),
              ),
            ],
          );
        }

        if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
          return Text(
            'RM ${widget.initialPrice.toStringAsFixed(2)}',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          );
        }

        final auction = snapshot.data!;
        
        // Check if auction is expired but status is still active
        if (auction.status == AuctionStatus.active && 
            auction.endTime.isBefore(DateTime.now())) {
          // Update the auction status to ended
          if (auction.id != null) {
            _firestoreService.updateAuction(
              auction.copyWith(status: AuctionStatus.ended)
            );
          }
        }
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.showLabel)
                  const Text(
                    'Current bid: ',
                    style: TextStyle(fontSize: 12),
                  ),
                Text(
                  'RM ${auction.currentPrice.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Colors.red,
                  ),
                ),
              ],
            ),
            if (widget.showHighestBidder && auction.topBidderName != null)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  'Highest: ${auction.topBidderName}',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade700,
                    fontStyle: FontStyle.italic,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
        );
      },
    );
  }
} 