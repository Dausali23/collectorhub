import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../models/listing_model.dart';
import '../../services/firestore_service.dart';
import '../../models/user_model.dart';
import '../../services/ebay_api_service.dart';
import '../../services/storage_service.dart';

class AddListingScreen extends StatefulWidget {
  final UserModel? user;
  
  const AddListingScreen({super.key, this.user});

  @override
  State<AddListingScreen> createState() => _AddListingScreenState();
}

class _AddListingScreenState extends State<AddListingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firestoreService = FirestoreService();
  final _ebayApiService = EbayApiService();
  final _picker = ImagePicker();
  final _storageService = StorageService();
  
  final TextEditingController _titleController = TextEditingController();
  
  String _title = '';
  String _description = '';
  double _price = 0.0;
  double? _marketPrice;
  String _selectedCategory = 'Trading Cards';
  String _selectedSubcategory = 'Pokémon TCG';
  CollectibleCondition _selectedCondition = CollectibleCondition.mint;
  // Always fixed price for this screen
  bool _isFixedPrice = true;
  bool _isLoadingMarketPrice = false;
  List<String> _images = [];
  List<File> _imageFiles = []; // Local image files
  
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
    _titleController.addListener(_fetchMarketPrice);
  }
  
  @override
  void dispose() {
    _titleController.removeListener(_fetchMarketPrice);
    _titleController.dispose();
    super.dispose();
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
  
  // Build horizontal scrollable list of image previews
  Widget _buildImagePreviewList() {
    return ListView.builder(
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
                    child: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
  
  // Fetch market price from eBay API
  Future<void> _fetchMarketPrice() async {
    // Only fetch when title is at least 3 characters long
    if (_titleController.text.length < 3) return;
    
    setState(() {
      _isLoadingMarketPrice = true;
    });
    
    try {
      final price = await _ebayApiService.getMarketPrice(
        _titleController.text,
        _selectedCategory,
        subcategory: _selectedSubcategory,
      );
      
      if (mounted) {
        setState(() {
          _marketPrice = price;
          _isLoadingMarketPrice = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _marketPrice = null;
          _isLoadingMarketPrice = false;
        });
      }
    }
  }

  Future<void> _addListing() async {
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
      // Use the user passed to constructor or get from Provider
      final currentUser = widget.user ?? Provider.of<UserModel?>(context, listen: false);
      
      if (currentUser == null) {
        throw Exception('User not logged in');
      }
      
      // Upload images to Firebase Storage if there are local files
      if (_imageFiles.isNotEmpty) {
        setState(() {
          _isUploadingImages = true;
        });
        
        // Upload images to Firebase Storage
        final downloadUrls = await _storageService.uploadImages(_imageFiles);
        
        // Add the new image URLs to the existing ones
        _images.addAll(downloadUrls);
        
        setState(() {
          _isUploadingImages = false;
        });
      }
      
      // Create listing model
      final listing = ListingModel(
        sellerId: currentUser.uid,
        sellerName: currentUser.displayName ?? currentUser.email.split('@')[0],
        title: _title,
        description: _description,
        price: _price,
        marketPrice: _marketPrice,
        category: _selectedCategory,
        subcategory: _selectedSubcategory,
        condition: _selectedCondition,
        images: _images,
        isFixedPrice: _isFixedPrice,
        createdAt: DateTime.now(),
      );
      
      // Save to Firestore
      await _firestoreService.addListing(listing);
      
      if (mounted) {
        // Show success message and navigate back
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Collectible listing added successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to add listing: $e';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${_errorMessage}'),
          backgroundColor: Colors.red,
        ),
      );
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
        title: const Text('Add Fixed Price Collectible'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
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
                          child: _buildImagePreviewList(),
                        ),
                      ],
                    ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Form fields - Item details
              const Text(
                'Item Details',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Item title
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: 'Item Title *',
                  hintText: 'Enter the name of your collectible',
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
              
              // Description
              TextFormField(
                decoration: InputDecoration(
                  labelText: 'Description *',
                  hintText: 'Describe your collectible in detail...',
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
              
              // Form fields - Category & condition
              const Text(
                'Category & Condition',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Category dropdown
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
                    
                    // Re-fetch market price with new category
                    _fetchMarketPrice();
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
              
              // Subcategory dropdown
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
                    
                    // Re-fetch market price with new subcategory
                    _fetchMarketPrice();
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
              
              // Condition dropdown
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
              
              // Form fields - Pricing
              const Text(
                'Pricing',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Market price info (from eBay)
              if (_isLoadingMarketPrice)
                const Padding(
                  padding: EdgeInsets.only(bottom: 16.0),
                  child: Center(
                    child: Column(
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 8),
                        Text('Fetching current market price...'),
                      ],
                    ),
                  ),
                )
              else if (_marketPrice != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: Card(
                    color: Colors.blue.shade50,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: Colors.blue.shade200),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.info_outline, color: Colors.blue.shade700),
                              const SizedBox(width: 8),
                              Text(
                                'Current Market Price',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue.shade700,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'RM${_marketPrice!.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Text(
                            'Based on recent eBay sales data',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              
              // Price field
              TextFormField(
                decoration: InputDecoration(
                  labelText: 'Price (RM) *',
                  hintText: '0.00',
                  prefixIcon: const Icon(Icons.attach_money),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a price';
                  }
                  try {
                    final price = double.parse(value);
                    if (price < 0) {
                      return 'Price cannot be negative';
                    }
                  } catch (_) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
                onSaved: (value) => _price = double.tryParse(value!) ?? 0,
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
                  onPressed: _isLoading ? null : _addListing,
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
                          'CREATE LISTING',
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