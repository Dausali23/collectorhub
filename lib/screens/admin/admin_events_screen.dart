import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import 'package:intl/intl.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'dart:async';
import 'dart:developer' as developer;
import '../../services/firestore_service.dart';
import '../../models/event_model.dart';
import '../../services/maps_service.dart';

class AdminEventsScreen extends StatefulWidget {
  final UserModel user;
  
  const AdminEventsScreen({super.key, required this.user});

  @override
  State<AdminEventsScreen> createState() => _AdminEventsScreenState();
}

class _AdminEventsScreenState extends State<AdminEventsScreen> {
  // Replace local events list with a stream from Firestore
  final FirestoreService _firestoreService = FirestoreService();
  bool _isLoading = true;
  List<EventModel> _events = [];
  StreamSubscription<List<EventModel>>? _eventsSubscription;

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
    
    // Subscribe to events stream
    _eventsSubscription = _firestoreService.getEvents(
      createdBy: widget.user.uid, 
      status: null, // Get all events regardless of status
    ).listen((events) {
      setState(() {
        _events = events;
        _isLoading = false;
      });
    }, onError: (error) {
      developer.log('Error loading events: $error');
      setState(() {
        _isLoading = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Events (${_events.length})'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _events.isEmpty
              ? _buildEmptyState()
              : _buildEventsList(),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showCreateEventDialog();
        },
        backgroundColor: Colors.deepPurple,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.event,
            size: 80,
            color: Colors.deepPurple.withAlpha(128), // 0.5 opacity is roughly 128 in alpha (0-255)
          ),
          const SizedBox(height: 16),
          const Text(
            'No Events Yet',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'Create your first collector event with minimum attendance requirements.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () {
              _showCreateEventDialog();
            },
            icon: const Icon(Icons.add_circle),
            label: const Text('Create New Event'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepPurple,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventsList() {
    return Column(
      children: [
        // Event count summary
        Padding(
          padding: const EdgeInsets.all(16),
          child: Card(
            color: Colors.deepPurple.withAlpha(25), // 0.1 opacity is roughly 25 in alpha (0-255)
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.event_note, size: 24, color: Colors.deepPurple),
                  const SizedBox(width: 16),
                  Text(
                    'Total Events: ${_events.length}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        // Event list
        Expanded(
          child: ListView.builder(
            itemCount: _events.length,
            padding: const EdgeInsets.all(16),
            itemBuilder: (context, index) {
              final event = _events[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                elevation: 2,
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
                              Text(DateFormat('EEEE, MMM d, yyyy').format(event.eventDate)),
                              const SizedBox(width: 16),
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
                          if (event.locationLat != 0 && event.locationLng != 0)
                            Column(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: SizedBox(
                                    height: 150,
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
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
                                        mapToolbarEnabled: false,
                                        myLocationButtonEnabled: false,
                                      ),
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: ElevatedButton.icon(
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
                                ),
                              ],
                            ),
                          const SizedBox(height: 16),
                          Text(event.description),
                          const SizedBox(height: 16),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            alignment: WrapAlignment.start,
                            children: [
                              _buildInfoChip(
                                Icons.people,
                                'Min: ${event.minAttendees}',
                                Colors.orange,
                              ),
                              _buildInfoChip(
                                Icons.how_to_reg,
                                '${event.currentAttendees}/${event.minAttendees}',
                                Colors.green,
                              ),
                              _buildInfoChip(
                                Icons.event_available,
                                'Due: ${DateFormat('MMM d').format(event.registrationDeadline)}',
                                Colors.red,
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              TextButton.icon(
                                onPressed: () {
                                  _editEvent(event);
                                },
                                icon: const Icon(Icons.edit, size: 18),
                                label: const Text('Edit'),
                                style: const ButtonStyle(
                                  visualDensity: VisualDensity.compact,
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                              ),
                              TextButton.icon(
                                onPressed: () {
                                  _deleteEvent(event);
                                },
                                icon: const Icon(Icons.delete, size: 18),
                                label: const Text('Delete'),
                                style: ButtonStyle(
                                  visualDensity: VisualDensity.compact,
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  foregroundColor: WidgetStateProperty.all(Colors.red),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
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
  
  // Function to get user's current location
  Future<Position> _getCurrentPosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Check if location services are enabled
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled');
    }

    // Request location permission
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
      return Future.error('Location permissions are permanently denied');
    }

    // Get the current position
    return await Geolocator.getCurrentPosition();
  }
  
  void _showCreateEventDialog() {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    final locationController = TextEditingController();
    final minAttendeesController = TextEditingController();
    
    DateTime selectedDate = DateTime.now().add(const Duration(days: 7));
    TimeOfDay selectedTime = TimeOfDay.now();
    DateTime registrationDeadline = DateTime.now().add(const Duration(days: 5));
    
    // Map location variables
    LatLng? selectedLocation;
    final mapController = GlobalKey<FormFieldState>();

    showDialog(
      context: context,
      builder: (context) => Dialog.fullscreen(
        child: Scaffold(
          appBar: AppBar(
            title: const Text('Create New Event'),
            backgroundColor: Colors.deepPurple,
            foregroundColor: Colors.white,
            leading: IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          body: StatefulBuilder(
            builder: (BuildContext context, StateSetter setDialogState) {
              return Form(
                key: formKey,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextFormField(
                        controller: nameController,
                        decoration: const InputDecoration(
                          labelText: 'Event Name',
                          icon: Icon(Icons.event),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter an event name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: descriptionController,
                        decoration: const InputDecoration(
                          labelText: 'Description',
                          icon: Icon(Icons.description),
                        ),
                        maxLines: 3,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a description';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      
                      // Location with Map
                      Card(
                        elevation: 2,
                        margin: EdgeInsets.zero,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Event Location',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  if (selectedLocation != null)
                                    IconButton(
                                      icon: const Icon(Icons.edit, color: Colors.deepPurple),
                                      onPressed: () {
                                        _showLocationPickerDialog(locationController, mapController, selectedLocation).then((pickedLocation) {
                                          if (pickedLocation != null) {
                                            setDialogState(() {
                                              selectedLocation = pickedLocation;
                                            });
                                          }
                                        });
                                      },
                                    ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              
                              // Location field with add button
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: TextFormField(
                                      controller: locationController,
                                      decoration: const InputDecoration(
                                        labelText: 'Location',
                                        hintText: 'Event location',
                                        prefixIcon: Icon(Icons.location_on),
                                      ),
                                      readOnly: true,
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Please select a location';
                                        }
                                        return null;
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  ElevatedButton.icon(
                                    onPressed: () {
                                      _showLocationPickerDialog(locationController, mapController, selectedLocation).then((pickedLocation) {
                                        if (pickedLocation != null) {
                                          setDialogState(() {
                                            selectedLocation = pickedLocation;
                                          });
                                        }
                                      });
                                    },
                                    icon: const Icon(Icons.add_location_alt),
                                    label: const Text('Add Location'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.deepPurple,
                                      foregroundColor: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                              
                              // Hidden FormField for validation
                              FormField<LatLng>(
                                key: mapController,
                                initialValue: selectedLocation,
                                validator: (value) {
                                  if (value == null) {
                                    return 'Please select a location';
                                  }
                                  return null;
                                },
                                builder: (FormFieldState<LatLng> state) {
                                  return state.hasError
                                    ? Padding(
                                        padding: const EdgeInsets.only(top: 8, left: 12),
                                        child: Text(
                                          state.errorText!,
                                          style: TextStyle(
                                            color: Theme.of(context).colorScheme.error,
                                            fontSize: 12,
                                          ),
                                        ),
                                      )
                                    : const SizedBox.shrink();
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          const Icon(Icons.calendar_today, color: Colors.grey),
                          const SizedBox(width: 16),
                          Expanded(
                            child: InkWell(
                              onTap: () async {
                                final dialogContext = context; // Store context locally
                                final pickedDate = await showDatePicker(
                                  context: context,
                                  initialDate: selectedDate,
                                  firstDate: DateTime.now(),
                                  lastDate: DateTime.now().add(const Duration(days: 365)),
                                );
                                if (pickedDate != null && dialogContext.mounted) {
                                  setDialogState(() {
                                    selectedDate = DateTime(
                                      pickedDate.year,
                                      pickedDate.month,
                                      pickedDate.day,
                                      selectedTime.hour,
                                      selectedTime.minute,
                                    );
                                  });
                                }
                              },
                              child: InputDecorator(
                                decoration: const InputDecoration(
                                  labelText: 'Event Date',
                                  border: InputBorder.none,
                                ),
                                child: Text(DateFormat('EEEE, MMM d, yyyy').format(selectedDate)),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          const Icon(Icons.access_time, color: Colors.grey),
                          const SizedBox(width: 16),
                          Expanded(
                            child: InkWell(
                              onTap: () async {
                                final dialogContext = context; // Store context locally
                                final pickedTime = await showTimePicker(
                                  context: context,
                                  initialTime: selectedTime,
                                );
                                if (pickedTime != null && dialogContext.mounted) {
                                  setDialogState(() {
                                    selectedTime = pickedTime;
                                    selectedDate = DateTime(
                                      selectedDate.year,
                                      selectedDate.month,
                                      selectedDate.day,
                                      selectedTime.hour,
                                      selectedTime.minute,
                                    );
                                  });
                                }
                              },
                              child: InputDecorator(
                                decoration: const InputDecoration(
                                  labelText: 'Event Time',
                                  border: InputBorder.none,
                                ),
                                child: Text(DateFormat('h:mm a').format(selectedDate)),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          const Icon(Icons.event_available, color: Colors.grey),
                          const SizedBox(width: 16),
                          Expanded(
                            child: InkWell(
                              onTap: () async {
                                final pickedDate = await showDatePicker(
                                  context: context,
                                  initialDate: registrationDeadline,
                                  firstDate: DateTime.now(),
                                  lastDate: selectedDate,
                                );
                                if (pickedDate != null && context.mounted) {
                                  setDialogState(() {
                                    registrationDeadline = pickedDate;
                                  });
                                }
                              },
                              child: InputDecorator(
                                decoration: const InputDecoration(
                                  labelText: 'Registration Deadline',
                                  border: InputBorder.none,
                                ),
                                child: Text(DateFormat('EEEE, MMM d, yyyy').format(registrationDeadline)),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: minAttendeesController,
                        decoration: const InputDecoration(
                          labelText: 'Minimum Attendees Required',
                          icon: Icon(Icons.people),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a number';
                          }
                          final number = int.tryParse(value);
                          if (number == null || number < 2) {
                            return 'Must be at least 2 attendees';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              );
            }
          ),
          bottomNavigationBar: BottomAppBar(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: () async {
                      // Update the mapController's value to ensure validation works properly
                      mapController.currentState?.didChange(selectedLocation);
                      
                      if (formKey.currentState!.validate() && selectedLocation != null) {
                        try {
                          // Set combined date and time
                          final eventDateTime = DateTime(
                            selectedDate.year,
                            selectedDate.month,
                            selectedDate.day,
                            selectedTime.hour,
                            selectedTime.minute,
                          );
                          
                          // Create EventModel
                          final newEvent = EventModel(
                            name: nameController.text,
                            description: descriptionController.text,
                            location: locationController.text,
                            locationLat: selectedLocation!.latitude,
                            locationLng: selectedLocation!.longitude,
                            eventDate: eventDateTime,
                            registrationDeadline: registrationDeadline,
                            minAttendees: int.parse(minAttendeesController.text),
                            currentAttendees: 0,
                            status: EventStatus.pending, // Start as pending
                            createdBy: widget.user.uid,
                            createdAt: DateTime.now(),
                            attendees: [], // Start with empty attendees list
                          );
                          
                          // Save to Firestore
                          await _firestoreService.createEvent(newEvent);
                          
                          if (context.mounted) {
                            Navigator.pop(context);
                            // Refresh events list
                            _loadEvents();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Event created successfully')),
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Error creating event: $e')),
                            );
                          }
                        }
                      } else if (selectedLocation == null) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Please select a location on the map')),
                          );
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Create Event'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<LatLng?> _showLocationPickerDialog(TextEditingController locationController, GlobalKey<FormFieldState> mapController, LatLng? initialLocation) {
    Completer<LatLng?> completer = Completer<LatLng?>();
    final formKey = GlobalKey<FormState>();
    final searchController = TextEditingController();
    // Use a local reference to initialLocation
    LatLng? selectedLocation = initialLocation;
    GoogleMapController? googleMapController;

    // Function to search location by address (redefining for dialog scope)
    Future<void> searchLocationFromDialog(
      String address, 
      StateSetter setDialogState
    ) async {
      if (address.isEmpty) return;
      
      // Store buildContext locally to avoid issues with async gaps
      final buildContext = context;
      
      try {
        // Show loading indicator
        if (buildContext.mounted) {
          ScaffoldMessenger.of(buildContext).showSnackBar(
            const SnackBar(content: Text('Searching location...'), duration: Duration(seconds: 1)),
          );
        }
        
        List<Location> locations = await locationFromAddress(address);
        
        if (locations.isNotEmpty && buildContext.mounted) {
          final location = locations.first;
          
          setDialogState(() {
            selectedLocation = LatLng(
              location.latitude,
              location.longitude,
            );
            
            // Update the map controller
            mapController.currentState?.didChange(selectedLocation);
          });
          
          // Navigate to the searched location on the map
          if (selectedLocation != null) {
            googleMapController?.animateCamera(
              CameraUpdate.newCameraPosition(
                CameraPosition(
                  target: selectedLocation!,
                  zoom: 15,
                ),
              ),
            );
          }
          
          // Show success message
          if (buildContext.mounted) {
            ScaffoldMessenger.of(buildContext).showSnackBar(
              SnackBar(content: Text('Location found: $address')),
            );
          }
        } else if (buildContext.mounted) {
          ScaffoldMessenger.of(buildContext).showSnackBar(
            const SnackBar(content: Text('No matching location found')),
          );
        }
      } catch (e) {
        if (buildContext.mounted) {
          ScaffoldMessenger.of(buildContext).showSnackBar(
            SnackBar(content: Text('Could not find location: $e')),
          );
        }
      }
    }

    showDialog(
      context: context,
      builder: (context) => Dialog.fullscreen(
        child: Scaffold(
          appBar: AppBar(
            title: const Text('Select Location'),
            backgroundColor: Colors.deepPurple,
            foregroundColor: Colors.white,
            leading: IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          body: StatefulBuilder(
            builder: (BuildContext context, StateSetter setDialogState) {
              return Form(
                key: formKey,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Search field with integrated button
                      TextFormField(
                        controller: searchController,
                        decoration: InputDecoration(
                          hintText: 'Search for a location...',
                          prefixIcon: const Icon(Icons.search),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.search),
                            onPressed: () {
                              searchLocationFromDialog(searchController.text, setDialogState);
                            },
                          ),
                          filled: true,
                          fillColor: Colors.grey.shade100,
                        ),
                        onFieldSubmitted: (value) async {
                          searchLocationFromDialog(value, setDialogState);
                        },
                      ),
                      const SizedBox(height: 16),

                      // Location buttons in a row
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () async {
                                try {
                                  final position = await _getCurrentPosition();
                                  
                                  // Update the map with current location
                                  LatLng currentLocation = LatLng(position.latitude, position.longitude);
                                  setDialogState(() {
                                    selectedLocation = currentLocation;
                                  });
                                  
                                  mapController.currentState?.didChange(selectedLocation);
                                  
                                  // Navigate to the current location on the map
                                  googleMapController?.animateCamera(
                                    CameraUpdate.newCameraPosition(
                                      CameraPosition(
                                        target: currentLocation,
                                        zoom: 15,
                                      ),
                                    ),
                                  );
                                  
                                  // Get address from coordinates
                                  List<Placemark> placemarks = await placemarkFromCoordinates(
                                    position.latitude, position.longitude
                                  );
                                  if (placemarks.isNotEmpty) {
                                    Placemark place = placemarks.first;
                                    searchController.text = '${place.street}, ${place.locality}, ${place.country}';
                                  }
                                } catch (e) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Error getting location: $e')),
                                    );
                                  }
                                }
                              },
                              icon: const Icon(Icons.my_location),
                              label: const Text('Use My Current Location'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.deepPurple,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: FormField<LatLng>(
                          key: mapController,
                          initialValue: selectedLocation,
                          validator: (value) {
                            if (value == null) {
                              return 'Please select a location on the map';
                            }
                            return null;
                          },
                          builder: (FormFieldState<LatLng> state) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  height: 250,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: state.value != null
                                      ? GoogleMap(
                                          initialCameraPosition: CameraPosition(
                                            target: state.value!,
                                            zoom: 15,
                                          ),
                                          markers: {
                                            Marker(
                                              markerId: const MarkerId('selectedLocation'),
                                              position: state.value!,
                                              draggable: true,
                                              onDragEnd: (LatLng position) async {
                                                selectedLocation = position;
                                                state.didChange(position);
                                                
                                                // Get address from the new position
                                                try {
                                                  List<Placemark> placemarks = await placemarkFromCoordinates(
                                                    position.latitude, position.longitude
                                                  );
                                                  if (placemarks.isNotEmpty) {
                                                    Placemark place = placemarks.first;
                                                    searchController.text = 
                                                      '${place.street}, ${place.locality}, ${place.country}';
                                                  }
                                                } catch (e) {
                                                  // Handle error getting address
                                                }
                                              },
                                            ),
                                          },
                                          onTap: (LatLng position) async {
                                            selectedLocation = position;
                                            state.didChange(position);
                                            
                                            // Get address from the tapped position
                                            try {
                                              List<Placemark> placemarks = await placemarkFromCoordinates(
                                                position.latitude, position.longitude
                                              );
                                              if (placemarks.isNotEmpty) {
                                                Placemark place = placemarks.first;
                                                searchController.text = 
                                                  '${place.street}, ${place.locality}, ${place.country}';
                                              }
                                            } catch (e) {
                                              // Handle error getting address
                                            }
                                          },
                                          onMapCreated: (controller) {
                                            googleMapController = controller;
                                          },
                                        )
                                      : const Center(
                                          child: Padding(
                                            padding: EdgeInsets.all(16.0),
                                            child: Text(
                                              'Search for a location or tap the map to set the event venue',
                                              textAlign: TextAlign.center,
                                              style: TextStyle(
                                                color: Colors.grey,
                                                fontSize: 16,
                                              ),
                                            ),
                                          ),
                                        ),
                                  ),
                                ),
                                if (state.hasError)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 8, left: 12),
                                    child: Text(
                                      state.errorText!,
                                      style: TextStyle(
                                        color: Theme.of(context).colorScheme.error,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                if (state.value != null)
                                  Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Text(
                                      'Tap anywhere on the map or drag the marker to adjust location',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade600,
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  ),
                              ],
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }
          ),
          bottomNavigationBar: BottomAppBar(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                      // Complete with null to indicate cancellation
                      completer.complete(null);
                    },
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: () {
                      if (formKey.currentState!.validate() && selectedLocation != null) {
                        locationController.text = searchController.text;
                        // Update the parent dialog's selectedLocation reference
                        mapController.currentState?.didChange(selectedLocation);
                        Navigator.pop(context);
                        // Complete with the selected location
                        completer.complete(selectedLocation);
                      } else if (selectedLocation == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Please select a location on the map')),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Select Location'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    
    // Return the completer's future
    return completer.future;
  }

  // Delete an event
  void _deleteEvent(EventModel event) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Event?'),
        content: Text('Are you sure you want to delete "${event.name}"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final contextRef = context; // Store context before async operation
              try {
                await _firestoreService.deleteEvent(event.id!);
                if (contextRef.mounted) {
                  // Refresh events list
                  _loadEvents();
                  ScaffoldMessenger.of(contextRef).showSnackBar(
                    const SnackBar(content: Text('Event deleted successfully')),
                  );
                }
              } catch (e) {
                if (contextRef.mounted) {
                  ScaffoldMessenger.of(contextRef).showSnackBar(
                    SnackBar(content: Text('Error deleting event: $e')),
                  );
                }
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _editEvent(EventModel event) {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: event.name);
    final descriptionController = TextEditingController(text: event.description);
    final locationController = TextEditingController(text: event.location);
    final minAttendeesController = TextEditingController(text: event.minAttendees.toString());
    
    DateTime selectedDate = event.eventDate;
    TimeOfDay selectedTime = TimeOfDay.fromDateTime(event.eventDate);
    DateTime registrationDeadline = event.registrationDeadline;
    
    // Map location variables
    LatLng selectedLocation = LatLng(event.locationLat, event.locationLng);
    final mapController = GlobalKey<FormFieldState>();

    showDialog(
      context: context,
      builder: (context) => Dialog.fullscreen(
        child: Scaffold(
          appBar: AppBar(
            title: const Text('Edit Event'),
            backgroundColor: Colors.deepPurple,
            foregroundColor: Colors.white,
            leading: IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          body: StatefulBuilder(
            builder: (BuildContext context, StateSetter setDialogState) {
              return Form(
                key: formKey,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextFormField(
                        controller: nameController,
                        decoration: const InputDecoration(
                          labelText: 'Event Name',
                          icon: Icon(Icons.event),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter an event name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: descriptionController,
                        decoration: const InputDecoration(
                          labelText: 'Description',
                          icon: Icon(Icons.description),
                        ),
                        maxLines: 3,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a description';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      
                      // Location with Map
                      Card(
                        elevation: 2,
                        margin: EdgeInsets.zero,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Event Location',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.edit, color: Colors.deepPurple),
                                    onPressed: () {
                                      _showLocationPickerDialog(locationController, mapController, selectedLocation).then((pickedLocation) {
                                        if (pickedLocation != null) {
                                          setDialogState(() {
                                            selectedLocation = pickedLocation;
                                          });
                                        }
                                      });
                                    },
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              
                              // Location field with add button
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: TextFormField(
                                      controller: locationController,
                                      decoration: const InputDecoration(
                                        labelText: 'Location',
                                        hintText: 'Event location',
                                        prefixIcon: Icon(Icons.location_on),
                                      ),
                                      readOnly: true,
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Please select a location';
                                        }
                                        return null;
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  ElevatedButton.icon(
                                    onPressed: () {
                                      _showLocationPickerDialog(locationController, mapController, selectedLocation).then((pickedLocation) {
                                        if (pickedLocation != null) {
                                          setDialogState(() {
                                            selectedLocation = pickedLocation;
                                          });
                                        }
                                      });
                                    },
                                    icon: const Icon(Icons.add_location_alt),
                                    label: const Text('Add Location'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.deepPurple,
                                      foregroundColor: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                              
                              // Hidden FormField for validation
                              FormField<LatLng>(
                                key: mapController,
                                initialValue: selectedLocation,
                                validator: (value) {
                                  if (value == null) {
                                    return 'Please select a location';
                                  }
                                  return null;
                                },
                                builder: (FormFieldState<LatLng> state) {
                                  return state.hasError
                                    ? Padding(
                                        padding: const EdgeInsets.only(top: 8, left: 12),
                                        child: Text(
                                          state.errorText!,
                                          style: TextStyle(
                                            color: Theme.of(context).colorScheme.error,
                                            fontSize: 12,
                                          ),
                                        ),
                                      )
                                    : const SizedBox.shrink();
                                },
                              ),
                              
                              // Map preview
                              const SizedBox(height: 16),
                              Container(
                                height: 200,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.grey.shade300),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: GoogleMap(
                                    initialCameraPosition: CameraPosition(
                                      target: selectedLocation,
                                      zoom: 14,
                                    ),
                                    markers: {
                                      Marker(
                                        markerId: const MarkerId('eventLocation'),
                                        position: selectedLocation,
                                      ),
                                    },
                                    mapType: MapType.normal,
                                    myLocationEnabled: true,
                                    myLocationButtonEnabled: false,
                                    zoomControlsEnabled: false,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          const Icon(Icons.calendar_today, color: Colors.grey),
                          const SizedBox(width: 16),
                          Expanded(
                            child: InkWell(
                              onTap: () async {
                                final dialogContext = context; // Store context locally
                                final pickedDate = await showDatePicker(
                                  context: context,
                                  initialDate: selectedDate,
                                  firstDate: DateTime.now(),
                                  lastDate: DateTime.now().add(const Duration(days: 365)),
                                );
                                if (pickedDate != null && dialogContext.mounted) {
                                  setDialogState(() {
                                    selectedDate = DateTime(
                                      pickedDate.year,
                                      pickedDate.month,
                                      pickedDate.day,
                                      selectedTime.hour,
                                      selectedTime.minute,
                                    );
                                  });
                                }
                              },
                              child: InputDecorator(
                                decoration: const InputDecoration(
                                  labelText: 'Event Date',
                                  border: InputBorder.none,
                                ),
                                child: Text(DateFormat('EEEE, MMM d, yyyy').format(selectedDate)),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          const Icon(Icons.access_time, color: Colors.grey),
                          const SizedBox(width: 16),
                          Expanded(
                            child: InkWell(
                              onTap: () async {
                                final dialogContext = context; // Store context locally
                                final pickedTime = await showTimePicker(
                                  context: context,
                                  initialTime: selectedTime,
                                );
                                if (pickedTime != null && dialogContext.mounted) {
                                  setDialogState(() {
                                    selectedTime = pickedTime;
                                    selectedDate = DateTime(
                                      selectedDate.year,
                                      selectedDate.month,
                                      selectedDate.day,
                                      selectedTime.hour,
                                      selectedTime.minute,
                                    );
                                  });
                                }
                              },
                              child: InputDecorator(
                                decoration: const InputDecoration(
                                  labelText: 'Event Time',
                                  border: InputBorder.none,
                                ),
                                child: Text(DateFormat('h:mm a').format(selectedDate)),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          const Icon(Icons.event_available, color: Colors.grey),
                          const SizedBox(width: 16),
                          Expanded(
                            child: InkWell(
                              onTap: () async {
                                final pickedDate = await showDatePicker(
                                  context: context,
                                  initialDate: registrationDeadline,
                                  firstDate: DateTime.now(),
                                  lastDate: selectedDate,
                                );
                                if (pickedDate != null && context.mounted) {
                                  setDialogState(() {
                                    registrationDeadline = pickedDate;
                                  });
                                }
                              },
                              child: InputDecorator(
                                decoration: const InputDecoration(
                                  labelText: 'Registration Deadline',
                                  border: InputBorder.none,
                                ),
                                child: Text(DateFormat('EEEE, MMM d, yyyy').format(registrationDeadline)),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: minAttendeesController,
                        decoration: const InputDecoration(
                          labelText: 'Minimum Attendees Required',
                          icon: Icon(Icons.people),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a number';
                          }
                          final number = int.tryParse(value);
                          if (number == null || number < 2) {
                            return 'Must be at least 2 attendees';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              );
            }
          ),
          bottomNavigationBar: BottomAppBar(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: () async {
                      // Update the mapController's value to ensure validation works properly
                      mapController.currentState?.didChange(selectedLocation);
                      
                      if (formKey.currentState!.validate()) {
                        try {
                          // Set combined date and time
                          final eventDateTime = DateTime(
                            selectedDate.year,
                            selectedDate.month,
                            selectedDate.day,
                            selectedTime.hour,
                            selectedTime.minute,
                          );
                          
                          // Create EventModel
                          final updatedEvent = EventModel(
                            id: event.id,
                            name: nameController.text,
                            description: descriptionController.text,
                            location: locationController.text,
                            locationLat: selectedLocation.latitude,
                            locationLng: selectedLocation.longitude,
                            eventDate: eventDateTime,
                            registrationDeadline: registrationDeadline,
                            minAttendees: int.parse(minAttendeesController.text),
                            currentAttendees: event.currentAttendees, // Keep existing attendees
                            status: event.status, // Keep existing status
                            createdBy: event.createdBy, // Keep existing createdBy
                            createdAt: event.createdAt, // Keep existing createdAt
                            attendees: event.attendees, // Keep existing attendees
                          );
                          
                          // Save to Firestore
                          await _firestoreService.updateEvent(updatedEvent);
                          
                          if (context.mounted) {
                            Navigator.pop(context);
                            // Refresh events list
                            _loadEvents();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Event updated successfully')),
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Error updating event: $e')),
                            );
                          }
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Update Event'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
} 