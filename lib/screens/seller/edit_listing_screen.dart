import 'package:flutter/material.dart';
import '../../models/listing_model.dart';
import '../../services/firestore_service.dart';

class EditListingScreen extends StatefulWidget {
  final String listingId;
  
  const EditListingScreen({super.key, required this.listingId});

  @override
  State<EditListingScreen> createState() => _EditListingScreenState();
}

class _EditListingScreenState extends State<EditListingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firestoreService = FirestoreService();
  
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  
  ListingModel? _listing;
  bool _isLoading = true;
  String _errorMessage = '';
  
  String _selectedCategory = 'Trading Cards';
  String _selectedSubcategory = 'Pokémon TCG';
  CollectibleCondition _selectedCondition = CollectibleCondition.mint;
  bool _isFixedPrice = true;
  
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
    _loadListing();
  }
  
  Future<void> _loadListing() async {
    try {
      final listing = await _firestoreService.getListingById(widget.listingId);
      
      if (mounted) {
        setState(() {
          _listing = listing;
          _isLoading = false;
          
          // Initialize form fields
          _titleController.text = listing.title;
          _descriptionController.text = listing.description;
          _priceController.text = listing.price.toString();
          _selectedCategory = listing.category;
          _selectedSubcategory = listing.subcategory;
          _selectedCondition = listing.condition;
          _isFixedPrice = listing.isFixedPrice;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load listing: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _updateListing() async {
    if (!_formKey.currentState!.validate() || _listing == null) {
      return;
    }
    
    _formKey.currentState!.save();
    
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    
    try {
      // Update the existing listing
      final updatedListing = _listing!.copyWith(
        title: _titleController.text,
        description: _descriptionController.text,
        price: double.parse(_priceController.text),
        category: _selectedCategory,
        subcategory: _selectedSubcategory,
        condition: _selectedCondition,
        isFixedPrice: _isFixedPrice,
      );
      
      // Save to Firestore
      await _firestoreService.updateListing(updatedListing);
      
      if (!mounted) return;
      
      // Show success message and navigate back
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Collectible updated successfully!')),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      
      setState(() {
        _errorMessage = 'Failed to update listing: $e';
        _isLoading = false;
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Edit Collectible'),
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    
    if (_errorMessage.isNotEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Edit Collectible'),
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Colors.white,
        ),
        body: Center(
          child: Text(_errorMessage, style: const TextStyle(color: Colors.red)),
        ),
      );
    }
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Collectible'),
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
              // Title field
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a title';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 16),
              
              // Description field
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
                maxLines: 4,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a description';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 16),
              
              // Price field
              TextFormField(
                controller: _priceController,
                decoration: const InputDecoration(
                  labelText: 'Price (RM)',
                  border: OutlineInputBorder(),
                  prefixText: 'RM ',
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a price';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  if (double.parse(value) <= 0) {
                    return 'Price must be greater than zero';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 16),
              
              // Category dropdown
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Category',
                  border: OutlineInputBorder(),
                ),
                value: _selectedCategory,
                items: _categories.map((category) {
                  return DropdownMenuItem<String>(
                    value: category,
                    child: Text(category),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedCategory = value;
                      // Reset subcategory to first item in the new category
                      _selectedSubcategory = _subcategories[value]![0];
                    });
                  }
                },
              ),
              
              const SizedBox(height: 16),
              
              // Subcategory dropdown
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Subcategory',
                  border: OutlineInputBorder(),
                ),
                value: _subcategories[_selectedCategory]!.contains(_selectedSubcategory)
                    ? _selectedSubcategory
                    : _subcategories[_selectedCategory]![0],
                items: _subcategories[_selectedCategory]!.map((subcategory) {
                  return DropdownMenuItem<String>(
                    value: subcategory,
                    child: Text(subcategory),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedSubcategory = value;
                    });
                  }
                },
              ),
              
              const SizedBox(height: 16),
              
              // Condition dropdown
              DropdownButtonFormField<CollectibleCondition>(
                decoration: const InputDecoration(
                  labelText: 'Condition',
                  border: OutlineInputBorder(),
                ),
                value: _selectedCondition,
                items: _conditions.map((condition) {
                  return DropdownMenuItem<CollectibleCondition>(
                    value: condition['condition'],
                    child: Text(condition['label']),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedCondition = value;
                    });
                  }
                },
              ),
              
              const SizedBox(height: 24),
              
              // Update button
              ElevatedButton(
                onPressed: _isLoading ? null : _updateListing,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text('Update Collectible'),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    super.dispose();
  }
} 