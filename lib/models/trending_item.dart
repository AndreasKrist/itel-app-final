enum TrendingItemType {
  event,
  article,
  news,
}

class TrendingItem {
  final String id;
  final String title;
  final String category;
  final TrendingItemType type;
  final String? date;
  final String? readTime;
  final String? imageUrl;     // New field for banner/image
  final String? customLink;   // New field for custom link
  final String? description;  // New field for short description
  final List<String>? tags;   // New field for tags
  
  TrendingItem({
    required this.id,
    required this.title,
    required this.category,
    required this.type,
    this.date,
    this.readTime,
    this.imageUrl,
    this.customLink,
    this.description,
    this.tags,
  });
  
  static List<TrendingItem> sampleItems = [
    TrendingItem(
      id: '1',
      title: 'Tech Skill-Up Festival 2025',
      category: 'Event',
      type: TrendingItemType.event,
      date: 'March 20, 2025',
      imageUrl: 'assets/images/banner.png',
      customLink: 'https://itel.com.sg/resources/events/',
      description: 'Join industry leaders for a day of insights, networking, and hands-on workshops focused on the latest cybersecurity trends and challenges.',
      tags: ['Cybersecurity', 'Networking', 'Workshop'],
    ),
    TrendingItem(
      id: '2',
      title: 'New SCTP Certification Path',
      category: 'Certification News',
      type: TrendingItemType.news,
      date: 'Just announced',
      imageUrl: 'assets/images/2.webp',
      description: 'ITEL introduces a new SCTP certification path designed to meet the evolving needs of IT professionals in Singapore.',
      tags: ['Certification', 'SCTP', 'Career Development'],
    ),
    TrendingItem(
      id: '3',
      title: 'Top Tech Skills for 2025',
      category: 'Career Development',
      type: TrendingItemType.article,
      readTime: '5 min read',
      imageUrl: 'assets/images/3.webp',
      description: 'Discover the most in-demand technology skills that employers are looking for in 2025 and beyond.',
      tags: ['Skills', 'Career', 'Technology Trends'],
    ),
    TrendingItem(
      id: '4',
      title: 'Future of Online Learning',
      category: 'Education',
      type: TrendingItemType.article,
      readTime: '8 min read',
      imageUrl: 'assets/images/4.webp',
      description: 'How technology is transforming education and what it means for learners and educators in the digital age.',
      tags: ['E-learning', 'EdTech', 'Digital Transformation'],
    ),
    TrendingItem(
      id: '5',
      title: 'Cloud Security Best Practices',
      category: 'Cybersecurity',
      type: TrendingItemType.article,
      readTime: '10 min read',
      imageUrl: 'assets/images/5.webp',
      description: 'Essential security practices every organization should implement to protect their cloud infrastructure and data.',
      tags: ['Cloud Computing', 'Security', 'Best Practices'],
    ),
    TrendingItem(
      id: '6',
      title: 'Tech Resume Optimization Workshop 2025',
      category: 'Event',
      type: TrendingItemType.event,
      date: 'April 15, 2025',
      imageUrl: 'assets/images/6.webp',
      customLink: 'https://itel.com.sg/resources/events/',
      description: 'A hands-on workshop introducing the fundamentals of artificial intelligence and machine learning for beginners.',
      tags: ['AI', 'Machine Learning', 'Workshop'],
    ),
  ];
}