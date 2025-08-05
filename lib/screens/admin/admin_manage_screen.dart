import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/user_model.dart';
import '../../services/admin_service.dart';
import 'package:intl/intl.dart';

class AdminManageScreen extends StatefulWidget {
  final UserModel user;
  
  const AdminManageScreen({super.key, required this.user});

  @override
  State<AdminManageScreen> createState() => _AdminManageScreenState();
}

class _AdminManageScreenState extends State<AdminManageScreen> with SingleTickerProviderStateMixin {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late TabController _tabController;
  bool _isLoading = true;
  
  // User data
  List<Map<String, dynamic>> _users = [];
  String _userSearchQuery = '';
  
  // Items data
  List<Map<String, dynamic>> _items = [];
  String _itemSearchQuery = '';
  
  // Auctions data
  List<Map<String, dynamic>> _auctions = [];
  String _auctionSearchQuery = '';
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        setState(() {
          _loadContentForTab(_tabController.index);
        });
      }
    });
    _loadContentForTab(0); // Load users by default
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
  
  void _loadContentForTab(int tabIndex) {
    switch (tabIndex) {
      case 0:
        _loadUsers();
        break;
      case 1:
        _loadItems();
        break;
      case 2:
        _loadAuctions();
        break;
    }
  }

  DateTime _parseDate(dynamic dateStr) {
    try {
      if (dateStr is String) {
        // Handle Firebase Auth metadata date format: "Sat, 21 Jun 2025 03:18:51 GMT"
        if (dateStr.contains('GMT')) {
          // Use DateFormat to parse RFC 1123 format
          final formatter = DateFormat('EEE, dd MMM yyyy HH:mm:ss');
          final dateWithoutGMT = dateStr.replaceAll(' GMT', '');
          return formatter.parse(dateWithoutGMT, true); // true for UTC
        }
        // Handle ISO format: "2025-06-21T03:18:51.000Z"
        else if (dateStr.contains('T') && dateStr.contains('Z')) {
          return DateTime.parse(dateStr);
        } 
        // Try general parse
        else {
          return DateTime.parse(dateStr);
        }
      }
      return DateTime.now();
    } catch (e) {
      print('Error parsing date: $dateStr, error: $e');
      return DateTime.now();
    }
  }
  
  Future<void> _loadUsers() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Get users from admin backend
      final response = await AdminService.getAllUsers();
      
      if (response['success'] == true && response['users'] != null) {
        final List<Map<String, dynamic>> loadedUsers = [];
        
        for (var userData in response['users']) {
          // Skip the current admin user
          if (userData['uid'] == widget.user.uid) continue;
          
          // Attempt to get Firestore data if needed
          Map<String, dynamic> firestoreData = {};
          try {
            final doc = await _firestore.collection('users').doc(userData['uid']).get();
            if (doc.exists) {
              firestoreData = doc.data() as Map<String, dynamic>;
            }
          } catch (e) {
            // Silently continue if Firestore fetch fails
          }
          
          loadedUsers.add({
            'id': userData['uid'],
            'email': userData['email'] ?? 'No email',
            'name': userData['displayName'] ?? firestoreData['displayName'] ?? 'Unknown',
            'role': firestoreData['role'] ?? 'buyer',
            'joinDate': firestoreData['createdAt'] != null 
                ? (firestoreData['createdAt'] as Timestamp).toDate() 
                : userData['metadata']?['creationTime'] != null 
                    ? _parseDate(userData['metadata']['creationTime']) 
                    : DateTime.now(),
          });
        }
        
        // Sort by join date (newest first)
        loadedUsers.sort((a, b) => (b['joinDate'] as DateTime).compareTo(a['joinDate'] as DateTime));
        
        setState(() {
          _users = loadedUsers;
          _isLoading = false;
        });
      } else {
        // Fallback to Firestore if Admin API fails
        final QuerySnapshot querySnapshot = await _firestore.collection('users').get();
        
        final List<Map<String, dynamic>> loadedUsers = [];
        
        for (var doc in querySnapshot.docs) {
          final data = doc.data() as Map<String, dynamic>;
          
          // Skip the current admin user
          if (doc.id == widget.user.uid) continue;
          
          loadedUsers.add({
            'id': doc.id,
            'email': data['email'] ?? 'No email',
            'name': data['displayName'] ?? 'Unknown',
            'role': data['role'] ?? 'buyer',
            'joinDate': data['createdAt'] != null 
                ? (data['createdAt'] as Timestamp).toDate() 
                : DateTime.now(),
          });
        }
        
        // Sort by join date (newest first)
        loadedUsers.sort((a, b) => (b['joinDate'] as DateTime).compareTo(a['joinDate'] as DateTime));
        
        setState(() {
          _users = loadedUsers;
          _isLoading = false;
        });
        
        // Show warning about Admin API
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Warning: Using Firestore data instead of Admin API. ' +
                (response['error'] != null ? 'Error: ${response['error']}' : '')),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading users: $e')),
      );
    }
  }
  
  Future<void> _loadItems() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Query listings where isFixedPrice is true (fixed price items)
      final QuerySnapshot querySnapshot = await _firestore.collection('listings')
          .where('isFixedPrice', isEqualTo: true)
          .get();
      
      final List<Map<String, dynamic>> loadedItems = [];
      
      for (var doc in querySnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        
        loadedItems.add({
          'id': doc.id,
          'title': data['title'] ?? 'No title',
          'price': data['price'] ?? 0.0,
          'seller': data['sellerName'] ?? 'Unknown seller',
          'sellerId': data['sellerId'] ?? '',
          'category': data['category'] ?? 'Uncategorized',
          'createdAt': data['createdAt'] != null 
              ? (data['createdAt'] as Timestamp).toDate() 
              : DateTime.now(),
          'imageUrl': data['images'] != null && (data['images'] as List).isNotEmpty 
              ? (data['images'] as List).first 
              : null,
        });
      }
      
      // Sort by creation date (newest first)
      loadedItems.sort((a, b) => (b['createdAt'] as DateTime).compareTo(a['createdAt'] as DateTime));
      
      setState(() {
        _items = loadedItems;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading items: $e')),
      );
    }
  }
  
  Future<void> _loadAuctions() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Query listings where isFixedPrice is false (auctions)
      final QuerySnapshot querySnapshot = await _firestore.collection('listings')
          .where('isFixedPrice', isEqualTo: false)
          .get();
      
      final List<Map<String, dynamic>> loadedAuctions = [];
      
      for (var doc in querySnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        
        final endTime = data['endTime'] != null 
            ? (data['endTime'] as Timestamp).toDate() 
            : DateTime.now();
        final isActive = endTime.isAfter(DateTime.now());
        
        loadedAuctions.add({
          'id': doc.id,
          'title': data['title'] ?? 'No title',
          'currentBid': data['currentBid'] ?? data['startingBid'] ?? 0.0,
          'seller': data['sellerName'] ?? 'Unknown seller',
          'sellerId': data['sellerId'] ?? '',
          'isActive': isActive,
          'endTime': endTime,
          'createdAt': data['createdAt'] != null 
              ? (data['createdAt'] as Timestamp).toDate() 
              : DateTime.now(),
          'imageUrl': data['images'] != null && (data['images'] as List).isNotEmpty 
              ? (data['images'] as List).first 
              : null,
        });
      }
      
      // Sort by creation date (newest first)
      loadedAuctions.sort((a, b) => (b['createdAt'] as DateTime).compareTo(a['createdAt'] as DateTime));
      
      setState(() {
        _auctions = loadedAuctions;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading auctions: $e')),
      );
    }
  }
  
  Future<void> _deleteUser(String userId, String userEmail) async {
    // Show confirmation dialog
    final bool confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete User'),
        content: Text('Are you sure you want to delete $userEmail?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    ) ?? false;
    
    if (!confirm) return;
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Delete user using Admin API
      final response = await AdminService.deleteUser(userId);
      
      if (response['success'] == true) {
        setState(() {
          _users.removeWhere((user) => user['id'] == userId);
          _isLoading = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User deleted successfully')),
        );
      } else {
        setState(() {
          _isLoading = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting user: ${response['error'] ?? 'Unknown error'}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting user: $e')),
      );
    }
  }
  
  Future<void> _deleteItem(String itemId, String itemTitle) async {
    // Show confirmation dialog
    final bool confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Item'),
        content: Text('Are you sure you want to delete "$itemTitle"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    ) ?? false;
    
    if (!confirm) return;
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Delete item document from Firestore
      await _firestore.collection('listings').doc(itemId).delete();
      
      setState(() {
        _items.removeWhere((item) => item['id'] == itemId);
        _isLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Item deleted successfully')),
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting item: $e')),
      );
    }
  }
  
  Future<void> _deleteAuction(String auctionId, String auctionTitle) async {
    // Show confirmation dialog
    final bool confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Auction'),
        content: Text('Are you sure you want to delete "$auctionTitle"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    ) ?? false;
    
    if (!confirm) return;
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Delete auction document from Firestore
      await _firestore.collection('auctions').doc(auctionId).delete();
      
      setState(() {
        _auctions.removeWhere((auction) => auction['id'] == auctionId);
        _isLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Auction deleted successfully')),
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting auction: $e')),
      );
    }
  }
  
  Future<void> _editUser(Map<String, dynamic> user) async {
    final TextEditingController nameController = TextEditingController(text: user['name']);
    final TextEditingController emailController = TextEditingController(text: user['email']);
    final TextEditingController passwordController = TextEditingController();
    String selectedRole = user['role'];
    
    final bool? result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit User'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: emailController,
              decoration: const InputDecoration(labelText: 'Email'),
              enabled: false, // Email should not be editable
            ),
            const SizedBox(height: 10),
            TextField(
              controller: passwordController,
              decoration: const InputDecoration(
                labelText: 'Password',
                hintText: 'Leave blank to keep current password',
              ),
              obscureText: true,
            ),
            const SizedBox(height: 15),
            DropdownButtonFormField<String>(
              value: selectedRole,
              decoration: const InputDecoration(labelText: 'Role'),
              items: const [
                DropdownMenuItem(value: 'buyer', child: Text('Buyer')),
                DropdownMenuItem(value: 'seller', child: Text('Seller')),
                DropdownMenuItem(value: 'admin', child: Text('Admin')),
              ],
              onChanged: (value) {
                selectedRole = value!;
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    
    if (result != true) return;
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Update user using Admin API
      final Map<String, dynamic> updateData = {
        'displayName': nameController.text.trim(),
        'role': selectedRole,
      };
      
      // Only include password if it was entered
      if (passwordController.text.isNotEmpty) {
        updateData['password'] = passwordController.text;
      }
      
      final response = await AdminService.updateUser(
        uid: user['id'],
        displayName: nameController.text.trim(),
        role: selectedRole,
        password: passwordController.text.isEmpty ? null : passwordController.text,
      );
      
      if (response['success'] == true) {
        // Also update in Firestore for consistency
        await _firestore.collection('users').doc(user['id']).update({
          'displayName': nameController.text.trim(),
          'role': selectedRole,
        });
        
        setState(() {
          // Update local list
          final index = _users.indexWhere((u) => u['id'] == user['id']);
          if (index != -1) {
            _users[index]['name'] = nameController.text.trim();
            _users[index]['role'] = selectedRole;
          }
          _isLoading = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User updated successfully')),
        );
      } else {
        setState(() {
          _isLoading = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating user: ${response['error'] ?? 'Unknown error'}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating user: $e')),
      );
    }
  }
  
  // Filtered lists
  List<Map<String, dynamic>> get _filteredUsers {
    if (_userSearchQuery.isEmpty) return _users;
    
    return _users.where((user) {
      final email = user['email'].toString().toLowerCase();
      final name = user['name'].toString().toLowerCase();
      final role = user['role'].toString().toLowerCase();
      final query = _userSearchQuery.toLowerCase();
      
      return email.contains(query) || name.contains(query) || role.contains(query);
    }).toList();
  }
  
  List<Map<String, dynamic>> get _filteredItems {
    if (_itemSearchQuery.isEmpty) return _items;
    
    return _items.where((item) {
      final title = item['title'].toString().toLowerCase();
      final category = item['category'].toString().toLowerCase();
      final seller = item['seller'].toString().toLowerCase();
      final query = _itemSearchQuery.toLowerCase();
      
      return title.contains(query) || category.contains(query) || seller.contains(query);
    }).toList();
  }
  
  List<Map<String, dynamic>> get _filteredAuctions {
    if (_auctionSearchQuery.isEmpty) return _auctions;
    
    return _auctions.where((auction) {
      final title = auction['title'].toString().toLowerCase();
      final seller = auction['seller'].toString().toLowerCase();
      final query = _auctionSearchQuery.toLowerCase();
      
      return title.contains(query) || seller.contains(query);
    }).toList();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Content'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Users'),
            Tab(text: 'Items'),
            Tab(text: 'Auctions'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Users Tab
          _buildUsersTab(),
          
          // Items Tab
          _buildItemsTab(),
          
          // Auctions Tab
          _buildAuctionsTab(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Reload current tab content
          _loadContentForTab(_tabController.index);
        },
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        child: const Icon(Icons.refresh),
      ),
    );
  }
  
  // Add a new user
  Future<void> _createUser() async {
    final TextEditingController emailController = TextEditingController();
    final TextEditingController passwordController = TextEditingController();
    final TextEditingController confirmPasswordController = TextEditingController();
    final TextEditingController nameController = TextEditingController();
    final TextEditingController phoneController = TextEditingController();
    String selectedRole = 'buyer';
    final _formKey = GlobalKey<FormState>();
    
    final bool? result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create New User'),
        content: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: 'Full Name',
                    prefixIcon: const Icon(Icons.person),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.grey[50],
                  ),
                  validator: (val) => val!.isEmpty ? 'Enter full name' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: emailController,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    prefixIcon: const Icon(Icons.email),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.grey[50],
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (val) => val!.isEmpty ? 'Enter an email' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: phoneController,
                  decoration: InputDecoration(
                    labelText: 'Phone Number',
                    prefixIcon: const Icon(Icons.phone),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.grey[50],
                  ),
                  keyboardType: TextInputType.phone,
                  validator: (val) => val!.isEmpty ? 'Enter phone number' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: passwordController,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    prefixIcon: const Icon(Icons.lock),
                    hintText: 'Minimum 6 characters',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.grey[50],
                  ),
                  obscureText: true,
                  validator: (val) => val!.length < 6 ? 'Password must be at least 6 characters' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: confirmPasswordController,
                  decoration: InputDecoration(
                    labelText: 'Confirm Password',
                    prefixIcon: const Icon(Icons.lock_outline),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.grey[50],
                  ),
                  obscureText: true,
                  validator: (val) {
                    if (val!.isEmpty) {
                      return 'Please confirm password';
                    }
                    if (val != passwordController.text) {
                      return 'Passwords do not match';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedRole,
                  decoration: InputDecoration(
                    labelText: 'Role',
                    prefixIcon: const Icon(Icons.admin_panel_settings),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.grey[50],
                  ),
                  items: const [
                    DropdownMenuItem(value: 'buyer', child: Text('Buyer')),
                    DropdownMenuItem(value: 'seller', child: Text('Seller')),
                  ],
                  onChanged: (value) {
                    selectedRole = value!;
                  },
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (_formKey.currentState!.validate()) {
                Navigator.pop(context, true);
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
    
    if (result != true) return;
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Create user with Admin API
      final response = await AdminService.createUser(
        email: emailController.text.trim(),
        password: passwordController.text,
        displayName: nameController.text.trim(),
        role: selectedRole,
        phoneNumber: phoneController.text.trim(),
      );
      
      if (response['success'] == true) {
        // Reload users list
        await _loadUsers();
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('User created successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        setState(() {
          _isLoading = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating user: ${response['error'] ?? 'Unknown error'}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error creating user: $e')),
      );
    }
  }

  Widget _buildUsersTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search users...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    filled: true,
                    fillColor: Colors.grey[100],
                  ),
                  onChanged: (value) {
                    setState(() {
                      _userSearchQuery = value;
                    });
                  },
                ),
              ),
              const SizedBox(width: 10),
              ElevatedButton.icon(
                onPressed: _createUser,
                icon: const Icon(Icons.person_add),
                label: const Text('Add User'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                ),
              ),
            ],
          ),
        ),
        
        Expanded(
          child: _isLoading && _tabController.index == 0
              ? const Center(child: CircularProgressIndicator())
              : _filteredUsers.isEmpty
                  ? const Center(child: Text('No users found'))
                  : ListView.builder(
                      itemCount: _filteredUsers.length,
                      itemBuilder: (context, index) {
                        final user = _filteredUsers[index];
                        final Color roleColor = _getRoleColor(user['role']);
                        
                        return Card(
                          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: roleColor.withOpacity(0.2),
                              child: Icon(Icons.person, color: roleColor),
                            ),
                            title: Text(user['name']),
                            subtitle: Text(user['email']),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: roleColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    user['role'].toString().toUpperCase(),
                                    style: TextStyle(
                                      color: roleColor,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.edit, color: Colors.blue),
                                  onPressed: () => _editUser(user),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  onPressed: () => _deleteUser(user['id'], user['email']),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
        ),
      ],
    );
  }
  
  Widget _buildItemsTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Search items...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              filled: true,
              fillColor: Colors.grey[100],
            ),
            onChanged: (value) {
              setState(() {
                _itemSearchQuery = value;
              });
            },
          ),
        ),
        
        Expanded(
          child: _isLoading && _tabController.index == 1
              ? const Center(child: CircularProgressIndicator())
              : _filteredItems.isEmpty
                  ? const Center(child: Text('No items found'))
                  : ListView.builder(
                      itemCount: _filteredItems.length,
                      itemBuilder: (context, index) {
                        final item = _filteredItems[index];
                        
                        return Card(
                          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          child: ListTile(
                            leading: item['imageUrl'] != null
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(4),
                                    child: Image.network(
                                      item['imageUrl'],
                                      width: 50,
                                      height: 50,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) => 
                                          Container(
                                            width: 50,
                                            height: 50,
                                            color: Colors.grey[300],
                                            child: const Icon(Icons.image_not_supported),
                                          ),
                                    ),
                                  )
                                : Container(
                                    width: 50,
                                    height: 50,
                                    color: Colors.grey[300],
                                    child: const Icon(Icons.image),
                                  ),
                            title: Text(item['title']),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Seller: ${item['seller']}'),
                                Text(
                                  'Price: \$${item['price'].toStringAsFixed(2)} • ${item['category']}',
                                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                                ),
                              ],
                            ),
                            isThreeLine: true,
                            trailing: IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _deleteItem(item['id'], item['title']),
                            ),
                          ),
                        );
                      },
                    ),
        ),
      ],
    );
  }
  
  Widget _buildAuctionsTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Search auctions...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              filled: true,
              fillColor: Colors.grey[100],
            ),
            onChanged: (value) {
              setState(() {
                _auctionSearchQuery = value;
              });
            },
          ),
        ),
        
        Expanded(
          child: _isLoading && _tabController.index == 2
              ? const Center(child: CircularProgressIndicator())
              : _filteredAuctions.isEmpty
                  ? const Center(child: Text('No auctions found'))
                  : ListView.builder(
                      itemCount: _filteredAuctions.length,
                      itemBuilder: (context, index) {
                        final auction = _filteredAuctions[index];
                        final bool isActive = auction['isActive'];
                        
                        return Card(
                          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          child: ListTile(
                            leading: auction['imageUrl'] != null
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(4),
                                    child: Image.network(
                                      auction['imageUrl'],
                                      width: 50,
                                      height: 50,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) => 
                                          Container(
                                            width: 50,
                                            height: 50,
                                            color: Colors.grey[300],
                                            child: const Icon(Icons.image_not_supported),
                                          ),
                                    ),
                                  )
                                : Container(
                                    width: 50,
                                    height: 50,
                                    color: Colors.grey[300],
                                    child: const Icon(Icons.gavel),
                                  ),
                            title: Text(auction['title']),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Seller: ${auction['seller']}'),
                                Text(
                                  'Current Bid: \$${auction['currentBid'].toStringAsFixed(2)}',
                                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                                ),
                              ],
                            ),
                            isThreeLine: true,
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: isActive ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    isActive ? 'ACTIVE' : 'ENDED',
                                    style: TextStyle(
                                      color: isActive ? Colors.green : Colors.red,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 10,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  onPressed: () => _deleteAuction(auction['id'], auction['title']),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
        ),
      ],
    );
  }
  
  Color _getRoleColor(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return Colors.red;
      case 'seller':
        return Colors.blue;
      case 'buyer':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
} 