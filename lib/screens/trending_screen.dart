import 'package:flutter/material.dart';
import '../models/trending_item.dart';
import '../widgets/trending_card.dart';
import '../utils/link_handler.dart';


class TrendingScreen extends StatelessWidget {
  const TrendingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<TrendingItem> allItems = TrendingItem.sampleItems;
    
    // Group items by type
    final List<TrendingItem> upcomingEvents = allItems
        .where((item) => item.type == TrendingItemType.upcomingEvents)
        .toList();
    final List<TrendingItem> coursePromotion = allItems
        .where((item) => item.type == TrendingItemType.coursePromotion)
        .toList();
    final List<TrendingItem> featuredArticles = allItems
        .where((item) => item.type == TrendingItemType.featuredArticles)
        .toList();
    final List<TrendingItem> techTipsOfTheWeek = allItems
        .where((item) => item.type == TrendingItemType.techTipsOfTheWeek)
        .toList();
    final List<TrendingItem> courseAssessor = allItems
        .where((item) => item.type == TrendingItemType.courseAssessor)
        .toList();

    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.04),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: MediaQuery.of(context).size.width * 0.1,
                height: MediaQuery.of(context).size.width * 0.1,
                padding: const EdgeInsets.all(6),
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
                "What's Trending",
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          // Upcoming Events section
          if (upcomingEvents.isNotEmpty) ...[
            _buildSectionHeader(context, 'Upcoming Events'),
            const SizedBox(height: 12),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: upcomingEvents.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) => TrendingCard(item: upcomingEvents[index]),
            ),
            const SizedBox(height: 24),
          ],
          
          // Course Promotion section
          if (coursePromotion.isNotEmpty) ...[
            _buildSectionHeader(context, 'Course Promotion'),
            const SizedBox(height: 12),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: coursePromotion.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) => TrendingCard(item: coursePromotion[index]),
            ),
            const SizedBox(height: 24),
          ],
          
          // Featured Articles section (Carousel style)
          if (featuredArticles.isNotEmpty) ...[
            _buildSectionHeader(context, 'Featured Articles'),
            const SizedBox(height: 12),
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.2,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 0),
                itemCount: featuredArticles.length,
                separatorBuilder: (context, index) => const SizedBox(width: 12),
                itemBuilder: (context, index) => SizedBox(
                  width: MediaQuery.of(context).size.width * 0.85,
                  child: TrendingCard(item: featuredArticles[index]),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
          
          // TechTips of the Week section
          if (techTipsOfTheWeek.isNotEmpty) ...[
            _buildSectionHeader(context, 'TechTips of the Week'),
            const SizedBox(height: 12),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: techTipsOfTheWeek.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) => TrendingCard(item: techTipsOfTheWeek[index]),
            ),
            const SizedBox(height: 24),
          ],
          
          // Course Assessor section
          if (courseAssessor.isNotEmpty) ...[
            _buildSectionHeader(context, 'Course Assessor'),
            const SizedBox(height: 12),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: courseAssessor.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) => TrendingCard(item: courseAssessor[index]),
            ),
            const SizedBox(height: 24),
          ],
          
          // Subscribe section
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.blue[100]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Stay Updated',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[800],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Subscribe to our newsletter to get the latest news and updates about our courses and events.',
                  style: TextStyle(
                    color: Colors.blue[800],
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                
                    LinkHandler.openLink(
                      context,
                      'https://itel.com.sg/resources/event',
                      fallbackMessage: 'Opening subscription page...'
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[700],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Center(
                    child: Text('Subscribe'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      ),
    );
  }
  
  Widget _buildSectionHeader(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
    );
  }
}