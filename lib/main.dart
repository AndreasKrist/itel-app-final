// lib/main.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'services/auth_service.dart';
import 'screens/home_screen.dart';
import 'screens/courses_screen.dart';
import 'screens/trending_screen.dart';
import 'screens/about_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/login_screen.dart';
import 'widgets/guest_banner.dart';
import 'services/user_preferences_service.dart';



void main() async {
  // Ensure Flutter bindings are initialized
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  await Firebase.initializeApp();
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ITEL App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Colors.grey[100],
        fontFamily: 'Poppins',
      ),
      home: const AuthWrapper(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  final AuthService _authService = AuthService();
  final UserPreferencesService _preferencesService = UserPreferencesService();

  late bool _isLoggedIn;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkAuthState();
  }
  
  Future<void> _checkAuthState() async {
    setState(() => _isLoading = true);
    
    // Check if user is already authenticated
    _isLoggedIn = _authService.isAuthenticated;
    
    // If logged in, load user data including favorites
    if (_isLoggedIn) {
      try {
        await _authService.loadUserData();
      } catch (e) {
        print('Error loading user data: $e');
      }
    }
    
    setState(() => _isLoading = false);
  }

void _handleLoginStatusChanged(bool isLoggedIn) async {
  // Set loading state
  setState(() {
    _isLoading = true;
  });
  
  // Update login status
  _isLoggedIn = isLoggedIn;
  
  // If logged in, load user data
  if (isLoggedIn) {
    try {
      await _authService.loadUserData();
    } catch (e) {
      print('Error loading user data: $e');
    }
  }
  
  setState(() {
    _isLoading = false;
  });
}

  // This method will be passed to the AppMockup to handle sign out
  Future<void> _handleSignOut() async {
    try {
      await _authService.signOut();
      
      // Update state to trigger re-render to login screen
      setState(() {
        _isLoggedIn = false;
      });
    } catch (e) {
      print('Sign out error: $e');
      // Show error message to user
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Sign out failed: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    
    // Force rebuild based on authentication state
    if (_isLoggedIn) {
      final isGuest = _authService.currentUser == null || 
                      _authService.currentUser!.id.isEmpty ||
                      _authService.currentUser!.email.isEmpty;
      return AppMockup(isGuest: isGuest, onSignOut: _handleSignOut);
    } else {
      // When not logged in, always return a fresh LoginScreen
      return LoginScreen(onLoginStatusChanged: _handleLoginStatusChanged);
    }
  }
}

class AppMockup extends StatefulWidget {
  final bool isGuest;
  final VoidCallback onSignOut;
  
  const AppMockup({
    super.key,
    this.isGuest = false,
    required this.onSignOut,
  });

  @override
  State<AppMockup> createState() => _AppMockupState();
}

class _AppMockupState extends State<AppMockup> {
  int _currentIndex = 0;
  String? _selectedCategory;

  void switchToCoursesWithCategory(String category) {
    setState(() {
      _currentIndex = 1; // Switch to courses tab (index 1)
      _selectedCategory = category;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Recreate screens list on each build to ensure fresh instances
    final List<Widget> screens = [
      HomeScreen(onCategorySelected: switchToCoursesWithCategory),
      CoursesScreen(initialCategory: _selectedCategory),
      const TrendingScreen(),
      const AboutScreen(),
      // Pass the sign out callback to the profile screen
      ProfileScreen(onSignOut: widget.onSignOut),
    ];

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Status Bar
            Container(
              height: 24,
              color: Colors.grey[900],
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '9:41',
                    style: TextStyle(color: Colors.white, fontSize: 12),
                  ),
                  Row(
                    children: [
                      Container(
                        width: 16,
                        height: 16,
                        margin: const EdgeInsets.only(right: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.75),
                          shape: BoxShape.circle,
                        ),
                      ),
                      Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.75),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // Guest banner (only visible for guest users)
            if (widget.isGuest)
              const GuestBanner(),
              
            // Main Content
            Expanded(
              child: _currentIndex == 4 && widget.isGuest
                  ? GuestProfileScreen(onSignOut: widget.onSignOut) // Pass sign out callback
                  : screens[_currentIndex],
            ),
            
            // Bottom Navigation
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(
                  top: BorderSide(color: Colors.grey[200]!),
                ),
              ),
              child: BottomNavigationBar(
                currentIndex: _currentIndex,
                onTap: (index) {
                  setState(() {
                    // If switching to profile tab, trigger reload of enrollments
                    if (index == 4 && _currentIndex != 4) {
                      // We need to trigger the ProfileScreen to reload data
                      print("Switching to profile tab - data will be refreshed");
                    }
                    
                    // Clear selected category if manually switching to courses tab
                    if (index == 1 && _currentIndex != 1) {
                      _selectedCategory = null;
                    }
                    
                    _currentIndex = index;
                  });
                },
                type: BottomNavigationBarType.fixed,
                selectedItemColor: Colors.blue[600],
                unselectedItemColor: Colors.grey[500],
                items: const [
                  BottomNavigationBarItem(
                    icon: Icon(Icons.home),
                    label: 'Home',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.book),
                    label: 'Courses',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.trending_up),
                    label: 'Trending',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.info),
                    label: 'About',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.person),
                    label: 'Profile',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class GuestProfileScreen extends StatelessWidget {
  final VoidCallback onSignOut;
  
  const GuestProfileScreen({
    super.key, 
    required this.onSignOut,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
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
                  // Changed from lock icon to a more friendly user icon
                  Icon(
                    Icons.person_outline,
                    size: 64,
                    color: Colors.blue[300],
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'You are currently a guest, to view more please sign in',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[800],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Sign in or be a member now to view profile, track your course progress, and experience more benefits here',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.grey[600],
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () {
                      // Use the passed onSignOut callback
                      onSignOut();
                    },
                    icon: const Icon(Icons.login),
                    label: const Text('Sign In as Member'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[600],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: () {
                      // Use the passed onSignOut callback with initialSignup flag
                      onSignOut();
                      // Use a post-frame callback to navigate to signup after the state is updated
                      SchedulerBinding.instance.addPostFrameCallback((_) {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => LoginScreen(
                              onLoginStatusChanged: (bool _) {},
                              initialSignup: true,
                            ),
                          ),
                        );
                      });
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Create Member Account'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}