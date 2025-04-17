import 'package:flutter/material.dart';
import '../models/course.dart';
import '../models/user.dart';
import '../models/schedule.dart';
import 'package:table_calendar/table_calendar.dart';
import '../widgets/enrolled_course_card.dart';
import '../models/enrolled_course.dart';
import '../services/auth_service.dart';
import '../services/user_preferences_service.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/course_card.dart';//import 'course_outline_screen.dart';
import '../widgets/edit_profile_dialog.dart';

class ProfileScreen extends StatefulWidget {
  final VoidCallback onSignOut;

  const ProfileScreen({
    super.key,
    required this.onSignOut,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _showPersonalInfo = true;
  String activeTab = 'profile'; // Default tab is profile
  bool _showCalendar = false;
  bool _isProfileLoading = false;
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();
  CalendarFormat _calendarFormat = CalendarFormat.month;
  

void _showEditProfileDialog() {
  showDialog(
    context: context,
    builder: (context) => EditProfileDialog(
      currentUser: User.currentUser,
      onSave: _updateProfile,
    ),
  );
}

// Update user profile
  Future<void> _updateProfile(String name, String phone, String? company) async {
  try {
    // Get current user
    final currentUser = _authService.currentUser;
    
    if (currentUser == null || currentUser.id.isEmpty) {
      if (mounted) {
        Navigator.pop(context); // Close dialog
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('You need to be logged in to update your profile')),
        );
      }
      return;
    }

    // Get Firebase user ID
    final firebaseUser = firebase_auth.FirebaseAuth.instance.currentUser;
    if (firebaseUser == null) {
      if (mounted) {
        Navigator.pop(context); // Close dialog
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Authentication error')),
        );
      }
      return;
    }
    
    // First update in Firestore to ensure data is saved
    await _preferencesService.saveUserProfile(
      userId: firebaseUser.uid,
      name: name,
      email: User.currentUser.email,
      phone: phone,
      company: company,
      tier: User.currentUser.tier,
      membershipExpiryDate: User.currentUser.membershipExpiryDate,
      favoriteCoursesIds: User.currentUser.favoriteCoursesIds,
      enrolledCourses: User.currentUser.enrolledCourses,
    );
    
    // Update Firebase Auth display name
    await firebaseUser.updateDisplayName(name);
    
    // Update local user model AFTER saving to ensure consistency
    if (mounted) {
      setState(() {
        User.currentUser = User.currentUser.copyWith(
          name: name,
          phone: phone,
          company: company,
        );
      });
      
      Navigator.pop(context); // Close dialog
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile updated successfully'),
          backgroundColor: Colors.green,
        ),
      );
    }
  } catch (e) {
    print('Error updating profile: $e');
    if (mounted) {
      Navigator.pop(context); // Close dialog
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating profile: ${e.toString()}')),
      );
    }
  }
}

Future<void> _loadFavoritesFromFirebase() async {
  try {
    setState(() {
      _isProfileLoading = true;
    });
    
    // Get current user
    final currentUser = firebase_auth.FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      setState(() {
        _isProfileLoading = false;
      });
      return;
    }
    
    print('Loading favorites for user: ${currentUser.uid}');
    
    try {
      // Get user document
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .get();
          
      if (userDoc.exists && userDoc.data()!.containsKey('favoriteCoursesIds')) {
        // Extract favorites
        final favoriteIds = List<String>.from(userDoc.data()!['favoriteCoursesIds'] ?? []);
        
        print('Loaded ${favoriteIds.length} favorites from Firebase: $favoriteIds');
        
        // Update the current user
        setState(() {
          User.currentUser = User.currentUser.copyWith(
            favoriteCoursesIds: favoriteIds,
          );
        });
      } else {
        print('No favorites found in user document');
      }
    } catch (e) {
      print('Error loading favorites: $e');
    }
    
    setState(() {
      _isProfileLoading = false;
    });
  } catch (e) {
    print('Error in _loadFavoritesFromFirebase: $e');
    if (mounted) {
      setState(() {
        _isProfileLoading = false;
      });
    }
  }
}

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Reload enrollments whenever the screen comes into focus
    _loadEnrollmentsFromFirebase();
    _loadFavoritesFromFirebase();
  }
  // Add to the _ProfileScreenState class
  @override
  void initState() {
    super.initState();
    _loadEnrollmentsFromFirebase();
    _loadFavoritesFromFirebase();
  }

// Replace this method in the ProfileScreen class

Future<void> _loadEnrollmentsFromFirebase() async {
  try {
    setState(() {
      _isProfileLoading = true;
    });
    
    // Get current user
    final currentUser = firebase_auth.FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      setState(() {
        _isProfileLoading = false;
      });
      return;
    }
    
    print('Loading enrollments for user: ${currentUser.uid}');
    
    // Create a set to track unique course IDs
    Set<String> processedCourseIds = {};
    List<EnrolledCourse> enrollments = [];
    
    // First try to fetch from subcollection (more reliable)
    try {
      final snapshotSubcollection = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .collection('enrolledCourses')
          .get();
          
      print('Found ${snapshotSubcollection.docs.length} enrollments in subcollection');
      
      for (var doc in snapshotSubcollection.docs) {
        final data = doc.data();
        if (data['courseId'] != null) {
          print('Processing subcollection enrollment for course: ${data['courseId']}');
          
          // Parse dates properly with null safety
          DateTime? enrollmentDate;
          if (data['enrollmentDate'] != null) {
            try {
              enrollmentDate = DateTime.parse(data['enrollmentDate']);
            } catch (e) {
              print('Error parsing enrollment date: $e');
              enrollmentDate = DateTime.now();
            }
          }
          
          DateTime? nextSessionDate;
          if (data['nextSessionDate'] != null) {
            try {
              nextSessionDate = DateTime.parse(data['nextSessionDate']);
            } catch (e) {
              print('Error parsing next session date: $e');
              nextSessionDate = null;
            }
          }
          
          // Parse status with more robust handling
          EnrollmentStatus status = EnrollmentStatus.pending;
          if (data['status'] != null) {
            String statusStr = data['status'].toString().toLowerCase();
            if (statusStr.contains('confirm')) {
              status = EnrollmentStatus.confirmed;
            } else if (statusStr.contains('active')) {
              status = EnrollmentStatus.active;
            } else if (statusStr.contains('complet')) {
              status = EnrollmentStatus.completed;
            } else if (statusStr.contains('cancel')) {
              status = EnrollmentStatus.cancelled;
            }
            // Default is pending
          }
          
          final enrollment = EnrolledCourse(
            courseId: data['courseId'],
            enrollmentDate: enrollmentDate ?? DateTime.now(),
            status: status,
            isOnline: data['isOnline'] ?? false,
            nextSessionDate: nextSessionDate,
            nextSessionTime: data['nextSessionTime'],
            location: data['location'],
            instructorName: data['instructorName'],
            progress: data['progress'],
          );
          
          enrollments.add(enrollment);
          processedCourseIds.add(data['courseId']);
        }
      }
    } catch (e) {
      print('Error fetching subcollection enrollments: $e');
      // Continue to try the main document
    }
    
    // Then check the main user document
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .get();
          
      if (userDoc.exists) {
        final userData = userDoc.data();
        if (userData != null && userData.containsKey('enrolledCourses')) {
          final List<dynamic> embeddedEnrollments = userData['enrolledCourses'];
          print('Found ${embeddedEnrollments.length} enrollments in main user document');
          
          for (var data in embeddedEnrollments) {
            // Skip if we already processed this course ID from the subcollection
            if (data['courseId'] != null && !processedCourseIds.contains(data['courseId'])) {
              print('Processing main document enrollment for course: ${data['courseId']}');
              
              // Parse dates properly with null safety
              DateTime? enrollmentDate;
              if (data['enrollmentDate'] != null) {
                try {
                  enrollmentDate = DateTime.parse(data['enrollmentDate']);
                } catch (e) {
                  print('Error parsing enrollment date: $e');
                  enrollmentDate = DateTime.now();
                }
              }
              
              DateTime? nextSessionDate;
              if (data['nextSessionDate'] != null) {
                try {
                  nextSessionDate = DateTime.parse(data['nextSessionDate']);
                } catch (e) {
                  print('Error parsing next session date: $e');
                  nextSessionDate = null;
                }
              }
              
              // Parse status with more robust handling
              EnrollmentStatus status = EnrollmentStatus.pending;
              if (data['status'] != null) {
                String statusStr = data['status'].toString().toLowerCase();
                if (statusStr.contains('confirm')) {
                  status = EnrollmentStatus.confirmed;
                } else if (statusStr.contains('active')) {
                  status = EnrollmentStatus.active;
                } else if (statusStr.contains('complet')) {
                  status = EnrollmentStatus.completed;
                } else if (statusStr.contains('cancel')) {
                  status = EnrollmentStatus.cancelled;
                }
                // Default is pending
              }
              
              final enrollment = EnrolledCourse(
                courseId: data['courseId'],
                enrollmentDate: enrollmentDate ?? DateTime.now(),
                status: status,
                isOnline: data['isOnline'] ?? false,
                nextSessionDate: nextSessionDate,
                nextSessionTime: data['nextSessionTime'],
                location: data['location'],
                instructorName: data['instructorName'],
                progress: data['progress'],
              );
              
              enrollments.add(enrollment);
              processedCourseIds.add(data['courseId']);
            }
          }
        }
      }
    } catch (e) {
      print('Error fetching main document enrollments: $e');
    }
    
    // Make sure the component is still mounted before updating state
    if (mounted) {
      setState(() {
        print('Updating User.currentUser with ${enrollments.length} enrollments');
        User.currentUser = User.currentUser.copyWith(
          enrolledCourses: enrollments,
        );
        _isProfileLoading = false;
      });
      
      // Print enrollment status for debugging
      for (var enrollment in User.currentUser.enrolledCourses) {
        print('Loaded enrollment for course ${enrollment.courseId} with status: ${enrollment.status}');
      }
    }
  } catch (e) {
    print('Error in _loadEnrollmentsFromFirebase: $e');
    if (mounted) {
      setState(() {
        _isProfileLoading = false;
      });
    }
  }
}


  // Add Auth Service
  final AuthService _authService = AuthService();
  final UserPreferencesService _preferencesService = UserPreferencesService();
  // Show edit profile dialog

  
  String _maskEmail(String email) {
  if (email.isEmpty) return '********';
  
  final parts = email.split('@');
  if (parts.length != 2) return '********';
  
  // Show first character and last character of username part, mask the rest
  String username = parts[0];
  if (username.length <= 2) {
    return '**@${parts[1]}';
  }
  
  String maskedUsername = '${username[0]}****${username[username.length - 1]}';
  return '$maskedUsername@${parts[1]}';
}

// Helper method to mask phone number
String _maskPhone(String phone) {
  if (phone.isEmpty) return '********';
  
  // Keep the last 4 digits visible, mask the rest
  if (phone.length <= 4) {
    return '****$phone';
  }
  
  return '****${phone.substring(phone.length - 4)}';
}


// Replace the _toggleFavorite method in profile_screen.dart
void _toggleFavorite(Course course) async {
  try {
    // Get current user
    final currentUser = _authService.currentUser;
    
    if (currentUser == null || currentUser.id.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please log in to save favorites')),
        );
      }
      return;
    }

    // Create an updated favorites list
    List<String> updatedFavorites = List.from(User.currentUser.favoriteCoursesIds);
    bool shouldAdd = !updatedFavorites.contains(course.id);
    
    // Update list based on new state
    if (shouldAdd) {
      updatedFavorites.add(course.id);
    } else {
      updatedFavorites.remove(course.id);
    }
    
    // Update local state immediately for responsive UI
    setState(() {
      User.currentUser = User.currentUser.copyWith(
        favoriteCoursesIds: updatedFavorites,
      );
    });
    
    // Update in Firestore directly with saveUserProfile
    await _preferencesService.saveUserProfile(
      userId: currentUser.id,
      name: currentUser.name,
      email: currentUser.email,
      phone: currentUser.phone, 
      company: currentUser.company,
      tier: currentUser.tier,
      membershipExpiryDate: currentUser.membershipExpiryDate,
      favoriteCoursesIds: updatedFavorites,
      enrolledCourses: User.currentUser.enrolledCourses,
    );
  } catch (e) {
    print('Error toggling favorite: $e');
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update favorite: ${e.toString()}')),
      );
    }
  }
}

  @override
  Widget build(BuildContext context) {
    // Get current user data from Firebase Auth
    final firebaseUser = _authService.currentUser;
    
    // Use Firebase user data or fall back to static data if not available
    final currentUser = firebaseUser ?? User.currentUser;
    
    // Generate initials for avatar
    final initials = currentUser.name.split(' ')
        .map((part) => part.isNotEmpty ? part[0] : '')
        .join('');

    return Stack(
      children: [
        SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile header with user data from Firebase - Now fixed at the top with larger size
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.blue[700],
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                  child: Row(
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: Colors.blue[100],
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white.withOpacity(0.3), width: 3),
                        ),
                        child: Center(
                          child: Text(
                            initials,
                            style: TextStyle(
                              fontSize: 30,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue[700],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              currentUser.name,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Text(
                                  currentUser.tier == MembershipTier.pro
                                      ? 'Private Member'
                                      : 'Standard Member',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.9),
                                    fontSize: 16,
                                  ),
                                ),
                                if (currentUser.tier == MembershipTier.pro) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color.fromARGB(255, 218, 218, 218),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      'Silver',
                                      style: TextStyle(
                                        color: Colors.blue[700],
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.logout, color: Colors.white, size: 28),
                          onPressed: widget.onSignOut,
                          tooltip: 'Sign Out',
                          iconSize: 28,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              // Tab selector - Now positioned below the profile card
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    _buildTabButton('Profile', 'profile'),
                    _buildTabButton('Favourite', 'courses'),
                    _buildTabButton('Membership', 'membership'),
                  ],
                ),
              ),
              
              // Tab content - Content depends on which tab is active
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (activeTab == 'profile')
                      _buildProfileTab()
                    else if (activeTab == 'courses')
                      _buildCoursesTab()
                    else if (activeTab == 'membership')
                      _buildMembershipTab(),
                  ],
                ),
              ),
            ],
          ),
        ),
        
        // Calendar overlay
        if (_showCalendar)
          GestureDetector(
            onTap: () {
              setState(() {
                _showCalendar = false;
              });
            },
            child: Container(
              color: Colors.black.withOpacity(0.5),
              child: Center(
                child: GestureDetector(
                  onTap: () {}, // Prevent taps from closing the overlay
                  child: Container(
                    margin: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Course Schedule',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue[800],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.close),
                                onPressed: () {
                                  setState(() {
                                    _showCalendar = false;
                                  });
                                },
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: TableCalendar(
                            firstDay: DateTime.utc(2023, 1, 1),
                            lastDay: DateTime.utc(2030, 12, 31),
                            focusedDay: _focusedDay,
                            calendarFormat: _calendarFormat,
                            selectedDayPredicate: (day) {
                              return isSameDay(_selectedDay, day);
                            },
                            onDaySelected: (selectedDay, focusedDay) {
                              setState(() {
                                _selectedDay = selectedDay;
                                _focusedDay = focusedDay;
                              });
                            },
                            onFormatChanged: (format) {
                              setState(() {
                                _calendarFormat = format;
                              });
                            },
                            onPageChanged: (focusedDay) {
                              _focusedDay = focusedDay;
                            },
                            eventLoader: (day) {
                              // Return a list of events for the given day based on enrolled courses
                              final enrolledDates = [];
                              
                              // Add active enrollment dates from the user
                              for (var enrollment in User.currentUser.enrolledCourses) {
                                if (enrollment.nextSessionDate != null && 
                                    isSameDay(enrollment.nextSessionDate!, day)) {
                                  enrolledDates.add(enrollment);
                                }
                              }
                              
                              // Add demo enrollment dates if no real enrollments
                              if (User.currentUser.enrolledCourses.isEmpty) {
                                // Demo course dates
                                final demoDates = [
                                  DateTime.now().add(const Duration(days: 2)),
                                  DateTime.now().add(const Duration(days: 5)),
                                  DateTime.now().add(const Duration(days: 12)),
                                ];
                                
                                for (var demoDate in demoDates) {
                                  if (isSameDay(demoDate, day)) {
                                    enrolledDates.add("Demo Session");
                                  }
                                }
                              }
                              
                              return enrolledDates;
                            },
                            calendarStyle: CalendarStyle(
                              markerDecoration: BoxDecoration(
                                color: Colors.blue[700],
                                shape: BoxShape.circle,
                              ),
                              selectedDecoration: BoxDecoration(
                                color: Colors.blue[700],
                                shape: BoxShape.circle,
                              ),
                              todayDecoration: BoxDecoration(
                                color: Colors.blue[200],
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        
                        // Events for selected day
                        Container(
                          padding: const EdgeInsets.all(16),
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.blue[50],
                            borderRadius: const BorderRadius.only(
                              bottomLeft: Radius.circular(16),
                              bottomRight: Radius.circular(16),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Course Sessions on ${_selectedDay.day}/${_selectedDay.month}/${_selectedDay.year}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Colors.blue[800],
                                ),
                              ),
                              const SizedBox(height: 12),
                              
                              // Just show a simple message about the enrolled course
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.blue[100]!),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: Colors.blue[50],
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        Icons.school,
                                        color: Colors.blue[700],
                                        size: 24,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Network Security Fundamentals',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          Text(
                                            'Session scheduled for this day',
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: Colors.grey[800],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
  
Widget _buildTabButton(String title, String tabId) {
  final isActive = activeTab == tabId;
  
  return Expanded(
    child: GestureDetector(
      onTap: () {
        setState(() {
          activeTab = tabId;
          
          // If switching to favorites tab, ensure we refresh the display
          if (tabId == 'courses') {
            print("Switched to favorites tab");
            print("Current favorites: ${User.currentUser.favoriteCoursesIds}");
          }
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isActive ? Colors.blue.withOpacity(0.05) : Colors.transparent,
          border: Border(
            bottom: BorderSide(
              color: isActive ? Colors.blue[600]! : Colors.transparent,
              width: 3,
            ),
          ),
        ),
        child: Text(
          title,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isActive ? Colors.blue[600] : Colors.grey[600],
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            fontSize: 15,
          ),
        ),
      ),
    ),
  );
}
  
Widget _buildProfileTab() {
  // Get current user data from Firebase Auth
  final currentUser = User.currentUser;

  
  final upcomingSchedules = Schedule.getDummySchedules();
  final completedCourses = Course.userCourseHistory.where((course) => course.completionDate != null).toList();
  
  // Get enrolled courses by matching them with their course data
  final enrolledCoursesList = currentUser.enrolledCourses.map((enrollment) {
    final courseData = Course.sampleCourses.firstWhere(
      (c) => c.id == enrollment.courseId,
      orElse: () => Course.sampleCourses.first, // Fallback
    );
    return {
      'enrollment': enrollment,
      'course': courseData,
    };
  }).toList();
  
  // Filter active and pending enrollments
  final activeEnrollments = enrolledCoursesList.where(
    (item) => (item['enrollment'] as EnrolledCourse).status == EnrollmentStatus.active ||
              (item['enrollment'] as EnrolledCourse).status == EnrollmentStatus.confirmed
  ).toList();
  
  final pendingEnrollments = enrolledCoursesList.where(
    (item) => (item['enrollment'] as EnrolledCourse).status == EnrollmentStatus.pending
  ).toList();

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const SizedBox(height: 16),
      
      // Personal Information - Using Firebase user data
      Container(
        padding: const EdgeInsets.all(16),
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Personal Information',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Row(
                  children: [
                    // Edit profile button
                    GestureDetector(
                      onTap: _showEditProfileDialog,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.blue[200]!),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.edit,
                              size: 16,
                              color: Colors.blue[700],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Edit',
                              style: TextStyle(
                                color: Colors.blue[700],
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Toggle visibility button
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _showPersonalInfo = !_showPersonalInfo;
                        });
                      },
                      child: Row(
                        children: [
                          Icon(
                            _showPersonalInfo ? Icons.visibility : Icons.visibility_off,
                            size: 18,
                            color: Colors.blue[600],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _showPersonalInfo ? 'Hide' : 'Show',
                            style: TextStyle(
                              color: Colors.blue[600],
                              fontWeight: FontWeight.w500,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Show masked or actual information based on visibility setting
            if (_showPersonalInfo) ...[
              _buildInfoRow('Email', currentUser.email),
              _buildInfoRow('Phone', currentUser.phone),
              if (currentUser.company != null)
                _buildInfoRow('Company', currentUser.company!),
            ] else ...[
              // Show masked information
              _buildInfoRow('Email', _maskEmail(currentUser.email)),
              _buildInfoRow('Phone', _maskPhone(currentUser.phone)),
              if (currentUser.company != null)
                _buildInfoRow('Company', '********'),
            ],
          ],
        ),
      ),
      
      const SizedBox(height: 24),
      
      // Dashboard Section
      Container(
        padding: const EdgeInsets.all(16),
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Learning Dashboard',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Stats Cards
            Row(
              children: [
                _buildStatCard(
                  'In Progress',
                  '${activeEnrollments.length}', // Use enrolled courses count
                  Icons.pending_actions,
                  Colors.orange,
                ),
                const SizedBox(width: 12),
                _buildStatCard(
                  'Completed',
                  '${completedCourses.length}',
                  Icons.check_circle,
                  Colors.green,
                ),
                const SizedBox(width: 12),
                _buildStatCard(
                  'Pending',
                  '${pendingEnrollments.length}', // Use pending enrollments count
                  Icons.hourglass_empty,
                  Colors.blue,
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Enrolled Courses section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'My Enrolled Courses',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _showCalendar = true;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.blue[200]!),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.calendar_month,
                          size: 16,
                          color: Colors.blue[700],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'View Calendar',
                          style: TextStyle(
                            color: Colors.blue[700],
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Check if we have actual active/confirmed enrollments
            if (User.currentUser.enrolledCourses
                .where((e) => e.status == EnrollmentStatus.active || 
                          e.status == EnrollmentStatus.confirmed)
                .isEmpty)
              // No active enrollments, show empty state message instead of demo courses
              _buildEmptyState(
                'No enrolled courses',
                'Courses you enroll in will appear here',
                Icons.school,
              )
            else
              // Display actual enrolled courses that are active or confirmed
              Column(
                children: User.currentUser.enrolledCourses
                  .where((e) => e.status == EnrollmentStatus.active || 
                              e.status == EnrollmentStatus.confirmed)
                  .map((enrollment) {
                    // Find the corresponding course data
                    final courseData = Course.sampleCourses.firstWhere(
                      (c) => c.id == enrollment.courseId,
                      orElse: () => Course.sampleCourses.first, // Fallback
                    );
                    
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: EnrolledCourseCard(
                        enrollment: enrollment,
                        course: courseData,
                      ),
                    );
                  }).toList(),
              ),

            const SizedBox(height: 16),
            
            // Pending Enrollments section
          if (User.currentUser.enrolledCourses
              .where((e) => e.status == EnrollmentStatus.pending)
              .isNotEmpty) 
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Pending Enrollments',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                
                // List pending enrollments by directly querying User.currentUser
                ...User.currentUser.enrolledCourses
                  .where((e) => e.status == EnrollmentStatus.pending)
                  .map((enrollment) {
                    // Find the corresponding course data
                    final courseData = Course.sampleCourses.firstWhere(
                      (c) => c.id == enrollment.courseId,
                      orElse: () => Course.sampleCourses.first, // Fallback
                    );
                    
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: EnrolledCourseCard(
                        enrollment: enrollment,
                        course: courseData,
                      ),
                    );
                  }),
              ],
            )
            else if (pendingEnrollments.isNotEmpty)
              // Fallback to using the pendingEnrollments variable if needed
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Pending Enrollments',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  
                  ...pendingEnrollments.map((item) => Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: EnrolledCourseCard(
                      enrollment: item['enrollment'] as EnrolledCourse,
                      course: item['course'] as Course,
                    ),
                  )),
                ],
              ),

            const SizedBox(height: 16),
            
            // Upcoming Schedule
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Upcoming Schedule',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _showCalendar = true;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.blue[200]!),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.calendar_month,
                          size: 16,
                          color: Colors.blue[700],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'View Calendar',
                          style: TextStyle(
                            color: Colors.blue[700],
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            if (upcomingSchedules.isEmpty)
              _buildEmptyState(
                'No upcoming sessions',
                'Your scheduled learning sessions will appear here',
                Icons.event_busy,
              )
            else
              Column(
                children: upcomingSchedules
                    .take(2)
                    .map((schedule) => Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: _buildScheduleCard(schedule),
                        ))
                    .toList(),
              ),
                
            if (upcomingSchedules.length > 2)
              TextButton(
                onPressed: () {
                  setState(() {
                    _showCalendar = true;
                  });
                },
                child: Text(
                  'View More',
                  style: TextStyle(
                    color: Colors.blue[700],
                  ),
                ),
              ),
          ],
        ),
      ),
      
      const SizedBox(height: 24),
      
      // Course History - Show only completed courses
      Text(
        'Course History',
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      const SizedBox(height: 12),
      
      if (completedCourses.isEmpty)
        _buildEmptyState(
          'No completed courses',
          'Your completed courses will appear here',
          Icons.school,
        )
      else
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: completedCourses.length,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final course = completedCourses[index];
            return Container(
              padding: const EdgeInsets.all(16),
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (course.certType != null) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.blue[50],
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            course.certType!,
                            style: TextStyle(
                              color: Colors.blue[700],
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      Expanded(
                        child: Text(
                          course.title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (course.completionDate != null)
                    Text(
                      'Completed ${course.completionDate}',
                      style: TextStyle(
                        color: Colors.green[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.book,
                        size: 16,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Course Code: ${course.courseCode}',
                        style: TextStyle(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      const SizedBox(height: 24),
    ],
  );
}
  
Widget _buildCoursesTab() {
  // Get current user data from Firebase Auth
  final firebaseUser = _authService.currentUser;
  
  // Use Firebase user data or fall back to static data if not available
  final currentUser = firebaseUser ?? User.currentUser;
  
  // Get all favorited courses
  final favoriteIds = User.currentUser.favoriteCoursesIds;
  final favoriteCourses = Course.sampleCourses
      .where((course) => favoriteIds.contains(course.id))
      .toList();

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const SizedBox(height: 16),
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Favourite Courses',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.pink[50],
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.favorite,
                  size: 16,
                  color: Colors.pink[400],
                ),
                const SizedBox(width: 4),
                Text(
                  '${favoriteCourses.length} ${favoriteCourses.length == 1 ? 'Course' : 'Courses'}',
                  style: TextStyle(
                    color: Colors.pink[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      const SizedBox(height: 16),
      
      if (favoriteCourses.isEmpty)
        Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Center(
            child: Column(
              children: [
                Icon(
                  Icons.favorite_border,
                  size: 48,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'Your favorites collection is empty',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Save your favorite courses by tapping the heart icon',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 24),
                OutlinedButton(
                  onPressed: () {
                    // Navigate to courses tab/screen
                  },
                  style: OutlinedButton.styleFrom(
                    backgroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    side: BorderSide(color: Colors.blue[600]!),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    'Browse Courses',
                    style: TextStyle(
                      color: Colors.blue[600],
                    ),
                  ),
                ),
              ],
            ),
          ),
        )
      else
        // Use the standard CourseCard component instead of custom implementation
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: favoriteCourses.length,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            return CourseCard(
              course: favoriteCourses[index],
              onFavoriteToggle: _toggleFavorite,
            );
          },
        ),
          
      const SizedBox(height: 24),
    ],
  );
}
  
  Widget _buildMembershipTab() {
    // Get current user data from Firebase Auth
    final firebaseUser = _authService.currentUser;
    
    // Use Firebase user data or fall back to static data if not available
    final currentUser = firebaseUser ?? User.currentUser;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.blue[200]!),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    currentUser.tier == MembershipTier.pro
                        ? 'Private Membership'
                        : 'Standard Membership',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[800],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue[600],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text(
                      'ACTIVE',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Valid until: ${currentUser.membershipExpiryDate}',
                style: TextStyle(
                  color: Colors.blue[800],
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Benefits:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              if (currentUser.tier == MembershipTier.pro) ...[
                _buildBenefitItem('Priority access to new courses'),
                _buildBenefitItem('25% discount on all certifications'),
                _buildBenefitItem('Exclusive webinars and events'),
                _buildBenefitItem('Career counseling sessions'),
              ] else ...[
                _buildBenefitItem('Access to standard courses'),
                _buildBenefitItem('Community forum access'),
                _buildBenefitItem('Monthly newsletter'),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (User.currentUser.tier == MembershipTier.standard)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[600],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Upgrade to PRO'),
            ),
          )
        else
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[600],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Renew Membership'),
            ),
          ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Upgrade to Private GOLD',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Get even more benefits than a Silver membership by upgrading to a Gold membership with our latest offers!',
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () {},
                    child: Text(
                      'Learn More',
                      style: TextStyle(
                        color: Colors.blue[700],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        // PRIVACY SETTING
                // Container(
                //   padding: const EdgeInsets.all(16),
                //   decoration: BoxDecoration(
                //     color: Colors.white,
                //     borderRadius: BorderRadius.circular(12),
                //     boxShadow: [
                //       BoxShadow(
                //         color: Colors.black.withOpacity(0.05),
                //         blurRadius: 10,
                //         offset: const Offset(0, 2),
                //       ),
                //     ],
                //   ),
                //   child: Column(
                //     crossAxisAlignment: CrossAxisAlignment.start,
                //     children: [
                //       const Text(
                //         'Privacy Settings',
                //         style: TextStyle(
                //           fontSize: 16,
                //           fontWeight: FontWeight.bold,
                //         ),
                //       ),
                //       const SizedBox(height: 16),
                //       Row(
                //         mainAxisAlignment: MainAxisAlignment.spaceBetween,
                //         children: [
                //           Text(
                //             'Show personal information',
                //             style: TextStyle(
                //               color: Colors.grey[800],
                //             ),
                //           ),
                //           Switch(
                //             value: _showPersonalInfo,
                //             onChanged: (value) {
                //               setState(() {
                //                 _showPersonalInfo = value;
                //               });
                //             },
                //             activeColor: Colors.blue[600],
                //           ),
                //         ],
                //       ),
                //       const SizedBox(height: 8),
                //       Text(
                //         'When turned off, your personal information will be masked for privacy.',
                //         style: TextStyle(
                //           color: Colors.grey[600],
                //           fontSize: 12,
                //         ),
                //       ),
                //     ],
                //   ),
                // ),

        const SizedBox(height: 24),
      ],
    );
  }
  
  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey[600],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildStatCard(String title, String value, IconData icon, MaterialColor color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color[100]!),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: color[700],
              size: 24,
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color[800],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: color[800],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildScheduleCard(Schedule schedule) {
    return Container(
      padding: const EdgeInsets.all(12),
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
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                Text(
                  schedule.date.day.toString(),
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[700],
                  ),
                ),
                Text(
                  _getMonthAbbreviation(schedule.date.month),
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.blue[700],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  schedule.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  schedule.courseTitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      size: 14,
                      color: Colors.grey[500],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${schedule.startTime} - ${schedule.endTime}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: schedule.isPending ? Colors.orange[50] : Colors.green[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: schedule.isPending ? Colors.orange[200]! : Colors.green[200]!,
              ),
            ),
            child: Text(
              schedule.isPending ? 'Upcoming' : 'Confirmed',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: schedule.isPending ? Colors.orange[800] : Colors.green[800],
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildEmptyState(String title, String subtitle, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Center(
        child: Column(
          children: [
            Icon(
              icon,
              size: 32,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
  
  String _getMonthAbbreviation(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[month - 1];
  }

  Widget _buildBenefitItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: Colors.blue[600],
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: Colors.blue[800],
              ),
            ),
          ),
        ],
      ),
    );
  }
}