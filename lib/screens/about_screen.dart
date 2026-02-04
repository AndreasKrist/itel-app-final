import 'package:flutter/material.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('About ITEL'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          
          // Logo or image
          Center(
            child: Container(
              width: 160,
              height: 160,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color.fromARGB(255, 255, 255, 255),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Image.asset(
                'assets/images/itel.png',
                fit: BoxFit.contain,
              ),
            ),
          ),
          const SizedBox(height: 24),
          
          // Vision section
          _buildVisionMissionSection(
            title: 'Vision',
            content: 'A World Class Life-Long Learning Center',
            bgColor: Colors.blue[50]!,
            textColor: Color(0xFF0056AC)!,
          ),
          const SizedBox(height: 24),
          
          // Mission section with icons
          _buildSectionTitle('Mission'),
          const SizedBox(height: 16),
          _buildMissionGrid(),
          const SizedBox(height: 24),
          
          // Our Story
          _buildSectionTitle('Our Story'),
          const SizedBox(height: 12),
          Text(
            'ITEL was conceived in 2001 by the need for IT Training Services. With its early origins as a New Horizons franchise, the company has moved forward to rebrand to the present-day ITEL.\n\nHeadquartered in Singapore, ITEL is an authorized Accredited Training Organization (ATO) and Continuing Education and Training (CET) service provider of industry training courses in the area of IT and Business. Training sessions are conducted on premises within its training centre, externally within the client site, and remotely.\n\nOver the past 23 years, ITEL has built a strong track record with more than 214,842 graduates and 250+ courses offered. In collaboration with Singapore Government–affiliated organizations such as SkillsFuture Singapore (SSG) and industry leaders like EC-Council, CompTIA, Microsoft, and PeopleCert, ITEL has been entrusted to deliver 26 SSG-funded courses alongside a growing suite of non-funded programs that are gaining popularity.\n\nITEL also offers a customized or curated approach to its corporate and group courses. Curriculum and delivery can be crafted to suit each group\'s needs.\n\nAt ITEL, we build on past insights to continuously enhance our training products and services, ensuring they evolve to address current needs and anticipate future advancements.',
            style: TextStyle(
              color: Colors.grey[800],
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),
          
          // Key Statistics
          _buildSectionTitle('You Can Trust Us'),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _buildStatistic(
                    icon: Icons.people,
                    number: '214,842+',
                    label: 'Graduates',
                  ),
                ),
                Expanded(
                  child: _buildStatistic(
                    icon: Icons.book,
                    number: '250+',
                    label: 'No. of Courses',
                  ),
                ),
                Expanded(
                  child: _buildStatistic(
                    icon: Icons.calendar_today,
                    number: '23',
                    label: 'Years in Business',
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Partners section
          _buildSectionTitle('Partners'),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildPartnerImage('assets/images/partner1.webp'),
                  const SizedBox(width: 12),
                  _buildPartnerImage('assets/images/partner2.webp'),
                  const SizedBox(width: 12),
                  _buildPartnerImage('assets/images/partner3.webp'),
                  const SizedBox(width: 12),
                  _buildPartnerImage('assets/images/partner4.webp'),
                  const SizedBox(width: 12),
                  _buildPartnerImage('assets/images/partner5.jpg'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Accolades section
          _buildSectionTitle('Accolades'),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildPartnerImage('assets/images/accolade1.webp'),
                  const SizedBox(width: 12),
                  _buildPartnerImage('assets/images/accolade2.webp'),
                  const SizedBox(width: 12),
                  _buildPartnerImage('assets/images/accolade3.webp'),
                  const SizedBox(width: 12),
                  _buildPartnerImage('assets/images/accolade4.webp'),
                  const SizedBox(width: 12),
                  _buildPartnerImage('assets/images/accolade5.webp'),
                  const SizedBox(width: 12),
                  _buildPartnerImage('assets/images/accolade6.webp'),
                  const SizedBox(width: 12),
                  _buildPartnerImage('assets/images/accolade7.webp'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Contact Us
          _buildSectionTitle('Contact Us'),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                _buildContactItem(
                  icon: Icons.email,
                  title: 'Email',
                  detail: 'enquiry@itel.com.sg',
                ),
                const Divider(),
                _buildContactItem(
                  icon: Icons.phone,
                  title: 'Phone',
                  detail: '6822 8282',
                ),
                const Divider(),
                _buildContactItem(
                  icon: Icons.location_on,
                  title: 'Address',
                  detail: '1 Maritime Square, HarbourFront Centre #10-24/25 (Lobby B) Singapore 099253',
                ),
                const Divider(),
                _buildContactItem(
                  icon: Icons.language,
                  title: 'Website',
                  detail: 'https://itel.com.sg/',
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Copyright
          Center(
            child: Text(
              '© 2026 ITEL. All rights reserved.',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
        ),
      ),
    );
  }

  Widget _buildVisionMissionSection({
    required String title,
    required String content,
    required Color bgColor,
    required Color textColor,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMissionGrid() {
    return Row(
      children: [
        Expanded(
          child: _buildMissionItem(
            icon: Icons.workspace_premium,
            title: 'Provide World Recognized Certifications',
          ),
        ),
        Expanded(
          child: _buildMissionItem(
            icon: Icons.people,
            title: 'Develop Human Capital for In-Demand Skills and Knowledge',
          ),
        ),
        Expanded(
          child: _buildMissionItem(
            icon: Icons.public,
            title: 'Contribute to Society and Nation Through Quality Education',
          ),
        ),
      ],
    );
  }

  Widget _buildMissionItem({required IconData icon, required String title}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 6),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue[100]!, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 32,
              color: Color(0xFF0056AC),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w500,
              color: Colors.grey[800],
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildStatistic({required IconData icon, required String number, required String label}) {
    return Column(
      children: [
        Icon(
          icon,
          color: Color(0xFF0056AC),
          size: 30,
        ),
        const SizedBox(height: 8),
        Text(
          number,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Color(0xFF0056AC),
          ),
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
  
  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Color(0xFF0056AC),
      ),
    );
  }
  
  Widget _buildFeatureItem({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: Color(0xFF0056AC),
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildContactItem({
    required IconData icon,
    required String title,
    required String detail,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(
            icon,
            color: Color(0xFF0056AC),
            size: 24,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
                Text(
                  detail,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPartnerImage(String imagePath) {
    return SizedBox(
      width: 100,
      height: 80,
      child: Image.asset(
        imagePath,
        fit: BoxFit.contain,
      ),
    );
  }
}