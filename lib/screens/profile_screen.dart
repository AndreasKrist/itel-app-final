import 'package:flutter/material.dart';
import '../models/course.dart';
import '../models/user.dart';
import '../models/schedule.dart';
import 'package:table_calendar/table_calendar.dart';
import '../widgets/enrolled_course_card.dart';
import '../models/enrolled_course.dart';
import '../services/auth_service.dart';
import '../services/user_preferences_service.dart';
import '../services/course_remote_config_service.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/course_card.dart';//import 'course_outline_screen.dart';
import '../widgets/edit_profile_dialog.dart';
import '../services/membership_service.dart';
import 'payment_screen.dart';

class ProfileScreen extends StatefulWidget {
  final VoidCallback onSignOut;
  final VoidCallback? onNavigateToCourses;

  const ProfileScreen({
    super.key,
    required this.onSignOut,
    this.onNavigateToCourses,
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

  final CourseRemoteConfigService _courseRemoteConfigService = CourseRemoteConfigService();
  List<Course> _allCourses = [];
  

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

    // First update in Firestore to ensure data is saved with ALL user data
    await _preferencesService.saveUserProfile(
      userId: firebaseUser.uid,
      name: name,
      email: User.currentUser.email,
      phone: phone,
      company: company,
      companyAddress: User.currentUser.companyAddress,
      accountType: User.currentUser.accountType,
      tier: User.currentUser.tier,
      membershipExpiryDate: User.currentUser.membershipExpiryDate,
      favoriteCoursesIds: User.currentUser.favoriteCoursesIds,
      enrolledCourses: User.currentUser.enrolledCourses,
      courseHistory: User.currentUser.courseHistory,
      giveAccess: User.currentUser.giveAccess,
      trainingCredits: User.currentUser.trainingCredits,
      trainingCreditHistory: User.currentUser.trainingCreditHistory,
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
        ),
      );

      print('Profile updated successfully. Current user: ${User.currentUser.name}, ${User.currentUser.phone}, ${User.currentUser.company}');
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
    // Reload data whenever the screen comes into focus
    _reloadUserData();
  }

  // Add to the _ProfileScreenState class
  @override
  void initState() {
    super.initState();
    _reloadUserData();
    _loadCourses();
  }

  Future<void> _loadCourses() async {
    try {
      final courses = await _courseRemoteConfigService.getRemoteCourses();
      if (mounted) {
        setState(() {
          _allCourses = courses;
        });
      }
    } catch (e) {
      print('Error loading courses in profile: $e');
      if (mounted) {
        setState(() {
          _allCourses = Course.sampleCourses; // Fallback
        });
      }
    }
  }

  // Reload user data including favorites and enrollments
  Future<void> _reloadUserData() async {
    try {
      print('Reloading user data on profile screen');
      // Use auth service to reload all user data from Firestore
      await _authService.loadUserData();

      // Force UI update after data reload
      if (mounted) {
        setState(() {
          // This will trigger a rebuild with the updated data
        });
      }

      print('User data reloaded. Favorites: ${User.currentUser.favoriteCoursesIds.length}, Enrollments: ${User.currentUser.enrolledCourses.length}');
    } catch (e) {
      print('Error reloading user data: $e');
    }
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
    List<EnrolledCourse> courseHistoryList = [];
    
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
        
        // Load course history from the same document
        if (userData != null && userData.containsKey('courseHistory')) {
          final List<dynamic> historyData = userData['courseHistory'] ?? [];
          print('Found ${historyData.length} course history items in main user document');
          
          for (var data in historyData) {
            if (data['courseId'] != null) {
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
              EnrollmentStatus status = EnrollmentStatus.cancelled; // Default for history
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
                } else if (statusStr.contains('pending')) {
                  status = EnrollmentStatus.pending;
                }
              }
              
              final historyItem = EnrolledCourse(
                courseId: data['courseId'],
                enrollmentDate: enrollmentDate ?? DateTime.now(),
                status: status,
                isOnline: data['isOnline'] ?? false,
                nextSessionDate: nextSessionDate,
                nextSessionTime: data['nextSessionTime'],
                location: data['location'],
                instructorName: data['instructorName'],
                progress: data['progress'],
                gradeOrCertificate: data['gradeOrCertificate'],
              );
              
              courseHistoryList.add(historyItem);
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
        print('Updating User.currentUser with ${enrollments.length} enrollments and ${courseHistoryList.length} history items');
        User.currentUser = User.currentUser.copyWith(
          enrolledCourses: enrollments,
          courseHistory: courseHistoryList,
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

// Helper function to format date
String _formatDate(DateTime date) {
  List<String> months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];
  return '${date.day} ${months[date.month - 1]} ${date.year}';
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

    // Update in Firestore directly with saveUserProfile to ensure persistence
    await _preferencesService.saveUserProfile(
      userId: currentUser.id,
      name: User.currentUser.name,
      email: User.currentUser.email,
      phone: User.currentUser.phone,
      company: User.currentUser.company,
      companyAddress: User.currentUser.companyAddress,
      accountType: User.currentUser.accountType,
      tier: User.currentUser.tier,
      membershipExpiryDate: User.currentUser.membershipExpiryDate,
      favoriteCoursesIds: updatedFavorites,
      enrolledCourses: User.currentUser.enrolledCourses,
      courseHistory: User.currentUser.courseHistory,
      giveAccess: User.currentUser.giveAccess,
      trainingCredits: User.currentUser.trainingCredits,
      trainingCreditHistory: User.currentUser.trainingCreditHistory,
    );

    print('Successfully updated favorites: ${updatedFavorites.length} items');
  } catch (e) {
    print('Error toggling favorite: $e');
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update favorite: ${e.toString()}')),
      );
    }
  }
}

// Add method to clean up all old subcollection data (for debugging/cleanup)
Future<void> _cleanupAllSubcollectionData() async {
  try {
    final currentUser = _authService.currentUser;
    if (currentUser != null) {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.id)
          .collection('enrolledCourses')
          .get();
          
      print('Found ${snapshot.docs.length} old enrollment documents to clean up');
      
      // Delete all documents in the subcollection
      for (var doc in snapshot.docs) {
        await doc.reference.delete();
        print('Deleted old enrollment: ${doc.data()['courseId']}');
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Cleaned up ${snapshot.docs.length} old enrollment records'),
            backgroundColor: Color(0xFF00FF00),
          ),
        );
      }
    }
  } catch (e) {
    print('Error cleaning up subcollection: $e');
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error during cleanup: ${e.toString()}')),
      );
    }
  }
}

// Add method to mark course as finished
void _removeCourseFromEnrolled(String courseId) async {
  try {
    // Show confirmation dialog
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Mark Course as Finished'),
        content: const Text('Are you sure you want to mark this course as finished? The course will remain in this section but be marked as completed.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: Color(0xFF00FF00),
            ),
            child: const Text('Mark Finished'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      // Update local state immediately - mark as completed but keep in enrolledCourses
      setState(() {
        final updatedEnrollments = User.currentUser.enrolledCourses.map((enrollment) {
          if (enrollment.courseId == courseId) {
            return enrollment.copyWith(
              status: EnrollmentStatus.completed,
              progress: "100% complete",
            );
          }
          return enrollment;
        }).toList();

        User.currentUser = User.currentUser.copyWith(
          enrolledCourses: updatedEnrollments,
        );
      });

      // Update in Firestore
      final currentUser = _authService.currentUser;
      if (currentUser != null) {
        // Update subcollection first
        try {
          final snapshot = await FirebaseFirestore.instance
              .collection('users')
              .doc(currentUser.id)
              .collection('enrolledCourses')
              .where('courseId', isEqualTo: courseId)
              .get();

          for (var doc in snapshot.docs) {
            await doc.reference.update({
              'status': 'completed',
              'progress': '100% complete',
            });
          }
          print('Updated course $courseId status in subcollection');
        } catch (e) {
          print('Error updating subcollection: $e');
        }

        // Update main user document
        await _preferencesService.saveUserProfile(
          userId: currentUser.id,
          name: currentUser.name,
          email: currentUser.email,
          phone: currentUser.phone,
          company: currentUser.company,
          companyAddress: User.currentUser.companyAddress,
          accountType: User.currentUser.accountType,
          tier: currentUser.tier,
          membershipExpiryDate: currentUser.membershipExpiryDate,
          favoriteCoursesIds: User.currentUser.favoriteCoursesIds,
          enrolledCourses: User.currentUser.enrolledCourses,
          courseHistory: User.currentUser.courseHistory,
          giveAccess: User.currentUser.giveAccess,
          trainingCredits: User.currentUser.trainingCredits,
          trainingCreditHistory: User.currentUser.trainingCreditHistory,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Course marked as completed!'),
            backgroundColor: Color(0xFF00FF00),
          ),
        );
      }
    }
  } catch (e) {
    print('Error marking course as finished: $e');
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to mark course as finished: ${e.toString()}')),
      );
    }
  }
}

  @override
  Widget build(BuildContext context) {
    // Always use User.currentUser for membership tier info as it gets updated during purchases
    // Firebase user is only used for auth state, not for membership data
    final currentUser = User.currentUser;
    
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
                  color: Color(0xFF0056AC),
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
                              color: Color(0xFF0056AC),
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
                            // In the profile header section, update the tier display:
                              Row(
                                children: [
                                  Text(
                                    currentUser.accountType == 'corporate'
                                        ? 'Corporate Account'
                                        : currentUser.tier.displayName,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.white.withOpacity(0.9),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  if (currentUser.tier.discountPercentage > 0) ...[
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: _getTierColor(currentUser.tier),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        '${(currentUser.tier.discountPercentage * 100).toInt()}% OFF',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
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
                                  color: Color(0xFF0056AC),
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
                                color: Color(0xFF0056AC),
                                shape: BoxShape.circle,
                              ),
                              selectedDecoration: BoxDecoration(
                                color: Color(0xFF0056AC),
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
                                  color: Color(0xFF0056AC),
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
                                        color: Color(0xFF0056AC),
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
              color: isActive ? Color(0xFF0056AC)! : Colors.transparent,
              width: 3,
            ),
          ),
        ),
        child: Text(
          title,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isActive ? Color(0xFF0056AC) : Colors.grey[600],
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

  // Count actual completed courses from user's enrollments and course history
  final userCompletedEnrollments = currentUser.enrolledCourses
      .where((enrollment) => enrollment.status == EnrollmentStatus.completed)
      .length;
  final userCompletedHistory = currentUser.courseHistory
      .where((enrollment) => enrollment.status == EnrollmentStatus.completed)
      .length;
  final totalCompletedCount = userCompletedEnrollments + userCompletedHistory;
  
  // Get enrolled courses by matching them with their course data
  final enrolledCoursesList = currentUser.enrolledCourses.map((enrollment) {
    final courseData = _allCourses.firstWhere(
      (c) => c.id == enrollment.courseId,
      orElse: () => _allCourses.isNotEmpty ? _allCourses.first : Course.sampleCourses.first, // Fallback
    );
    return {
      'enrollment': enrollment,
      'course': courseData,
    };
  }).toList();
  
  // Helper function to check if a course is free/complimentary
  bool isFreeComplimentaryCourse(String courseId) {
    final course = _allCourses.firstWhere(
      (c) => c.id == courseId,
      orElse: () => _allCourses.isNotEmpty ? _allCourses.first : Course.sampleCourses.first,
    );
    return course.price == '\$0' || course.price.contains('Free') || course.funding == 'Complimentary';
  }

  // Filter enrollments for "My Enrolled Courses" (free/complimentary courses)
  final activeEnrollments = enrolledCoursesList.where(
    (item) {
      final enrollment = item['enrollment'] as EnrolledCourse;
      return isFreeComplimentaryCourse(enrollment.courseId) &&
             (enrollment.status == EnrollmentStatus.active ||
              enrollment.status == EnrollmentStatus.confirmed ||
              enrollment.status == EnrollmentStatus.completed);
    }
  ).toList();

  // Filter enrollments for "Enquiry Courses" (paid courses)
  final pendingEnrollments = enrolledCoursesList.where(
    (item) {
      final enrollment = item['enrollment'] as EnrolledCourse;
      return !isFreeComplimentaryCourse(enrollment.courseId) &&
             (enrollment.status == EnrollmentStatus.pending ||
              enrollment.status == EnrollmentStatus.completed);
    }
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
                              color: Color(0xFF0056AC),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Edit',
                              style: TextStyle(
                                color: Color(0xFF0056AC),
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
                            color: Color(0xFF0056AC),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _showPersonalInfo ? 'Hide' : 'Show',
                            style: TextStyle(
                              color: Color(0xFF0056AC),
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
              if (currentUser.company != null && currentUser.company!.isNotEmpty && currentUser.accountType != 'corporate')
                _buildInfoRow('Company', currentUser.company!),
            ] else ...[
              // Show masked information
              _buildInfoRow('Email', _maskEmail(currentUser.email)),
              _buildInfoRow('Phone', _maskPhone(currentUser.phone)),
              if (currentUser.company != null && currentUser.company!.isNotEmpty && currentUser.accountType != 'corporate')
                _buildInfoRow('Company', '********'),
            ],
          ],
        ),
      ),

      // Company Information Section (Corporate accounts only)
      if (currentUser.accountType == 'corporate') ...[
        const SizedBox(height: 24),
        _buildCompanyInformationSection(currentUser),
      ],

      const SizedBox(height: 24),

      // Dashboard Section (Hidden for corporate accounts)
      if (currentUser.accountType != 'corporate') ...[
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
                  'Enrolled',
                  '${activeEnrollments.length}', // Use enrolled courses count
                  Icons.pending_actions,
                  Color(0xFF0056AC),
                ),
                const SizedBox(width: 12),
                _buildStatCard(
                  'Completed',
                  '${totalCompletedCount}',
                  Icons.check_circle,
                  Color(0xFF00FF00),
                ),
                const SizedBox(width: 12),
                _buildStatCard(
                  'Enquiry',
                  '${pendingEnrollments.length}', // Use pending enrollments count
                  Icons.hourglass_empty,
                  Color(0xFFFF6600),
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
                // GestureDetector(
                //   onTap: () {
                //     setState(() {
                //       _showCalendar = true;
                //     });
                //   },
                //   child: Container(
                //     padding: const EdgeInsets.symmetric(
                //       horizontal: 10,
                //       vertical: 5,
                //     ),
                //     decoration: BoxDecoration(
                //       color: Colors.blue[50],
                //       borderRadius: BorderRadius.circular(16),
                //       border: Border.all(color: Colors.blue[200]!),
                //     ),
                //     child: Row(
                //       children: [
                //         Icon(
                //           Icons.calendar_month,
                //           size: 16,
                //           color: Color(0xFF0056AC),
                //         ),
                //         const SizedBox(width: 4),
                //         Text(
                //           'View Calendar',
                //           style: TextStyle(
                //             color: Color(0xFF0056AC),
                //             fontSize: 12,
                //             fontWeight: FontWeight.w500,
                //           ),
                //         ),
                //       ],
                //     ),
                //   ),
                // ),
              ],
            ),
            const SizedBox(height: 12),

            // Check if we have actual active/confirmed/completed enrollments for free courses
            if (User.currentUser.enrolledCourses
                .where((e) => (e.status == EnrollmentStatus.active ||
                          e.status == EnrollmentStatus.confirmed ||
                          e.status == EnrollmentStatus.completed) &&
                          isFreeComplimentaryCourse(e.courseId))
                .isEmpty)
              // No active enrollments, show empty state message instead of demo courses
              _buildEmptyState(
                'No enrolled courses',
                'Courses you enroll in will appear here',
                Icons.school,
              )
            else
              // Display actual enrolled courses that are active, confirmed, or completed (free courses)
              Column(
                children: User.currentUser.enrolledCourses
                  .where((e) => (e.status == EnrollmentStatus.active ||
                              e.status == EnrollmentStatus.confirmed ||
                              e.status == EnrollmentStatus.completed) &&
                              isFreeComplimentaryCourse(e.courseId))
                  .map((enrollment) {
                    // Find the corresponding course data
                    final courseData = _allCourses.firstWhere(
                      (c) => c.id == enrollment.courseId,
                      orElse: () => _allCourses.isNotEmpty ? _allCourses.first : Course.sampleCourses.first, // Fallback
                    );
                    
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: EnrolledCourseCard(
                        enrollment: enrollment,
                        course: courseData,
                        onRemove: () => _removeCourseFromEnrolled(enrollment.courseId),
                      ),
                    );
                  }).toList(),
              ),

            const SizedBox(height: 16),
            
            // Enquiry Courses section
          if (User.currentUser.enrolledCourses
              .where((e) => (e.status == EnrollmentStatus.pending ||
                          e.status == EnrollmentStatus.completed) &&
                          !isFreeComplimentaryCourse(e.courseId))
              .isNotEmpty) 
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Enquiry Courses',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    // Debug button hidden - uncomment if needed for troubleshooting
                    // TextButton(
                    //   onPressed: _cleanupAllSubcollectionData,
                    //   style: TextButton.styleFrom(
                    //     foregroundColor: Colors.red,
                    //     padding: const EdgeInsets.symmetric(horizontal: 8),
                    //   ),
                    //   child: const Text(
                    //     'Clean DB',
                    //     style: TextStyle(fontSize: 12),
                    //   ),
                    // ),
                  ],
                ),
                const SizedBox(height: 12),
                
                // List pending and completed enquiry enrollments by directly querying User.currentUser
                ...User.currentUser.enrolledCourses
                  .where((e) => (e.status == EnrollmentStatus.pending ||
                              e.status == EnrollmentStatus.completed) &&
                              !isFreeComplimentaryCourse(e.courseId))
                  .map((enrollment) {
                    // Find the corresponding course data
                    final courseData = _allCourses.firstWhere(
                      (c) => c.id == enrollment.courseId,
                      orElse: () => _allCourses.isNotEmpty ? _allCourses.first : Course.sampleCourses.first, // Fallback
                    );
                    
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: EnrolledCourseCard(
                        enrollment: enrollment,
                        course: courseData,
                        onRemove: () => _removeCourseFromEnrolled(enrollment.courseId),
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
                        'Enquiry Courses',
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
                      onRemove: () => _removeCourseFromEnrolled((item['enrollment'] as EnrolledCourse).courseId),
                    ),
                  )),
                ],
              ),

            // Upcoming Schedule section - hidden for now, may be implemented in future
            // const SizedBox(height: 16),
            //
            // Row(
            //   mainAxisAlignment: MainAxisAlignment.spaceBetween,
            //   children: [
            //     Text(
            //       'Upcoming Schedule',
            //       style: TextStyle(
            //         fontWeight: FontWeight.bold,
            //       ),
            //     ),
            //     GestureDetector(
            //       onTap: () {
            //         setState(() {
            //           _showCalendar = true;
            //         });
            //       },
            //       child: Container(
            //         padding: const EdgeInsets.symmetric(
            //           horizontal: 10,
            //           vertical: 5,
            //         ),
            //         decoration: BoxDecoration(
            //           color: Colors.blue[50],
            //           borderRadius: BorderRadius.circular(16),
            //           border: Border.all(color: Colors.blue[200]!),
            //         ),
            //         child: Row(
            //           children: [
            //             Icon(
            //               Icons.calendar_month,
            //               size: 16,
            //               color: Colors.blue[700],
            //             ),
            //             const SizedBox(width: 4),
            //             Text(
            //               'View Calendar',
            //               style: TextStyle(
            //                 color: Colors.blue[700],
            //                 fontSize: 12,
            //                 fontWeight: FontWeight.w500,
            //               ),
            //             ),
            //           ],
            //         ),
            //       ),
            //     ),
            //   ],
            // ),
            // const SizedBox(height: 12),
            //
            // if (upcomingSchedules.isEmpty)
            //   _buildEmptyState(
            //     'No upcoming sessions',
            //     'Your scheduled learning sessions will appear here',
            //     Icons.event_busy,
            //   )
            // else
            //   Column(
            //     children: upcomingSchedules
            //         .take(2)
            //         .map((schedule) => Padding(
            //               padding: const EdgeInsets.only(bottom: 8.0),
            //               child: _buildScheduleCard(schedule),
            //             ))
            //         .toList(),
            //   ),
            //
            // if (upcomingSchedules.length > 2)
            //   TextButton(
            //     onPressed: () {
            //       setState(() {
            //         _showCalendar = true;
            //       });
            //     },
            //     child: Text(
            //       'View More',
            //       style: TextStyle(
            //         color: Colors.blue[700],
            //       ),
            //     ),
            //   ),
          ],
        ),
      ),
      ], // End of dashboard section (hidden for corporate accounts)

      // const SizedBox(height: 24),

      // Course History - Show completed courses from history + static completed courses
      // Commented out for now - can be re-enabled later when needed
      // Text(
      //   'Course History',
      //   style: TextStyle(
      //     fontSize: 18,
      //     fontWeight: FontWeight.bold,
      //   ),
      // ),
      // const SizedBox(height: 12),

      // Show completed courses
      // if (User.currentUser.courseHistory
      //     .where((enrollment) => enrollment.status == EnrollmentStatus.completed)
      //     .isEmpty && completedCourses.isEmpty)
      //   _buildEmptyState(
      //     'No completed courses',
      //     'Courses you mark as finished will appear here',
      //     Icons.history,
      //   )
      // else
      //   Column(
      //     children: [
      //       // Show user-completed courses (marked as finished)
      //       ...User.currentUser.courseHistory
      //           .where((enrollment) => enrollment.status == EnrollmentStatus.completed)
      //           .map((enrollment) {
      //           // Find the corresponding course data
      //           final courseData = _allCourses.firstWhere(
      //             (c) => c.id == enrollment.courseId,
      //             orElse: () => _allCourses.isNotEmpty ? _allCourses.first : Course.sampleCourses.first, // Fallback
      //           );
      //
      //           return Padding(
      //             padding: const EdgeInsets.only(bottom: 12),
      //             child: Container(
      //               padding: const EdgeInsets.all(16),
      //               decoration: BoxDecoration(
      //                 color: Colors.white,
      //                 borderRadius: BorderRadius.circular(12),
      //                 boxShadow: [
      //                   BoxShadow(
      //                     color: Colors.black.withOpacity(0.05),
      //                     blurRadius: 10,
      //                     offset: const Offset(0, 2),
      //                   ),
      //                 ],
      //               ),
      //               child: Column(
      //                 crossAxisAlignment: CrossAxisAlignment.start,
      //                 children: [
      //                   Row(
      //                     children: [
      //                       Container(
      //                         padding: const EdgeInsets.symmetric(
      //                           horizontal: 8,
      //                           vertical: 2,
      //                         ),
      //                         decoration: BoxDecoration(
      //                           color: Colors.green[50],
      //                           borderRadius: BorderRadius.circular(10),
      //                         ),
      //                         child: Text(
      //                           'COMPLETED',
      //                           style: TextStyle(
      //                             color: Color(0xFF00FF00),
      //                             fontWeight: FontWeight.bold,
      //                             fontSize: 12,
      //                           ),
      //                         ),
      //                       ),
      //                       const SizedBox(width: 8),
      //                       Expanded(
      //                         child: Text(
      //                           courseData.title,
      //                           style: const TextStyle(
      //                             fontSize: 16,
      //                             fontWeight: FontWeight.bold,
      //                           ),
      //                         ),
      //                       ),
      //                     ],
      //                   ),
      //                   const SizedBox(height: 8),
      //                   Text(
      //                     'Completed ${_formatDate(DateTime.now())}',
      //                     style: TextStyle(
      //                       color: Color(0xFF00FF00),
      //                       fontWeight: FontWeight.w500,
      //                     ),
      //                   ),
      //                   const SizedBox(height: 4),
      //                   Text(
      //                     'Progress: ${enrollment.progress ?? "100% complete"}',
      //                     style: TextStyle(
      //                       color: Colors.grey[600],
      //                       fontSize: 13,
      //                     ),
      //                   ),
      //                   const SizedBox(height: 4),
      //                   Row(
      //                     children: [
      //                       Icon(
      //                         Icons.book,
      //                         size: 16,
      //                         color: Colors.grey[600],
      //                       ),
      //                       const SizedBox(width: 4),
      //                       Text(
      //                         'Course Code: ${courseData.courseCode}',
      //                         style: TextStyle(
      //                           color: Colors.grey[600],
      //                         ),
      //                       ),
      //                     ],
      //                   ),
      //                 ],
      //               ),
      //             ),
      //           );
      //         }),
      //
      //       // Show pre-existing completed courses (from sample data)
      //       if (completedCourses.isNotEmpty) ...[
      //         ListView.separated(
      //           shrinkWrap: true,
      //           physics: const NeverScrollableScrollPhysics(),
      //           itemCount: completedCourses.length,
      //           separatorBuilder: (context, index) => const SizedBox(height: 12),
      //           itemBuilder: (context, index) {
      //             final course = completedCourses[index];
      //             return Container(
      //               padding: const EdgeInsets.all(16),
      //               decoration: BoxDecoration(
      //                 color: Colors.white,
      //                 borderRadius: BorderRadius.circular(12),
      //                 boxShadow: [
      //                   BoxShadow(
      //                     color: Colors.black.withOpacity(0.05),
      //                     blurRadius: 10,
      //                     offset: const Offset(0, 2),
      //                   ),
      //                 ],
      //               ),
      //               child: Column(
      //                 crossAxisAlignment: CrossAxisAlignment.start,
      //                 children: [
      //                   Row(
      //                     children: [
      //                       if (course.certType != null) ...[
      //                         Container(
      //                           padding: const EdgeInsets.symmetric(
      //                             horizontal: 8,
      //                             vertical: 2,
      //                           ),
      //                           decoration: BoxDecoration(
      //                             color: Colors.blue[50],
      //                             borderRadius: BorderRadius.circular(10),
      //                           ),
      //                           child: Text(
      //                             course.certType!,
      //                             style: TextStyle(
      //                               color: Color(0xFF0056AC),
      //                               fontWeight: FontWeight.bold,
      //                               fontSize: 12,
      //                             ),
      //                           ),
      //                         ),
      //                         const SizedBox(width: 8),
      //                       ],
      //                       Expanded(
      //                         child: Text(
      //                           course.title,
      //                           style: const TextStyle(
      //                             fontSize: 16,
      //                             fontWeight: FontWeight.bold,
      //                           ),
      //                         ),
      //                       ),
      //                     ],
      //                   ),
      //                   const SizedBox(height: 8),
      //                   if (course.completionDate != null)
      //                     Text(
      //                       'Completed ${course.completionDate}',
      //                       style: TextStyle(
      //                         color: Color(0xFF00FF00),
      //                         fontWeight: FontWeight.w500,
      //                       ),
      //                     ),
      //                   const SizedBox(height: 8),
      //                   Row(
      //                     children: [
      //                       Icon(
      //                         Icons.book,
      //                         size: 16,
      //                         color: Colors.grey[600],
      //                       ),
      //                       const SizedBox(width: 4),
      //                       Text(
      //                         'Course Code: ${course.courseCode}',
      //                         style: TextStyle(
      //                           color: Colors.grey[600],
      //                         ),
      //                       ),
      //                     ],
      //                   ),
      //                 ],
      //               ),
      //             );
      //           },
      //         ),
      //       ],
      //     ],
      //   ),
      // const SizedBox(height: 24),
    ],
  );
}

// Company Information Section for Corporate accounts
Widget _buildCompanyInformationSection(User currentUser) {
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
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Company Information',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.business, size: 14, color: Color(0xFF0056AC)),
                  const SizedBox(width: 4),
                  Text(
                    'Corporate',
                    style: TextStyle(
                      color: Color(0xFF0056AC),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Company Name
        if (currentUser.company != null && currentUser.company!.isNotEmpty)
          _buildInfoRow('Company', currentUser.company!),

        // Company Address
        if (currentUser.companyAddress != null && currentUser.companyAddress!.isNotEmpty)
          _buildInfoRow('Address', currentUser.companyAddress!),

        const SizedBox(height: 16),

        // Available Training Credits Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF0056AC), Colors.blue[700]!],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Available Training Credits',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Icon(
                    Icons.account_balance_wallet,
                    color: Colors.white,
                    size: 24,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                '\$${currentUser.trainingCredits.toStringAsFixed(2)}',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Training Credit History
        Text(
          'Training Credit History',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),

        if (currentUser.trainingCreditHistory.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                'No credit history yet',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: currentUser.trainingCreditHistory.length,
            separatorBuilder: (context, index) => Divider(height: 1, color: Colors.grey[200]),
            itemBuilder: (context, index) {
              final historyItem = currentUser.trainingCreditHistory[index];
              final courseName = historyItem['courseName'] ?? 'Unknown Course';
              final amount = historyItem['amount'] ?? 0.0;
              final date = historyItem['date'] ?? '';

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            courseName,
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                              fontSize: 14,
                            ),
                          ),
                          if (date.isNotEmpty)
                            Text(
                              date,
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                        ],
                      ),
                    ),
                    Text(
                      '\$${amount.toStringAsFixed(2)}',
                      style: TextStyle(
                        color: amount < 0 ? Colors.red[600] : Color(0xFF00FF00),
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
      ],
    ),
  );
}

Widget _buildCoursesTab() {
  // Always use User.currentUser for consistent user data
  final currentUser = User.currentUser;
  
  // Get all favorited courses
  final favoriteIds = User.currentUser.favoriteCoursesIds;
  final favoriteCourses = _allCourses
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
                  color: Color(0xFFFF6600),
                ),
                const SizedBox(width: 4),
                Text(
                  '${favoriteCourses.length} ${favoriteCourses.length == 1 ? 'Course' : 'Courses'}',
                  style: TextStyle(
                    color: Color(0xFFFF6600),
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
                    if (widget.onNavigateToCourses != null) {
                      widget.onNavigateToCourses!();
                    }
                  },
                  style: OutlinedButton.styleFrom(
                    backgroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    side: BorderSide(color: Color(0xFF0056AC)!),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    'Browse Courses',
                    style: TextStyle(
                      color: Color(0xFF0056AC),
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
  // Always use User.currentUser for membership tier info as it gets updated during purchases
  final currentUser = User.currentUser;
  
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const SizedBox(height: 16),
      
      // Current Membership Status
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
                  'Membership Type: Associate',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0056AC),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _getTierColor(currentUser.tier),
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
          ],
        ),
      ),

      const SizedBox(height: 24),

      // Membership Tiers
      Text(
        'Available Membership',
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.grey[800],
        ),
      ),
      const SizedBox(height: 16),
      
      // Tier Cards
      _buildTierCard(
        tier: MembershipTier.tier1,
        title: 'Associate Member',
        price: '',
        originalPrice: '',
        discount: '',
        features: [
          'Priority support',
          'Extended resource access',
          'Click to activate (not automatic)',
        ],
        isPopular: false,
        currentUserTier: currentUser.tier,
      ),
      
      // Professional and Specialist tiers hidden for now
      /*
      const SizedBox(height: 12),

      _buildTierCard(
        tier: MembershipTier.tier2,
        title: 'Professional',
        price: '\$299.99 (One-time)',
        originalPrice: '',
        discount: '25%',
        features: [
          '25% discount on all courses',
          'Priority access to new courses',
          'Exclusive webinars',
          'Advanced certifications',
          'Lifetime access',
        ],
        isPopular: false,
        currentUserTier: currentUser.tier,
      ),

      const SizedBox(height: 12),

      _buildTierCard(
        tier: MembershipTier.tier3,
        title: 'Specialist',
        price: '\$599.99 (One-time)',
        originalPrice: '',
        discount: '35%',
        features: [
          '35% discount on all courses',
          'One-on-one mentoring',
          'Early beta access',
          'Custom learning paths',
          'Dedicated account manager',
          'Lifetime access',
        ],
        isPopular: true,
        currentUserTier: currentUser.tier,
      ),

      const SizedBox(height: 12),
      */

      const SizedBox(height: 24),
    ],
  );
}

Widget _buildTierCard({
  required MembershipTier tier,
  required String title,
  required String price,
  required String originalPrice,
  required String discount,
  required List<String> features,
  required bool isPopular,
  required MembershipTier currentUserTier,
}) {
  final isCurrentTier = currentUserTier == tier;
  final canChange = currentUserTier != tier; // Allow both upgrade and downgrade for testing
  
  return Container(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(
        color: isPopular ? Color(0xFFFF6600) : Colors.grey[300]!,
        width: isPopular ? 2 : 1,
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isPopular ? Colors.orange[50] : Colors.grey[50],
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(12),
              topRight: Radius.circular(12),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (isPopular)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Color(0xFFFF6600),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'RECOMMENDED',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
              if (price.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  price,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0056AC),
                  ),
                ),
              ],
              if (discount.isNotEmpty)
                Text(
                  '$discount discount on all courses',
                  style: TextStyle(
                    color: Color(0xFF00FF00),
                    fontWeight: FontWeight.w500,
                  ),
                ),
            ],
          ),
        ),
        
        // Features
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ...features.map((feature) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Icon(
                      Icons.check_circle,
                      color: Color(0xFF00FF00),
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        feature,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                  ],
                ),
              )),
              
              const SizedBox(height: 16),
              
              // Action Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  // onPressed: isCurrentTier ? null : canChange ? () => _purchaseMembership(tier) : null, // Temporarily disabled
                  onPressed: null, // Remove this line and uncomment above to re-enable upgrade functionality
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isCurrentTier 
                        ? Colors.grey[400]
                        : canChange 
                            ? (isPopular ? Color(0xFFFF6600) : Color(0xFF0056AC))
                            : Colors.grey[400],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    isCurrentTier 
                        ? 'Current Plan'
                        : canChange 
                            ? (currentUserTier.index < tier.index ? 'Upgrade Now' : 'Change to This Plan')
                            : 'Not Available',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

Color _getTierColor(MembershipTier tier) {
  switch (tier) {
    case MembershipTier.standard:
      return Colors.grey[600]!;
    case MembershipTier.tier1:
      return Color(0xFF0056AC)!;
    case MembershipTier.tier2:
      return Color(0xFFFF6600)!;
    case MembershipTier.tier3:
      return Colors.purple[600]!;
  }
}

// Clean up any previous payment state
Future<void> _cleanupPreviousPaymentState() async {
  // Small delay to ensure any previous payment screens are fully closed
  await Future.delayed(const Duration(milliseconds: 500));
  
  // Force garbage collection of any lingering payment states
  if (mounted) {
    setState(() {
      // This will trigger a rebuild and clear any cached states
    });
  }
}

// Add this method to handle membership purchase with Xendit
Future<void> _purchaseMembership(MembershipTier tier) async {
  final membershipService = MembershipService();
  final currentUser = _authService.currentUser ?? User.currentUser;
  
  if (currentUser.id.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Please log in to purchase membership')),
    );
    return;
  }
  
  // Show confirmation dialog
  final confirm = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('${currentUser.tier.index < tier.index ? "Upgrade" : "Change"} to ${tier.displayName}'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('You are about to ${currentUser.tier.index < tier.index ? "upgrade" : "change"} to ${tier.displayName}'),
          const SizedBox(height: 8),
          Text('Benefits: ${tier.benefits}'),
          const SizedBox(height: 8),
          Text('Price: ${tier == MembershipTier.tier1 ? "FREE for 1 year" : tier == MembershipTier.tier2 ? "IDR 10,000 (Test)" : "IDR 20,000 (Test)"}'),
          if (tier == MembershipTier.tier1)
            const Text(
              'Special Offer: First year completely FREE!',
              style: TextStyle(
                color: Color(0xFF00FF00),
                fontWeight: FontWeight.bold,
              ),
            ),
          if (tier != MembershipTier.tier1)
            Container(
              margin: const EdgeInsets.only(top: 8),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: const Text(
                '🧪 Test Mode: Use test payment methods only',
                style: TextStyle(
                  color: Color(0xFF0056AC),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, true),
          child: Text('Confirm ${currentUser.tier.index < tier.index ? "Upgrade" : "Change"}'),
        ),
      ],
    ),
  );
  
  if (confirm == true) {
    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );
    
    try {
      // Clean up any previous payment state
      await _cleanupPreviousPaymentState();
      
      // Create payment invoice
      final paymentResult = await membershipService.createPaymentInvoice(
        userId: currentUser.id,
        tier: tier,
        currentUser: currentUser,
      );
      
      Navigator.pop(context); // Close loading dialog
      
      if (paymentResult.success) {
        if (tier == MembershipTier.tier1) {
          // Free tier, process immediately
          final success = await membershipService.processMembershipPurchase(
            userId: currentUser.id,
            tier: tier,
            currentUser: currentUser,
            invoiceId: paymentResult.invoiceId,
          );
          
          _handlePaymentResult(success, tier, paymentResult.invoiceId);
        } else {
          // Paid tier, show payment screen
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PaymentScreen(
                tier: tier,
                invoiceUrl: paymentResult.invoiceUrl!,
                invoiceId: paymentResult.invoiceId!,
                onPaymentComplete: (success, invoiceId) {
                  _handlePaymentComplete(success, tier, invoiceId);
                },
              ),
            ),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create payment: ${paymentResult.errorMessage}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      Navigator.pop(context); // Close loading dialog
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

// Handle payment completion
Future<void> _handlePaymentComplete(bool success, MembershipTier tier, String? invoiceId) async {
  if (success && invoiceId != null) {
    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );
    
    // Process membership purchase
    final membershipService = MembershipService();
    final currentUser = User.currentUser;
    
    final purchaseSuccess = await membershipService.processMembershipPurchase(
      userId: currentUser.id,
      tier: tier,
      currentUser: currentUser,
      invoiceId: invoiceId,
    );
    
    Navigator.pop(context); // Close loading dialog
    
    _handlePaymentResult(purchaseSuccess, tier, invoiceId);
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Payment was cancelled or failed'),
        backgroundColor: Color(0xFFFF6600),
      ),
    );
  }
}

// Handle payment result
void _handlePaymentResult(bool success, MembershipTier tier, String? invoiceId) {
  if (success) {
    setState(() {}); // Refresh UI
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Successfully changed to ${tier.displayName}!'),
        backgroundColor: Color(0xFF00FF00),
      ),
    );
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Failed to process membership. Please try again.'),
        backgroundColor: Colors.red,
      ),
    );
  }
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
  
  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    bool isGreen = color == const Color(0xFF00FF00);
    Color textColor = isGreen ? const Color(0xD9013220) : color;
    Color bgColor = isGreen ? color : color.withOpacity(0.2);
    Color borderColor = isGreen ? const Color(0xD9013220) : color.withOpacity(0.3);

    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: textColor,
              size: 24,
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 11,
                color: textColor,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
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
                    color: Color(0xFF0056AC),
                  ),
                ),
                Text(
                  _getMonthAbbreviation(schedule.date.month),
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF0056AC),
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
                color: schedule.isPending ? Color(0xFFFF6600) : Color(0xFF00FF00),
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
              color: Color(0xFF0056AC),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: Color(0xFF0056AC),
              ),
            ),
          ),
        ],
      ),
    );
  }
}