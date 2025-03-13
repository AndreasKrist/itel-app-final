import 'package:flutter/material.dart';
import '../models/trending_item.dart';
import '../widgets/trending_card.dart';

class TrendingScreen extends StatelessWidget {
  const TrendingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<TrendingItem> allItems = TrendingItem.sampleItems;
    
    // Group items by type
    final List<TrendingItem> events = allItems
        .where((item) => item.type == TrendingItemType.event)
        .toList();
    final List<TrendingItem> news = allItems
        .where((item) => item.type == TrendingItemType.news)
        .toList();
    final List<TrendingItem> articles = allItems
        .where((item) => item.type == TrendingItemType.article)
        .toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "What's Trending",
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 24),
          
          // Events section
          if (events.isNotEmpty) ...[
            _buildSectionHeader(context, 'Upcoming Events'),
            const SizedBox(height: 12),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: events.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) => TrendingCard(item: events[index]),
            ),
            const SizedBox(height: 24),
          ],
          
          // News section
          if (news.isNotEmpty) ...[
            _buildSectionHeader(context, 'Latest News'),
            const SizedBox(height: 12),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: news.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) => TrendingCard(item: news[index]),
            ),
            const SizedBox(height: 24),
          ],
          
          // Articles section
          if (articles.isNotEmpty) ...[
            _buildSectionHeader(context, 'Featured Articles'),
            const SizedBox(height: 12),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: articles.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) => TrendingCard(item: articles[index]),
            ),
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
                  onPressed: () {},
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