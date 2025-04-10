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

// Get discounted price for PRO members
  String getDiscountedPrice(MembershipTier userTier) {
    if (userTier != MembershipTier.pro) {
      return price;
    }
    
    // Extract numeric value from price string
    final priceString = price.replaceAll(RegExp(r'[^\d.]'), '');
    if (priceString.isEmpty) {
      return price; // Return original if we can't parse it
    }
    
    try {
      double originalPrice = double.parse(priceString);
      double discountedPrice = originalPrice * 0.75; // 25% discount
      
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
    // Free courses and courses not eligible for funding don't get additional discounts
    return !(price == '\$0' || 
            price.contains('Free') || 
            funding == 'Complimentary');
  }
  
static List<Course> sampleCourses = [
    Course(
      id: '1',
      courseCode: 'SEC101',
      title: 'Network Security Fundamentals',
      category: 'Cybersecurity',
      certType: 'CEH',
      rating: 4.8,
      duration: '5 days',
      price: '\$3,215.50',
      funding: 'Eligible for funding',
      deliveryMethods: ['OLL', 'ILT'],
      startDate: 'March 15, 2025',
      nextAvailableDate: 'April 20, 2025',
      description: 'This comprehensive course introduces students to the fundamentals of network security, covering essential concepts and techniques to protect digital information and infrastructure from cyber threats.',
      outline: {
        'Lesson 1: Introduction to Network Security': [
          'Understanding security principles',
          'Threat landscape overview',
          'Security objectives and strategies',
        ],
        'Lesson 2: Threat Assessment': [
          'Identifying vulnerabilities',
          'Risk assessment methodologies',
          'Threat modeling techniques',
        ],
        'Lesson 3: Security Protocols': [
          'Encryption fundamentals',
          'Authentication protocols',
          'Secure communication channels',
        ],
        'Lesson 4: Penetration Testing': [
          'Testing methodologies',
          'Tool selection and usage',
          'Reporting and analysis',
        ],
      },
      prerequisites: [
        'Basic understanding of networking concepts',
        'Familiarity with operating systems',
        'Knowledge of TCP/IP protocols',
      ],
      whoShouldAttend: 'IT professionals, network administrators, security specialists, and anyone interested in building a career in cybersecurity.',
      importantNotes: 'Participants are required to bring their own laptops. All software needed for the course will be provided.',
      feeStructure: {
        'Full Course Fee': {'Price': '\$3,215.50'},
        'SG Citizens aged 21 - 39 years old / PRs aged 21 years old and above': {'Individual': '\$1,740.50', 'Company Sponsored (Non-SME)': '\$1,740.50', 'Company Sponsored (SME)': '\$1,150.50'},
        'SG Citizens age 40 years old and above': {'Individual': '\$1,150.50', 'Company Sponsored (Non-SME)': '\$1,150.50', 'Company Sponsored (SME)': '\$1,150.50'},
      },
    ),
    Course(
      id: '2',
      courseCode: 'CLD201',
      title: 'Cloud Infrastructure Management',
      category: 'Cloud Computing',
      certType: 'CCNA',
      rating: 4.6,
      duration: '10 days',
      price: '\$3,499.50',
      funding: 'Not eligible for funding',
      deliveryMethods: ['OLL', 'ILT'],
      startDate: 'April 5, 2025',
      nextAvailableDate: 'May 15, 2025',
      description: 'Learn to design, implement, and manage cloud infrastructure across major platforms including AWS, Azure, and Google Cloud.',
      outline: {
        'Lesson 1: Cloud Computing Fundamentals': [
          'Cloud service models',
          'Deployment models',
          'Cloud architecture principles',
        ],
        'Lesson 2: AWS/Azure/GCP Services': [
          'Compute services',
          'Storage options',
          'Networking in the cloud',
        ],
        'Lesson 3: Infrastructure as Code': [
          'Configuration management',
          'Terraform basics',
          'Infrastructure automation',
        ],
        'Lesson 4: Cloud Security': [
          'Identity and access management',
          'Network security',
          'Compliance frameworks',
        ],
      },
      prerequisites: [
        'Basic understanding of IT infrastructure',
        'Familiarity with virtualization concepts',
        'Basic scripting or programming skills',
      ],
      whoShouldAttend: 'IT administrators, system engineers, DevOps professionals, and technical managers interested in cloud technologies.',
      importantNotes: 'Students will need to create free accounts on AWS, Azure, and Google Cloud platforms before the course starts.',
      feeStructure: {
        'Full Course Fee': {'Price': '\$3,499.50'},
        'SG Citizens aged 21 - 39 years old / PRs aged 21 years old and above': {'Individual': '\$1,999.50', 'Company Sponsored (Non-SME)': '\$1,999.50', 'Company Sponsored (SME)': '\$1,299.50'},
        'SG Citizens age 40 years old and above': {'Individual': '\$1,299.50', 'Company Sponsored (Non-SME)': '\$1,299.50', 'Company Sponsored (SME)': '\$1,299.50'},
      },
    ),
    Course(
      id: '3',
      courseCode: 'NET301',
      title: 'Advanced Network Management',
      category: 'Networking',
      certType: 'CCNP',
      rating: 4.9,
      duration: '12 days',
      price: '\$3,899.50',
      funding: 'Eligible for funding',
      deliveryMethods: ['ILT'],
      startDate: 'May 10, 2025',
      nextAvailableDate: 'June 25, 2025',
      description: 'An advanced course covering enterprise network management, complex routing protocols, and modern networking technologies.',
      outline: {
        'Lesson 1: Advanced Routing Protocols': [
          'BGP configuration and tuning',
          'OSPF advanced features',
          'Route redistribution and filtering',
        ],
        'Lesson 2: Network Design': [
          'Enterprise network architecture',
          'High availability design',
          'Campus network design',
        ],
        'Lesson 3: Troubleshooting Methodologies': [
          'Systematic troubleshooting approach',
          'Protocol analysis',
          'Root cause identification',
        ],
      },
      prerequisites: [
        'CCNA certification or equivalent knowledge',
        'At least 1 year of networking experience',
        'Understanding of routing and switching fundamentals',
      ],
      whoShouldAttend: 'Network engineers, system administrators, and IT professionals looking to advance their networking knowledge.',
      importantNotes: 'This course includes hands-on lab exercises on real networking equipment.',
      feeStructure: {
        'Full Course Fee': {'Price': '\$3,899.50'},
        'SG Citizens aged 21 - 39 years old / PRs aged 21 years old and above': {'Individual': '\$2,199.50', 'Company Sponsored (Non-SME)': '\$2,199.50', 'Company Sponsored (SME)': '\$1,399.50'},
        'SG Citizens age 40 years old and above': {'Individual': '\$1,399.50', 'Company Sponsored (Non-SME)': '\$1,399.50', 'Company Sponsored (SME)': '\$1,399.50'},
      },
    ),
    Course(
      id: '4',
      courseCode: 'SEC201',
      title: 'Data Security and Privacy',
      category: 'Cybersecurity',
      certType: 'SCTP',
      rating: 4.7,
      duration: '6 days',
      price: '\$2,999.50',
      funding: 'Eligible for funding',
      deliveryMethods: ['OLL'],
      startDate: 'March 22, 2025',
      nextAvailableDate: 'April 10, 2025',
      description: 'This course focuses on data protection regulations, privacy practices, and implementing security measures to protect sensitive information.',
      outline: {
        'Lesson 1: Data Protection Regulations': [
          'GDPR overview',
          'PDPA requirements',
          'Industry-specific regulations',
        ],
        'Lesson 2: Encryption Technologies': [
          'Symmetric and asymmetric encryption',
          'Hash functions and digital signatures',
          'Key management',
        ],
        'Lesson 3: Privacy by Design': [
          'Privacy principles',
          'Data minimization',
          'Privacy impact assessments',
        ],
      },
      prerequisites: [
        'Basic understanding of IT security concepts',
        'Familiarity with data management principles',
      ],
      whoShouldAttend: 'Data protection officers, compliance managers, IT security professionals, and anyone responsible for data privacy.',
      importantNotes: 'This course includes case studies of real-world data breaches and their resolution.',
      feeStructure: {
        'Full Course Fee': {'Price': '\$2,999.50'},
        'SG Citizens aged 21 - 39 years old / PRs aged 21 years old and above': {'Individual': '\$1,699.50', 'Company Sponsored (Non-SME)': '\$1,699.50', 'Company Sponsored (SME)': '\$999.50'},
        'SG Citizens age 40 years old and above': {'Individual': '\$999.50', 'Company Sponsored (Non-SME)': '\$999.50', 'Company Sponsored (SME)': '\$999.50'},
      },
    ),
    Course(
      id: '5',
      courseCode: 'ITL401',
      title: 'ITIL 4 Foundation',
      category: 'IT Service Management',
      certType: 'ITIL',
      rating: 4.5,
      duration: '3 days',
      price: '\$1,850.00',
      funding: 'Eligible for funding',
      deliveryMethods: ['OLL', 'ILT'],
      nextAvailableDate: 'April 3, 2025',
      description: 'Learn the key concepts of ITIL 4, the latest evolution of the most widely adopted guidance on IT service management in the world.',
      outline: {
        'Module 1: ITIL 4 Foundation Concepts': [
          'Service value system overview',
          'Four dimensions model',
          'Key concepts of service management',
        ],
        'Module 2: ITIL Guiding Principles': [
          'Focus on value',
          'Start where you are',
          'Progress iteratively with feedback',
          'Collaborate and promote visibility',
        ],
        'Module 3: Service Value Chain': [
          'Plan',
          'Improve',
          'Engage',
          'Design & transition',
          'Obtain/build',
          'Deliver & support',
        ],
      },
      prerequisites: [
        'No formal prerequisites',
        'Basic IT knowledge is beneficial',
      ],
      whoShouldAttend: 'IT professionals at all levels who need to understand the key concepts of IT service management and how ITIL can be used to enhance service delivery.',
      importantNotes: 'This course includes the official ITIL 4 Foundation exam, which will be taken on the last day of the course.',
      feeStructure: {
        'Full Course Fee': {'Price': '\$1,850.00'},
        'SG Citizens aged 21 - 39 years old / PRs aged 21 years old and above': {'Individual': '\$950.00', 'Company Sponsored (Non-SME)': '\$950.00', 'Company Sponsored (SME)': '\$650.00'},
        'SG Citizens age 40 years old and above': {'Individual': '\$650.00', 'Company Sponsored (Non-SME)': '\$650.00', 'Company Sponsored (SME)': '\$650.00'},
      },
    ),
    Course(
      id: '6',
      courseCode: 'SEC301',
      title: 'Certified Ethical Hacker (CEH)',
      category: 'Cybersecurity',
      certType: 'CEH',
      rating: 4.9,
      duration: '5 days',
      price: '\$3,500.00',
      funding: 'Eligible for funding',
      deliveryMethods: ['OLL', 'ILT'],
      nextAvailableDate: 'May 5, 2025',
      description: 'Learn to think like a hacker but act like a security professional. This course covers the latest hacking techniques, tools, and methodologies used by hackers and information security professionals.',
      outline: {
        'Module 1: Introduction to Ethical Hacking': [
          'Hacking concepts and methodologies',
          'Footprinting and reconnaissance',
          'Scanning networks',
        ],
        'Module 2: System Hacking': [
          'Enumeration techniques',
          'Vulnerability analysis',
          'System hacking methodology',
        ],
        'Module 3: Web Application Hacking': [
          'Web server and web application attacks',
          'SQL injection techniques',
          'Session hijacking',
        ],
        'Module 4: Network Defense': [
          'IDS, firewall, and honeypot evasion',
          'Cloud computing threats',
          'Cryptography attacks',
        ],
      },
      prerequisites: [
        'Strong understanding of TCP/IP',
        'Knowledge of Linux and Windows operating systems',
        'Basic understanding of networking concepts',
      ],
      whoShouldAttend: 'Security professionals, site administrators, security officers, security consultants, security auditors, and anyone concerned about the integrity of their network infrastructure.',
      importantNotes: 'Students must sign an ethical conduct agreement before participating in hands-on labs.',
      feeStructure: {
        'Full Course Fee': {'Price': '\$3,500.00'},
        'SG Citizens aged 21 - 39 years old / PRs aged 21 years old and above': {'Individual': '\$1,800.00', 'Company Sponsored (Non-SME)': '\$1,800.00', 'Company Sponsored (SME)': '\$1,200.00'},
        'SG Citizens age 40 years old and above': {'Individual': '\$1,200.00', 'Company Sponsored (Non-SME)': '\$1,200.00', 'Company Sponsored (SME)': '\$1,200.00'},
      },
    ),
    Course(
      id: '7',
      courseCode: 'CMP101',
      title: 'CompTIA A+ Certification',
      category: 'IT Fundamentals',
      certType: 'COMPTIA',
      rating: 4.6,
      duration: '5 days',
      price: '\$2,200.00',
      funding: 'Eligible for funding',
      deliveryMethods: ['ILT'],
      nextAvailableDate: 'April 15, 2025',
      description: 'This course provides the foundational knowledge and skills needed to become an IT support professional and earn the CompTIA A+ certification.',
      outline: {
        'Module 1: Hardware': [
          'PC components',
          'Mobile device hardware',
          'Networking hardware concepts',
        ],
        'Module 2: Operating Systems': [
          'Windows, Mac, and Linux features',
          'Operating system installation and configuration',
          'Command line tools',
        ],
        'Module 3: Security': [
          'Physical security',
          'Authentication and authorization',
          'Data destruction and device sanitization',
        ],
        'Module 4: Software Troubleshooting': [
          'Troubleshoot operating systems',
          'Resolve application security issues',
          'Malware removal',
        ],
      },
      prerequisites: [
        'Basic understanding of computer hardware',
        'Familiarity with operating systems',
        'No formal prerequisites required',
      ],
      whoShouldAttend: 'Entry-level IT professionals, IT support specialists, help desk technicians, and individuals looking to start a career in IT.',
      importantNotes: 'This course includes hands-on labs to reinforce the skills learned in the classroom.',
      feeStructure: {
        'Full Course Fee': {'Price': '\$2,200.00'},
        'SG Citizens aged 21 - 39 years old / PRs aged 21 years old and above': {'Individual': '\$1,100.00', 'Company Sponsored (Non-SME)': '\$1,100.00', 'Company Sponsored (SME)': '\$800.00'},
        'SG Citizens age 40 years old and above': {'Individual': '\$800.00', 'Company Sponsored (Non-SME)': '\$800.00', 'Company Sponsored (SME)': '\$800.00'},
      },
    ),
    Course(
      id: '8',
      courseCode: 'CMP201',
      title: 'CompTIA Security+',
      category: 'Cybersecurity',
      certType: 'COMPTIA',
      rating: 4.7,
      duration: '5 days',
      price: '\$2,800.00',
      funding: 'Eligible for funding',
      deliveryMethods: ['OLL', 'ILT'],
      nextAvailableDate: 'May 22, 2025',
      description: 'This course provides the foundational knowledge of cybersecurity concepts and industry best practices needed to earn the CompTIA Security+ certification.',
      outline: {
        'Module 1: Threats, Attacks and Vulnerabilities': [
          'Malware types',
          'Social engineering attacks',
          'Application attacks',
        ],
        'Module 2: Architecture and Design': [
          'Enterprise security architecture',
          'Secure network architecture',
          'Physical security controls',
        ],
        'Module 3: Implementation': [
          'Secure protocols',
          'Host security',
          'Mobile security',
        ],
        'Module 4: Governance, Risk and Compliance': [
          'Security policies',
          'Risk management',
          'Business continuity concepts',
        ],
      },
      prerequisites: [
        'CompTIA A+ certification recommended',
        'Two years of IT administration experience with security focus',
        'Basic understanding of networking concepts',
      ],
      whoShouldAttend: 'Security administrators, system administrators, IT auditors, and security professionals looking to validate their foundational security skills.',
      importantNotes: 'This course prepares you for the CompTIA Security+ certification exam, which is not included in the course fee.',
      feeStructure: {
        'Full Course Fee': {'Price': '\$2,800.00'},
        'SG Citizens aged 21 - 39 years old / PRs aged 21 years old and above': {'Individual': '\$1,400.00', 'Company Sponsored (Non-SME)': '\$1,400.00', 'Company Sponsored (SME)': '\$950.00'},
        'SG Citizens age 40 years old and above': {'Individual': '\$950.00', 'Company Sponsored (Non-SME)': '\$950.00', 'Company Sponsored (SME)': '\$950.00'},
      },
    ),
    Course(
      id: '9',
      courseCode: 'CIS301',
      title: 'Certified Chief Information Security Officer (CCISO)',
      category: 'Leadership',
      certType: 'CCISO',
      rating: 4.8,
      duration: '5 days',
      price: '\$4,200.00',
      funding: 'Not eligible for funding',
      deliveryMethods: ['ILT'],
      nextAvailableDate: 'June 10, 2025',
      description: 'This executive-level certification program focuses on the application of information security management principles from an executive management point of view.',
      outline: {
        'Domain 1: Governance & Risk Management': [
          'Security governance frameworks',
          'Legal, regulatory compliance and privacy',
          'Security risk management',
        ],
        'Domain 2: Information Security Controls & Audit Management': [
          'Design, implementation, management of controls',
          'Control frameworks and documentation',
          'Audit management',
        ],
        'Domain 3: Security Program Management & Operations': [
          'Management projects and operations',
          'Resource and vendor management',
          'Communications and security awareness',
        ],
        'Domain 4: Information Security Core Concepts': [
          'Access control systems and methodology',
          'Data security and privacy',
          'Physical security',
        ],
        'Domain 5: Strategic Planning, Finance & Vendor Management': [
          'Strategic planning',
          'Finance, acquisition, and vendor management',
          'Security architecture',
        ],
      },
      prerequisites: [
        'Five years of experience in three of the five CCISO domains',
        'Executive-level management experience',
        'Prior information security certification (CISSP, CISM, etc.)',
      ],
      whoShouldAttend: 'Chief Information Security Officers, aspiring CISOs, senior security managers, and executives responsible for information security.',
      importantNotes: 'This course includes case studies from real-world scenarios and interactive discussions with industry professionals.',
      feeStructure: {
        'Full Course Fee': {'Price': '\$4,200.00'},
        'SG Citizens aged 21 - 39 years old / PRs aged 21 years old and above': {'Individual': '\$4,200.00', 'Company Sponsored (Non-SME)': '\$4,200.00', 'Company Sponsored (SME)': '\$4,200.00'},
        'SG Citizens age 40 years old and above': {'Individual': '\$4,200.00', 'Company Sponsored (Non-SME)': '\$4,200.00', 'Company Sponsored (SME)': '\$4,200.00'},
      },
    ),
    Course(
      id: '10',
      courseCode: 'CIS201',
      title: 'Certified Information Security Manager (CISM)',
      category: 'Leadership',
      certType: 'CISM',
      rating: 4.8,
      duration: '4 days',
      price: '\$3,700.00',
      funding: 'Eligible for funding',
      deliveryMethods: ['OLL', 'ILT'],
      nextAvailableDate: 'April 25, 2025',
      description: 'CISM is the globally accepted standard for individuals who design, build and manage information security programs. This course prepares you for the CISM certification exam.',
      outline: {
        'Domain 1: Information Security Governance': [
          'Security strategy aligned with organizational goals',
          'Information security governance framework',
          'Security governance metrics',
        ],
        'Domain 2: Information Risk Management': [
          'Risk assessment and analysis',
          'Risk treatment options',
          'Security control selection and implementation',
        ],
        'Domain 3: Information Security Program Development': [
          'Information security strategy development',
          'Security program frameworks',
          'Security resource management',
        ],
        'Domain 4: Information Security Program Management': [
          'Security operations management',
          'Security monitoring',
          'Incident management',
        ],
      },
      prerequisites: [
        'Five years of information security management experience',
        'Knowledge of information security principles and practices',
        'Understanding of risk management concepts',
      ],
      whoShouldAttend: 'Information security managers, aspiring security managers, IT consultants, and security professionals who want to validate their managerial experience.',
      importantNotes: 'This course prepares you for the ISACA CISM certification exam, which is not included in the course fee.',
      feeStructure: {
        'Full Course Fee': {'Price': '\$3,800.00'},
        'SG Citizens aged 21 - 39 years old / PRs aged 21 years old and above': {'Individual': '\$1,900.00', 'Company Sponsored (Non-SME)': '\$1,900.00', 'Company Sponsored (SME)': '\$1,300.00'},
        'SG Citizens age 40 years old and above': {'Individual': '\$1,300.00', 'Company Sponsored (Non-SME)': '\$1,300.00', 'Company Sponsored (SME)': '\$1,300.00'},
      },
    ),
    Course(
      id: '11',
      courseCode: 'NET101',
      title: 'CCNA Routing and Switching',
      category: 'Networking',
      certType: 'CCNA',
      rating: 4.7,
      duration: '5 days',
      price: '\$2,950.00',
      funding: 'Eligible for funding',
      deliveryMethods: ['OLL', 'ILT'],
      nextAvailableDate: 'May 8, 2025',
      description: 'This course provides a comprehensive understanding of networking fundamentals and prepares you for the Cisco Certified Network Associate (CCNA) exam.',
      outline: {
        'Module 1: Network Fundamentals': [
          'Network components and topologies',
          'OSI and TCP/IP models',
          'IPv4 and IPv6 addressing',
        ],
        'Module 2: Network Access': [
          'VLANs and trunking',
          'EtherChannel',
          'Wireless LANs',
        ],
        'Module 3: IP Connectivity': [
          'Static and dynamic routing',
          'OSPF configuration',
          'InterVLAN routing',
        ],
        'Module 4: IP Services': [
          'DHCP and DNS',
          'NAT and ACLs',
          'QoS concepts',
        ],
      },
      prerequisites: [
        'Basic understanding of computer networking concepts',
        'Familiarity with operating systems',
        'No formal prerequisites required',
      ],
      whoShouldAttend: 'Network administrators, network support engineers, and IT professionals seeking to validate their networking knowledge.',
      importantNotes: 'This course includes hands-on labs using Cisco equipment and prepares you for the CCNA certification exam.',
      feeStructure: {
        'Full Course Fee': {'Price': '\$2,950.00'},
        'SG Citizens aged 21 - 39 years old / PRs aged 21 years old and above': {'Individual': '\$1,500.00', 'Company Sponsored (Non-SME)': '\$1,500.00', 'Company Sponsored (SME)': '\$950.00'},
        'SG Citizens age 40 years old and above': {'Individual': '\$950.00', 'Company Sponsored (Non-SME)': '\$950.00', 'Company Sponsored (SME)': '\$950.00'},
      },
    ),
    Course(
      id: '12',
      courseCode: 'DEV101',
      title: 'Introduction to Python Programming',
      category: 'Software Development',
      certType: null,
      rating: 4.5,
      duration: '3 days',
      price: '\$1,500.00',
      funding: 'Eligible for funding',
      deliveryMethods: ['OLL', 'ILT'],
      nextAvailableDate: 'April 12, 2025',
      description: 'Learn the fundamentals of Python programming, one of the most popular and versatile programming languages used in web development, data analysis, AI, and more.',
      outline: {
        'Module 1: Python Basics': [
          'Variables and data types',
          'Control flow (if statements, loops)',
          'Functions and modules',
        ],
        'Module 2: Data Structures': [
          'Lists, tuples, and dictionaries',
          'Sets and strings',
          'List comprehensions',
        ],
        'Module 3: Object-Oriented Programming': [
          'Classes and objects',
          'Inheritance and polymorphism',
          'Encapsulation and abstraction',
        ],
        'Module 4: Practical Applications': [
          'File handling',
          'Error handling',
          'Working with external libraries',
        ],
      },
      prerequisites: [
        'Basic computer literacy',
        'No prior programming experience required',
        'Logical thinking ability',
      ],
      whoShouldAttend: 'Beginners interested in learning programming, IT professionals wanting to add Python to their skillset, and anyone interested in automation or data analysis.',
      importantNotes: 'Participants should bring their own laptops. Python will be installed during the first session.',
      feeStructure: {
        'Full Course Fee': {'Price': '\$1,500.00'},
        'SG Citizens aged 21 - 39 years old / PRs aged 21 years old and above': {'Individual': '\$750.00', 'Company Sponsored (Non-SME)': '\$750.00', 'Company Sponsored (SME)': '\$500.00'},
        'SG Citizens age 40 years old and above': {'Individual': '\$500.00', 'Company Sponsored (Non-SME)': '\$500.00', 'Company Sponsored (SME)': '\$500.00'},
      },
    ),
    Course(
      id: '13',
      courseCode: 'DAT101',
      title: 'Data Analysis with Python',
      category: 'Data Science',
      certType: null,
      rating: 4.7,
      duration: '4 days',
      price: '\$2,200.00',
      funding: 'Eligible for funding',
      deliveryMethods: ['OLL'],
      nextAvailableDate: 'May 18, 2025',
      description: 'Learn how to analyze data efficiently using Python and its powerful libraries including Pandas, NumPy, and Matplotlib.',
      outline: {
        'Module 1: Python for Data Science': [
          'Python fundamentals review',
          'Jupyter notebooks',
          'NumPy for numerical computing',
        ],
        'Module 2: Data Manipulation with Pandas': [
          'DataFrames and Series',
          'Data cleaning and preprocessing',
          'Data transformation techniques',
        ],
        'Module 3: Data Visualization': [
          'Matplotlib basics',
          'Seaborn for statistical visualization',
          'Interactive plots with Plotly',
        ],
        'Module 4: Data Analysis Projects': [
          'Exploratory data analysis',
          'Statistical analysis',
          'Building reports and dashboards',
        ],
      },
      prerequisites: [
        'Basic programming knowledge (preferably Python)',
        'Understanding of basic statistical concepts',
        'Familiarity with data concepts',
      ],
      whoShouldAttend: 'Data analysts, business analysts, IT professionals, and anyone interested in learning data analysis techniques using Python.',
      importantNotes: 'Participants will work on real-world datasets and complete a capstone project by the end of the course.',
      feeStructure: {
        'Full Course Fee': {'Price': '\$2,200.00'},
        'SG Citizens aged 21 - 39 years old / PRs aged 21 years old and above': {'Individual': '\$1,100.00', 'Company Sponsored (Non-SME)': '\$1,100.00', 'Company Sponsored (SME)': '\$750.00'},
        'SG Citizens age 40 years old and above': {'Individual': '\$750.00', 'Company Sponsored (Non-SME)': '\$750.00', 'Company Sponsored (SME)': '\$750.00'},
      },
    ),
    Course(
      id: '14',
      courseCode: 'CLD101',
      title: 'AWS Cloud Practitioner Essentials',
      category: 'Cloud Computing',
      certType: null,
      rating: 4.6,
      duration: '1 day',
      price: '\$800.00',
      funding: 'Eligible for funding',
      deliveryMethods: ['OLL', 'ILT'],
      nextAvailableDate: 'April 5, 2025',
      description: 'This foundational course introduces you to AWS Cloud concepts, AWS services, security, architecture, pricing, and support to build your AWS Cloud knowledge.',
      outline: {
        'Module 1: Cloud Concepts': [
          'Introduction to AWS',
          'Cloud computing benefits',
          'AWS global infrastructure',
        ],
        'Module 2: Security and Compliance': [
          'AWS shared responsibility model',
          'AWS security services',
          'AWS Identity and Access Management (IAM)',
        ],
        'Module 3: Technology': [
          'AWS compute services',
          'AWS storage services',
          'AWS networking services',
        ],
        'Module 4: Billing and Pricing': [
          'AWS pricing models',
          'AWS free tier',
          'AWS cost management tools',
        ],
      },
      prerequisites: [
        'Basic IT knowledge',
        'No cloud experience required',
      ],
      whoShouldAttend: 'Sales, legal, marketing, business analysts, project managers, and other non-technical professionals working with AWS.',
      importantNotes: 'This course helps prepare you for the AWS Certified Cloud Practitioner exam (not included in the course fee).',
      feeStructure: {
        'Full Course Fee': {'Price': '\$800.00'},
        'SG Citizens aged 21 - 39 years old / PRs aged 21 years old and above': {'Individual': '\$400.00', 'Company Sponsored (Non-SME)': '\$400.00', 'Company Sponsored (SME)': '\$280.00'},
        'SG Citizens age 40 years old and above': {'Individual': '\$280.00', 'Company Sponsored (Non-SME)': '\$280.00', 'Company Sponsored (SME)': '\$280.00'},
      },
    ),
    Course(
      id: '15',
      courseCode: 'ITL201',
      title: 'ITIL 4 Managing Professional Transition',
      category: 'IT Service Management',
      certType: 'ITIL',
      rating: 4.8,
      duration: '5 days',
      price: '\$3,200.00',
      funding: 'Not eligible for funding',
      deliveryMethods: ['ILT'],
      nextAvailableDate: 'May 12, 2025',
      description: 'This course is designed for ITIL v3 experts who want to transition to ITIL 4 and achieve the ITIL 4 Managing Professional designation.',
      outline: {
        'Module 1: ITIL 4 Foundation Recap': [
          'ITIL 4 key concepts',
          'Service value system',
          'Four dimensions model',
        ],
        'Module 2: Direct, Plan, and Improve': [
          'Organizational change management',
          'Measurement and reporting',
          'Continual improvement',
        ],
        'Module 3: Create, Deliver and Support': [
          'Service design',
          'Service integration',
          'Development and operations',
        ],
        'Module 4: Drive Stakeholder Value': [
          'Customer journey mapping',
          'SLA design',
          'User experience design',
        ],
      },
      prerequisites: [
        'ITIL v3 Expert certification or 17 ITIL v3 credits',
        'ITIL 4 Foundation certification',
        'Experience in IT service management',
      ],
      whoShouldAttend: 'ITIL v3 certified professionals who want to update their knowledge and achieve the ITIL 4 Managing Professional designation.',
      importantNotes: 'This course includes the official ITIL 4 Managing Professional Transition exam on the last day.',
      feeStructure: {
        'Full Course Fee': {'Price': '\$3,200.00'},
        'SG Citizens aged 21 - 39 years old / PRs aged 21 years old and above': {'Individual': '\$3,200.00', 'Company Sponsored (Non-SME)': '\$3,200.00', 'Company Sponsored (SME)': '\$3,200.00'},
        'SG Citizens age 40 years old and above': {'Individual': '\$3,200.00', 'Company Sponsored (Non-SME)': '\$3,200.00', 'Company Sponsored (SME)': '\$3,200.00'},
      },
    ),
    Course(
      id: '16',
      courseCode: 'SEC401',
      title: 'Cybersecurity First Responder',
      category: 'Cybersecurity',
      certType: 'COMPTIA',
      rating: 4.7,
      duration: '5 days',
      price: '\$3,100.00',
      funding: 'Eligible for funding',
      deliveryMethods: ['ILT'],
      nextAvailableDate: 'June 3, 2025',
      description: 'Learn how to identify and respond to cybersecurity incidents. This course provides hands-on experience in threat detection, containment, and remediation.',
      outline: {
        'Module 1: Threat Landscape': [
          'Modern attack vectors',
          'Threat actors and motivations',
          'Indicators of compromise',
        ],
        'Module 2: Security Tools and Technologies': [
          'SIEM systems',
          'Endpoint detection and response',
          'Network monitoring tools',
        ],
        'Module 3: Incident Response': [
          'Incident response framework',
          'Triage and analysis',
          'Evidence collection and handling',
        ],
        'Module 4: Containment and Remediation': [
          'Containment strategies',
          'System isolation techniques',
          'Recovery procedures',
        ],
      },
      prerequisites: [
        'Security+ certification or equivalent knowledge',
        'Basic understanding of networks and operating systems',
        'Familiarity with cybersecurity concepts',
      ],
      whoShouldAttend: 'IT security professionals responsible for incident detection and response, security operations center (SOC) analysts, and security team members.',
      importantNotes: 'This course includes an extensive capture-the-flag (CTF) exercise on the last day that simulates a real-world incident.',
      feeStructure: {
        'Full Course Fee': {'Price': '\$3,100.00'},
        'SG Citizens aged 21 - 39 years old / PRs aged 21 years old and above': {'Individual': '\$1,550.00', 'Company Sponsored (Non-SME)': '\$1,550.00', 'Company Sponsored (SME)': '\$1,050.00'},
        'SG Citizens age 40 years old and above': {'Individual': '\$1,050.00', 'Company Sponsored (Non-SME)': '\$1,050.00', 'Company Sponsored (SME)': '\$1,050.00'},
      },
    ),
    Course(
      id: '17',
      courseCode: 'AI101',
      title: 'Introduction to Artificial Intelligence',
      category: 'Data Science',
      certType: null,
      rating: 4.5,
      duration: '2 days',
      price: '\$1,200.00',
      funding: 'Eligible for funding',
      deliveryMethods: ['OLL'],
      nextAvailableDate: 'April 28, 2025',
      description: 'This course provides a comprehensive introduction to Artificial Intelligence concepts, applications, and implications. Learn about machine learning, neural networks, and how AI is transforming businesses.',
      outline: {
        'Module 1: AI Fundamentals': [
          'What is artificial intelligence',
          'History and evolution of AI',
          'Types of AI: narrow vs. general',
        ],
        'Module 2: Machine Learning Basics': [
          'Supervised learning',
          'Unsupervised learning',
          'Reinforcement learning',
        ],
        'Module 3: Neural Networks': [
          'Structure of neural networks',
          'Deep learning concepts',
          'Applications of neural networks',
        ],
        'Module 4: AI Applications': [
          'Computer vision',
          'Natural language processing',
          'Robotics and automation',
        ],
      },
      prerequisites: [
        'Basic understanding of mathematics',
        'No programming experience required',
        'Interest in technology and innovation',
      ],
      whoShouldAttend: 'Business leaders, managers, professionals, and anyone interested in understanding the fundamentals of AI and its business applications.',
      importantNotes: 'This course focuses on concepts rather than technical implementation. No coding knowledge is required.',
      feeStructure: {
        'Full Course Fee': {'Price': '\$1,200.00'},
        'SG Citizens aged 21 - 39 years old / PRs aged 21 years old and above': {'Individual': '\$600.00', 'Company Sponsored (Non-SME)': '\$600.00', 'Company Sponsored (SME)': '\$400.00'},
        'SG Citizens age 40 years old and above': {'Individual': '\$400.00', 'Company Sponsored (Non-SME)': '\$400.00', 'Company Sponsored (SME)': '\$400.00'},
      },
    ),
    Course(
      id: '18',
      courseCode: 'BIZ101',
      title: 'Digital Transformation Strategies',
      category: 'Business',
      certType: null,
      rating: 4.6,
      duration: '1 day',
      price: '\$950.00',
      funding: 'Eligible for funding',
      deliveryMethods: ['OLL', 'ILT'],
      nextAvailableDate: 'April 15, 2025',
      description: 'Learn how to lead successful digital transformation initiatives in your organization. This course covers strategic frameworks, implementation methodologies, and change management techniques.',
      outline: {
        'Module 1: Digital Transformation Fundamentals': [
          'What is digital transformation',
          'Drivers and enablers',
          'Digital maturity assessment',
        ],
        'Module 2: Strategic Frameworks': [
          'Business model innovation',
          'Customer experience transformation',
          'Operational excellence',
        ],
        'Module 3: Technology Enablers': [
          'Cloud computing',
          'Data analytics and AI',
          'IoT and automation',
        ],
        'Module 4: Implementation and Change Management': [
          'Roadmap development',
          'Managing organizational change',
          'Measuring success and ROI',
        ],
      },
      prerequisites: [
        'Management experience',
        'Basic understanding of business operations',
        'No technical background required',
      ],
      whoShouldAttend: 'Business leaders, executives, managers, consultants, and anyone responsible for driving digital initiatives within their organization.',
      importantNotes: 'Participants will develop a digital transformation roadmap for their organization during the course.',
      feeStructure: {
        'Full Course Fee': {'Price': '\$950.00'},
        'SG Citizens aged 21 - 39 years old / PRs aged 21 years old and above': {'Individual': '\$475.00', 'Company Sponsored (Non-SME)': '\$475.00', 'Company Sponsored (SME)': '\$332.50'},
        'SG Citizens age 40 years old and above': {'Individual': '\$332.50', 'Company Sponsored (Non-SME)': '\$332.50', 'Company Sponsored (SME)': '\$332.50'},
      },
    ),
    Course(
      id: '19',
      courseCode: 'SEC501',
      title: 'Blockchain Security',
      category: 'Cybersecurity',
      certType: null,
      rating: 4.9,
      duration: '3 days',
      price: '\$2,600.00',
      funding: 'Not eligible for funding',
      deliveryMethods: ['OLL'],
      nextAvailableDate: 'May 20, 2025',
      description: 'This specialized course covers the security aspects of blockchain technology, including vulnerabilities, attack vectors, and security best practices for blockchain implementations.',
      outline: {
        'Module 1: Blockchain Fundamentals': [
          'Blockchain architecture',
          'Consensus mechanisms',
          'Smart contracts',
        ],
        'Module 2: Security Vulnerabilities': [
          '51% attacks',
          'Smart contract vulnerabilities',
          'Wallet security issues',
        ],
        'Module 3: Security Controls': [
          'Cryptographic controls',
          'Secure coding practices',
          'Security auditing',
        ],
        'Module 4: Regulatory Compliance': [
          'Legal frameworks',
          'Privacy considerations',
          'AML/KYC requirements',
        ],
      },
      prerequisites: [
        'Understanding of cybersecurity principles',
        'Basic knowledge of blockchain technology',
        'Familiarity with cryptography concepts',
      ],
      whoShouldAttend: 'Security professionals, blockchain developers, security auditors, and IT professionals working with blockchain technologies.',
      importantNotes: 'This course includes hands-on labs where participants will identify and exploit vulnerabilities in blockchain applications.',
      feeStructure: {
        'Full Course Fee': {'Price': '\$2,600.00'},
        'SG Citizens aged 21 - 39 years old / PRs aged 21 years old and above': {'Individual': '\$2,600.00', 'Company Sponsored (Non-SME)': '\$2,600.00', 'Company Sponsored (SME)': '\$2,600.00'},
        'SG Citizens age 40 years old and above': {'Individual': '\$2,600.00', 'Company Sponsored (Non-SME)': '\$2,600.00', 'Company Sponsored (SME)': '\$2,600.00'},
      },
    ),
    Course(
      id: '20',
      courseCode: 'PRJ101',
      title: 'Agile Project Management',
      category: 'Project Management',
      certType: null,
      rating: 4.7,
      duration: '2 days',
      price: '\$0',
      funding: 'Complimentary',
      deliveryMethods: ['OLL', 'ILT'],
      nextAvailableDate: 'April 10, 2025',
      description: 'Learn the principles and practices of Agile project management, including Scrum, Kanban, and Lean methodologies. This course is offered complimentary as part of our community outreach program.',
      outline: {
        'Module 1: Agile Fundamentals': [
          'Agile manifesto and principles',
          'Traditional vs. Agile approaches',
          'Agile mindset',
        ],
        'Module 2: Scrum Framework': [
          'Scrum roles and responsibilities',
          'Sprint planning and execution',
          'Backlog management',
        ],
        'Module 3: Kanban System': [
          'Visualizing workflow',
          'WIP limits and flow',
          'Continuous improvement',
        ],
        'Module 4: Agile Practices': [
          'User stories',
          'Estimation techniques',
          'Retrospectives',
        ],
      },
      prerequisites: [
        'Basic understanding of project management concepts',
        'No prior Agile experience required',
      ],
      whoShouldAttend: 'Project managers, team leaders, product owners, and anyone interested in learning Agile methodologies.',
      importantNotes: 'This is a complimentary course, but registration is required as seats are limited. Priority is given to Singapore Citizens and Permanent Residents.',
      feeStructure: {
        'Full Course Fee': {'Price': '\$0'},
        'SG Citizens aged 21 - 39 years old / PRs aged 21 years old and above': {'Individual': '\$0', 'Company Sponsored (Non-SME)': '\$0', 'Company Sponsored (SME)': '\$0'},
        'SG Citizens age 40 years old and above': {'Individual': '\$0', 'Company Sponsored (Non-SME)': '\$0', 'Company Sponsored (SME)': '\$0'},
      },
    ),
    Course(
  id: '21',
  courseCode: 'MSO101',
  title: 'Essential Excel for Office Worker',
  category: 'Office Productivity',
  certType: null,
  rating: 4.5,
  duration: '1 day',
  price: '\$0',
  funding: 'Complimentary',
  deliveryMethods: ['OLL', 'ILT'],
  nextAvailableDate: 'April 5, 2025',
  description: 'Master the fundamentals of Microsoft Excel including formulas, formatting, and basic data analysis. This introductory course is perfect for beginners or those looking to refresh their Excel skills.',
  outline: {
    'Module 1: Excel Basics': [
      'Getting started with Excel interface',
      'Cell navigation and selection techniques',
      'Basic data entry and formatting',
    ],
    'Module 2: Essential Formulas': [
      'Creating basic formulas',
      'Using built-in functions (SUM, AVERAGE, MAX, MIN)',
      'Relative vs. absolute cell references',
    ],
    'Module 3: Data Management': [
      'Sorting and filtering data',
      'Creating and formatting tables',
      'Basic data validation',
    ],
    'Module 4: Charts and Visualization': [
      'Creating basic charts',
      'Customizing chart elements',
      'Visual data presentation',
    ],
  },
  prerequisites: [
    'Basic computer skills',
    'No prior Excel experience required',
  ],
  whoShouldAttend: 'Office workers, students, job seekers, and anyone looking to improve their productivity with Excel.',
  importantNotes: 'This is a complimentary course provided as part of our community outreach program. Participants must bring their own devices with Microsoft Excel installed.',
  feeStructure: {
    'Full Course Fee': {'Price': '\$0'},
    'SG Citizens aged 21 - 39 years old / PRs aged 21 years old and above': {'Individual': '\$0', 'Company Sponsored (Non-SME)': '\$0', 'Company Sponsored (SME)': '\$0'},
    'SG Citizens age 40 years old and above': {'Individual': '\$0', 'Company Sponsored (Non-SME)': '\$0', 'Company Sponsored (SME)': '\$0'},
  },
),

Course(
  id: '24',
  courseCode: 'MSO102',
  title: 'Microsoft Excel Advanced Techniques for Data Science',
  category: 'Office Productivity',
  certType: null,
  rating: 4.7,
  duration: '1 day',
  price: '\$0',
  funding: 'Complimentary',
  deliveryMethods: ['OLL'],
  nextAvailableDate: 'April 15, 2025',
  description: 'Take your Excel skills to the next level with advanced functions, PivotTables, and data analysis techniques. This course builds on basic Excel knowledge to help you become more efficient in data manipulation and analysis.',
  outline: {
    'Module 1: Advanced Functions': [
      'VLOOKUP, HLOOKUP, and INDEX-MATCH',
      'Logical functions (IF, AND, OR, IFERROR)',
      'Text and date manipulation functions',
    ],
    'Module 2: Data Analysis': [
      'PivotTables and PivotCharts',
      'What-if analysis tools',
      'Data analysis with slicers',
    ],
    'Module 3: Excel Power Tools': [
      'Power Query basics',
      'Data modeling concepts',
      'Introduction to Power Pivot',
    ],
    'Module 4: Automation': [
      'Recording basic macros',
      'Customizing the Excel interface',
      'Creating dashboard reports',
    ],
  },
  prerequisites: [
    'Microsoft Excel Essential Skills or equivalent experience',
    'Basic understanding of Excel formulas and functions',
  ],
  whoShouldAttend: 'Current Excel users looking to enhance their skills, data analysts, business professionals, and administrative staff who work with data.',
  importantNotes: 'This complimentary course requires participants to have prior Excel experience. Please bring your own device with Microsoft Excel installed.',
  feeStructure: {
    'Full Course Fee': {'Price': '\$0'},
    'SG Citizens aged 21 - 39 years old / PRs aged 21 years old and above': {'Individual': '\$0', 'Company Sponsored (Non-SME)': '\$0', 'Company Sponsored (SME)': '\$0'},
    'SG Citizens age 40 years old and above': {'Individual': '\$0', 'Company Sponsored (Non-SME)': '\$0', 'Company Sponsored (SME)': '\$0'},
  },
),

Course(
  id: '23',
  courseCode: 'MSO201',
  title: 'Microsoft PowerPoint Mastery the Mind Control',
  category: 'Office Productivity',
  certType: null,
  rating: 4.6,
  duration: '1 day',
  price: '\$0',
  funding: 'Complimentary',
  deliveryMethods: ['OLL', 'ILT'],
  nextAvailableDate: 'April 8, 2025',
  description: 'Learn to create engaging and professional presentations using Microsoft PowerPoint. This course covers everything from basic slides to advanced animations, transitions, and multimedia integration.',
  outline: {
    'Module 1: Presentation Fundamentals': [
      'PowerPoint interface and navigation',
      'Creating and organizing slides',
      'Working with templates and themes',
    ],
    'Module 2: Design and Formatting': [
      'Text formatting and alignment',
      'Working with images and shapes',
      'Creating SmartArt graphics',
    ],
    'Module 3: Animation and Media': [
      'Adding slide transitions',
      'Creating custom animations',
      'Incorporating audio and video',
    ],
    'Module 4: Delivering Presentations': [
      'Presenter view and presentation tools',
      'Creating handouts and notes',
      'Exporting presentations to different formats',
    ],
  },
  prerequisites: [
    'Basic computer skills',
    'No prior PowerPoint experience required',
  ],
  whoShouldAttend: 'Anyone who needs to create and deliver presentations, including business professionals, educators, students, and sales personnel.',
  importantNotes: 'This complimentary course is provided as part of our digital literacy initiative. Please bring a laptop with Microsoft PowerPoint installed.',
  feeStructure: {
    'Full Course Fee': {'Price': '\$0'},
    'SG Citizens aged 21 - 39 years old / PRs aged 21 years old and above': {'Individual': '\$0', 'Company Sponsored (Non-SME)': '\$0', 'Company Sponsored (SME)': '\$0'},
    'SG Citizens age 40 years old and above': {'Individual': '\$0', 'Company Sponsored (Non-SME)': '\$0', 'Company Sponsored (SME)': '\$0'},
  },
),

Course(
  id: '22',
  courseCode: 'MSO301',
  title: 'Essential Word for Office Worker',
  category: 'Office Productivity',
  certType: null,
  rating: 4.5,
  duration: '1 day',
  price: '\$0',
  funding: 'Complimentary',
  deliveryMethods: ['OLL'],
  nextAvailableDate: 'April 20, 2025',
  moodleCourseId: '8',
  description: 'Master Microsoft Word to create professional-looking documents for business and academic purposes. This course covers document formatting, styles, templates, and advanced editing features.',
  outline: {
    'Module 1: Document Basics': [
      'Word interface and navigation',
      'Document creation and formatting',
      'Page layout and design',
    ],
    'Module 2: Professional Formatting': [
      'Styles and themes',
      'Headers, footers, and page numbering',
      'Working with sections and columns',
    ],
    'Module 3: Advanced Features': [
      'Tables and table formatting',
      'Mail merge for mass communications',
      'Creating and using templates',
    ],
    'Module 4: Collaboration Tools': [
      'Track changes and comments',
      'Document protection and sharing',
      'Comparing and combining documents',
    ],
  },
  prerequisites: [
    'Basic computer skills',
    'Familiarity with word processing concepts',
  ],
  whoShouldAttend: 'Administrative professionals, students, job seekers, business owners, and anyone who needs to create professional documents.',
  importantNotes: 'This complimentary course requires participants to have Microsoft Word installed on their devices.',
  feeStructure: {
    'Full Course Fee': {'Price': '\$0'},
    'SG Citizens aged 21 - 39 years old / PRs aged 21 years old and above': {'Individual': '\$0', 'Company Sponsored (Non-SME)': '\$0', 'Company Sponsored (SME)': '\$0'},
    'SG Citizens age 40 years old and above': {'Individual': '\$0', 'Company Sponsored (Non-SME)': '\$0', 'Company Sponsored (SME)': '\$0'},
  },
),

Course(
  id: '25',
  courseCode: 'MSO401',
  title: 'Microsoft Outlook Email Management',
  category: 'Office Productivity',
  certType: null,
  rating: 4.4,
  duration: '1 day',
  price: '\$0',
  funding: 'Complimentary',
  deliveryMethods: ['OLL', 'ILT'],
  nextAvailableDate: 'May 3, 2025',
  description: 'Improve your email productivity and organization using Microsoft Outlook. Learn to manage emails, contacts, calendars, and tasks efficiently in a professional environment.',
  outline: {
    'Module 1: Email Management': [
      'Outlook interface overview',
      'Email composition and formatting',
      'Creating and using email templates',
    ],
    'Module 2: Organization Tools': [
      'Folders and filing system',
      'Search techniques and filters',
      'Rules and automatic processing',
    ],
    'Module 3: Calendar and Scheduling': [
      'Calendar views and navigation',
      'Creating and managing appointments',
      'Meeting scheduling and resource booking',
    ],
    'Module 4: Productivity Features': [
      'Task management and follow-ups',
      'Contact management',
      'Notes and integration with other Office apps',
    ],
  },
  prerequisites: [
    'Basic computer skills',
    'Access to Microsoft Outlook',
  ],
  whoShouldAttend: 'Office workers, administrators, managers, and anyone who uses email in a professional capacity.',
  importantNotes: 'This complimentary course is designed to help professionals better manage their digital communications. Participants should have Microsoft Outlook installed on their devices.',
  feeStructure: {
    'Full Course Fee': {'Price': '\$0'},
    'SG Citizens aged 21 - 39 years old / PRs aged 21 years old and above': {'Individual': '\$0', 'Company Sponsored (Non-SME)': '\$0', 'Company Sponsored (SME)': '\$0'},
    'SG Citizens age 40 years old and above': {'Individual': '\$0', 'Company Sponsored (Non-SME)': '\$0', 'Company Sponsored (SME)': '\$0'},
  },
),

Course(
  id: '26',
  courseCode: 'MSO501',
  title: 'Essential Word for Business Owner',
  category: 'Office Productivity',
  certType: null,
  rating: 4.8,
  duration: '1 day',
  price: '\$0',
  funding: 'Complimentary',
  deliveryMethods: ['OLL'],
  nextAvailableDate: 'April 30, 2025',
  moodleCourseId: '8',
  description: 'Master Microsoft Teams to enhance remote and hybrid workplace collaboration. Learn to use chat, meetings, channels, and app integrations to improve team productivity and communication.',
  outline: {
    'Module 1: Teams Fundamentals': [
      'Teams interface and navigation',
      'Chat and communication basics',
      'Creating and managing teams and channels',
    ],
    'Module 2: Effective Meetings': [
      'Scheduling and joining meetings',
      'Meeting features and controls',
      'Recording and sharing meetings',
    ],
    'Module 3: File Collaboration': [
      'File sharing and co-authoring',
      'Integration with SharePoint and OneDrive',
      'Managing file permissions',
    ],
    'Module 4: Productivity Enhancement': [
      'App integrations and tabs',
      'Using Teams on mobile devices',
      'Teams governance and best practices',
    ],
  },
  prerequisites: [
    'Basic computer skills',
    'Microsoft 365 account with Teams access',
  ],
  whoShouldAttend: 'Remote workers, team leaders, project managers, and anyone working in collaborative environments.',
  importantNotes: 'This complimentary course is provided to support effective remote and hybrid work practices. Participants should have access to Microsoft Teams.',
  feeStructure: {
    'Full Course Fee': {'Price': '\$0'},
    'SG Citizens aged 21 - 39 years old / PRs aged 21 years old and above': {'Individual': '\$0', 'Company Sponsored (Non-SME)': '\$0', 'Company Sponsored (SME)': '\$0'},
    'SG Citizens age 40 years old and above': {'Individual': '\$0', 'Company Sponsored (Non-SME)': '\$0', 'Company Sponsored (SME)': '\$0'},
  },
),
  ];

  static List<Course> userCourseHistory = [
    Course(
      id: '1',
      courseCode: 'SEC101',
      title: 'Network Security Fundamentals',
      category: 'Cybersecurity',
      certType: 'CEH',
      rating: 4.8,
      duration: '8 weeks',
      price: '\$1,299',
      completionDate: 'Jan 15, 2025',
    ),
    Course(
      id: '2',
      courseCode: 'CLD201',
      title: 'Cloud Infrastructure Management',
      category: 'Cloud Computing',
      certType: 'CCNA',
      rating: 4.6,
      duration: '10 weeks',
      price: '\$1,499',
      completionDate: 'Feb 25, 2025',
    ),
  ];
}
