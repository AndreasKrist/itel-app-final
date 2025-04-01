import 'package:flutter/material.dart';
import '../models/course.dart';
import '../models/user.dart';
import '../widgets/course_card.dart';
import '../widgets/filter_modal.dart';
import '../widgets/sort_modal.dart';
import '../services/user_preferences_service.dart';
import '../services/auth_service.dart';

class CoursesScreen extends StatefulWidget {
  const CoursesScreen({super.key});

  @override
  State<CoursesScreen> createState() => _CoursesScreenState();
}

class _CoursesScreenState extends State<CoursesScreen> {
  List<Course> courses = Course.sampleCourses;
  Map<String, String> activeFilters = {
    'funding': 'all',
    'duration': 'all',
    'certType': 'all',
  };
  String activeSort = 'none';
  bool showFilters = false;
  bool showSortOptions = false;
  final bool _isLoading = false;
  
  // Service instances
  final UserPreferencesService _preferencesService = UserPreferencesService();
  final AuthService _authService = AuthService();

  // Handle favorite toggling with Firestore persistence
void _toggleFavorite(Course course) async {
  try {
    // Get current user from AuthService
    final currentUser = _authService.currentUser;
    
    if (currentUser == null || currentUser.id.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please log in to save favorites')),
        );
      }
      return;
    }

    print('Toggle favorite for course ${course.id} by user ${currentUser.id}');
    
    // First, update the UI immediately for responsive feel
    setState(() {
      List<String> tempFavorites = List.from(User.currentUser.favoriteCoursesIds);
      if (tempFavorites.contains(course.id)) {
        tempFavorites.remove(course.id);
      } else {
        tempFavorites.add(course.id);
      }
      User.currentUser = User.currentUser.copyWith(
        favoriteCoursesIds: tempFavorites,
      );
    });
    
    // Then update Firestore
    final updatedFavorites = await _preferencesService.toggleFavorite(
      userId: currentUser.id,
      courseId: course.id,
      currentFavorites: User.currentUser.favoriteCoursesIds,
    );
    
    // Update local state again with the server response
    if (mounted) {
      setState(() {
        User.currentUser = User.currentUser.copyWith(
          favoriteCoursesIds: updatedFavorites,
        );
        print('UI updated with favorites: ${User.currentUser.favoriteCoursesIds}');
      });
    }
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
    
    // Apply funding filter
    if (activeFilters['funding'] != 'all') {
      if (activeFilters['funding'] == 'available') {
        result = result.where((course) => course.funding?.contains('Eligible') ?? false).toList();
      } else if (activeFilters['funding'] == 'none') {
        result = result.where((course) => course.funding?.contains('Not eligible') ?? false).toList();
      } else if (activeFilters['funding'] == 'free') {
        result = result.where((course) => course.price.contains('Free') || course.price == '\$0').toList();
      }
    }
    
    // Apply duration filter
    if (activeFilters['duration'] != 'all') {
      if (activeFilters['duration'] == 'short') {
        // Filter for short courses (< 2 days)
        result = result.where((course) {
          // Check if duration contains "day" or "days"
          if (course.duration.contains('day')) {
            final days = int.tryParse(course.duration.split(' ')[0]) ?? 0;
            return days < 2;
          } 
          // For non-day formats, assume weeks are long
          return false;
        }).toList();
      } else if (activeFilters['duration'] == 'long') {
        // Filter for long courses (2+ days)
        result = result.where((course) {
          // Check if duration contains "day" or "days"
          if (course.duration.contains('day')) {
            final days = int.tryParse(course.duration.split(' ')[0]) ?? 0;
            return days >= 2;
          } 
          // For non-day formats (weeks, months), consider them long
          return true;
        }).toList();
      }
    }
    
    // Apply cert type filter
    if (activeFilters['certType'] != 'all') {
      result = result.where((course) => course.certType == activeFilters['certType']).toList();
    }
    
    // Apply sorting
    if (activeSort == 'priceLow') {
      return List.from(result)..sort((a, b) {
        final aPrice = double.tryParse(a.price.replaceAll(RegExp(r'[^\d.]'), '')) ?? 0;
        final bPrice = double.tryParse(b.price.replaceAll(RegExp(r'[^\d.]'), '')) ?? 0;
        return aPrice.compareTo(bPrice);
      });
    } else if (activeSort == 'priceHigh') {
      return List.from(result)..sort((a, b) {
        final aPrice = double.tryParse(a.price.replaceAll(RegExp(r'[^\d.]'), '')) ?? 0;
        final bPrice = double.tryParse(b.price.replaceAll(RegExp(r'[^\d.]'), '')) ?? 0;
        return bPrice.compareTo(aPrice);
      });
    } else if (activeSort == 'durationLow') {
      return List.from(result)..sort((a, b) {
        // Get numeric duration for days
        int getDurationDays(String duration) {
          if (duration.contains('day')) {
            return int.tryParse(duration.split(' ')[0]) ?? 0;
          } else if (duration.contains('week')) {
            return (int.tryParse(duration.split(' ')[0]) ?? 0) * 7;
          } else if (duration.contains('month')) {
            return (int.tryParse(duration.split(' ')[0]) ?? 0) * 30;
          }
          return 0;
        }
        
        final aDays = getDurationDays(a.duration);
        final bDays = getDurationDays(b.duration);
        return aDays.compareTo(bDays);
      });
    } else if (activeSort == 'durationHigh') {
      return List.from(result)..sort((a, b) {
        // Get numeric duration for days
        int getDurationDays(String duration) {
          if (duration.contains('day')) {
            return int.tryParse(duration.split(' ')[0]) ?? 0;
          } else if (duration.contains('week')) {
            return (int.tryParse(duration.split(' ')[0]) ?? 0) * 7;
          } else if (duration.contains('month')) {
            return (int.tryParse(duration.split(' ')[0]) ?? 0) * 30;
          }
          return 0;
        }
        
        final aDays = getDurationDays(a.duration);
        final bDays = getDurationDays(b.duration);
        return bDays.compareTo(aDays);
      });
    }
    
    return result;
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Courses',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
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
              
              // Active filters display
              if (activeFilters.values.any((value) => value != 'all') || activeSort != 'none') ...[
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
            child: Center(
              child: CircularProgressIndicator(),
            ),
          ),
      ],
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