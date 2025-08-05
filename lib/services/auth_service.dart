import 'package:firebase_auth/firebase_auth.dart';
import 'dart:developer' as developer;
import '../models/user_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Cache user models to avoid repeated Firestore queries
  final Map<String, UserModel> _userCache = {};

  // Get user model from Firebase user
  Future<UserModel?> _userFromFirebaseUser(User? user) async {
    if (user == null) return null;
    
    // Check cache first
    if (_userCache.containsKey(user.uid)) {
      developer.log('DEBUGGING: Returning cached user model for ${user.email}');
      return _userCache[user.uid];
    }
    
    // Hardcoded roles for specific emails to bypass Firestore permission issues
    final Map<String, UserRole> hardcodedRoles = {
      'admin123@gmail.com': UserRole.admin,
    };
    
    // Check if the user's email matches any hardcoded values
    if (user.email != null && hardcodedRoles.containsKey(user.email!.toLowerCase())) {
      developer.log('DEBUGGING: Using hardcoded role for ${user.email}');
      UserRole role = hardcodedRoles[user.email!.toLowerCase()]!;
      developer.log('DEBUGGING: Hardcoded role is ${role.toString()}');
      final userModel = UserModel.fromFirebase(user, role: role);
      
      // Cache the user model
      _userCache[user.uid] = userModel;
      
      return userModel;
    }
    
    try {
      developer.log('DEBUGGING: Fetching user role for ${user.email}');
      
      // Fetch directly from Firestore without using compute isolate
      // The compute isolate might be causing Firebase access issues
      final doc = await _firestore.collection('users').doc(user.uid).get();
      
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        developer.log('DEBUGGING: Found user document in Firestore for ${user.email}');
        developer.log('DEBUGGING: Role in document: ${data['role']}');
        
        final roleStr = data['role'] as String?;
        final name = data['displayName'] as String? ?? user.displayName;
        final phone = data['phoneNumber'] as String?;
        UserRole role = UserRole.buyer; // Default
        
        // More robust role checking (case insensitive, trim whitespace, etc.)
        if (roleStr != null) {
          final normalizedRole = roleStr.trim().toLowerCase();
          developer.log('DEBUGGING: Normalized role: $normalizedRole');
          
          if (normalizedRole == 'seller') {
            role = UserRole.seller;
            developer.log('DEBUGGING: Setting role to SELLER for ${user.email}');
          } else if (normalizedRole == 'admin') {
            role = UserRole.admin;
            developer.log('DEBUGGING: Setting role to ADMIN for ${user.email}');
          } else {
            developer.log('DEBUGGING: Role not recognized, defaulting to BUYER for ${user.email}');
          }
        } else {
          developer.log('DEBUGGING: Role field is null, defaulting to BUYER for ${user.email}');
        }
        
        final userModel = UserModel(
          uid: user.uid,
          email: user.email ?? 'no-email',
          displayName: name,
          phoneNumber: phone,
          role: role,
          photoUrl: user.photoURL,
        );
        
        // Cache the user model
        _userCache[user.uid] = userModel;
        
        developer.log('DEBUGGING: Final user model role: ${userModel.role}');
        return userModel;
      } else {
        developer.log('DEBUGGING: User document does NOT exist in Firestore for ${user.email}');
        
        // Default if no role found in Firestore
        developer.log('DEBUGGING: Returning default UserModel (buyer role)');
        return UserModel.fromFirebase(user);
      }
    } catch (e) {
      developer.log('DEBUGGING: Error fetching user role: $e');
      developer.log('DEBUGGING: Error stack trace: ${StackTrace.current}');
      
      // Default if no role found in Firestore
      developer.log('DEBUGGING: Returning default UserModel (buyer role)');
      return UserModel.fromFirebase(user);
    }
  }
  


  // Auth state changes stream
  Stream<UserModel?> get user {
    return _auth.authStateChanges().asyncMap((firebaseUser) async {
      developer.log('DEBUGGING: Auth state changed for user: ${firebaseUser?.email}');
      return await _userFromFirebaseUser(firebaseUser);
    });
  }

  // Special utility method to fix user role issues
  Future<bool> fixUserRole(String email, UserRole newRole) async {
    try {
      // First find the user by email
      final usersQuery = await _firestore.collection('users')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();
      
      if (usersQuery.docs.isEmpty) {
        developer.log('DEBUGGING: No user found with email $email');
        return false;
      }
      
      final userDoc = usersQuery.docs.first;
      developer.log('DEBUGGING: Found user document with ID: ${userDoc.id}');
      
      // Convert role to string
      String roleString;
      switch (newRole) {
        case UserRole.seller:
          roleString = 'seller';
          break;
        case UserRole.admin:
          roleString = 'admin';
          break;
        case UserRole.buyer:
          roleString = 'buyer';
          break;
      }
      
      // Update the role
      await _firestore.collection('users').doc(userDoc.id).update({
        'role': roleString,
      });
      
      developer.log('DEBUGGING: Updated role for $email to $roleString');
      return true;
    } catch (e) {
      developer.log('DEBUGGING: Error fixing user role: $e');
      return false;
    }
  }

  // Sign up with email and password
  Future<Map<String, dynamic>> signUp(String email, String password, UserRole role, {String? displayName, String? phoneNumber}) async {
    try {
      // Clean up and format the email
      email = email.trim(); // Remove any whitespace
      
      // Ensure it has @ and domain if missing
      if (!email.contains('@')) {
        email = '$email@example.com';
      }
      
      developer.log('Attempting to create user with email: $email');

      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      // Store user role in Firestore
      if (result.user != null) {
        // Convert enum to string more explicitly to ensure correct format
        String roleString;
        switch (role) {
          case UserRole.seller:
            roleString = 'seller';
            break;
          case UserRole.admin:
            roleString = 'admin';
            break;
          case UserRole.buyer:
            roleString = 'buyer';
            break;
        }
        
        // Log the role being stored
        developer.log('Storing user with role: $roleString');
        
        await _firestore.collection('users').doc(result.user!.uid).set({
          'email': email,
          'role': roleString, // Use the explicit string instead of enum conversion
          'displayName': displayName,
          'phoneNumber': phoneNumber,
          'createdAt': FieldValue.serverTimestamp(),
        });
        
        // Update displayName in Firebase Auth
        if (displayName != null) {
          await result.user!.updateDisplayName(displayName);
        }
      }
      
      return {
        'success': true,
        'user': result.user
      };
    } on FirebaseAuthException catch (e) {
      developer.log('Sign up error: ${e.code}: ${e.message}');
      
      String errorMessage = 'Registration failed. Please try again.';
      
      // More specific error messages
      if (e.code == 'weak-password') {
        errorMessage = 'The password is too weak.';
      } else if (e.code == 'email-already-in-use') {
        errorMessage = 'This email is already registered.';
      } else if (e.code == 'invalid-email') {
        // If email format is invalid, try to fix it
        try {
          String fixedEmail = email;
          if (!fixedEmail.contains('@')) {
            fixedEmail = '$fixedEmail@example.com';
          }
          if (!fixedEmail.contains('.')) {
            fixedEmail = fixedEmail.replaceAll('@', '@mail.');
          }
          
          developer.log('Retrying with fixed email: $fixedEmail');
          
          UserCredential result = await _auth.createUserWithEmailAndPassword(
            email: fixedEmail,
            password: password,
          );
          
          // Store user role in Firestore with the same explicit mapping
          if (result.user != null) {
            // Convert enum to string more explicitly
            String roleString;
            switch (role) {
              case UserRole.seller:
                roleString = 'seller';
                break;
              case UserRole.admin:
                roleString = 'admin';
                break;
              case UserRole.buyer:
                roleString = 'buyer';
                break;
            }
            
            // Log the role being stored
            developer.log('Storing user with role: $roleString (retry)');
            
            await _firestore.collection('users').doc(result.user!.uid).set({
              'email': fixedEmail,
              'role': roleString,
              'displayName': displayName,
              'phoneNumber': phoneNumber,
              'createdAt': FieldValue.serverTimestamp(),
            });
            
            // Update displayName in Firebase Auth
            if (displayName != null) {
              await result.user!.updateDisplayName(displayName);
            }
          }
          
          return {
            'success': true,
            'user': result.user
          };
        } catch (innerError) {
          developer.log('Error after fixing email: $innerError');
          errorMessage = 'The email format is invalid. Try something like "yourname@example.com"';
        }
      }
      
      return {
        'success': false,
        'message': errorMessage
      };
    } catch (e) {
      developer.log('Unknown error during sign up: $e');
      return {
        'success': false,
        'message': 'An unexpected error occurred.'
      };
    }
  }

  // Sign in with email and password
  Future<Map<String, dynamic>> signIn(String email, String password) async {
    try {
      // Clean up and format the email
      email = email.trim(); // Remove any whitespace
      
      // Ensure it has @ and domain if missing
      if (!email.contains('@')) {
        email = '$email@example.com';
      }
      
      developer.log('DEBUGGING: Attempting to sign in with email: $email');

      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      developer.log('DEBUGGING: Sign in successful for user: ${result.user?.email}');
      
      // Get user role with hardcoded values or from Firestore if available
      final userModel = await _userFromFirebaseUser(result.user);
      developer.log('DEBUGGING: User role after sign in: ${userModel?.role}');
      
      return {
        'success': true,
        'user': result.user,
        'role': userModel?.role
      };
    } on FirebaseAuthException catch (e) {
      developer.log('Sign in error: ${e.code}: ${e.message}');
      
      String errorMessage = 'Sign in failed. Please try again.';
      
      if (e.code == 'user-not-found') {
        errorMessage = 'No user found with this email.';
      } else if (e.code == 'wrong-password') {
        errorMessage = 'Incorrect password.';
      } else if (e.code == 'invalid-email') {
        errorMessage = 'The email format is invalid. Try something like "yourname@example.com"';
      } else if (e.code == 'user-disabled') {
        errorMessage = 'This user account has been disabled.';
      }
      
      return {
        'success': false,
        'message': errorMessage
      };
    } catch (e) {
      developer.log('Unknown error during sign in: $e');
      return {
        'success': false,
        'message': 'An unexpected error occurred.'
      };
    }
  }

  // Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }
  
  // Update phone number if not set
  Future<bool> updatePhoneNumberIfNeeded(String uid, String phoneNumber) async {
    try {
      final userDoc = await _firestore.collection('users').doc(uid).get();
      
      if (!userDoc.exists) {
        return false;
      }
      
      final userData = userDoc.data() as Map<String, dynamic>;
      
      // Only update if phone number is missing or empty
      if (!userData.containsKey('phoneNumber') || userData['phoneNumber'] == null || userData['phoneNumber'] == '') {
        await _firestore.collection('users').doc(uid).update({
          'phoneNumber': phoneNumber
        });
        
        // Clear the cache for this user to force a refresh
        if (_userCache.containsKey(uid)) {
          _userCache.remove(uid);
        }
        
        return true;
      }
      
      return false;
    } catch (e) {
      developer.log('Error updating phone number: $e');
      return false;
    }
  }
}