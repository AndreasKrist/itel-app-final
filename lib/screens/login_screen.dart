// lib/screens/login_screen.dart
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'signup_screen.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;

class LoginScreen extends StatefulWidget {
  final Function(bool) onLoginStatusChanged;
  final bool initialSignup;
  
  const LoginScreen({
    super.key,
    required this.onLoginStatusChanged,
    this.initialSignup = false,
  });

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final AuthService _authService = AuthService();
  
  bool _isLoading = false;
  bool _isGoogleLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    // If initialSignup is true, navigate to signup screen after a short delay
    if (widget.initialSignup) {
      Future.delayed(Duration.zero, () {
        if (mounted) {
          Navigator.push(
            context, 
            MaterialPageRoute(
              builder: (context) => SignupScreen(
                onLoginStatusChanged: widget.onLoginStatusChanged,
              ),
            ),
          );
        }
      });
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    // Validate inputs
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      setState(() {
        _errorMessage = "Please enter both email and password";
        _isLoading = false;
      });
      return;
    }

    try {
      // Sign in with Firebase
      final user = await _authService.signInWithEmailPassword(
        _emailController.text.trim(),
        _passwordController.text,
      );
      
      if (!mounted) return;
      
      // If we get here without an exception, login was successful
      if (user != null) {
        print('Email login successful for user: ${user.email}');
        // Don't reset loading state here - let the parent handle navigation
        widget.onLoginStatusChanged(true);
      }
      
    } on firebase_auth.FirebaseAuthException catch (e) {
      setState(() {
        switch (e.code) {
          case 'user-not-found':
            _errorMessage = "No user found with this email";
            break;
          case 'wrong-password':
            _errorMessage = "Wrong password provided";
            break;
          case 'invalid-credential':
            _errorMessage = "Email or password is incorrect";
            break;
          case 'invalid-email':
            _errorMessage = "Invalid email format";
            break;
          case 'user-disabled':
            _errorMessage = "This account has been disabled";
            break;
          default:
            _errorMessage = "Login failed: ${e.message}";
        }
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = "An error occurred during login";
        _isLoading = false;
        print("Login error: ${e.toString()}");
      });
    }
  }

  Future<void> _loginWithGoogle() async {
    print('=== _loginWithGoogle started ===');
    setState(() {
      _isGoogleLoading = true;
      _errorMessage = null;
    });
    
    try {
      print('Calling _authService.signInWithGoogle()');
      // Sign in with Google
      final user = await _authService.signInWithGoogle();
      print('_authService.signInWithGoogle() completed. User: ${user?.email}');
      
      if (!mounted) {
        print('Widget not mounted, returning');
        return;
      }
      
      if (user != null) {
        // Sign-in was successful - call the callback to trigger navigation
        print('Google sign-in successful for user: ${user.email}');
        // Don't reset loading state here - let the parent handle navigation
        widget.onLoginStatusChanged(true);
      } else {
        // User cancelled Google sign-in
        print('User cancelled Google sign-in');
        if (mounted) {
          setState(() {
            _isGoogleLoading = false;
          });
        }
      }
    } catch (e) {
      print('Google sign-in error: ${e.toString()}');
      setState(() {
        _errorMessage = "Google sign-in failed. Please try again.";
        _isGoogleLoading = false;
      });
    }
    print('=== _loginWithGoogle completed ===');
  }

  Future<void> _loginAsGuest() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      // Sign in anonymously with Firebase
      final user = await _authService.signInAnonymously();
      
      if (!mounted) return;
      
      // Guest login successful
      if (user != null) {
        print('Guest login successful');
        // Don't reset loading state here - let the parent handle navigation
        widget.onLoginStatusChanged(true);
      }
      
    } catch (e) {
      setState(() {
        _errorMessage = "Guest login failed. Please try again later.";
        _isLoading = false;
        print("Anonymous login error: ${e.toString()}");
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue[50],
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Logo and title
                Center(
                  child: Column(
                    children: [
                      Container(
                        width: 120,
                        height: 120,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color.fromARGB(255, 255, 255, 255),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Image.asset(
                          'assets/images/itel-logo.png',
                          fit: BoxFit.contain,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'ITEL',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[800],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        " ''Training You Today for Tomorrow'' ",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontStyle: FontStyle.italic,
                          color: Colors.blue[700],
                          fontSize: 20,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Sign in now to start learning!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 22),
                
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
                
                // Email field
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
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      hintText: 'Email',
                      prefixIcon: Icon(Icons.email, color: Colors.blue[400]),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                
                // Password field
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
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      hintText: 'Password',
                      prefixIcon: Icon(Icons.lock, color: Colors.blue[400]),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword ? Icons.visibility : Icons.visibility_off,
                          color: Colors.grey[500],
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
                
                // Forgot password
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                      // Implement forgot password functionality
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Forgot password functionality coming soon!')),
                      );
                    },
                    child: Text(
                      'Forgot Password?',
                      style: TextStyle(
                        color: Colors.blue[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Login button
                ElevatedButton(
                  onPressed: _isLoading ? null : _login,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[700],
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
                        'Sign In',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                ),
                
                const SizedBox(height: 16),
                
                // Google Sign In Button
                ElevatedButton.icon(
                  onPressed: _isGoogleLoading ? null : _loginWithGoogle,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.grey[800],
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 1,
                  ),
                  icon: _isGoogleLoading
                    ? SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.red,
                          strokeWidth: 3,
                        ),
                      )
                    : Image.asset(
                        'assets/images/g.png', // You need to add this image
                        height: 24,
                        width: 24,
                      ),
                  label: Text(
                    'Continue with Google',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Login as guest
                OutlinedButton(
                  onPressed: _isLoading || _isGoogleLoading ? null : _loginAsGuest,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: BorderSide(color: Colors.blue[200]!),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Continue as Guest'),
                ),
                
                const SizedBox(height: 24),
                
                // Sign up section
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Not a member yet? ",
                      style: TextStyle(
                        color: Colors.grey[700],
                      ),
                    ),
                    TextButton(
                      onPressed: _isLoading || _isGoogleLoading ? null : () {
                        Navigator.push(
                          context, 
                          MaterialPageRoute(
                            builder: (context) => SignupScreen(
                              onLoginStatusChanged: widget.onLoginStatusChanged,
                            ),
                          ),
                        );
                      },
                      child: Text(
                        'Join Now',
                        style: TextStyle(
                          color: Colors.blue[700],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}