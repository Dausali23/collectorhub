import 'package:flutter/material.dart';
import '../../../services/auth_service.dart';
import '../../../models/user_model.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final AuthService _auth = AuthService();
  
  // Form state
  final _formKey = GlobalKey<FormState>();
  String _email = '';
  String _password = '';
  String _confirmPassword = '';
  String _name = '';
  String _phoneNumber = '';
  bool _isLogin = true;
  bool _isLoading = false;
  String _error = '';
  UserRole _selectedRole = UserRole.seller;
  
  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      // Additional validation for password confirmation during registration
      if (!_isLogin && _password != _confirmPassword) {
        setState(() {
          _error = 'Passwords do not match';
        });
        return;
      }
      
      if (mounted) {
        setState(() {
          _isLoading = true;
          _error = '';
        });
      }
      
      Map<String, dynamic> result;
      try {
        if (_isLogin) {
          // For login, simply authenticate with email and password
          // The role will be retrieved from Firestore in the auth service
          result = await _auth.signIn(_email, _password);
          
          // If login fails, show the error
          if (!result['success'] && mounted) {
            setState(() {
              _error = result['message'];
              _isLoading = false;
            });
          }
        } else {
          // For signup, we include the selected role from the UI
          result = await _auth.signUp(
            _email, 
            _password, 
            _selectedRole,
            displayName: _name,
            phoneNumber: _phoneNumber,
          );
          
          // If registration was successful, sign the user out and show login screen
          if (result['success']) {
            // Sign out the user since we want them to manually log in
            await _auth.signOut();
            
            // Show success message
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Account created successfully! Please log in.'),
                  backgroundColor: Colors.green,
                ),
              );
            
              // Switch to login mode
              setState(() {
                _isLogin = true;
                _isLoading = false;
              });
            }
            return;
          }
          
          // If registration fails, show the error
          if (!result['success'] && mounted) {
            setState(() {
              _error = result['message'];
              _isLoading = false;
            });
          }
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _error = e.toString();
            _isLoading = false;
          });
        }
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.deepPurple.shade50,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Logo
                Icon(
                  Icons.collections_bookmark,
                  size: 80,
                  color: Colors.deepPurple.shade400,
                ),
                const SizedBox(height: 16),
                Text(
                  'CollectorHub',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.deepPurple.shade800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _isLogin ? 'Welcome back!' : 'Create an account',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey.shade700,
                  ),
                ),
                const SizedBox(height: 32),
                
                // Name field - only show when registering
                if (!_isLogin) ...[
                  TextFormField(
                    decoration: InputDecoration(
                      labelText: 'Full Name',
                      prefixIcon: const Icon(Icons.person),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    validator: (val) => val!.isEmpty ? 'Enter your name' : null,
                    onChanged: (val) {
                      setState(() => _name = val);
                    },
                  ),
                  const SizedBox(height: 16),
                ],
                
                // Email field
                TextFormField(
                  decoration: InputDecoration(
                    labelText: 'Email',
                    prefixIcon: const Icon(Icons.email),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (val) => val!.isEmpty ? 'Enter an email' : null,
                  onChanged: (val) {
                    setState(() => _email = val);
                  },
                ),
                const SizedBox(height: 16),
                
                // Phone number field - only show when registering
                if (!_isLogin) ...[
                  TextFormField(
                    decoration: InputDecoration(
                      labelText: 'Phone Number',
                      prefixIcon: const Icon(Icons.phone),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    keyboardType: TextInputType.phone,
                    validator: (val) => val!.isEmpty ? 'Enter your phone number' : null,
                    onChanged: (val) {
                      setState(() => _phoneNumber = val);
                    },
                  ),
                  const SizedBox(height: 16),
                ],
                
                // Password field
                TextFormField(
                  decoration: InputDecoration(
                    labelText: 'Password',
                    prefixIcon: const Icon(Icons.lock),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  obscureText: true,
                  validator: (val) => val!.length < 6 ? 'Password must be at least 6 characters' : null,
                  onChanged: (val) {
                    setState(() => _password = val);
                  },
                ),
                const SizedBox(height: 16),
                
                // Confirm Password field - only show when registering
                if (!_isLogin) ...[
                  TextFormField(
                    decoration: InputDecoration(
                      labelText: 'Confirm Password',
                      prefixIcon: const Icon(Icons.lock_outline),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    obscureText: true,
                    validator: (val) {
                      if (val!.isEmpty) {
                        return 'Please confirm your password';
                      }
                      if (val != _password) {
                        return 'Passwords do not match';
                      }
                      return null;
                    },
                    onChanged: (val) {
                      setState(() => _confirmPassword = val);
                    },
                  ),
                  const SizedBox(height: 16),
                ],
                
                // Role selection - only show during registration
                if (!_isLogin) ...[
                  const Text(
                    'Choose your role:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _buildRoleSelectionCard(
                          title: 'Buyer',
                          icon: Icons.shopping_cart,
                          isSelected: _selectedRole == UserRole.buyer,
                          onTap: () {
                            setState(() {
                              _selectedRole = UserRole.buyer;
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildRoleSelectionCard(
                          title: 'Seller',
                          icon: Icons.store,
                          isSelected: _selectedRole == UserRole.seller,
                          onTap: () {
                            setState(() {
                              _selectedRole = UserRole.seller;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
                
                // Submit button
                ElevatedButton(
                  onPressed: _isLoading ? null : _submitForm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(_isLogin ? 'Log In' : 'Sign Up'),
                ),
                const SizedBox(height: 16),
                
                // Toggle login/register
                TextButton(
                  onPressed: () {
                    setState(() {
                      _isLogin = !_isLogin;
                      _error = '';
                      _confirmPassword = '';
                    });
                  },
                  child: Text(
                    _isLogin ? 'Need an account? Sign Up' : 'Have an account? Log In',
                    style: TextStyle(
                      color: Colors.deepPurple.shade700,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                
                // Error message
                if (_error.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _error,
                      style: TextStyle(
                        color: Colors.red.shade900,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildRoleSelectionCard({
    required String title,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? Colors.deepPurple.shade100 : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Colors.deepPurple : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 40,
              color: isSelected ? Colors.deepPurple : Colors.grey.shade600,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.deepPurple : Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }
} 
