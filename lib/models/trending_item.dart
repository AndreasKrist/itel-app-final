enum TrendingItemType {
  upcomingEvents,
  coursePromotion,
  featuredArticles,
  techTipsOfTheWeek,
  courseAssessor,
}

class TrendingItem {
  final String id;
  final String title;
  final String category;
  final TrendingItemType type;
  final String? date;
  final String? readTime;
  final String? imageUrl;
  final String? customLink;
  final String? description;
  final List<String>? tags;
  final String? fullContent;   
  
  // Add new fields specifically for events
  final String? eventTime;
  final String? eventLocation;
  final String? eventFormat;
  final List<String>? eventLearningPoints; // What You'll Learn bullets
  
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
    this.fullContent,
    // New parameters for event details
    this.eventTime,
    this.eventLocation,
    this.eventFormat,
    this.eventLearningPoints,
  });

  // JSON serialization methods
  factory TrendingItem.fromJson(Map<String, dynamic> json) {
    return TrendingItem(
      id: json['id'] as String,
      title: json['title'] as String,
      category: json['category'] as String,
      type: _stringToTrendingItemType(json['type'] as String),
      date: json['date'] as String?,
      readTime: json['readTime'] as String?,
      imageUrl: json['imageUrl'] as String?,
      customLink: json['customLink'] as String?,
      description: json['description'] as String?,
      tags: (json['tags'] as List<dynamic>?)?.cast<String>(),
      fullContent: json['fullContent'] as String?,
      eventTime: json['eventTime'] as String?,
      eventLocation: json['eventLocation'] as String?,
      eventFormat: json['eventFormat'] as String?,
      eventLearningPoints: (json['eventLearningPoints'] as List<dynamic>?)?.cast<String>(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'category': category,
      'type': _trendingItemTypeToString(type),
      'date': date,
      'readTime': readTime,
      'imageUrl': imageUrl,
      'customLink': customLink,
      'description': description,
      'tags': tags,
      'fullContent': fullContent,
      'eventTime': eventTime,
      'eventLocation': eventLocation,
      'eventFormat': eventFormat,
      'eventLearningPoints': eventLearningPoints,
    };
  }

  // Helper methods for enum conversion
  static TrendingItemType _stringToTrendingItemType(String typeString) {
    switch (typeString) {
      case 'upcomingEvents':
        return TrendingItemType.upcomingEvents;
      case 'coursePromotion':
        return TrendingItemType.coursePromotion;
      case 'featuredArticles':
        return TrendingItemType.featuredArticles;
      case 'techTipsOfTheWeek':
        return TrendingItemType.techTipsOfTheWeek;
      case 'courseAssessor':
        return TrendingItemType.courseAssessor;
      default:
        throw ArgumentError('Unknown TrendingItemType: $typeString');
    }
  }

  static String _trendingItemTypeToString(TrendingItemType type) {
    switch (type) {
      case TrendingItemType.upcomingEvents:
        return 'upcomingEvents';
      case TrendingItemType.coursePromotion:
        return 'coursePromotion';
      case TrendingItemType.featuredArticles:
        return 'featuredArticles';
      case TrendingItemType.techTipsOfTheWeek:
        return 'techTipsOfTheWeek';
      case TrendingItemType.courseAssessor:
        return 'courseAssessor';
    }
  }
  
  static List<TrendingItem> sampleItems = [
    TrendingItem(
      id: '1',
      title: 'The Development of Linux and Its Power Today',
      category: 'Featured Articles',
      type: TrendingItemType.featuredArticles,
      date: 'April 5, 2025',
      imageUrl: '',
      description: 'Originally developed as a hobby project by Linus Torvalds in 1991, Linux has grown into one of the world’s most powerful and widely used operating systems. Its open-source nature, adaptability, and security have driven its expansion, making it the backbone of modern digital infrastructure, from cloud computing and supercomputers to enterprise servers.In Singapore, Linux plays a pivotal role across various sectors, including government, education, startups, and corporate enterprises. Looking ahead, Linux’s influence remains strong as it continues to drive advancements in artificial intelligence (AI), the Internet of Things (IoT), and cloud computing—cementing its role in shaping the future of technology.Why Linux Engineers Are in DemandThe widespread adoption of Linux has created a high demand for skilled professionals across multiple industries:',
      tags: ['Cybersecurity', 'Networking', 'Workshop'],
      fullContent: '''
        Originally developed as a hobby project by Linus Torvalds in 1991, Linux has grown into one of the world’s most powerful and widely used operating systems. Its open-source nature, adaptability, and security have driven its expansion, making it the backbone of modern digital infrastructure, from cloud computing and supercomputers to enterprise servers.

In Singapore, Linux plays a pivotal role across various sectors, including government, education, startups, and corporate enterprises. Looking ahead, Linux’s influence remains strong as it continues to drive advancements in artificial intelligence (AI), the Internet of Things (IoT), and cloud computing—cementing its role in shaping the future of technology.

Why Linux Engineers Are in Demand

The widespread adoption of Linux has created a high demand for skilled professionals across multiple industries:

Enterprise Adoption – Organizations worldwide, including those in Singapore, rely on Linux for IT infrastructure, requiring skilled engineers for system administration, security, and maintenance.
Cloud Computing & DevOps – Major cloud platforms (AWS, Google Cloud, Azure) run on Linux, increasing the need for engineers with cloud and containerization expertise.
Cybersecurity – As Linux dominates enterprise and government IT systems, security-focused Linux engineers are essential for protecting critical data and infrastructure.
Open-Source Contributions – Companies leveraging Linux require engineers to customize and contribute to open-source projects, optimizing performance and functionality.
AI & IoT Growth – The rise of AI and IoT has expanded opportunities for Linux engineers in automation, data processing, and embedded systems.

The demand for Linux engineers in Singapore is evident in job market trends. As of November 19, 2024, there were over 1,000 job listings for Linux engineers on Indeed.com, highlighting the strong need for professionals with Linux expertise. By February 22, 2025, Indeed.com still listed over 300 Linux engineer positions in the Singapore 228095 area, reinforcing the sustained demand in the region.

To support this growing demand, ITEL offers various Linux courses, including CompTIA Linux+, CKA (Certified Kubernetes Administrator), CKAD (Certified Kubernetes Application Developer), and DevOps Advanced, equipping professionals with the necessary skills to thrive in this field.

These figures and educational opportunities illustrate the consistent need for Linux engineers in Singapore, emphasizing Linux’s critical role across technology, finance, and government sectors. As businesses continue to embrace Linux-based solutions, professionals with Linux expertise will remain essential in driving innovation and securing digital infrastructure.
              ''',
    ),
    TrendingItem(
      id: '2',
      title: 'The Widespread Impact of VoIP Technology',
      category: 'Featured Articles',
      type: TrendingItemType.featuredArticles,
      date: 'March 7, 2025',
      imageUrl: '',
      description: 'Join industry leaders for a day of insights, networking, and hands-on workshops focused on the latest cybersecurity trends and challenges.',
      tags: ['Cybersecurity', 'Networking', 'Workshop'],
      fullContent: '''
Voice over Internet Protocol (VoIP) has revolutionized the way we communicate, enabling voice calls over the internet and bypassing traditional telephone systems. However, few people know that the development of VoIP is significantly tied to a woman who played a pivotal role in shaping this technology.


The Woman Who Created VoIP

Dr. Marian Rogers Croak, an engineer and innovator, is credited with creating VoIP technology. During her career at various tech companies, Dr. Croak conducted groundbreaking research and developed algorithms and protocols that enabled voice data to be transmitted over the internet. Her pioneering work in digital communication and her innovative ideas laid the foundation for VoIP technology, though much of the credit is often attributed to a broader group of engineers and developers.

Dr. Croak’s contributions to the early development of VoIP have had a lasting impact on the future of communication, making it more accessible and affordable worldwide. Her work paved the way for modern communication platforms like Skype, WhatsApp, and Zoom, which are now integral to both personal and professional life.

VoIP technology has grown to provide several key benefits:

- Cost-Effective Communication: VoIP has significantly reduced the cost of voice calls, particularly for international communication. Users can make calls over the internet for little to no cost.
- Accessibility and Flexibility: VoIP services are available across a variety of devices, including smartphones, computers, tablets, and even dedicated VoIP phones.
- Enhanced Features: VoIP services often include added features such as video calls, voicemail-to-email, call forwarding, and integration with other online services.
- Scalability for Businesses: For businesses, VoIP offers scalability and efficiency. Unlike traditional phone systems, which require costly hardware and physical lines, VoIP can be easily scaled to meet a company’s needs, reducing costs and simplifying management.
- Improved Communication Quality: With advancements in VoIP technology, the quality of calls has greatly improved, with high-definition voice and video calls becoming the standard.
In summary, VoIP has had a profound impact on the way we communicate, and the role of pioneers like Dr. Marian Rogers Croak in its creation cannot be overstated. Thanks to VoIP, communication has become more accessible, affordable, and feature-rich than ever before, transforming the way we connect globally.
              ''',
    ),
    TrendingItem(
      id: '3',
      title: 'Tech Trends for Singapore Enterprises 2025',
      category: 'Featured Articles',
      type: TrendingItemType.featuredArticles,
      date: 'January 15, 2025',
      imageUrl: '',
      description: 'Join industry leaders for a day of insights, networking, and hands-on workshops focused on the latest cybersecurity trends and challenges.',
      tags: ['Cybersecurity', 'Networking', 'Workshop'],
      fullContent: '''
According to The Straits Times (2025, January 6), “Singapore’s cyber frameworks and practices are set to become global gold standards, with cybersecurity leaders scrambling for talent and chief information officers (CIOs) embracing agentic systems.” This shift highlights the emerging trend of autonomous AI agents in workflows, poised to surpass previous technologies such as generative AI and chatbots. These AI agents will operate independently, collaborating with each other and making real-time decisions without constant human input. For example, AI agents could be deployed to handle complex tasks like negotiating with customers who have overdue bills.

Major tech firms like Microsoft, Google, Salesforce, and SAP are integrating these agents into their software to tackle challenges such as talent shortages, boost productivity, and enhance sales and customer service. However, the full benefits of these systems may only become evident by 2025, as many companies are still in the early stages of adoption.

To fully leverage autonomous AI agents, companies will need to invest in infrastructure, such as data management systems and integration strategies. Additionally, oversight mechanisms will be necessary to ensure these AI systems are used responsibly and to mitigate any potential impacts on employees and stakeholders. These agents have the potential to revolutionize industries by handling complex, time-consuming tasks like customer service and collections (e.g., negotiating overdue payments). This could free up human workers to focus on higher-value activities, improving efficiency and enhancing customer experiences.

As AI systems become more autonomous, issues surrounding accountability, transparency, and ethical use will become increasingly important. Strong oversight is needed to ensure that AI agents operate in alignment with corporate values and societal norms, while also managing their impact on employees and other stakeholders.

The demand for cybersecurity experts is also growing rapidly, as companies increase spending to protect not only their own networks but also those of their suppliers. However, the supply of qualified cybersecurity talent is falling short of this demand. According to the Ministry of Manpower’s Shortage Occupation List, three out of 13 job categories in Infocomm Technology are cybersecurity roles, highlighting the need for foreign expertise. The Cyber Security Agency is also conducting a study to define the minimum skill requirements for cybersecurity personnel, which could further reduce the talent pool.

Several factors are expected to exacerbate the shortage of cybersecurity talent, including the end of support for Windows 10 (after October 14, 2025) and the passing of the Health Information Bill in 2025. The end of support for Windows 10 will leave users vulnerable to cyberattacks due to the lack of security updates, while the Health Information Bill will require healthcare providers to migrate sensitive data, presenting new security and compliance challenges.

The clear shortage of cybersecurity talent requires comprehensive, long-term solutions. Key measures include ramping up investment in training and development programs and fostering closer collaboration between industry and educational institutions to ensure curricula are better aligned with the sector’s evolving needs.

In December, Indeed reported a significant surge in generative AI-related job postings, with a 4.6-fold increase over the 12 months leading up to September, compared to the previous year. Singapore led other developed economies—such as Ireland, Spain, Canada, Britain, the US, Germany, Australia, and France—in the number of AI-related job postings.

The demand for AI skills now extends beyond traditional roles in data analytics, reaching industries such as architecture and medical information. This reflects the growing integration of AI across diverse fields. Callam Pickering, Indeed’s economist for the Asia-Pacific, noted that the demand for generative AI skills is outpacing supply, as these skills are still emerging and evolving. He emphasized that businesses that can effectively reskill and upskill their existing workforce will have a competitive advantage in the future job market.

As Singapore’s technology landscape evolves, the growing demand for cybersecurity and AI professionals presents both challenges and opportunities for enterprises. The rise of autonomous AI agents is set to transform workflows by handling complex tasks independently, boosting productivity, and enhancing customer experiences. However, the successful integration of these systems will require significant investment in infrastructure, oversight mechanisms, and ongoing skill development. Simultaneously, the shortage of qualified cybersecurity talent calls for long-term solutions, such as increased training and closer collaboration between industry and educational institutions.

Reference:
The Straits Times. (2025, January 6) “5 tech trends for Singapore enterprises in 2025”
              ''',
    ),
    TrendingItem(
      id: '4',
      title: '10 Essential Windows Shortcuts Every User Should Know',
      category: 'TechTips of the Week',
      type: TrendingItemType.techTipsOfTheWeek,
      date: 'January 29, 2025',
      imageUrl: '',
      description: 'Boost your productivity with these 10 powerful Windows shortcuts that will save you time and make your computing experience more efficient.',
      tags: ['Windows', 'Shortcuts', 'Productivity'],
      fullContent: '''
Master these 10 essential Windows shortcuts to dramatically improve your productivity and streamline your daily computing tasks:

1. Windows Key + L - Lock Your Computer
Instantly lock your screen when stepping away from your desk. This is crucial for maintaining security in shared workspaces.

2. Alt + Tab - Switch Between Applications
Quickly cycle through open applications without using your mouse. Hold Alt and press Tab repeatedly to navigate between programs.

3. Windows Key + D - Show/Hide Desktop
Instantly minimize all windows to access your desktop, or restore them with the same shortcut.

4. Ctrl + Shift + Esc - Open Task Manager
Direct access to Task Manager without going through Ctrl+Alt+Del. Perfect for managing unresponsive applications.

5. Windows Key + I - Open Settings
Quickly access Windows Settings instead of navigating through menus.

6. Windows Key + S - Open Search
Instantly open the Windows search function to find files, applications, or settings.

7. Ctrl + C, Ctrl + V, Ctrl + X - Copy, Paste, Cut
The holy trinity of productivity shortcuts. Essential for moving text, files, and data efficiently.

8. Windows Key + Arrow Keys - Snap Windows
Use left/right arrows to snap windows to half the screen, or up/down to maximize/minimize windows.

9. Alt + F4 - Close Current Window
Quickly close the active window or application without clicking the X button.

10. Windows Key + V - Clipboard History
Access your clipboard history to paste from multiple copied items (requires Windows 10 version 1809 or later).

Pro Tip: Practice these shortcuts daily for a week, and they'll become second nature. Your mouse will thank you for the reduced workload!

Bonus: Windows Key + Period (.) opens the emoji panel for adding expressions to your messages! 😊
              ''',
    ),
    TrendingItem(
      id: '6',
      title: 'Public Consultation on Suggested Guidelines for AI Security',
      category: 'Featured Articles',
      type: TrendingItemType.featuredArticles,
      date: 'October 9, 2024',
      imageUrl: '',
      description: 'Join industry leaders for a day of insights, networking, and hands-on workshops focused on the latest cybersecurity trends and challenges.',
      tags: ['Cybersecurity', 'Networking', 'Workshop'],
      fullContent: '''
Artificial Intelligence (AI) is widely recognized for its ability to enhance efficiency and drive innovation across various sectors. However, some inherent threats can hinder this potential. AI systems are at risk of cybersecurity issues, including adversarial attacks, where malicious actors intentionally attempt to mislead the AI. These issues can worsen existing weaknesses in business systems, leading to data leaks, breaches, and unfair or harmful outcomes. To fully realize AI’s benefits while mitigating these risks, organizations must prioritize its security

To address security concerns, the Cyber Security Agency of Singapore (CSA) has developed the Guidelines on Securing AI Systems to help system owners protect AI throughout its lifecycle. These guidelines raise awareness of potential threats to AI behaviour and system security, offering principles and best practices for implementing security controls. Additionally, the CSA is working with AI and cybersecurity experts to create a Companion Guide that will provide practical measures and insights from both industry and academia to support the main guidelines.

Additionally, CSA is holding a public consultation on the Guidelines and the Companion Guide, which will close on September 15, 2024.

The Guidelines point out the cybersecurity risks related to AI, including both classical threats and Adversarial Machine Learning (ML). These new attacks try to confuse the AI and lead to inaccurate or harmful results.

Classical risks include supply chain attacks, unauthorized access, and disruptions to cloud services, data centre operations or other digital infrastructure (e.g Denial of Service attacks). Adversarial ML risks involve data poisoning, evasion attacks that mislead trained models, and extraction attacks that aim to steal sensitive data or the model itself.

Risk Assessment

The Guidelines suggest that organisations begin securing AI systems with a risk assessment. This helps identify potential risks and priorities, leading to suitable risk management strategies. They recommend a four-step process for managing risks:

Step 1: Conduct a risk assessment that focuses on the security risks to AI systems.
Step 2: Prioritise areas to address based on risk level, impact, and available resources.
Step 3: Identify and take the necessary actions to secure the AI system.
Step 4: Evaluate any remaining risks and decide whether to mitigate or accept them.
Guidelines for Securing AI Systems

These Guidelines apply to all five stages of an AI system’s lifecycle. System owners should consider it as essential points to ensure the secure implementation of AI.

Stage 1: Planning and Design
• Increase awareness and understanding of security risks.
• Perform security risk assessments.

Stage 2: Development
• Ensure the security of the supply chain.
• Evaluate the security benefits and trade-offs when choosing the right model.
• Identify, monitor, and safeguard AI-related assets.
• Protect the AI development environment.

Stage 3: Deployment
• Secure the infrastructure and environment for deploying AI systems.
• Set up incident management procedures.
• Ensure the responsible release of AI systems.

Stage 4: Operations and Maintenance
• Monitor the inputs to the AI system.
• Track the outputs and behavior of the AI system.
• Implement a secure-by-design approach for updates and ongoing learning.
• Establish a vulnerability disclosure process.

Stage 5: End of Life
• Ensure the proper disposal of data and models.

The Cyber Security Agency of Singapore’s guidelines provide a structured approach for businesses to enhance their AI security, promoting a proactive stance on potential threats. The ongoing public consultation allows stakeholders to contribute their insights, ensuring diverse perspectives are considered in developing effective security measures. As the field of AI security continues to evolve, businesses must remain vigilant and adapt their strategies to counter emerging threats, highlighting the necessity for continuous improvement in safeguarding AI systems.

By establishing the Guidelines on Securing AI Systems, the Cyber Security Agency of Singapore (CSA) emphasizes the importance of proactive measures in safeguarding AI technologies. This initiative not only raises awareness of potential vulnerabilities but also encourages system owners to adopt best practices for risk management throughout the AI lifecycle.

Source from news from Cyber Security Agency of Singapore (CSA).
              ''',
    ),
    TrendingItem(
      id: '12',
      title: 'Adobe Photoshop Complete Level 1',
      category: 'Course Promotion',
      type: TrendingItemType.coursePromotion,
      customLink: 'course://102',
      description: 'Master the fundamentals of Adobe Photoshop with our comprehensive Level 1 course. Perfect for beginners looking to develop professional design skills.',
      tags: ['Adobe', 'Photoshop', 'Design'],
    ),
    TrendingItem(
      id: '13',
      title: 'PTSA - Prelim Tech Skills Assessor',
      category: 'Course Assessor',
      type: TrendingItemType.courseAssessor,
      customLink: 'https://itel-ptsa.vercel.app/',
      description: 'Assess your preliminary technology skills and get personalized learning recommendations.',
      tags: ['Assessment', 'Skills', 'PTSA'],
    ),
    TrendingItem(
      id: '14',
      title: 'Microsoft Excel Visual Basic Applications (VBA)',
      category: 'Course Promotion',
      type: TrendingItemType.coursePromotion,
      customLink: 'course://79',
      description: 'Automate your Excel workflows and boost productivity with VBA programming. Learn to create powerful macros and custom applications.',
      tags: ['Microsoft', 'Excel', 'VBA'],
    ),
    TrendingItem(
    id: '16',
    title: 'Tech Skill-Up Festival 2025',
    category: 'Upcoming Events',
    type: TrendingItemType.upcomingEvents,
    date: 'March 12, 2025',
    imageUrl: 'assets/images/techskill.png',
    customLink: 'https://itel.com.sg/itel-tech-skill-up-festival-2025/',
    description: 'A hands-on workshop introducing the fundamentals of artificial intelligence and machine learning for beginners.',
    tags: ['Skill', 'Course', 'Workshop'],
    // Structured event details
    eventTime: '09:00 AM - 05:00 PM',
    eventLocation: 'ITEL Training Center, Singapore',
    eventFormat: 'In-person workshop',
    eventLearningPoints: [
      'Latest industry trends and technologies',
      'Hands-on practical skills and techniques',
      'Networking opportunities with industry experts',
      'Certificate of participation',
    ],
  ),
  ];
}