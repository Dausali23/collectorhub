import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'models/user_model.dart';
import 'services/auth_service.dart';
import 'services/auth_wrapper.dart';
import 'dart:developer' as developer;

void main() async {
  // Ensure Flutter is initialized before doing anything else
  WidgetsFlutterBinding.ensureInitialized();
  
  // Run the app with a FutureBuilder to handle Firebase initialization
  runApp(const AppInitializer());
}

class AppInitializer extends StatelessWidget {
  const AppInitializer({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      // Initialize Firebase asynchronously
      future: _initializeFirebase(),
      builder: (context, snapshot) {
        // Show loading screen while Firebase initializes
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const MaterialApp(
            home: Scaffold(
              body: Center(
                child: CircularProgressIndicator(),
              ),
            ),
          );
        }
        
        // Firebase initialized successfully or was already initialized, start the main app
        return const MyApp();
      },
    );
  }

  // Initialize Firebase safely
  Future<void> _initializeFirebase() async {
    try {
      // Check if Firebase is already initialized
      if (Firebase.apps.isNotEmpty) {
        developer.log('Firebase was already initialized');
        return;
      }
      
      // Initialize Firebase for the first time
      developer.log('Initializing Firebase');
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      developer.log('Firebase initialized successfully');
    } catch (e) {
      // Just log the error but don't fail - the app might still work
      developer.log('Error initializing Firebase: $e');
      // We don't rethrow here, as we want the app to continue even if Firebase fails
    }
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  
  @override
  Widget build(BuildContext context) {
    return StreamProvider<UserModel?>.value(
      initialData: null,
      value: AuthService().user,
      catchError: (_, error) {
        developer.log('Error in user stream: $error');
        return null;
      },
      child: MaterialApp(
        title: 'CollectorHub',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          useMaterial3: true,
        ),
        home: const AuthWrapper(),
      ),
    );
  }
}
