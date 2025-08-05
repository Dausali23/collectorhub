import 'package:flutter/material.dart';
import '../models/user_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:developer' as developer;
import 'package:firebase_auth/firebase_auth.dart';

class EditProfileScreen extends StatefulWidget {
  final UserModel user;
  
  const EditProfileScreen({super.key, required this.user});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  late TextEditingController _displayNameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneNumberController;
  late TextEditingController _currentPasswordController;
  late TextEditingController _newPasswordController;
  late TextEditingController _confirmPasswordController;
  
  bool _isLoading = false;
  String _errorMessage = '';
  bool _showPasswordFields = false;
  
  @override
  void initState() {
    super.initState();
    _displayNameController = TextEditingController(text: widget.user.displayName ?? '');
    _emailController = TextEditingController(text: widget.user.email);
    _phoneNumberController = TextEditingController(text: widget.user.phoneNumber ?? '');
    _currentPasswordController = TextEditingController();
    _newPasswordController = TextEditingController();
    _confirmPasswordController = TextEditingController();
  }
  
  @override
  void dispose() {
    _displayNameController.dispose();
    _emailController.dispose();
    _phoneNumberController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // Update user name in all related collections
  Future<void> _updateUserNameEverywhere(String userId, String newDisplayName) async {
    try {
      developer.log('Updating user name everywhere for user: $userId');

      // Create a batch for atomic updates
      final batch = _firestore.batch();

      // 1. Update listings where user is the seller
      final listingsQuery = await _firestore
          .collection('listings')
          .where('sellerId', isEqualTo: userId)
          .get();

      for (var doc in listingsQuery.docs) {
        batch.update(doc.reference, {'sellerName': newDisplayName});
      }

      // 2. Update auctions where user is the seller
      final auctionsQuery = await _firestore
          .collection('auctions')
          .where('sellerId', isEqualTo: userId)
          .get();

      for (var doc in auctionsQuery.docs) {
        batch.update(doc.reference, {'sellerName': newDisplayName});
      }

      // 3. Update purchases where user is the buyer
      final buyerPurchasesQuery = await _firestore
          .collection('purchases')
          .where('buyerId', isEqualTo: userId)
          .get();

      for (var doc in buyerPurchasesQuery.docs) {
        batch.update(doc.reference, {'buyerName': newDisplayName});
      }

      // 4. Update purchases where user is the seller
      final sellerPurchasesQuery = await _firestore
          .collection('purchases')
          .where('sellerId', isEqualTo: userId)
          .get();

      for (var doc in sellerPurchasesQuery.docs) {
        batch.update(doc.reference, {'sellerName': newDisplayName});
      }

      // 5. Update bids where user is the top bidder
      final bidsQuery = await _firestore
          .collection('bids')
          .where('topBidderId', isEqualTo: userId)
          .get();

      for (var doc in bidsQuery.docs) {
        batch.update(doc.reference, {'topBidderName': newDisplayName});
      }

      // Commit all updates atomically
      await batch.commit();
      developer.log('Successfully updated user name in all collections');

    } catch (e) {
      developer.log('Error updating user name everywhere: $e');
      // Don't throw here - we don't want to fail the profile update if this fails
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    
    try {
      final newDisplayName = _displayNameController.text.trim();
      final newPhoneNumber = _phoneNumberController.text.trim();

      // Update Firestore user document
      await _firestore.collection('users').doc(widget.user.uid).update({
        'displayName': newDisplayName,
        'phoneNumber': newPhoneNumber,
      });

      // Update user name in all related collections if name changed
      if (newDisplayName != widget.user.displayName) {
        await _updateUserNameEverywhere(widget.user.uid, newDisplayName);
      }
      
      // Update Firebase Auth display name if needed
      final currentUser = _auth.currentUser;
      if (currentUser != null) {
        await currentUser.updateDisplayName(newDisplayName);
        
        // Change password if requested
        if (_showPasswordFields && 
            _currentPasswordController.text.isNotEmpty &&
            _newPasswordController.text.isNotEmpty) {
          
          // Re-authenticate user before changing password
          AuthCredential credential = EmailAuthProvider.credential(
            email: currentUser.email!,
            password: _currentPasswordController.text,
          );
          
          try {
            await currentUser.reauthenticateWithCredential(credential);
            await currentUser.updatePassword(_newPasswordController.text);
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Password updated successfully!'))
              );
            }
          } catch (e) {
            setState(() {
              _errorMessage = 'Failed to update password: $e';
              _isLoading = false;
            });
            return;
          }
        }
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully!'))
        );
        Navigator.pop(context, true); // Return true to indicate success
      }
    } catch (e, stackTrace) {
      developer.log('Error updating profile: $e');
      developer.log('Stack trace: $stackTrace');

      String errorMessage;
      if (e.toString().contains('permission-denied')) {
        errorMessage = 'Permission denied. Please check your account permissions.';
      } else if (e.toString().contains('network')) {
        errorMessage = 'Network error. Please check your internet connection.';
      } else {
        errorMessage = 'Failed to update profile. Please try again.';
      }

      setState(() {
        _errorMessage = errorMessage;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // Profile picture (placeholder)
              Center(
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 60,
                      backgroundColor: Colors.grey.shade200,
                      backgroundImage: widget.user.photoUrl != null
                          ? NetworkImage(widget.user.photoUrl!)
                          : null,
                      child: widget.user.photoUrl == null
                          ? const Icon(Icons.person, size: 60, color: Colors.grey)
                          : null,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.deepPurple,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Icon(
                          Icons.camera_alt,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 30),
              
              // Display name field
              TextFormField(
                controller: _displayNameController,
                decoration: InputDecoration(
                  labelText: 'Display Name',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  prefixIcon: const Icon(Icons.person),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter your name';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 16),
              
              // Email field (disabled)
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  prefixIcon: const Icon(Icons.email),
                  filled: true,
                  fillColor: Colors.grey.shade200,
                ),
                readOnly: true, // Email can't be changed directly
              ),
              
              const SizedBox(height: 16),
              
              // Phone number field
              TextFormField(
                controller: _phoneNumberController,
                decoration: InputDecoration(
                  labelText: 'Phone Number',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  prefixIcon: const Icon(Icons.phone),
                ),
                keyboardType: TextInputType.phone,
              ),
              
              const SizedBox(height: 24),
              
              // Change password section toggle
              InkWell(
                onTap: () {
                  setState(() {
                    _showPasswordFields = !_showPasswordFields;
                  });
                },
                child: Row(
                  children: [
                    Icon(
                      _showPasswordFields ? Icons.arrow_drop_down : Icons.arrow_right,
                      color: Colors.deepPurple,
                    ),
                    const Text(
                      'Change Password',
                      style: TextStyle(
                        fontSize: 16, 
                        fontWeight: FontWeight.bold,
                        color: Colors.deepPurple,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Password change fields
              if (_showPasswordFields) ...[
                const SizedBox(height: 16),
                TextFormField(
                  controller: _currentPasswordController,
                  decoration: InputDecoration(
                    labelText: 'Current Password',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    prefixIcon: const Icon(Icons.lock),
                  ),
                  obscureText: true,
                  validator: _showPasswordFields ? (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your current password';
                    }
                    return null;
                  } : null,
                ),
                
                const SizedBox(height: 16),
                
                TextFormField(
                  controller: _newPasswordController,
                  decoration: InputDecoration(
                    labelText: 'New Password',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    prefixIcon: const Icon(Icons.lock_outline),
                  ),
                  obscureText: true,
                  validator: _showPasswordFields ? (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a new password';
                    }
                    if (value.length < 6) {
                      return 'Password must be at least 6 characters long';
                    }
                    return null;
                  } : null,
                ),
                
                const SizedBox(height: 16),
                
                TextFormField(
                  controller: _confirmPasswordController,
                  decoration: InputDecoration(
                    labelText: 'Confirm New Password',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    prefixIcon: const Icon(Icons.lock_outline),
                  ),
                  obscureText: true,
                  validator: _showPasswordFields ? (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please confirm your new password';
                    }
                    if (value != _newPasswordController.text) {
                      return 'Passwords do not match';
                    }
                    return null;
                  } : null,
                ),
              ],
              
              if (_errorMessage.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  _errorMessage,
                  style: const TextStyle(color: Colors.red),
                ),
              ],
              
              const SizedBox(height: 32),
              
              // Save button
              ElevatedButton(
                onPressed: _isLoading ? null : _saveProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Save Changes'),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 