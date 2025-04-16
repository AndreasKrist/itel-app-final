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
  final String? imageUrl;     // For banner/image
  final String? customLink;   // For custom link
  final String? description;  // Short description
  final List<String>? tags;   // For tags
  
  // Single field for full custom content
  final String? fullContent;  // Complete article/news/event content
  
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
  });
  
  static List<TrendingItem> sampleItems = [
    TrendingItem(
      id: '1',
      title: 'The Development of Linux and Its Power Today',
      category: 'Article',
      type: TrendingItemType.article,
      date: 'April 5, 2025',
      imageUrl: 'assets/images/banner.png',
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
      category: 'Article',
      type: TrendingItemType.article,
      date: 'March 7, 2025',
      imageUrl: 'assets/images/banner.png',
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
      category: 'Aticle',
      type: TrendingItemType.article,
      date: 'January 15, 2025',
      imageUrl: 'assets/images/banner.png',
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
      title: 'Tech Trends in 2025',
      category: 'Aticle',
      type: TrendingItemType.article,
      date: 'December 27, 2024',
      imageUrl: 'assets/images/banner.png',
      description: 'Join industry leaders for a day of insights, networking, and hands-on workshops focused on the latest cybersecurity trends and challenges.',
      tags: ['Cybersecurity', 'Networking', 'Workshop'],
      fullContent: '''
As we look toward 2025, the landscape of information technology is set to evolve in ways that will redefine the very fabric of business, society, and everyday life. In this rapidly shifting environment, organizations will not only need to adapt but also embrace new paradigms to stay competitive, all while navigating the complex challenges of cybersecurity, data privacy, and ethical AI use. These will reshape how we live, work, and interact with the world.

By 2025, AI will have transitioned from a futuristic idea to an integral part of our everyday lives. Despite this progress, we are still in the early stages of the intelligence revolution. With innovations ranging from generative video to autonomous AI agents and potentially even quantum-powered AI, groundbreaking advancements are expected to push the limits of what we thought possible—sometimes in awe-inspiring, other times in unsettling ways. The most transformative AI applications in 2025 will focus on the evolving collaboration between humans and machines, with AI tools designed to support our daily activities while enhancing our capabilities. For instance, generative video may become mainstream as technologies like OpenAI’s Sora become more accessible.

It is predicted that by 2025, the threat of cyberattacks to businesses will be overshadowed by the growing risks to society, national security, and public safety. Attacks targeting critical infrastructure—such as energy grids, healthcare systems, and electoral processes—are on the rise. These attacks have the potential to disrupt essential services, destabilize economies, and undermine public trust in institutions. Addressing these threats will require significant investment in cybersecurity, national cooperation, and the use of AI for enhanced detection and prevention. However, the challenge is compounded by the fact that cyber attackers will also exploit AI for political motives, making cybersecurity a pressing issue not just for businesses, but for global security.

According to a Gartner report, by 2028, enterprises utilizing AI governance platforms will achieve 30% higher customer trust ratings and 25% better regulatory compliance scores than their competitors. Additionally, 50% of enterprises will adopt products, services, or features to address disinformation security, a dramatic increase from less than 5% in 2024. Disinformation, which encompasses phishing, hacktivism, fake news, and social engineering, has become a digital arms race. Companies like NewsGuard and Jigsaw (a Google subsidiary) are developing AI-powered platforms to detect and combat disinformation across social media, ensuring users are exposed to accurate and verified content.

Energy-efficient computing refers to designing and operating computers, data centers, and other digital systems in ways that minimize energy consumption and reduce carbon footprints. They will continue to grow in importance. Hybrid computing, which combines diverse technologies such as CPUs, GPUs, edge devices, and quantum systems, will address complex computational challenges by tapping into the strengths of each technology. Cloud-based quantum computing, in particular, could become more accessible in 2025, making its transformative potential more tangible for businesses and organizations. Experts predict that quantum computing will revolutionize fields like climate modeling, material discovery, genomics, clean energy, and encryption.

Meanwhile, CRISPR and other gene-editing technologies are reshaping healthcare and agriculture. These advances enable the correction of genetic disorders and the development of crops that can thrive in extreme conditions, exemplified by promising treatments for sickle cell anemia and genetically modified crops designed to withstand climate change.

In conclusion, the landscape of technology in 2025 promises a future where AI, hybrid computing, and gene-editing technologies will play pivotal roles in shaping industries, society, and the environment. However, with these advancements come significant challenges, particularly in the realms of cybersecurity, data privacy, and the ethical implications of AI use. As we navigate these profound changes, the key to success will lie in how we balance technological progress with responsible and thoughtful governance.

The above article includes the findings from the Forbes and Gartner reports on top emerging tech trends for 2025. (Forbes, September 2024; Gartner, October 2024)
              ''',
    ),
    TrendingItem(
      id: '5',
      title: 'Embracing the Digital Future: How Technology is Transforming our',
      category: 'Aticle',
      type: TrendingItemType.article,
      date: 'November 15, 2024',
      imageUrl: 'assets/images/banner.png',
      description: 'Join industry leaders for a day of insights, networking, and hands-on workshops focused on the latest cybersecurity trends and challenges.',
      tags: ['Cybersecurity', 'Networking', 'Workshop'],
      fullContent: '''
In Singapore, digitalization has brought numerous benefits to families, enhancing both daily life and long-term opportunities. Families can now seamlessly access a wide range of services and resources online, from digital healthcare platforms that allow for remote consultations to government services like digital banking, bill payments, and even education portals for children. The convenience of digital tools has made managing household tasks easier, enabling parents to work from home, shop online, and communicate effortlessly with extended family members, both locally and abroad. Moreover, digital platforms have also opened doors to lifelong learning, with parents and children alike able to access educational content, courses, and tutorials on various subjects. For families with young children, interactive and educational apps have become valuable tools for learning and development.

To further build on the digitalization trend, the Digital for Life Festival by the Infocomm Media Development Authority (IMDA) was one of the most exciting digital innovation events in Singapore in the month of October and November 2024. Focused on celebrating the intersection of technology, creativity, and live experiences, the festival showcased the transformative potential of digital tools in the live entertainment industry. The event brought together tech innovators, creative professionals, and industry leaders to explore how digital solutions could elevate live performances, from immersive experiences and augmented reality (AR) to virtual reality (VR) and advanced live-streaming technologies. Additionally, there were discussions, workshops, and panels led by industry experts, exploring topics such as the future of digital storytelling, the role of AI in live performances, and the evolving nature of audience engagement in the digital age.

As digital tools continue to reshape every aspect of our daily life, they inspire both individuals and organizations to embrace the potential of digitalization in their everyday lives and creative pursuits.
              ''',
    ),
    TrendingItem(
      id: '6',
      title: 'Public Consultation on Suggested Guidelines for AI Security',
      category: 'Aticle',
      type: TrendingItemType.article,
      date: 'October 9, 2024',
      imageUrl: 'assets/images/banner.png',
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
      title: 'New SCTP Certification Path',
      category: 'Certification News',
      type: TrendingItemType.news,
      date: 'Just announced',
      imageUrl: 'assets/images/2.webp',
      description: 'ITEL introduces a new SCTP certification path designed to meet the evolving needs of IT professionals in Singapore.',
      tags: ['Certification', 'SCTP', 'Career Development'],
    ),
    TrendingItem(
      id: '13',
      title: 'Top Tech Skills for 2025',
      category: 'Career Development',
      type: TrendingItemType.article,
      readTime: '5 min read',
      imageUrl: 'assets/images/3.webp',
      description: 'Discover the most in-demand technology skills that employers are looking for in 2025 and beyond.',
      tags: ['Skills', 'Career', 'Technology Trends'],
    ),
    TrendingItem(
      id: '14',
      title: 'Future of Online Learning',
      category: 'Education',
      type: TrendingItemType.article,
      readTime: '8 min read',
      imageUrl: 'assets/images/4.webp',
      description: 'How technology is transforming education and what it means for learners and educators in the digital age.',
      tags: ['E-learning', 'EdTech', 'Digital Transformation'],
    ),
    TrendingItem(
      id: '15',
      title: 'Cloud Security Best Practices',
      category: 'Cybersecurity',
      type: TrendingItemType.article,
      readTime: '10 min read',
      imageUrl: 'assets/images/5.webp',
      description: 'Essential security practices every organization should implement to protect their cloud infrastructure and data.',
      tags: ['Cloud Computing', 'Security', 'Best Practices'],
    ),
    TrendingItem(
      id: '16',
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