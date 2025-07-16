import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:async';
import '../../models/user_model.dart';
import '../../services/firestore_service.dart';
import '../../models/event_model.dart';
import '../../services/maps_service.dart';

class SellerEventsScreen extends StatefulWidget {
  final UserModel user;
  
  const SellerEventsScreen({super.key, required this.user});

  @override
  State<SellerEventsScreen> createState() => _SellerEventsScreenState();
}

class _SellerEventsScreenState extends State<SellerEventsScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  bool _isLoading = true;
  List<EventModel> _upcomingEvents = [];
  StreamSubscription? _eventsSubscription;

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }
  
  @override
  void dispose() {
    _eventsSubscription?.cancel();
    super.dispose();
  }
  
  void _loadEvents() {
    setState(() {
      _isLoading = true;
    });
    
    // Check and update any events with passed deadlines and insufficient attendees
    _firestoreService.checkAndUpdatePendingEvents().then((_) {
      // After updating events, subscribe to the stream
      _eventsSubscription = _firestoreService.getEvents(
        onlyUpcoming: true,
      ).listen((events) {
        if (mounted) {
          setState(() {
            _upcomingEvents = events;
            _isLoading = false;
          });
        }
      }, onError: (error) {
        print('Error loading upcoming events: $error');
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      });
    }).catchError((error) {
      print('Error checking pending events: $error');
      // Still load events even if check fails
      _eventsSubscription = _firestoreService.getEvents(
        onlyUpcoming: true,
      ).listen((events) {
        if (mounted) {
          setState(() {
            _upcomingEvents = events;
            _isLoading = false;
          });
        }
      }, onError: (error) {
        print('Error loading upcoming events: $error');
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Events'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildEventsList(_upcomingEvents),
    );
  }

  Widget _buildEventsList(List<EventModel> events) {
    if (events.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.event_note,
              size: 80,
              color: Colors.deepPurple.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            const Text(
              'No upcoming events available',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                'Check back later for collector events in your area',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: events.length,
      padding: const EdgeInsets.all(16),
      itemBuilder: (context, index) {
        final event = events[index];
        final bool hasJoined = event.attendees.contains(widget.user.uid);
        
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          elevation: 2,
          child: InkWell(
            onTap: () => _showEventDetails(event),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  color: Colors.deepPurple,
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    event.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              DateFormat('EEEE, MMM d, yyyy').format(event.eventDate),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.access_time, size: 16, color: Colors.grey),
                          const SizedBox(width: 8),
                          Text(DateFormat('h:mm a').format(event.eventDate)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.location_on, size: 16, color: Colors.grey),
                          const SizedBox(width: 8),
                          Expanded(child: Text(event.location)),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                _buildInfoChip(
                                  Icons.people,
                                  '${event.currentAttendees}/${event.minAttendees}',
                                  event.currentAttendees >= event.minAttendees ? Colors.green : Colors.orange,
                                ),
                                _buildInfoChip(
                                  Icons.event_available,
                                  'Due: ${DateFormat('MMM d').format(event.registrationDeadline)}',
                                  Colors.deepPurple,
                                ),
                                if (event.status == EventStatus.canceled)
                                  _buildInfoChip(
                                    Icons.cancel,
                                    'Canceled',
                                    Colors.red,
                                  ),
                                if (event.status == EventStatus.confirmed)
                                  _buildInfoChip(
                                    Icons.check_circle,
                                    'Confirmed',
                                    Colors.green,
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (event.registrationDeadline.isAfter(DateTime.now()) && event.status != EventStatus.canceled)
                            SizedBox(
                              height: 32,
                              child: hasJoined 
                                ? Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.green.shade100,
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(color: Colors.green.shade700),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.check_circle, size: 16, color: Colors.green.shade700),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Joined',
                                          style: TextStyle(
                                            color: Colors.green.shade700,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                : ElevatedButton(
                                    onPressed: () => _joinEvent(event),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.deepPurple,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(horizontal: 12),
                                    ),
                                    child: const Text('Join'),
                                  ),
                            )
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
  
  void _showEventDetails(EventModel event) {
    bool isJoined = event.attendees.contains(widget.user.uid);
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => DraggableScrollableSheet(
          initialChildSize: 0.9,
          maxChildSize: 0.9,
          minChildSize: 0.5,
          builder: (_, controller) => Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: Colors.deepPurple,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(Icons.close, color: Colors.white),
                          ),
                        ],
                      ),
                      Text(
                        event.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.calendar_today, size: 16, color: Colors.white70),
                          const SizedBox(width: 8),
                          Text(
                            DateFormat('EEEE, MMM d, yyyy').format(event.eventDate),
                            style: const TextStyle(color: Colors.white, fontSize: 16),
                          ),
                          const SizedBox(width: 16),
                          const Icon(Icons.access_time, size: 16, color: Colors.white70),
                          const SizedBox(width: 8),
                          Text(
                            DateFormat('h:mm a').format(event.eventDate),
                            style: const TextStyle(color: Colors.white, fontSize: 16),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView(
                    controller: controller,
                    padding: const EdgeInsets.all(20),
                    children: [
                      const Text(
                        'Location',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(event.location),
                      const SizedBox(height: 16),
                      if (event.locationLat != 0 && event.locationLng != 0)
                        Column(
                          children: [
                            Container(
                              height: 200,
                              margin: const EdgeInsets.only(bottom: 16),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: GoogleMap(
                                  initialCameraPosition: CameraPosition(
                                    target: event.getLocation(),
                                    zoom: 15,
                                  ),
                                  markers: {
                                    Marker(
                                      markerId: MarkerId(event.id ?? ''),
                                      position: event.getLocation(),
                                      infoWindow: InfoWindow(title: event.name),
                                    ),
                                  },
                                  zoomControlsEnabled: false,
                                  mapToolbarEnabled: true,
                                  myLocationButtonEnabled: false,
                                ),
                              ),
                            ),
                            ElevatedButton.icon(
                              onPressed: () async {
                                try {
                                  await MapsService.openDirections(
                                    event.locationLat,
                                    event.locationLng,
                                  );
                                } catch (e) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Could not open directions: $e')),
                                    );
                                  }
                                }
                              },
                              icon: const Icon(Icons.directions),
                              label: const Text('Get Directions'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.deepPurple,
                                foregroundColor: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],
                        ),
                      const Text(
                        'About this event',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        event.description,
                        style: const TextStyle(
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Attendance Information',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Current Attendees:',
                                    style: TextStyle(fontSize: 16),
                                  ),
                                  Text(
                                    '${event.currentAttendees}',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Minimum Required:',
                                    style: TextStyle(fontSize: 16),
                                  ),
                                  Text(
                                    '${event.minAttendees}',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Registration Deadline:',
                                    style: TextStyle(fontSize: 16),
                                  ),
                                  Text(
                                    DateFormat('MMM d, yyyy').format(event.registrationDeadline),
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Status:',
                                    style: TextStyle(fontSize: 16),
                                  ),
                                  _buildStatusBadge(event.status),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      if (event.registrationDeadline.isAfter(DateTime.now()))
                        if (!isJoined)
                          ElevatedButton(
                            onPressed: () async {
                              await _joinEvent(event);
                              
                              // Fetch the updated event to reflect the new status
                              EventModel? updatedEvent = await _firestoreService.getEvent(event.id!);
                              if (updatedEvent != null && mounted) {
                                setModalState(() {
                                  event = updatedEvent;
                                  isJoined = updatedEvent.attendees.contains(widget.user.uid);
                                });
                              } else {
                                Navigator.pop(context);
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.deepPurple,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: const Text('Join This Event'),
                          )
                        else
                          OutlinedButton(
                            onPressed: () async {
                              await _leaveEvent(event);
                              
                              // Fetch the updated event to reflect the new status
                              EventModel? updatedEvent = await _firestoreService.getEvent(event.id!);
                              if (updatedEvent != null && mounted) {
                                setModalState(() {
                                  event = updatedEvent;
                                  isJoined = updatedEvent.attendees.contains(widget.user.uid);
                                });
                              } else {
                                Navigator.pop(context);
                              }
                            },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.red,
                              side: const BorderSide(color: Colors.red),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: const Text('Leave This Event'),
                          ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildStatusBadge(EventStatus status) {
    Color color;
    String label;
    
    switch (status) {
      case EventStatus.pending:
        color = Colors.orange;
        label = 'Pending';
        break;
      case EventStatus.confirmed:
        color = Colors.green;
        label = 'Confirmed';
        break;
      case EventStatus.canceled:
        color = Colors.red;
        label = 'Canceled';
        break;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
  
  Future<void> _joinEvent(EventModel event) async {
    try {
      await _firestoreService.joinEvent(event.id!, widget.user.uid);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Successfully joined the event!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error joining event: $e')),
        );
      }
    }
  }
  
  Future<void> _leaveEvent(EventModel event) async {
    try {
      await _firestoreService.leaveEvent(event.id!, widget.user.uid);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('You have left the event')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error leaving event: $e')),
        );
      }
    }
  }

  Widget _buildInfoChip(IconData icon, String label, Color color) {
    return Chip(
      avatar: Icon(icon, size: 16, color: Colors.white),
      label: Text(
        label,
        style: const TextStyle(fontSize: 11, color: Colors.white),
        overflow: TextOverflow.ellipsis,
      ),
      backgroundColor: color,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
    );
  }
} 