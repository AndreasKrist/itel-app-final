# Dynamic Trending Content Setup Guide

## Overview
Your ITEL app now supports dynamic trending content that can be updated remotely without rebuilding the app. Content is fetched from a remote JSON file and cached locally for offline access.

## 🚀 Quick Setup

### Step 1: Upload JSON Files to GitHub
1. Create a new repository or use an existing one
2. Upload both JSON files to your repository:
   - `articles.json` - Contains all your articles (featured articles, blog posts, etc.)
   - `other_content.json` - Contains events, courses, tech tips, and assessments
3. Make sure the repository is public (or configure private access)

### Step 2: Configure the Service
The service is already configured for your repository:

```dart
// GitHub raw content URLs for AndreasKrist/Trending_item repository
static const String _articlesUrl = 'https://raw.githubusercontent.com/AndreasKrist/Trending_item/main/articles.json';
static const String _otherContentUrl = 'https://raw.githubusercontent.com/AndreasKrist/Trending_item/main/other_content.json';
```

**Your Repository URLs:**
- Articles: `https://raw.githubusercontent.com/AndreasKrist/Trending_item/main/articles.json`
- Other Content: `https://raw.githubusercontent.com/AndreasKrist/Trending_item/main/other_content.json`

### Step 3: Test the Implementation
1. Build and run your app
2. Check that content loads from remote source
3. Test offline functionality by turning off internet
4. Test refresh functionality with pull-to-refresh

## 📝 Updating Content

### Method 1: GitHub Web Interface (Easiest)

**For Articles:**
1. Go to `https://github.com/AndreasKrist/Trending_item`
2. Navigate to `articles.json`
3. Click the ✏️ edit button
4. Add/edit/remove articles
5. Commit the changes

**For Other Content (Events, Courses, Tips):**
1. Go to `https://github.com/AndreasKrist/Trending_item`
2. Navigate to `other_content.json`
3. Click the ✏️ edit button
4. Make your changes
5. Commit the changes

### Method 2: Git Commands
```bash
# Clone or pull your repository
git clone https://github.com/AndreasKrist/Trending_item.git
cd Trending_item

# Edit the JSON files
# ... make your changes to articles.json or other_content.json ...

# Commit and push
git add articles.json other_content.json
git commit -m "Update trending content"
git push
```

### Benefits of Separate Files:
- **Easy Management**: Articles in one file, everything else in another
- **Better Performance**: Only fetch what you need to update
- **Reduced Conflicts**: Multiple people can work on different content types
- **Easier Maintenance**: Smaller, focused JSON files are easier to manage

## 📋 JSON Content Structure

```json
{
  "lastUpdated": "2025-01-20T10:00:00Z",
  "version": "1.0",
  "items": [
    {
      "id": "unique-id",
      "title": "Content Title",
      "category": "Category Name",
      "type": "featuredArticles|upcomingEvents|coursePromotion|techTipsOfTheWeek|courseAssessor",
      "date": "Optional date string",
      "imageUrl": "Optional image URL",
      "description": "Short description",
      "tags": ["tag1", "tag2"],
      "fullContent": "Full article content...",

      // For events only:
      "eventTime": "09:00 AM - 05:00 PM",
      "eventLocation": "Location name",
      "eventFormat": "In-person workshop",
      "eventLearningPoints": ["Point 1", "Point 2"],

      // For courses/assessments:
      "customLink": "course://123 or https://external-link.com"
    }
  ]
}
```

### Content Types Available:
- `featuredArticles` - Blog posts and articles
- `upcomingEvents` - Events and workshops
- `coursePromotion` - Course advertisements
- `techTipsOfTheWeek` - Technical tips and tricks
- `courseAssessor` - Assessment tools and links

## ⚡ Features

### ✅ Implemented Features
- **Remote Content Fetching** - Loads content from GitHub/remote URL
- **Local Caching** - 2-hour cache duration for better performance
- **Offline Fallback** - Uses cached content when offline
- **Pull-to-Refresh** - Users can refresh content manually
- **Error Handling** - Graceful fallback to hardcoded content
- **Loading States** - Shows loading indicator while fetching
- **Auto-refresh** - Content refreshes automatically every 2 hours

### 🔧 Configuration Options
You can modify these in `trending_content_service.dart`:

```dart
// Cache duration (default: 2 hours)
static const Duration _cacheValidityDuration = Duration(hours: 2);

// Request timeout (default: 10 seconds)
.timeout(const Duration(seconds: 10))
```

## 🛠️ Troubleshooting

### Content Not Loading
1. **Check URL**: Ensure the GitHub raw URL is correct
2. **Check JSON Format**: Validate JSON syntax at jsonlint.com
3. **Check Network**: Ensure device has internet connection
4. **Check Logs**: Look for error messages in console

### JSON Validation Errors
- Ensure all required fields are present (`id`, `title`, `category`, `type`)
- Check that `type` values match exactly: `featuredArticles`, `upcomingEvents`, etc.
- Validate JSON syntax with online validators

### Cache Issues
- Use the refresh button or pull-to-refresh to force update
- Clear app data to reset cache
- Check cache info in debug logs

## 🔍 Debug Information

The service provides debug information through `getCacheInfo()`:

```dart
final cacheInfo = await _contentService.getCacheInfo();
print('Cache info: $cacheInfo');
```

This shows:
- Whether cached data exists
- Cache timestamp
- Cache validity status
- Cache size

## 🚀 Advanced Setup

### Custom Backend
Instead of GitHub, you can use any HTTP endpoint that returns the JSON structure:

```dart
static const String _remoteContentUrl = 'https://your-api.com/trending-content';
```

### Private Repository
For private GitHub repos, you'll need to:
1. Generate a Personal Access Token
2. Add authentication headers to HTTP requests

### Content Versioning
The JSON includes a `version` field for future versioning support:

```json
{
  "version": "1.0",
  "lastUpdated": "2025-01-20T10:00:00Z",
  ...
}
```

## 📱 User Experience

Users will experience:
1. **First Load** - Loading indicator while fetching remote content
2. **Subsequent Loads** - Instant display from cache
3. **Refresh** - Pull down to refresh or tap refresh button
4. **Offline** - Seamless access to cached content
5. **Errors** - Informational messages with fallback content

The implementation ensures users always have access to content, even when offline or when remote sources are unavailable.