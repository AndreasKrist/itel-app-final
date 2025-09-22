import 'package:flutter/material.dart';
import '../models/trending_item.dart';
import '../utils/link_handler.dart';

class TrendingDetailScreen extends StatelessWidget {
  final TrendingItem item;

  const TrendingDetailScreen({
    super.key,
    required this.item,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          item.type == TrendingItemType.upcomingEvents 
              ? 'Event Details' 
              : (item.type == TrendingItemType.coursePromotion ? 'Course Details' : 'Article Details'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Share functionality coming soon!')),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Banner Image
            Container(
              width: double.infinity,
              height: 200,
              decoration: BoxDecoration(
                color: _getColorForType(item.type),
                image: item.imageUrl != null
                  ? DecorationImage(
                      image: AssetImage(item.imageUrl!),
                      fit: BoxFit.cover,
                      colorFilter: ColorFilter.mode(
                        _getColorForType(item.type).withOpacity(0.1),
                        BlendMode.srcOver,
                      ),
                    )
                  : null,
              ),
              child: Center(
                child: item.imageUrl == null
                  ? Icon(
                      _getIconForType(item.type),
                      size: 64,
                      color: Colors.white,
                    )
                  : null,
              ),
            ),
            
            // Content
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title and Category
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getLightColorForType(item.type),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          item.category,
                          style: TextStyle(
                            color: _getColorForType(item.type),
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      if (item.date != null || item.readTime != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                item.type == TrendingItemType.upcomingEvents || item.date != null
                                  ? Icons.calendar_today
                                  : Icons.access_time,
                                color: Colors.grey[600],
                                size: 12,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                item.date ?? item.readTime ?? '',
                                style: TextStyle(
                                  color: Colors.grey[700],
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Title
                  Text(
                    item.title,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Type-specific content
                  if (item.type == TrendingItemType.upcomingEvents)
                    _buildEventContent(context)
                  else if (item.type == TrendingItemType.coursePromotion)
                    _buildNewsContent()
                  else
                    _buildArticleContent(),
                  
                  const SizedBox(height: 24),
                  
                  // Tags
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildTag('ITEL'),
                      _buildTag(item.category),
                      _buildTag(_getTypeText(item.type)),
                      if (item.tags != null)
                        ...item.tags!.map((tag) => _buildTag(tag)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomAction(context, item.customLink),
    );
  }
  
  Widget _buildEventContent(BuildContext context) {
  // If fullContent is provided, use that
  if (item.fullContent != null && item.fullContent!.isNotEmpty) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: _formatContent(item.fullContent!),
    );
  }
  
  // Otherwise use the structured event fields
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _buildSectionTitle('About This Event'),
      const SizedBox(height: 12),
      Text(
        item.description ?? 'Join us for this exciting event!',
        style: TextStyle(
          height: 1.5,
          color: Colors.grey[800],
        ),
      ),
      const SizedBox(height: 24),
      
      _buildSectionTitle('Event Details'),
      const SizedBox(height: 12),
      _buildDetailRow('Date', item.date ?? 'TBA'),
      _buildDetailRow('Time', item.eventTime ?? 'TBA'),
      _buildDetailRow('Location', item.eventLocation ?? 'TBA'),
      _buildDetailRow('Format', item.eventFormat ?? 'TBA'),
      const SizedBox(height: 24),
      
      if (item.eventLearningPoints != null && item.eventLearningPoints!.isNotEmpty) ...[
        _buildSectionTitle('What You\'ll Learn'),
        const SizedBox(height: 12),
        ...item.eventLearningPoints!.map((point) => _buildBulletPoint(point)),
        const SizedBox(height: 24),
      ],
      
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.amber[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.amber[200]!),
        ),
        child: Row(
          children: [
            Icon(
              Icons.info_outline,
              color: Colors.amber[800],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Limited seats available. Registration closes one week before the event date.',
                style: TextStyle(
                  color: Colors.amber[800],
                ),
              ),
            ),
          ],
        ),
      ),
    ],
  );
}
  
  Widget _buildNewsContent() {
  // Use provided fullContent or fallback to generated content
  if (item.fullContent != null && item.fullContent!.isNotEmpty) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: _formatContent(item.fullContent!),
    );
  }
  
  // Fallback to default template if no fullContent is provided
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        item.description ?? 'ITEL is pleased to announce ${item.title}, which aims to provide enhanced career pathways for IT professionals in Singapore.',
        style: TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 16,
          color: Colors.grey[800],
        ),
      ),
      const SizedBox(height: 16),
      
      Text(
        'The company has adopted digital learning platforms to reduce paper usage, implemented energy-efficient systems in its training centers, and prioritized virtual training sessions to minimize travel-related carbon emissions. ITEL also partners with local environmental organizations to promote sustainability awareness among IT professionals, aligning its programs with Singapore’s green initiatives. This effort reflects ITEL’s dedication to fostering a sustainable future while delivering top-tier IT training.',
        style: TextStyle(
          height: 1.5,
          color: Colors.grey[800],
        ),
      ),
      const SizedBox(height: 16),
      
      Text(
        'Key Features of ITEL’s Sustainability Efforts Include:',
        style: TextStyle(
          fontWeight: FontWeight.w500,
          color: Colors.grey[800],
        ),
      ),
      const SizedBox(height: 8),
      _buildBulletPoint('Digital platforms to reduce paper consumption'),
      _buildBulletPoint('Energy-efficient systems in training facilities'),
      _buildBulletPoint('Virtual training to lower carbon emissions'),
      _buildBulletPoint('Partnerships promoting environmental awareness'),
      
      const SizedBox(height: 16),
      
      Text(
        'This initiative is part of ITEL\'s ongoing commitment to providing world-class training and certification programs that meet the needs of both individuals and organizations.',
        style: TextStyle(
          height: 1.5,
          color: Colors.grey[800],
        ),
      ),
      
      const SizedBox(height: 24),
      
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
            Text(
              'Upcoming Information Sessions',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFF0056AC),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Join our free information sessions to learn more about the new certification path and how it can benefit your career.',
              style: TextStyle(
                color: Color(0xFF0056AC),
              ),
            ),
          ],
        ),
      ),
    ],
  );
}
  
  Widget _buildArticleContent() {
  // Use provided fullContent or fallback to generated content
  if (item.fullContent != null && item.fullContent!.isNotEmpty) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: _formatContent(item.fullContent!),
    );
  }
  
  // Fallback to default template if no fullContent is provided
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        item.description ?? 'The technology landscape is constantly evolving, and staying ahead of the curve is essential for career growth and professional development.',
        style: TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 16,
          color: Colors.grey[800],
        ),
      ),
      const SizedBox(height: 16),
      
      Text(
        'In this article, we explore ${item.title} and their importance in today\'s competitive job market. Whether you\'re just starting your IT career or looking to advance to the next level, understanding these key skills can give you a significant advantage.',
        style: TextStyle(
          height: 1.5,
          color: Colors.grey[800],
        ),
      ),
      const SizedBox(height: 24),
      
      _buildSectionTitle('Key Insights'),
      const SizedBox(height: 12),
      _buildBulletPoint('Cloud computing skills remain in high demand, with specific expertise in multi-cloud environments becoming increasingly valuable'),
      _buildBulletPoint('Cybersecurity professionals continue to be among the most sought-after IT specialists, with a growing emphasis on cloud security'),
      _buildBulletPoint('Data analysis and AI/ML skills are becoming essential across various IT roles, not just for specialists'),
      _buildBulletPoint('DevOps and automation capabilities can significantly increase your marketability'),
      
      const SizedBox(height: 24),
      
      Text(
        'According to recent industry reports, professionals who possess a combination of technical expertise and soft skills such as communication and problem-solving are particularly well-positioned for career advancement.',
        style: TextStyle(
          height: 1.5,
          color: Colors.grey[800],
        ),
      ),
      
      const SizedBox(height: 16),
      
      Text(
        'At ITEL, we offer comprehensive training programs designed to help you develop these in-demand skills and advance your career. Our courses are regularly updated to reflect the latest industry trends and technologies.',
        style: TextStyle(
          height: 1.5,
          color: Colors.grey[800],
        ),
      ),
    ],
  );
}

// Helper method to format text with proper paragraphs and bullet points
List<Widget> _formatContent(String content) {
  List<Widget> widgets = [];
  List<String> paragraphs = content.split('\n\n');
  
  for (String paragraph in paragraphs) {
    if (paragraph.trim().isEmpty) continue;
    
    // Check if paragraph is a bullet list
    if (paragraph.contains('•')) {
      // Process bullet list
      List<String> lines = paragraph.split('\n');
      
      // Check if the first line is a heading (no bullet)
      if (!lines[0].trim().startsWith('•')) {
        widgets.add(
          Text(
            lines[0].trim(),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
              fontSize: 16,
            ),
          ),
        );
        widgets.add(const SizedBox(height: 8));
        lines = lines.sublist(1); // Remove the first line
      }
      
      // Process remaining bullet points
      for (String line in lines) {
        if (line.trim().isEmpty) continue;
        if (line.trim().startsWith('•')) {
          widgets.add(_buildBulletPoint(line.replaceFirst('•', '').trim()));
        }
      }
      widgets.add(const SizedBox(height: 8));
    } else {
      // Normal paragraph
      widgets.add(
        Text(
          paragraph.trim(),
          style: TextStyle(
            height: 1.5,
            color: Colors.grey[800],
          ),
        ),
      );
      widgets.add(const SizedBox(height: 16));
    }
  }
  
  return widgets;
}
  
  Widget _buildBottomAction(BuildContext context, String? customLink) {
    if (item.type == TrendingItemType.upcomingEvents) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: () {
            LinkHandler.openEventRegistration(context, customLink);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Color(0xFF00FF00),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: const Text(
            'Register Now',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );
    } else if (item.type == TrendingItemType.coursePromotion) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Back to Trending'),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  LinkHandler.openNewsLink(context, customLink);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF0056AC),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Learn More'),
              ),
            ),
          ],
        ),
      );
    } else {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.bookmark_border),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Bookmark functionality coming soon!')),
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.share),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Share functionality coming soon!')),
                );
              },
            ),
            const Spacer(),
            ElevatedButton(
              onPressed: () {
                LinkHandler.openRelatedCoursesLink(context, customLink);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF0056AC),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Explore Related Courses'),
            ),
          ],
        ),
      );
    }
  }
  
  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    );
  }
  
  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
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
  
  Widget _buildBulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('• ', style: TextStyle(color: _getColorForType(item.type), fontSize: 16)),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: Colors.grey[800],
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildTag(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: Colors.grey[700],
          fontSize: 12,
        ),
      ),
    );
  }
  
  Color _getColorForType(TrendingItemType type) {
    return Color(0xFF0056AC)!;
  }
  
  Color _getLightColorForType(TrendingItemType type) {
    return Colors.blue[50]!;
  }
  
  IconData _getIconForType(TrendingItemType type) {
    switch (type) {
      case TrendingItemType.upcomingEvents:
        return Icons.event;
      case TrendingItemType.coursePromotion:
        return Icons.school;
      case TrendingItemType.featuredArticles:
        return Icons.article;
      case TrendingItemType.techTipsOfTheWeek:
        return Icons.lightbulb;
      case TrendingItemType.courseAssessor:
        return Icons.assessment;
    }
  }
  
  String _getTypeText(TrendingItemType type) {
    switch (type) {
      case TrendingItemType.upcomingEvents:
        return 'Event';
      case TrendingItemType.coursePromotion:
        return 'Course';
      case TrendingItemType.featuredArticles:
        return 'Article';
      case TrendingItemType.techTipsOfTheWeek:
        return 'Tech Tip';
      case TrendingItemType.courseAssessor:
        return 'Assessment';
    }
  }
}