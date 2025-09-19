import 'package:flutter/material.dart';
import '../models/course.dart';
import '../models/course_category.dart';
import '../models/user.dart';
import '../widgets/course_card.dart';
import '../widgets/filter_modal.dart';
import '../widgets/sort_modal.dart';
import '../services/user_preferences_service.dart';
import '../services/auth_service.dart';
import '../services/course_remote_config_service.dart';

class CoursesScreen extends StatefulWidget {
  final String? initialCategory;
  
  const CoursesScreen({super.key, this.initialCategory});

  @override
  State<CoursesScreen> createState() => _CoursesScreenState();
}

class _CoursesScreenState extends State<CoursesScreen> {
  List<Course> courses = [];
  Map<String, String> activeFilters = {
    'funding': 'all',
    'duration': 'all',
    'certType': 'all',
    'category': 'all',
  };
  String activeSort = 'none';
  bool showFilters = false;
  bool showSortOptions = false;
  bool _isLoading = true;

  // Service instances
  final UserPreferencesService _preferencesService = UserPreferencesService();
  final AuthService _authService = AuthService();
  final CourseRemoteConfigService _courseRemoteConfigService = CourseRemoteConfigService();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isSearching = false;

  @override
void initState() {
  super.initState();
  // Add listener to search controller
  _searchController.addListener(_onSearchChanged);

  // Set initial category if provided
  if (widget.initialCategory != null) {
    activeFilters['category'] = widget.initialCategory!;
  }

  // Load courses from remote configuration
  _loadCourses();
}

Future<void> _loadCourses() async {
  try {
    setState(() {
      _isLoading = true;
    });

    final remoteCourses = await _courseRemoteConfigService.getRemoteCourses();

    setState(() {
      courses = remoteCourses;
      _isLoading = false;
    });

    print('Loaded ${courses.length} courses from remote configuration');
  } catch (e) {
    print('Error loading courses: $e');

    // Fallback to sample courses if remote loading fails
    setState(() {
      courses = Course.sampleCourses;
      _isLoading = false;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Using offline course data'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }
}

Future<void> _refreshCourses() async {
  try {
    setState(() {
      _isLoading = true;
    });

    final remoteCourses = await _courseRemoteConfigService.refreshCourses();

    setState(() {
      courses = remoteCourses;
      _isLoading = false;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Courses updated successfully'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  } catch (e) {
    setState(() {
      _isLoading = false;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to refresh courses: $e'),
          duration: const Duration(seconds: 3),
        ),
      );
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

void _clearSearch() {
  setState(() {
    _searchController.clear();
    _searchQuery = '';
    _isSearching = false;
  });
}

  // Replace the _toggleFavorite method in courses_screen.dart
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
      tier: User.currentUser.tier,
      membershipExpiryDate: User.currentUser.membershipExpiryDate,
      favoriteCoursesIds: updatedFavorites,
      enrolledCourses: User.currentUser.enrolledCourses,
      courseHistory: User.currentUser.courseHistory,
    );

    print('Successfully updated favorites in courses screen: ${updatedFavorites.length} items');
  } catch (e) {
    print('Error toggling favorite: $e');
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update favorite: ${e.toString()}')),
      );
    }
  }
}

  List<Course> get filteredCourses {
    // Start with all courses
    List<Course> result = courses;
    
    // Apply search filter first if there's a search query
  if (_searchQuery.isNotEmpty) {
    String query = _searchQuery.toLowerCase();
    result = result.where((course) {
      // Search in title, category, course code, and certification type
      return course.title.toLowerCase().contains(query) ||
             course.category.toLowerCase().contains(query) ||
             course.courseCode.toLowerCase().contains(query) ||
             (course.certType?.toLowerCase().contains(query) ?? false) ||
             (course.description?.toLowerCase().contains(query) ?? false);
    }).toList();
  }
  
  // Apply funding filter
  if (activeFilters['funding'] != 'all') {
    if (activeFilters['funding'] == 'available') {
      result = result.where((course) => course.funding?.contains('Eligible') ?? false).toList();
    } else if (activeFilters['funding'] == 'none') {
      result = result.where((course) => course.funding == null || course.funding!.contains('Not eligible')).toList();
    } else if (activeFilters['funding'] == 'free') {
      result = result.where((course) => course.price.contains('Free') || course.price == '\$0').toList();
    }
  }
    
    // Apply duration filter
    if (activeFilters['duration'] != 'all') {
      if (activeFilters['duration'] == 'short') {
        // Filter for short courses (< 2 days)
        result = result.where((course) {
          final durationLower = course.duration.toLowerCase();
          final numericPart = int.tryParse(course.duration.split(' ')[0]) ?? 0;

          if (durationLower.contains('day')) {
            return numericPart < 2;
          } else if (durationLower.contains('hour')) {
            return numericPart < 48; // Less than 48 hours (2 days)
          } else if (durationLower.contains('minute')) {
            return numericPart < 2880; // Less than 2880 minutes (2 days)
          } else if (durationLower.contains('week') || durationLower.contains('month')) {
            return false; // Weeks and months are always long
          }
          return false;
        }).toList();
      } else if (activeFilters['duration'] == 'long') {
        // Filter for long courses (2+ days)
        result = result.where((course) {
          final durationLower = course.duration.toLowerCase();
          final numericPart = int.tryParse(course.duration.split(' ')[0]) ?? 0;

          if (durationLower.contains('day')) {
            return numericPart >= 2;
          } else if (durationLower.contains('hour')) {
            return numericPart >= 48; // 48+ hours (2+ days)
          } else if (durationLower.contains('minute')) {
            return numericPart >= 2880; // 2880+ minutes (2+ days)
          } else if (durationLower.contains('week') || durationLower.contains('month')) {
            return true; // Weeks and months are always long
          }
          return false;
        }).toList();
      }
    }
    
    // Apply cert type filter
    if (activeFilters['certType'] != 'all') {
      result = result.where((course) => course.certType == activeFilters['certType']).toList();
    }
    
    // Apply category filter
    if (activeFilters['category'] != 'all') {
      result = result.where((course) => course.category == activeFilters['category']).toList();
    }
    
    // Apply sorting
    if (activeSort == 'priceLow') {
      return List.from(result)..sort((a, b) {
        final aPriceStr = a.price.replaceAll(RegExp(r'[^\d.]'), '');
        final bPriceStr = b.price.replaceAll(RegExp(r'[^\d.]'), '');
        final aPrice = double.tryParse(aPriceStr);
        final bPrice = double.tryParse(bPriceStr);

        // If both have numeric prices, compare normally
        if (aPrice != null && bPrice != null) {
          return aPrice.compareTo(bPrice);
        }
        // If only a has numeric price, a comes first
        if (aPrice != null && bPrice == null) {
          return -1;
        }
        // If only b has numeric price, b comes first
        if (aPrice == null && bPrice != null) {
          return 1;
        }
        // If both are non-numeric, sort alphabetically
        return a.price.compareTo(b.price);
      });
    } else if (activeSort == 'priceHigh') {
      return List.from(result)..sort((a, b) {
        final aPriceStr = a.price.replaceAll(RegExp(r'[^\d.]'), '');
        final bPriceStr = b.price.replaceAll(RegExp(r'[^\d.]'), '');
        final aPrice = double.tryParse(aPriceStr);
        final bPrice = double.tryParse(bPriceStr);

        // If both have numeric prices, compare in reverse order
        if (aPrice != null && bPrice != null) {
          return bPrice.compareTo(aPrice);
        }
        // If only a has numeric price, a comes first
        if (aPrice != null && bPrice == null) {
          return -1;
        }
        // If only b has numeric price, b comes first
        if (aPrice == null && bPrice != null) {
          return 1;
        }
        // If both are non-numeric, sort alphabetically
        return a.price.compareTo(b.price);
      });
    } else if (activeSort == 'durationLow') {
      return List.from(result)..sort((a, b) {
        // Get numeric duration in hours for precise comparison
        int getDurationInHours(String duration) {
          final durationLower = duration.toLowerCase();
          final numericPart = int.tryParse(duration.split(' ')[0]) ?? 0;

          if (durationLower.contains('day')) {
            return numericPart * 24; // Convert days to hours
          } else if (durationLower.contains('week')) {
            return numericPart * 7 * 24; // Convert weeks to hours
          } else if (durationLower.contains('month')) {
            return numericPart * 30 * 24; // Convert months to hours
          } else if (durationLower.contains('hour')) {
            return numericPart; // Already in hours
          } else if (durationLower.contains('minute')) {
            return (numericPart / 60).ceil(); // Convert minutes to hours
          }
          return 0;
        }
        
        final aDuration = getDurationInHours(a.duration);
        final bDuration = getDurationInHours(b.duration);
        return aDuration.compareTo(bDuration);
      });
    } else if (activeSort == 'durationHigh') {
      return List.from(result)..sort((a, b) {
        // Get numeric duration in hours for precise comparison
        int getDurationInHours(String duration) {
          final durationLower = duration.toLowerCase();
          final numericPart = int.tryParse(duration.split(' ')[0]) ?? 0;

          if (durationLower.contains('day')) {
            return numericPart * 24; // Convert days to hours
          } else if (durationLower.contains('week')) {
            return numericPart * 7 * 24; // Convert weeks to hours
          } else if (durationLower.contains('month')) {
            return numericPart * 30 * 24; // Convert months to hours
          } else if (durationLower.contains('hour')) {
            return numericPart; // Already in hours
          } else if (durationLower.contains('minute')) {
            return (numericPart / 60).ceil(); // Convert minutes to hours
          }
          return 0;
        }
        
        final aDuration = getDurationInHours(a.duration);
        final bDuration = getDurationInHours(b.duration);
        return bDuration.compareTo(aDuration);
      });
    }

    // Default ordering: show complimentary/free courses first when no sorting is applied
    if (activeSort == 'none') {
      return List.from(result)..sort((a, b) {
        final aIsFree = a.price.toLowerCase().contains('free') ||
                       a.price.contains('\$0') ||
                       a.price == '0';
        final bIsFree = b.price.toLowerCase().contains('free') ||
                       b.price.contains('\$0') ||
                       b.price == '0';

        // If only one is free, free comes first
        if (aIsFree && !bIsFree) return -1;
        if (!aIsFree && bIsFree) return 1;

        // If both are free or both are paid, maintain original order
        return 0;
      });
    }

    return result;
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Stack(
        children: [
          RefreshIndicator(
            onRefresh: _refreshCourses,
            child: SingleChildScrollView(
              padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.04),
              physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: MediaQuery.of(context).size.width * 0.1,
                        height: MediaQuery.of(context).size.width * 0.1,
                        padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.015),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Image.asset(
                          'assets/images/itel.png',
                          fit: BoxFit.contain,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Courses',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      // Sort button
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            showSortOptions = true;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: activeSort != 'none' 
                                ? Colors.orange[100] 
                                : Colors.grey[200],
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.sort,
                                size: 18,
                                color: activeSort != 'none' 
                                    ? Colors.orange[700] 
                                    : Colors.grey[700],
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Sort',
                                style: TextStyle(
                                  color: activeSort != 'none' 
                                      ? Colors.orange[700] 
                                      : Colors.grey[700],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Filter button
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            showFilters = true;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: activeFilters.values.any((value) => value != 'all')
                                ? Colors.blue[100] 
                                : Colors.grey[200],
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.filter_list,
                                size: 18,
                                color: activeFilters.values.any((value) => value != 'all')
                                    ? Colors.blue[700] 
                                    : Colors.grey[700],
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Filter',
                                style: TextStyle(
                                  color: activeFilters.values.any((value) => value != 'all')
                                      ? Colors.blue[700] 
                                      : Colors.grey[700],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              // Search bar
const SizedBox(height: 16),
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
              
              // Category chips
              const SizedBox(height: 16),
              SizedBox(
                height: 40,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: CourseCategory.values.length + 1, // +1 for "All" chip
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      // "All" chip
                      return _buildCategoryChip(
                        'All',
                        activeFilters['category'] == 'all',
                        () {
                          setState(() {
                            activeFilters['category'] = 'all';
                          });
                        },
                      );
                    }
                    
                    final category = CourseCategory.values[index - 1];
                    return _buildCategoryChip(
                      category.displayName,
                      activeFilters['category'] == category.displayName,
                      () {
                        setState(() {
                          activeFilters['category'] = category.displayName;
                        });
                      },
                    );
                  },
                ),
              ),
              
              // Active filters display
              if (activeFilters.values.any((value) => value != 'all') || activeSort != 'none' || _isSearching) ...[
                const SizedBox(height: 16),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      if (activeFilters['funding'] != 'all')
                        _buildFilterChip(
                          'Funding: ${_getDisplayText('funding', activeFilters['funding']!)}',
                          () {
                            setState(() {
                              activeFilters['funding'] = 'all';
                            });
                          },
                          Colors.blue,
                        ),
                        
                      if (activeFilters['duration'] != 'all')
                        _buildFilterChip(
                          'Duration: ${_getDisplayText('duration', activeFilters['duration']!)}',
                          () {
                            setState(() {
                              activeFilters['duration'] = 'all';
                            });
                          },
                          Colors.blue,
                        ),
                        
                      if (activeFilters['certType'] != 'all')
                        _buildFilterChip(
                          'Cert: ${activeFilters['certType']}',
                          () {
                            setState(() {
                              activeFilters['certType'] = 'all';
                            });
                          },
                          Colors.blue,
                        ),
                        
                      if (activeFilters['category'] != 'all')
                        _buildFilterChip(
                          'Category: ${_getDisplayText('category', activeFilters['category']!)}',
                          () {
                            setState(() {
                              activeFilters['category'] = 'all';
                            });
                          },
                          Colors.blue,
                        ),
                        
                      if (activeSort != 'none')
                        _buildFilterChip(
                          'Sort: ${_getDisplayText('sort', activeSort)}',
                          () {
                            setState(() {
                              activeSort = 'none';
                            });
                          },
                          Colors.orange,
                        ),
                        
                      if (activeFilters.values.any((value) => value != 'all') || activeSort != 'none')
                        TextButton(
                          onPressed: () {
                            setState(() {
                              activeFilters = {
                                'funding': 'all',
                                'duration': 'all',
                                'certType': 'all',
                                'category': 'all',
                              };
                              activeSort = 'none';
                            });
                          },
                          child: Text(
                            'Clear All',
                            style: TextStyle(
                              color: Colors.red[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
              
              const SizedBox(height: 24),
              
              if (filteredCourses.isEmpty)
                Container(
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
                        'Try adjusting your filters or search criteria',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                )
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
        ),
        
        // Filter modal
        if (showFilters)
          GestureDetector(
            onTap: () {
              setState(() {
                showFilters = false;
              });
            },
            child: Container(
              color: Colors.black.withOpacity(0.5),
              child: Center(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 24),
                  child: FilterModal(
                    activeFilters: activeFilters,
                    onFiltersChanged: (filters) {
                      setState(() {
                        activeFilters = filters;
                      });
                    },
                    onApply: () {
                      setState(() {
                        showFilters = false;
                      });
                    },
                    onCancel: () {
                      setState(() {
                        // Reset to previous values
                        activeFilters = {
                          'funding': 'all',
                          'duration': 'all',
                          'certType': 'all',
                        };
                        showFilters = false;
                      });
                    },
                  ),
                ),
              ),
            ),
          ),
          
        // Sort modal
        if (showSortOptions)
          GestureDetector(
            onTap: () {
              setState(() {
                showSortOptions = false;
              });
            },
            child: Container(
              color: Colors.black.withOpacity(0.5),
              child: Center(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 24),
                  child: SortModal(
                    activeSort: activeSort,
                    onSortChanged: (sort) {
                      setState(() {
                        activeSort = sort;
                      });
                    },
                    onApply: () {
                      setState(() {
                        showSortOptions = false;
                      });
                    },
                    onCancel: () {
                      setState(() {
                        activeSort = 'none';
                        showSortOptions = false;
                      });
                    },
                  ),
                ),
              ),
            ),
          ),
            
        // Optional loading overlay
        if (_isLoading)
          Container(
            color: Colors.black.withOpacity(0.3),
            child: const Center(
              child: CircularProgressIndicator(),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildFilterChip(String label, VoidCallback onRemove, MaterialColor color) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color[100]!),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              color: color[700],
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onRemove,
            child: Icon(
              Icons.close,
              size: 16,
              color: color[700],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildCategoryChip(String label, bool isActive, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? Colors.blue[600] : Colors.grey[200],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? Colors.white : Colors.grey[700],
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
  
  String _getDisplayText(String category, String value) {
    if (category == 'funding') {
      switch (value) {
        case 'available': return 'Available';
        case 'none': return 'No Funding';
        case 'free': return 'Free';
        default: return 'All';
      }
    } else if (category == 'duration') {
      switch (value) {
        case 'short': return 'Short (<2 days)';
        case 'long': return 'Long (2+ days)';
        default: return 'All';
      }
    } else if (category == 'category') {
      return value == 'all' ? 'All Categories' : value;
    } else if (category == 'sort') {
      switch (value) {
        case 'priceLow': return 'Price: Low to High';
        case 'priceHigh': return 'Price: High to Low';
        case 'durationLow': return 'Duration: Low to High';
        case 'durationHigh': return 'Duration: High to Low';
        default: return 'None';
      }
    }
    return value;
  }
}