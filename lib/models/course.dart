import 'user.dart'; // 
class Course {
  final String id;
  final String courseCode; // Added course code
  final String title;
  final String category;
  final String? certType;
  final double rating;
  final String duration;
  final String price;
  final String? funding;
  final bool isFavorite;
  final List<String>? deliveryMethods;
  final String? startDate;
  final String? nextAvailableDate; // Added next available date
  final Map<String, List<String>>? outline; // Changed to Map for expandable outline
  final String? description; // Added course description
  final List<String>? prerequisites; // Added prerequisites
  final String? whoShouldAttend; // Added who should attend
  final String? importantNotes; // Added important notes
  final Map<String, Map<String, String>>? feeStructure; // Added fee structure
  final String? progress;
  final String? completionDate;
  final String? moodleCourseId; // The ID of this course in Moodle

  Course({
    required this.id,
    this.courseCode = '', // Default empty string
    required this.title,
    required this.category,
    this.certType,
    required this.rating,
    required this.duration,
    required this.price,
    this.funding,
    this.isFavorite = false,
    this.deliveryMethods,
    this.startDate,
    this.nextAvailableDate,
    this.outline,
    this.description,
    this.prerequisites,
    this.whoShouldAttend,
    this.importantNotes,
    this.feeStructure,
    this.progress,
    this.completionDate,
    this.moodleCourseId,
  });

  Course copyWith({
    String? id,
    String? courseCode,
    String? title,
    String? category,
    String? certType,
    double? rating,
    String? duration,
    String? price,
    String? funding,
    bool? isFavorite,
    List<String>? deliveryMethods,
    String? startDate,
    String? nextAvailableDate,
    Map<String, List<String>>? outline,
    String? description,
    List<String>? prerequisites,
    String? whoShouldAttend,
    String? importantNotes,
    Map<String, Map<String, String>>? feeStructure,
    String? progress,
    String? completionDate,
    String? moodleCourseId,
  }) {
    return Course(
      id: id ?? this.id,
      courseCode: courseCode ?? this.courseCode,
      title: title ?? this.title,
      category: category ?? this.category,
      certType: certType ?? this.certType,
      rating: rating ?? this.rating,
      duration: duration ?? this.duration,
      price: price ?? this.price,
      funding: funding ?? this.funding,
      isFavorite: isFavorite ?? this.isFavorite,
      deliveryMethods: deliveryMethods ?? this.deliveryMethods,
      startDate: startDate ?? this.startDate,
      nextAvailableDate: nextAvailableDate ?? this.nextAvailableDate,
      outline: outline ?? this.outline,
      description: description ?? this.description,
      prerequisites: prerequisites ?? this.prerequisites,
      whoShouldAttend: whoShouldAttend ?? this.whoShouldAttend,
      importantNotes: importantNotes ?? this.importantNotes,
      feeStructure: feeStructure ?? this.feeStructure,
      progress: progress ?? this.progress,
      completionDate: completionDate ?? this.completionDate,
      moodleCourseId: moodleCourseId ?? this.moodleCourseId,
    );
  }

// Replace the getDiscountedPrice method in Course class
  String getDiscountedPrice(MembershipTier userTier) {
    final discountPercentage = userTier.discountPercentage;
    
    if (discountPercentage == 0) {
      return price;
    }
    
    // Extract numeric value from price string
    final priceString = price.replaceAll(RegExp(r'[^\d.]'), '');
    if (priceString.isEmpty) {
      return price; // Return original if we can't parse it
    }
    
    try {
      double originalPrice = double.parse(priceString);
      double discountedPrice = originalPrice * (1 - discountPercentage);
      
      // Format price with same currency symbol
      if (price.contains('\$')) {
        return '\$${discountedPrice.toStringAsFixed(2)}';
      } else {
        return discountedPrice.toStringAsFixed(2);
      }
    } catch (e) {
      return price; // Return original price if parsing fails
    }
  }
  
  // Check if course is eligible for discount
  bool isDiscountEligible() {
    // Free courses, complimentary courses, and government funding eligible courses cannot have additional discounts
    return !(price == '\$0' || 
            price.contains('Free') || 
            funding == 'Complimentary' ||
            (funding != null && funding!.contains('Eligible for funding')));
  }
  
static List<Course> sampleCourses = [
    

    Course(
    id: '218',
    courseCode: 'IOT-101',
    title: 'IoT Literacy — Understanding the Internet of Things',
    category: 'Information Technology',
    certType: 'Microsoft',
    rating: 4.6,
    duration: '1 Hour',
    price: '\$0',
    funding: 'Complimentary',
    deliveryMethods: ['OLL'],
    nextAvailableDate: 'Available',
    moodleCourseId: '13',
    description: 'This comprehensive foundational course is designed for general learners, professionals, and business teams seeking essential IoT knowledge. Participants will understand what IoT is and how it works, explore key components and technologies powering IoT systems, and learn about real-world applications across various industries. The course covers the benefits, risks, and ethical considerations of IoT implementation while developing awareness of future trends and opportunities in the IoT landscape. This course empowers learners to make informed decisions about IoT adoption and understand its transformative impact on modern business and daily life.',
    outline: {
      'Nano Module 1: Introduction to IoT': [
        'What is IoT?',
        'Why IoT Matters Today',
      ],
      'Nano Module 2: How IoT Works': [
        'IoT Ecosystem Basics',
        'Data Flow Example',
      ],
      'Nano Module 3: Applications of IoT': [
        'Consumer IoT',
        'Industrial & Commercial IoT',
      ],
      'Nano Module 4: Benefits of IoT': [
        'Key Advantages',
        'Real-World Success Examples',
      ],
      'Nano Module 5: Risks, Challenges & Ethics': [
        'Security Concerns',
        'Ethical & Operational Challenges',
      ],
      'Nano Module 6: The Future of IoT': [
        'Emerging Trends',
        'Opportunities Ahead',
        'END',
      ],
      'Nano Quiz on IoT Literacy': [
        'Nano Quiz on IoT Literacy',
        'Thank you',
      ],
    },
    prerequisites: [
      'Basic computer literacy',
      'Understanding of internet and basic technology concepts',
      'No prior IoT experience required',
    ],
    whoShouldAttend: 'General Learners, Professionals, and Business Teams seeking foundational IoT knowledge',
    importantNotes: 'Upon completion of this course, participants will have comprehensive foundational knowledge of IoT technologies, enabling them to understand IoT ecosystems, recognize implementation opportunities, assess risks and benefits, and make informed decisions about IoT adoption in their personal and professional contexts.',
    feeStructure: {
    },
  ),


  ];

  static List<Course> userCourseHistory = [
    Course(
      id: '1',
      courseCode: 'SEC101',
      title: 'Essential Excel for Sales & Marketing (Part 1)',
      category: 'Excel',
      certType: 'CEH',
      rating: 4.8,
      duration: '8 weeks',
      price: '\$1,299',
      completionDate: 'Jan 15, 2025',
    ),
    
  ];
}