import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import '../../models/user_model.dart';
import '../../models/listing_model.dart';
import '../../services/firestore_service.dart';
import '../../services/storage_service.dart';

class CreateAuctionScreen extends StatefulWidget {
  final UserModel user;
  
  const CreateAuctionScreen({
    super.key,
    required this.user,
  });

  @override
  State<CreateAuctionScreen> createState() => _CreateAuctionScreenState();
}

class _CreateAuctionScreenState extends State<CreateAuctionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firestoreService = FirestoreService();
  final _picker = ImagePicker();
  final _storageService = StorageService();
  
  // Form controllers
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _startingPriceController = TextEditingController();
  final TextEditingController _bidIncrementController = TextEditingController();
  final TextEditingController _startDateController = TextEditingController();
  final TextEditingController _startTimeController = TextEditingController();
  final TextEditingController _endDateController = TextEditingController();
  final TextEditingController _endTimeController = TextEditingController();
  
  // Form values
  String _title = '';
  String _description = '';
  double _startingPrice = 0.0;
  double _bidIncrement = 1.0;
  String _selectedCategory = 'Trading Cards';
  String _selectedSubcategory = 'Pokémon TCG';
  CollectibleCondition _selectedCondition = CollectibleCondition.mint;
  bool _startNow = true;
  DateTime _startDate = DateTime.now();
  TimeOfDay _startTime = TimeOfDay.now();
  DateTime _endDate = DateTime.now().add(const Duration(days: 7));
  TimeOfDay _endTime = TimeOfDay.now();
  final List<String> _images = []; // For existing/uploaded image URLs
  final List<File> _imageFiles = []; // For local image files
  
  bool _isLoading = false;
  bool _isUploadingImages = false;
  String _errorMessage = '';
  
  // Predefined categories for dropdown (based on project proposal)
  final List<String> _categories = [
    'Trading Cards',
    'Comics',
    'Toys',
    'Stamps',
    'Coins',
    'Funko Pops',
    'Action Figures',
    'Vintage Items',
  ];
  
  // Map of subcategories for each category
  final Map<String, List<String>> _subcategories = {
    'Trading Cards': ['Pokémon TCG', 'Magic: The Gathering', 'Yu-Gi-Oh!', 'Sports Cards', 'Other'],
    'Comics': ['Marvel', 'DC', 'Manga', 'Independent', 'European', 'Other'],
    'Toys': ['Action Figures', 'Model Kits', 'Dolls', 'Vintage', 'LEGO', 'Other'],
    'Stamps': ['Malaysia', 'Asia', 'Europe', 'Americas', 'Africa', 'Other'],
    'Coins': ['Malaysia', 'Ancient', 'World', 'Commemorative', 'Bullion', 'Other'],
    'Funko Pops': ['Marvel', 'DC', 'Movies', 'TV Shows', 'Games', 'Animation', 'Other'],
    'Action Figures': ['Marvel', 'DC', 'Star Wars', 'Anime', 'Video Games', 'Other'],
    'Vintage Items': ['Toys', 'Games', 'Electronics', 'Household', 'Other'],
  };

  // Condition options
  final List<Map<String, dynamic>> _conditions = [
    {'condition': CollectibleCondition.mint, 'label': 'Mint'},
    {'condition': CollectibleCondition.nearMint, 'label': 'Near Mint'},
    {'condition': CollectibleCondition.excellent, 'label': 'Excellent'},
    {'condition': CollectibleCondition.good, 'label': 'Good'},
    {'condition': CollectibleCondition.poor, 'label': 'Poor'},
  ];

  @override
  void initState() {
    super.initState();
    
    // Initialize date/time controllers with default values
    _startDateController.text = DateFormat('yyyy-MM-dd').format(_startDate);
    _startTimeController.text = _formatTimeOfDay(_startTime);
    _endDateController.text = DateFormat('yyyy-MM-dd').format(_endDate);
    _endTimeController.text = _formatTimeOfDay(_endTime);
    
    // Set default bid increment
    _bidIncrementController.text = '1.00';
  }
  
  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _startingPriceController.dispose();
    _bidIncrementController.dispose();
    _startDateController.dispose();
    _startTimeController.dispose();
    _endDateController.dispose();
    _endTimeController.dispose();
    super.dispose();
  }
  
  // Format TimeOfDay to string
  String _formatTimeOfDay(TimeOfDay time) {
    final hours = time.hour.toString().padLeft(2, '0');
    final minutes = time.minute.toString().padLeft(2, '0');
    return '$hours:$minutes';
  }
  
  // Show date picker
  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final DateTime initialDate = isStartDate ? _startDate : _endDate;
    final DateTime firstDate = isStartDate ? DateTime.now() : _startDate;
    
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: DateTime.now().add(const Duration(days: 90)), // Allow up to 90 days
    );
    
    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
          _startDateController.text = DateFormat('yyyy-MM-dd').format(picked);
          
          // If end date is before start date, adjust it
          if (_endDate.isBefore(_startDate)) {
            _endDate = _startDate.add(const Duration(days: 1));
            _endDateController.text = DateFormat('yyyy-MM-dd').format(_endDate);
          }
        } else {
          _endDate = picked;
          _endDateController.text = DateFormat('yyyy-MM-dd').format(picked);
        }
      });
    }
  }
  
  // Show time picker
  Future<void> _selectTime(BuildContext context, bool isStartTime) async {
    final TimeOfDay initialTime = isStartTime ? _startTime : _endTime;
    
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
    );
    
    if (picked != null) {
      setState(() {
        if (isStartTime) {
          _startTime = picked;
          _startTimeController.text = _formatTimeOfDay(picked);
        } else {
          _endTime = picked;
          _endTimeController.text = _formatTimeOfDay(picked);
        }
      });
    }
  }
  
  // Show bottom sheet with camera and gallery options
  Future<void> _showImagePickerOptions() async {
    await showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Gallery'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera),
                title: const Text('Camera'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              if (_imageFiles.isNotEmpty)
                ListTile(
                  leading: const Icon(Icons.delete, color: Colors.red),
                  title: const Text('Remove All Images', style: TextStyle(color: Colors.red)),
                  onTap: () {
                    Navigator.pop(context);
                    setState(() {
                      _imageFiles.clear();
                      _images.clear();
                    });
                  },
                ),
            ],
          ),
        );
      },
    );
  }
  
  // Pick image from gallery or camera
  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        imageQuality: 80,
      );
      
      if (image != null) {
        setState(() {
          _imageFiles.add(File(image.path));
        });
        
        // Show success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Image added successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error picking image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Create auction
  Future<void> _createAuction() async {
    // Validate all fields and show all errors at once
    final isValid = _formKey.currentState!.validate();
    
    if (!isValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in all required fields'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    _formKey.currentState!.save();
    
    // Check for empty images list
    if (_imageFiles.isEmpty && _images.isEmpty) {
      setState(() {
        _errorMessage = 'Please add at least one image';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add at least one image'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      // Upload images to Firebase Storage if there are local files
      if (_imageFiles.isNotEmpty) {
        setState(() {
          _isUploadingImages = true;
        });
        
        // Upload images to Firebase Storage
        final downloadUrls = await _storageService.uploadImages(_imageFiles, 'auctions');
        
        // Add the new image URLs to the existing ones
        _images.addAll(downloadUrls);
        
        setState(() {
          _isUploadingImages = false;
        });
      }

      // Combine date and time for start and end
      DateTime startDateTime;
      if (_startNow) {
        startDateTime = DateTime.now();
      } else {
        final startHour = _startTime.hour;
        final startMinute = _startTime.minute;
        startDateTime = DateTime(
          _startDate.year,
          _startDate.month,
          _startDate.day,
          startHour,
          startMinute,
        );
      }

      final endHour = _endTime.hour;
      final endMinute = _endTime.minute;
      final endDateTime = DateTime(
        _endDate.year,
        _endDate.month,
        _endDate.day,
        endHour,
        endMinute,
      );

      // Create the auction
      await _firestoreService.createAuction(
        title: _title,
        description: _description,
        sellerId: widget.user.uid,
        sellerName: widget.user.displayName ?? 'Unknown Seller',
        startingPrice: _startingPrice,
        bidIncrement: _bidIncrement,
        startTime: startDateTime,
        endTime: endDateTime,
        category: _selectedCategory,
        subcategory: _selectedSubcategory,
        condition: _selectedCondition,
        images: _images,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Auction created successfully'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error creating auction: $e';
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $_errorMessage'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isUploadingImages = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Auction'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: _isLoading && !_isUploadingImages
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Creating auction...'),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Image upload section
                    GestureDetector(
                      onTap: () {
                        _showImagePickerOptions();
                      },
                      child: Container(
                        width: double.infinity,
                        height: 200,
                        decoration: BoxDecoration(
                          color: _images.isEmpty && _imageFiles.isEmpty ? Colors.grey.shade200 : Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _images.isEmpty && _imageFiles.isEmpty ? Colors.grey.shade400 : Theme.of(context).colorScheme.primary,
                            width: _images.isEmpty && _imageFiles.isEmpty ? 1 : 2,
                          )
                        ),
                        child: _isUploadingImages ? 
                          const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                CircularProgressIndicator(),
                                SizedBox(height: 12),
                                Text('Uploading images...'),
                              ],
                            ),
                          ) :
                          _imageFiles.isEmpty && _images.isEmpty ?
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(
                                Icons.add_photo_alternate_outlined,
                                size: 50,
                                color: Colors.grey,
                              ),
                              SizedBox(height: 12),
                              Text(
                                'Add Photos (up to 8)',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'First image will be the cover image',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                              ),
                              Text(
                                '* Required',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.red,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ) :
                          Column(
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text(
                                  '${_imageFiles.length} image(s) selected',
                                  style: TextStyle(
                                    color: Theme.of(context).colorScheme.primary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: _imageFiles.length,
                                  itemBuilder: (context, index) {
                                    return Padding(
                                      padding: const EdgeInsets.all(4.0),
                                      child: Stack(
                                        children: [
                                          ClipRRect(
                                            borderRadius: BorderRadius.circular(8),
                                            child: Image.file(
                                              _imageFiles[index],
                                              width: 100,
                                              height: 100,
                                              fit: BoxFit.cover,
                                            ),
                                          ),
                                          Positioned(
                                            top: 0,
                                            right: 0,
                                            child: GestureDetector(
                                              onTap: () {
                                                setState(() {
                                                  _imageFiles.removeAt(index);
                                                });
                                              },
                                              child: Container(
                                                decoration: const BoxDecoration(
                                                  color: Colors.red,
                                                  shape: BoxShape.circle,
                                                ),
                                                padding: const EdgeInsets.all(4),
                                                child: const Icon(
                                                  Icons.close,
                                                  color: Colors.white,
                                                  size: 16,
                                                ),
                                              ),
                                            ),
                                          ),
                                          if (index == 0)
                                            Positioned(
                                              bottom: 0,
                                              left: 0,
                                              child: Container(
                                                decoration: BoxDecoration(
                                                  color: Colors.blue,
                                                  borderRadius: BorderRadius.circular(4),
                                                ),
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                child: const Text(
                                                  'Cover',
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                      ),
                    ),
                    if (_errorMessage.isNotEmpty && _imageFiles.isEmpty && _images.isEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          'Error: At least one image is required',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      ),
                    const SizedBox(height: 24),

                    // Item Details section
                    const Text(
                      'Item Details',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _titleController,
                      decoration: InputDecoration(
                        labelText: 'Item Title *',
                        prefixIcon: const Icon(Icons.title),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a title';
                        }
                        return null;
                      },
                      onSaved: (value) => _title = value!,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _descriptionController,
                      decoration: InputDecoration(
                        labelText: 'Description *',
                        prefixIcon: const Icon(Icons.description),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      maxLines: 4,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a description';
                        }
                        return null;
                      },
                      onSaved: (value) => _description = value!,
                    ),
                    const SizedBox(height: 24),

                    // Category & Condition section
                    const Text(
                      'Category & Condition',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      decoration: InputDecoration(
                        labelText: 'Category *',
                        prefixIcon: const Icon(Icons.category),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      value: _selectedCategory,
                      items: _categories
                          .map((category) => DropdownMenuItem(
                                value: category,
                                child: Text(category),
                              ))
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedCategory = value!;
                          // Reset subcategory based on new category
                          if (_subcategories.containsKey(_selectedCategory)) {
                            _selectedSubcategory = _subcategories[_selectedCategory]![0];
                          }
                        });
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please select a category';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      decoration: InputDecoration(
                        labelText: 'Subcategory *',
                        prefixIcon: const Icon(Icons.category_outlined),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      value: _selectedSubcategory,
                      items: (_subcategories[_selectedCategory] ?? ['Other'])
                          .map((subcategory) => DropdownMenuItem(
                                value: subcategory,
                                child: Text(subcategory),
                              ))
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedSubcategory = value!;
                        });
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please select a subcategory';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<CollectibleCondition>(
                      decoration: InputDecoration(
                        labelText: 'Condition *',
                        prefixIcon: const Icon(Icons.star_border),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      value: _selectedCondition,
                      items: _conditions
                          .map((item) => DropdownMenuItem<CollectibleCondition>(
                                value: item['condition'] as CollectibleCondition,
                                child: Text(item['label']),
                              ))
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedCondition = value!;
                        });
                      },
                      validator: (value) {
                        if (value == null) {
                          return 'Please select a condition';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    
                    // Auction Details section
                    const Text(
                      'Auction Details',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _startingPriceController,
                      decoration: InputDecoration(
                        labelText: 'Starting Price (RM) *',
                        prefixIcon: const Icon(Icons.monetization_on),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a starting price';
                        }
                        try {
                          double price = double.parse(value);
                          if (price <= 0) {
                            return 'Price must be greater than 0';
                          }
                        } catch (e) {
                          return 'Please enter a valid number';
                        }
                        return null;
                      },
                      onSaved: (value) => _startingPrice = double.tryParse(value!) ?? 0,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _bidIncrementController,
                      decoration: InputDecoration(
                        labelText: 'Bid Increment (RM) *',
                        prefixIcon: const Icon(Icons.trending_up),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a bid increment';
                        }
                        try {
                          double increment = double.parse(value);
                          if (increment <= 0) {
                            return 'Increment must be greater than 0';
                          }
                        } catch (e) {
                          return 'Please enter a valid number';
                        }
                        return null;
                      },
                      onSaved: (value) => _bidIncrement = double.tryParse(value!) ?? 1.0,
                    ),
                    const SizedBox(height: 24),
                    
                    // Start Time section
                    const Text(
                      'Start Time',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SwitchListTile(
                      title: const Text('Start auction now'),
                      value: _startNow,
                      onChanged: (value) {
                        setState(() {
                          _startNow = value;
                        });
                      },
                    ),
                    if (!_startNow) ...[
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _startDateController,
                              readOnly: true,
                              decoration: InputDecoration(
                                labelText: 'Start Date *',
                                prefixIcon: const Icon(Icons.calendar_today),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                filled: true,
                                fillColor: Colors.white,
                              ),
                              onTap: () => _selectDate(context, true),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: _startTimeController,
                              readOnly: true,
                              decoration: InputDecoration(
                                labelText: 'Start Time *',
                                prefixIcon: const Icon(Icons.access_time),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                filled: true,
                                fillColor: Colors.white,
                              ),
                              onTap: () => _selectTime(context, true),
                            ),
                          ),
                        ],
                      ),
                    ],
                    
                    const SizedBox(height: 24),
                    
                    // End Time section
                    const Text(
                      'End Time',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _endDateController,
                            readOnly: true,
                            decoration: InputDecoration(
                              labelText: 'End Date *',
                              prefixIcon: const Icon(Icons.calendar_today),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              filled: true,
                              fillColor: Colors.white,
                            ),
                            onTap: () => _selectDate(context, false),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _endTimeController,
                            readOnly: true,
                            decoration: InputDecoration(
                              labelText: 'End Time *',
                              prefixIcon: const Icon(Icons.access_time),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              filled: true,
                              fillColor: Colors.white,
                            ),
                            onTap: () => _selectTime(context, false),
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 32),
                    
                    if (_errorMessage.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: Text(
                          _errorMessage,
                          style: TextStyle(color: Theme.of(context).colorScheme.error),
                        ),
                      ),
                    
                    // Required fields note
                    const Padding(
                      padding: EdgeInsets.only(bottom: 16.0),
                      child: Text(
                        '* Required fields must be filled',
                        style: TextStyle(
                          color: Colors.red,
                          fontStyle: FontStyle.italic,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    
                    SizedBox(
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _createAuction,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isLoading
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text(
                                'CREATE AUCTION',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}