import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/trending_item.dart';

class TrendingContentService {
  static const String _cacheKey = 'trending_content_cache';
  static const String _cacheTimestampKey = 'trending_content_cache_timestamp';
  static const Duration _cacheValidityDuration = Duration(seconds: 0); // No cache - always fetch fresh content

  // GitHub raw content URLs for AndreasKrist/Trending_item repository
  static const String _articlesUrl = 'https://raw.githubusercontent.com/AndreasKrist/Trending_item/main/articles.json';
  static const String _otherContentUrl = 'https://raw.githubusercontent.com/AndreasKrist/Trending_item/main/other_content.json';

  /// Fetches trending content from remote source with caching and fallback
  Future<List<TrendingItem>> getTrendingContent() async {
    try {
      // Check cache first
      final cachedContent = await _getCachedContent();
      if (cachedContent != null && await _isCacheValid()) {
        print('Using cached trending content');
        return cachedContent;
      }

      // Fetch from remote if cache is invalid or empty
      print('Fetching trending content from remote...');
      final remoteContent = await _fetchFromRemote();

      // Cache the new content
      await _cacheContent(remoteContent);

      return remoteContent;
    } catch (e) {
      print('Error fetching trending content: $e');

      // Try to return cached content even if expired
      final cachedContent = await _getCachedContent();
      if (cachedContent != null && cachedContent.isNotEmpty) {
        print('Using expired cached content as fallback');
        return cachedContent;
      }

      // Final fallback to hardcoded content
      print('Using hardcoded fallback content');
      return TrendingItem.sampleItems;
    }
  }

  /// Forces refresh from remote source
  Future<List<TrendingItem>> refreshContent() async {
    try {
      print('Force refreshing trending content...');
      final remoteContent = await _fetchFromRemote();
      await _cacheContent(remoteContent);
      return remoteContent;
    } catch (e) {
      print('Error refreshing content: $e');
      throw Exception('Failed to refresh content: $e');
    }
  }

  /// Fetches content from multiple remote URLs
  Future<List<TrendingItem>> _fetchFromRemote() async {
    final List<TrendingItem> allItems = [];

    try {
      // Fetch articles
      print('Fetching articles...');
      final articlesItems = await _fetchFromUrl(_articlesUrl);
      allItems.addAll(articlesItems);
      print('Loaded ${articlesItems.length} articles');
    } catch (e) {
      print('Error fetching articles: $e');
      // Continue even if articles fail
    }

    try {
      // Fetch other content (events, courses, tech tips, assessments)
      print('Fetching other content...');
      final otherItems = await _fetchFromUrl(_otherContentUrl);
      allItems.addAll(otherItems);
      print('Loaded ${otherItems.length} other items');
    } catch (e) {
      print('Error fetching other content: $e');
      // Continue even if other content fails
    }

    if (allItems.isEmpty) {
      throw Exception('Failed to fetch any content from remote sources');
    }

    print('Total items loaded: ${allItems.length}');
    return allItems;
  }

  /// Fetches content from a single URL
  Future<List<TrendingItem>> _fetchFromUrl(String url) async {
    final response = await http.get(
      Uri.parse(url),
      headers: {
        'Cache-Control': 'no-cache',
      },
    ).timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      final jsonData = json.decode(response.body);

      if (jsonData is Map<String, dynamic> && jsonData.containsKey('items')) {
        final items = jsonData['items'] as List;
        return items.map((item) => TrendingItem.fromJson(item)).toList();
      } else {
        throw Exception('Invalid JSON structure in $url');
      }
    } else {
      throw Exception('Failed to fetch content from $url: ${response.statusCode}');
    }
  }

  /// Gets cached content from local storage
  Future<List<TrendingItem>?> _getCachedContent() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedJson = prefs.getString(_cacheKey);

      if (cachedJson != null) {
        final jsonData = json.decode(cachedJson);
        if (jsonData is List) {
          return jsonData.map((item) => TrendingItem.fromJson(item)).toList();
        }
      }
      return null;
    } catch (e) {
      print('Error reading cached content: $e');
      return null;
    }
  }

  /// Caches content to local storage
  Future<void> _cacheContent(List<TrendingItem> items) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonData = items.map((item) => item.toJson()).toList();

      await prefs.setString(_cacheKey, json.encode(jsonData));
      await prefs.setInt(_cacheTimestampKey, DateTime.now().millisecondsSinceEpoch);

      print('Cached ${items.length} trending items');
    } catch (e) {
      print('Error caching content: $e');
    }
  }

  /// Checks if cached content is still valid
  Future<bool> _isCacheValid() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final timestamp = prefs.getInt(_cacheTimestampKey);

      if (timestamp == null) return false;

      final cacheTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
      final now = DateTime.now();

      return now.difference(cacheTime) < _cacheValidityDuration;
    } catch (e) {
      print('Error checking cache validity: $e');
      return false;
    }
  }

  /// Clears the cache
  Future<void> clearCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_cacheKey);
      await prefs.remove(_cacheTimestampKey);
      print('Trending content cache cleared');
    } catch (e) {
      print('Error clearing cache: $e');
    }
  }

  /// Gets cache information for debugging
  Future<Map<String, dynamic>> getCacheInfo() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final timestamp = prefs.getInt(_cacheTimestampKey);
      final cachedJson = prefs.getString(_cacheKey);

      return {
        'hasCachedData': cachedJson != null,
        'cacheTimestamp': timestamp != null
            ? DateTime.fromMillisecondsSinceEpoch(timestamp).toString()
            : null,
        'isCacheValid': await _isCacheValid(),
        'cacheSize': cachedJson?.length ?? 0,
      };
    } catch (e) {
      return {'error': e.toString()};
    }
  }
}