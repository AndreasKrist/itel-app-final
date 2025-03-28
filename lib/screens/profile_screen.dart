import 'package:flutter/material.dart';
import '../models/course.dart';
import '../models/user.dart';
import '../models/schedule.dart';
import 'course_outline_screen.dart';
import 'package:table_calendar/table_calendar.dart';
import '../widgets/enrolled_course_card.dart';
import '../models/enrolled_course.dart';
import '../services/auth_service.dart';

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
  String activeTab = 'profile'; // Default tab is profile
  bool _showCalendar = false;
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();
  CalendarFormat _calendarFormat = CalendarFormat.month;
  
  // Add Auth Service
  final AuthService _authService = AuthService();

  void _toggleFavorite(Course course) {
    setState(() {
      final firebaseUser = _authService.currentUser;
      final currentUser = firebaseUser ?? User.currentUser;
      
      List<String> updatedFavorites = List.from(currentUser.favoriteCoursesIds);
      if (updatedFavorites.contains(course.id)) {
        updatedFavorites.remove(course.id);
      } else {
        updatedFavorites.add(course.id);
      }
      User.currentUser = User.currentUser.copyWith(
        favoriteCoursesIds: updatedFavorites,
      );
    });
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
                              // Return a list of events for the given day
                              return Schedule.getDummySchedules()
                                  .where((schedule) => isSameDay(schedule.date, day))
                                  .toList();
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
                                'Sessions on ${_selectedDay.day}/${_selectedDay.month}/${_selectedDay.year}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Colors.blue[800],
                                ),
                              ),
                              const SizedBox(height: 8),
                              
                              // List events for the selected day
                              ...Schedule.getDummySchedules()
                                  .where((schedule) => isSameDay(schedule.date, _selectedDay))
                                  .map((schedule) => Padding(
                                    padding: const EdgeInsets.only(bottom: 8.0),
                                    child: Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: Colors.blue[100]!),
                                      ),
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
                                          Row(
                                            children: [
                                              Icon(Icons.access_time_filled, 
                                                size: 14, 
                                                color: Colors.blue[700]
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                '${schedule.startTime} - ${schedule.endTime}',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey[700],
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              Icon(Icons.location_on, 
                                                size: 14, 
                                                color: Colors.blue[700]
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                schedule.location ?? 'Online',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey[700],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  )),
                              
                              if (Schedule.getDummySchedules()
                                  .where((schedule) => isSameDay(schedule.date, _selectedDay))
                                  .isEmpty)
                                Center(
                                  child: Padding(
                                    padding: const EdgeInsets.all(12.0),
                                    child: Text(
                                      'No scheduled sessions',
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
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
    final firebaseUser = _authService.currentUser;
    
    // Use Firebase user data or fall back to static data if not available
    final currentUser = firebaseUser ?? User.currentUser;
    
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
              Text(
                'Personal Information',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              _buildInfoRow('Email', currentUser.email),
              _buildInfoRow('Phone', currentUser.phone),
              if (currentUser.company != null)
                _buildInfoRow('Company', currentUser.company!),
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
              if (activeEnrollments.isNotEmpty) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'My Enrolled Courses',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                
                // List enrolled courses
                ...activeEnrollments.map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: EnrolledCourseCard(
                    enrollment: item['enrollment'] as EnrolledCourse,
                    course: item['course'] as Course,
                  ),
                )),
              ],
              
              const SizedBox(height: 16),
              
              // Pending Enrollments section
              if (pendingEnrollments.isNotEmpty) ...[
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
                
                // List pending enrollments
                ...pendingEnrollments.map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: EnrolledCourseCard(
                    enrollment: item['enrollment'] as EnrolledCourse,
                    course: item['course'] as Course,
                  ),
                )),
              ],
              
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
        
        // Edit Profile Button
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: () {},
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              side: BorderSide(color: Colors.grey[300]!),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Edit Profile'),
          ),
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
    final favoriteIds = currentUser.favoriteCoursesIds;
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
              'Liked Courses',
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
                    'Your liked courses is empty',
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
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: favoriteCourses.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final course = favoriteCourses[index];
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
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                course.title,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                course.category,
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 14,
                                ),
                              ),
                              if (course.certType != null) ...[
                                const SizedBox(height: 4),
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
                              ],
                            ],
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.favorite,
                            color: Colors.pink[400],
                          ),
                          onPressed: () => _toggleFavorite(course),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Row(
                          children: [
                            Icon(Icons.access_time, color: Colors.grey[400], size: 16),
                            const SizedBox(width: 4),
                            Text(
                              course.duration,
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 16),
                        Row(
                          children: [
                            Icon(Icons.attach_money, color: Colors.grey[400], size: 16),
                            const SizedBox(width: 4),
                            Text(
                              course.price,
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        if (course.nextAvailableDate != null)
                          Text(
                            'Next start: ${course.nextAvailableDate}',
                            style: TextStyle(
                              color: Colors.blue[700],
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          )
                        else
                          const SizedBox(),
                        TextButton(
                          onPressed: () {
                            // Navigate to course outline instead of details
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => CourseOutlineScreen(course: course),
                              ),
                            );
                          },
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Text(
                            'View Outline',
                            style: TextStyle(
                              color: Colors.blue[600],
                              fontWeight: FontWeight.w500,
                            ),
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