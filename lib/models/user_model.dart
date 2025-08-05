import 'package:firebase_auth/firebase_auth.dart';

enum UserRole {
  buyer,
  seller,
  admin
}

class UserModel {
  final String uid;
  final String email;
  final UserRole role;
  final String? displayName;
  final String? phoneNumber;
  final String? photoUrl;
  final DateTime? createdAt;

  UserModel({
    required this.uid, 
    required this.email, 
    required this.role,
    this.displayName,
    this.phoneNumber,
    this.photoUrl,
    this.createdAt,
  });

  factory UserModel.fromFirebase(User user, {UserRole role = UserRole.buyer, String? name, String? phone}) {
    // In a real app, you'd check a database to determine role
    // For demo purposes, we'll make a specific email an admin
    final isAdmin = user.email?.toLowerCase() == 'admin123@gmail.com';

    return UserModel(
      uid: user.uid,
      email: user.email ?? 'no-email',
      role: isAdmin ? UserRole.admin : role,
      displayName: name ?? user.displayName,
      phoneNumber: phone,
      photoUrl: user.photoURL,
      createdAt: user.metadata.creationTime,
    );
  }
} 