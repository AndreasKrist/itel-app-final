// lib/screens/signup_screen.dart
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;

enum AccountType { corporate, private }

class SignupScreen extends StatefulWidget {
  final Function(bool) onLoginStatusChanged;
  final AccountType? initialAccountType;

  const SignupScreen({
    super.key,
    required this.onLoginStatusChanged,
    this.initialAccountType,
  });

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final TextEditingController _companyController = TextEditingController();
  final TextEditingController _jobTitleController = TextEditingController();
  final TextEditingController _companyAddressController = TextEditingController();
  final AuthService _authService = AuthService();

  late AccountType _selectedAccountType;
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _selectedAccountType = widget.initialAccountType ?? AccountType.private;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _companyController.dispose();
    _jobTitleController.dispose();
    _companyAddressController.dispose();
    super.dispose();
  }

Future<void> _signup() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    // Validate fields
    if (_nameController.text.isEmpty ||
        _emailController.text.isEmpty ||
        _passwordController.text.isEmpty ||
        _confirmPasswordController.text.isEmpty ||
        (_selectedAccountType == AccountType.corporate && _companyController.text.isEmpty) ||
        (_selectedAccountType == AccountType.corporate && _jobTitleController.text.isEmpty) ||
        (_selectedAccountType == AccountType.corporate && _companyAddressController.text.isEmpty)) {
      setState(() {
        _errorMessage = "Please fill in all required fields";
        _isLoading = false;
      });
      return;
    }

    // Validate email format
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(_emailController.text)) {
      setState(() {
        _errorMessage = "Please enter a valid email address";
        _isLoading = false;
      });
      return;
    }

    // Validate password length
    if (_passwordController.text.length < 6) {
      setState(() {
        _errorMessage = "Password must be at least 6 characters";
        _isLoading = false;
      });
      return;
    }

    // Validate password match
    if (_passwordController.text != _confirmPasswordController.text) {
      setState(() {
        _errorMessage = "Passwords do not match";
        _isLoading = false;
      });
      return;
    }

    try {
      // Register with Firebase
      print("Attempting to register user with email: ${_emailController.text}");

      await _authService.registerWithEmailPassword(
        _emailController.text.trim(),
        _passwordController.text,
        _nameController.text.trim(),
        accountType: _selectedAccountType == AccountType.corporate ? 'corporate' : 'private',
        company: _selectedAccountType == AccountType.corporate ? _companyController.text.trim() : null,
        jobTitle: _selectedAccountType == AccountType.corporate ? _jobTitleController.text.trim() : null,
        companyAddress: _selectedAccountType == AccountType.corporate ? _companyAddressController.text.trim() : null,
      );

      if (!mounted) return;

      print("Registration successful, updating UI");

      // If we get here without an exception, registration was successful
      // Reset loading state and navigate the user to the main app
      setState(() {
        _isLoading = false;
      });

      // Pop the signup screen and notify parent that user is logged in
      Navigator.of(context).pop();
      widget.onLoginStatusChanged(true);
      
    } on firebase_auth.FirebaseAuthException catch (e) {
      print("Firebase Auth Error during signup: ${e.code} - ${e.message}");
      
      if (!mounted) return;
      
      setState(() {
        switch (e.code) {
          case 'email-already-in-use':
            _errorMessage = "Email is already in use";
            break;
          case 'invalid-email':
            _errorMessage = "Invalid email format";
            break;
          case 'weak-password':
            _errorMessage = "Password is too weak";
            break;
          case 'operation-not-allowed':
            _errorMessage = "Email/password accounts are not enabled";
            break;
          default:
            _errorMessage = "Registration failed: ${e.message}";
        }
        _isLoading = false;
      });
    } catch (e) {
      print("General error during signup: ${e.toString()}");
      
      if (!mounted) return;
      
      setState(() {
        _errorMessage = "An error occurred during registration: ${e.toString()}";
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue[50],
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Color(0xFF0056AC)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Create Account',
          style: TextStyle(
            color: Color(0xFF0056AC),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Account type selector
              const Text(
                'Account Type',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    _buildAccountTypeOption(
                      AccountType.private,
                      'Private',
                      'Individual access to courses',
                      Icons.person,
                    ),
                    Divider(height: 1, color: Colors.grey[200]),
                    _buildAccountTypeOption(
                      AccountType.corporate,
                      'Associate Corporate',
                      'Organizational business access to courses',
                      Icons.business,
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Error message
              if (_errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red[200]!),
                  ),
                  child: Text(
                    _errorMessage!,
                    style: TextStyle(color: Colors.red[700]),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              
              // Name field
              _buildTextField(
                controller: _nameController,
                hintText: 'Full Name',
                prefixIcon: Icons.person,
              ),
              const SizedBox(height: 16),

              // Email field
              _buildTextField(
                controller: _emailController,
                hintText: 'Email',
                prefixIcon: Icons.email,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),

              // Company field (only for corporate accounts)
              if (_selectedAccountType == AccountType.corporate) ...[
                _buildTextField(
                  controller: _companyController,
                  hintText: 'Company Name',
                  prefixIcon: Icons.business,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _jobTitleController,
                  hintText: 'Job Title',
                  prefixIcon: Icons.work,
                ),
                const SizedBox(height: 16),
                // Company Address textarea
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _companyAddressController,
                    maxLines: 3,
                    keyboardType: TextInputType.multiline,
                    decoration: InputDecoration(
                      hintText: 'Company Address',
                      prefixIcon: Padding(
                        padding: const EdgeInsets.only(bottom: 40),
                        child: Icon(Icons.location_on, color: Colors.blue[400]),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Password field
              _buildTextField(
                controller: _passwordController,
                hintText: 'Password',
                prefixIcon: Icons.lock,
                obscureText: _obscurePassword,
                toggleObscure: () {
                  setState(() {
                    _obscurePassword = !_obscurePassword;
                  });
                },
              ),
              const SizedBox(height: 16),

              // Confirm password field
              _buildTextField(
                controller: _confirmPasswordController,
                hintText: 'Confirm Password',
                prefixIcon: Icons.lock_outline,
                obscureText: _obscureConfirmPassword,
                toggleObscure: () {
                  setState(() {
                    _obscureConfirmPassword = !_obscureConfirmPassword;
                  });
                },
              ),
              const SizedBox(height: 16),
              
              // Signup button
              ElevatedButton(
                onPressed: _isLoading ? null : _signup,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF0056AC),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
                child: _isLoading
                  ? SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 3,
                      ),
                    )
                  : const Text(
                      'Create Account',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
              ),
              
              const SizedBox(height: 24),
              
              // Terms and conditions
              Text(
                'By creating an account, you agree to our Terms of Service and Privacy Policy.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAccountTypeOption(
    AccountType type,
    String title,
    String description,
    IconData icon,
  ) {
    final isSelected = _selectedAccountType == type;
    
    return InkWell(
      onTap: () {
        setState(() {
          _selectedAccountType = type;
        });
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isSelected ? Colors.blue[100] : Colors.grey[100],
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: isSelected ? Color(0xFF0056AC) : Colors.grey[600],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Color(0xFF0056AC) : Colors.black,
                    ),
                  ),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Radio<AccountType>(
              value: type,
              groupValue: _selectedAccountType,
              onChanged: (value) {
                setState(() {
                  _selectedAccountType = value!;
                });
              },
              activeColor: Color(0xFF0056AC),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData prefixIcon,
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
    VoidCallback? toggleObscure,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          hintText: hintText,
          prefixIcon: Icon(prefixIcon, color: Colors.blue[400]),
          suffixIcon: toggleObscure != null
              ? IconButton(
                  icon: Icon(
                    obscureText ? Icons.visibility : Icons.visibility_off,
                    color: Colors.grey[500],
                  ),
                  onPressed: toggleObscure,
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }
}