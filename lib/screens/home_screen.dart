import 'package:flutter/material.dart';
import '../models/course.dart';
import '../models/trending_item.dart';
import '../models/user.dart';
import '../widgets/course_card.dart';
import '../widgets/trending_card.dart';
import '../services/user_preferences_service.dart';
import '../services/auth_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Course> courses = Course.sampleCourses;
  List<TrendingItem> trendingItems = TrendingItem.sampleItems.take(2).toList();
  final bool _isLoading = false;
  
  // Service instances
  final UserPreferencesService _preferencesService = UserPreferencesService();
  final AuthService _authService = AuthService();
  
  // Search controller and query
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isSearching = false;
  
  @override
  void initState() {
    super.initState();
    // Add listener to search controller
    _searchController.addListener(_onSearchChanged);
  }
  
  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }
  
  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text;
      _isSearching = _searchQuery.isNotEmpty;
    });
  }
  
  // Replace the _toggleFavorite method in home_screen.dart
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
  
  void _clearSearch() {
    setState(() {
      _searchController.clear();
      _searchQuery = '';
      _isSearching = false;
    });
  }

  // Get filtered courses based on search query
  List<Course> get filteredCourses {
    if (_searchQuery.isEmpty) {
      return courses;
    }
    
    String query = _searchQuery.toLowerCase();
    return courses.where((course) {
      // Search in title, category, course code, and certification type
      return course.title.toLowerCase().contains(query) ||
             course.category.toLowerCase().contains(query) ||
             course.courseCode.toLowerCase().contains(query) ||
             (course.certType?.toLowerCase().contains(query) ?? false) ||
             (course.description?.toLowerCase().contains(query) ?? false);
    }).toList();
  }

  // Get complimentary courses (free courses)
  List<Course> get complimentaryCourses {
    List<Course> baseList = _isSearching ? filteredCourses : courses;
    return baseList.where((course) => 
      course.price == '\$0' || 
      course.price.contains('Free') || 
      course.funding == 'Complimentary').toList();
  }

  // Get popular courses (excluding complimentary courses)
  List<Course> get popularCourses {
    // Define specific course IDs that you want to show as popular
    final popularCourseIds = ['1276', '5272', '794', '5665', '1278', '1458', '5284', '1850', '5285', '1344', '5274', '1345', '5275', '1350', '5279', '1315', '5282', '1408', '940', '1997', '2047', '2056', '5286', '5291', '5280', '1441']; // Replace with your selected course IDs
    
    List<Course> baseList = _isSearching ? filteredCourses : courses;
    return baseList.where((course) => popularCourseIds.contains(course.id)).toList();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome to ITEL',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  Text(
                    'Discover your next course',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    'PRO',
                    style: TextStyle(
                      color: Colors.blue[700],
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          // Search bar
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search courses...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _isSearching 
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: _clearSearch,
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: Colors.grey[200]!),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: Colors.grey[200]!),
                ),
              ),
              onSubmitted: (value) {
                setState(() {
                  _searchQuery = value;
                  _isSearching = value.isNotEmpty;
                });
              },
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Search results or regular content
          if (_isSearching) ...[
            // Search results header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Search Results',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                Text(
                  '${filteredCourses.length} found',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Display search results
            if (filteredCourses.isEmpty)
              _buildEmptySearchResults()
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: filteredCourses.length,
                separatorBuilder: (context, index) => const SizedBox(height: 12),
                itemBuilder: (context, index) => CourseCard(
                  course: filteredCourses[index],
                  onFavoriteToggle: _toggleFavorite,
                ),
              ),
          ] else ...[
            // Regular content when not searching
            // Popular Courses
            Text(
              'Popular Courses',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            
            SizedBox(
              height: 230, // Fixed height for the horizontal scroll view
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: popularCourses.length,
                separatorBuilder: (context, index) => const SizedBox(width: 12),
                itemBuilder: (context, index) => SizedBox(
                  width: MediaQuery.of(context).size.width * 0.85, // Control the width of each card
                  child: CourseCard(
                    course: popularCourses[index],
                    onFavoriteToggle: _toggleFavorite,
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Complimentary Courses
            if (complimentaryCourses.isNotEmpty) ...[
              Text(
                'Complimentary Courses',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 16),
              
              SizedBox(
                height: 230, // Fixed height for the horizontal scroll view
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: complimentaryCourses.length,
                  separatorBuilder: (context, index) => const SizedBox(width: 12),
                  itemBuilder: (context, index) => SizedBox(
                    width: MediaQuery.of(context).size.width * 0.85, // Control the width of each card
                    child: CourseCard(
                      course: complimentaryCourses[index],
                      onFavoriteToggle: _toggleFavorite,
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
            ],
            
            // What's Trending
            Text(
              "What's Trending",
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: trendingItems.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) => TrendingCard(
                item: trendingItems[index],
              ),
            ),
          ],
        ],
      ),
    );
  }
  
  Widget _buildEmptySearchResults() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          Icon(
            Icons.search_off,
            size: 48,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No courses found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try adjusting your search terms',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: _clearSearch,
            icon: const Icon(Icons.refresh),
            label: const Text('Clear search'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }
}