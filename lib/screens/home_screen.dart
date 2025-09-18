import 'package:flutter/material.dart';
import '../models/course.dart';
import '../models/trending_item.dart';
import '../models/user.dart';
import '../widgets/course_card.dart';
import '../widgets/trending_card.dart';
import '../services/user_preferences_service.dart';
import '../services/auth_service.dart';
import '../services/trending_content_service.dart';

class HomeScreen extends StatefulWidget {
  final Function(String)? onCategorySelected;
  
  const HomeScreen({super.key, this.onCategorySelected});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Course> courses = Course.sampleCourses;
  List<TrendingItem> trendingItems = [];
  bool _isLoading = true;
  final TrendingContentService _contentService = TrendingContentService();
  
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
    // Load trending content
    _loadTrendingContent();
  }

  Future<void> _loadTrendingContent() async {
    try {
      final allItems = await _contentService.getTrendingContent();
      if (mounted) {
        setState(() {
          trendingItems = _getHomeTrendingItems(allItems);
          _isLoading = false;
        });
      }
    } catch (e) {
      // Fallback to static content if dynamic loading fails
      if (mounted) {
        setState(() {
          trendingItems = _getHomeTrendingItems(TrendingItem.sampleItems);
          _isLoading = false;
        });
      }
    }
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
    final popularCourseIds = ['29', '30', '32', '33', '34', '35', '37', '41', '42', '43', '45', '54', '56', '57', '59', '120', '121', '127', '139', '141', '174', '175', '179', '194', '198', '199', '200', '202', '203', '206', '208', '209', '211', '212']; // Replace with your selected course IDs
    
    List<Course> baseList = _isSearching ? filteredCourses : courses;
    return baseList.where((course) => popularCourseIds.contains(course.id)).toList();
  }

  // Get funded courses
  List<Course> get fundedCourses {
    // Define specific course IDs for funded courses
    final fundedCourseIds = ['29', '30', '31', '32', '33', '34', '35', '36', '37', '38', '39', '40', '41', '42', '43', '44', '45', '46', '62', '64', '65', '66', '108', '113', '139', '181', '193', '194', '195', '196', '197', '198', '199', '200', '201', '202', '203', '204', '205', '206', '207', '208', '209', '210', '211', '212']; // You can assign specific course IDs here
    
    List<Course> baseList = _isSearching ? filteredCourses : courses;
    return baseList.where((course) => fundedCourseIds.contains(course.id)).toList();
  }

  // Get SCTP courses
  List<Course> get sctpCourses {
    // Define specific course IDs for SCTP courses
    final sctpCourseIds = ['113', '193']; // You can assign specific course IDs here
    
    List<Course> baseList = _isSearching ? filteredCourses : courses;
    return baseList.where((course) => sctpCourseIds.contains(course.id)).toList();
  }

  // Get trending items for home screen - one from each category
  static List<TrendingItem> _getHomeTrendingItems(List<TrendingItem> allItems) {
    List<TrendingItem> homeItems = [];
    
    // Get one item from each category
    final upcomingEvents = allItems.where((item) => item.type == TrendingItemType.upcomingEvents).take(1);
    final coursePromotion = allItems.where((item) => item.type == TrendingItemType.coursePromotion).take(1);
    final featuredArticles = allItems.where((item) => item.type == TrendingItemType.featuredArticles).take(1);
    final techTips = allItems.where((item) => item.type == TrendingItemType.techTipsOfTheWeek).take(1);
    final courseAssessor = allItems.where((item) => item.type == TrendingItemType.courseAssessor).take(1);
    
    homeItems.addAll(upcomingEvents);
    homeItems.addAll(coursePromotion);
    homeItems.addAll(featuredArticles);
    homeItems.addAll(techTips);
    homeItems.addAll(courseAssessor);
    
    return homeItems;
  }

  // Get course disciplines/categories
  List<Map<String, String>> get courseDisciplines {
    return [
      {'name': 'AI & IoT', 'icon': 'smart_toy'},
      {'name': 'Big Data | Analytics | Database', 'icon': 'analytics'},
      {'name': 'Business Operations', 'icon': 'business'},
      {'name': 'Cloud Computing & Virtualization', 'icon': 'cloud'},
      {'name': 'Cybersecurity', 'icon': 'security'},
      {'name': 'DevOps', 'icon': 'developer_mode'},
      {'name': 'IT Business Management & Strategy', 'icon': 'business_center'},
      {'name': 'Mobile & App Technology', 'icon': 'phone_android'},
      {'name': 'Networking Infrastructure & Architecture', 'icon': 'network_wifi'},
      {'name': 'Programming', 'icon': 'code'},
    ];
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            color: Colors.blue[700],
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                width: 60,
                height: 60,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Image.asset(
                  'assets/images/itel.png',
                  fit: BoxFit.contain,
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: 16),
                  child: Text(
                    'Technology Training',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                    textAlign: TextAlign.right,
                  ),
                ),
              ),
              ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Search bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
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
          ),

          const SizedBox(height: 16),

          // Search results or regular content
          if (_isSearching) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
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
                ],
              ),
            ),
          ] else ...[
            // Regular content when not searching
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Popular Courses
                  Text(
                    'Popular Courses',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[800],
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
                            color: Colors.blue[800],
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
                  
                  // Funded Courses
                  if (fundedCourses.isNotEmpty) ...[
                    Text(
                      'Funded Courses',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[800],
                          ),
                    ),
                    const SizedBox(height: 16),
                    
                    SizedBox(
                      height: 230,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: fundedCourses.length,
                        separatorBuilder: (context, index) => const SizedBox(width: 12),
                        itemBuilder: (context, index) => SizedBox(
                          width: MediaQuery.of(context).size.width * 0.85,
                          child: CourseCard(
                            course: fundedCourses[index],
                            onFavoriteToggle: _toggleFavorite,
                          ),
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                  ],
                  
                  // SCTP Courses
                  if (sctpCourses.isNotEmpty) ...[
                    Text(
                      'SCTP Courses',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[800],
                          ),
                    ),
                    const SizedBox(height: 16),
                    
                    SizedBox(
                      height: 230,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: sctpCourses.length,
                        separatorBuilder: (context, index) => const SizedBox(width: 12),
                        itemBuilder: (context, index) => SizedBox(
                          width: MediaQuery.of(context).size.width * 0.85,
                          child: CourseCard(
                            course: sctpCourses[index],
                            onFavoriteToggle: _toggleFavorite,
                          ),
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                  ],
                ],
              ),
            ),
            
            // Course Discipline Section with background
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[200],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Course Discipline',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 16),
                  
                  SizedBox(
                    height: 180,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: courseDisciplines.length,
                      separatorBuilder: (context, index) => const SizedBox(width: 12),
                      itemBuilder: (context, index) => SizedBox(
                        width: MediaQuery.of(context).size.width * 0.45,
                        child: _buildDisciplineCard(courseDisciplines[index]),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // What's Trending Section with darker background
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[300],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "What's Trending",
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 16),
                  _isLoading
                      ? const Center(
                          child: Padding(
                            padding: EdgeInsets.all(20.0),
                            child: CircularProgressIndicator(),
                          ),
                        )
                      : trendingItems.isEmpty
                          ? const Center(
                              child: Padding(
                                padding: EdgeInsets.all(20.0),
                                child: Text('No trending content available'),
                              ),
                            )
                          : ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: trendingItems.length,
                              separatorBuilder: (context, index) => const SizedBox(height: 12),
                              itemBuilder: (context, index) => TrendingCard(
                                item: trendingItems[index],
                              ),
                            ),
                ],
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
  
  Widget _buildDisciplineCard(Map<String, String> discipline) {
    return Container(
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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            // Switch to courses tab with category filter
            widget.onCategorySelected?.call(discipline['name']!);
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _getIconData(discipline['icon']!),
                    size: 32,
                    color: Colors.blue[700],
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  discipline['name']!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'smart_toy':
        return Icons.smart_toy;
      case 'analytics':
        return Icons.analytics;
      case 'business':
        return Icons.business;
      case 'cloud':
        return Icons.cloud;
      case 'security':
        return Icons.security;
      case 'developer_mode':
        return Icons.developer_mode;
      case 'business_center':
        return Icons.business_center;
      case 'phone_android':
        return Icons.phone_android;
      case 'network_wifi':
        return Icons.network_wifi;
      case 'code':
        return Icons.code;
      default:
        return Icons.category;
    }
  }
}