import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

enum EventStatus {
  pending,
  confirmed,
  canceled
}

class EventModel {
  final String? id;
  final String name;
  final String description;
  final String location;
  final double locationLat;
  final double locationLng;
  final DateTime eventDate;
  final DateTime registrationDeadline;
  final int minAttendees;
  final int currentAttendees;
  final EventStatus status;
  final String createdBy;
  final DateTime createdAt;
  final List<String> attendees; // List of user IDs who are attending

  EventModel({
    this.id,
    required this.name,
    required this.description,
    required this.location,
    required this.locationLat,
    required this.locationLng,
    required this.eventDate,
    required this.registrationDeadline,
    required this.minAttendees,
    required this.currentAttendees,
    required this.status,
    required this.createdBy,
    required this.createdAt,
    required this.attendees,
  });

  // Convert EventStatus to String
  static String statusToString(EventStatus status) {
    return status.toString().split('.').last;
  }

  // Convert String to EventStatus
  static EventStatus stringToStatus(String statusStr) {
    switch (statusStr.toLowerCase()) {
      case 'pending':
        return EventStatus.pending;
      case 'confirmed':
        return EventStatus.confirmed;
      case 'canceled':
        return EventStatus.canceled;
      default:
        return EventStatus.pending;
    }
  }

  // Convert EventModel to a Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'location': location,
      'locationLat': locationLat,
      'locationLng': locationLng,
      'eventDate': Timestamp.fromDate(eventDate),
      'registrationDeadline': Timestamp.fromDate(registrationDeadline),
      'minAttendees': minAttendees,
      'currentAttendees': currentAttendees,
      'status': statusToString(status),
      'createdBy': createdBy,
      'createdAt': Timestamp.fromDate(createdAt),
      'attendees': attendees,
    };
  }

  // Create an EventModel from a Firestore document
  factory EventModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return EventModel(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      location: data['location'] ?? '',
      locationLat: (data['locationLat'] ?? 0.0).toDouble(),
      locationLng: (data['locationLng'] ?? 0.0).toDouble(),
      eventDate: (data['eventDate'] as Timestamp).toDate(),
      registrationDeadline: (data['registrationDeadline'] as Timestamp).toDate(),
      minAttendees: data['minAttendees'] ?? 2,
      currentAttendees: data['currentAttendees'] ?? 0,
      status: stringToStatus(data['status'] ?? 'pending'),
      createdBy: data['createdBy'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      attendees: List<String>.from(data['attendees'] ?? []),
    );
  }

  // Create a copy of this EventModel with modified fields
  EventModel copyWith({
    String? name,
    String? description,
    String? location,
    double? locationLat,
    double? locationLng,
    DateTime? eventDate,
    DateTime? registrationDeadline,
    int? minAttendees,
    int? currentAttendees,
    EventStatus? status,
    String? createdBy,
    DateTime? createdAt,
    List<String>? attendees,
  }) {
    return EventModel(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      location: location ?? this.location,
      locationLat: locationLat ?? this.locationLat,
      locationLng: locationLng ?? this.locationLng,
      eventDate: eventDate ?? this.eventDate,
      registrationDeadline: registrationDeadline ?? this.registrationDeadline,
      minAttendees: minAttendees ?? this.minAttendees,
      currentAttendees: currentAttendees ?? this.currentAttendees,
      status: status ?? this.status,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      attendees: attendees ?? this.attendees,
    );
  }

  // Get LatLng object for map display
  LatLng getLocation() {
    return LatLng(locationLat, locationLng);
  }
} 