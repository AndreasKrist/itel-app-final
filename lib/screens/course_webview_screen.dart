import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../models/course.dart';
import '../models/user.dart';
import '../services/user_preferences_service.dart';
import '../services/auth_service.dart';

class CourseWebViewScreen extends StatefulWidget {
  final Course course;

  const CourseWebViewScreen({
    super.key,
    required this.course,
  });

  @override
  State<CourseWebViewScreen> createState() => _CourseWebViewScreenState();
}

class _CourseWebViewScreenState extends State<CourseWebViewScreen> {
  late final WebViewController _controller;
  final UserPreferencesService _preferencesService = UserPreferencesService();
  final AuthService _authService = AuthService();
  bool _isLoading = true;
  late bool isFavorite;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    isFavorite = User.currentUser.favoriteCoursesIds.contains(widget.course.id);
    _initializeWebView();
  }

  void _initializeWebView() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            // Loading progress
          },
          onPageStarted: (String url) {
            if (mounted) {
              setState(() {
                _isLoading = true;
                _errorMessage = null;
              });
            }
          },
          onPageFinished: (String url) {
            if (mounted) {
              setState(() {
                _isLoading = false;
              });
            }
          },
          onWebResourceError: (WebResourceError error) {
            if (mounted) {
              setState(() {
                _isLoading = false;
                _errorMessage = 'Failed to load page. Please check your internet connection.';
              });
            }
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.course.wordpressUrl!));
  }

  void _toggleFavorite() async {
    try {
      final currentUser = _authService.currentUser;

      if (currentUser == null || currentUser.id.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please log in to save favorites')),
          );
        }
        return;
      }

      final newFavoriteState = !isFavorite;

      setState(() {
        isFavorite = newFavoriteState;
      });

      List<String> updatedFavorites = List.from(User.currentUser.favoriteCoursesIds);
      if (newFavoriteState) {
        if (!updatedFavorites.contains(widget.course.id)) {
          updatedFavorites.add(widget.course.id);
        }
      } else {
        updatedFavorites.remove(widget.course.id);
      }

      User.currentUser = User.currentUser.copyWith(
        favoriteCoursesIds: updatedFavorites,
      );

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
        giveAccess: User.currentUser.giveAccess,
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          isFavorite = User.currentUser.favoriteCoursesIds.contains(widget.course.id);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update favorite: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.course.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          IconButton(
            icon: Icon(
              isFavorite ? Icons.favorite : Icons.favorite_border,
              color: isFavorite ? const Color(0xFFFF6600) : null,
            ),
            onPressed: _toggleFavorite,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                _isLoading = true;
                _errorMessage = null;
              });
              _controller.reload();
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          if (_errorMessage != null)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.wifi_off,
                      size: 64,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _errorMessage!,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () {
                        setState(() {
                          _isLoading = true;
                          _errorMessage = null;
                        });
                        _controller.reload();
                      },
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0056AC),
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            WebViewWidget(controller: _controller),
          if (_isLoading)
            const LinearProgressIndicator(
              color: Color(0xFF0056AC),
            ),
        ],
      ),
    );
  }
}
