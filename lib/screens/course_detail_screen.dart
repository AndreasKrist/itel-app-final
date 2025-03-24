import 'package:flutter/material.dart';
import '../models/course.dart';
import '../models/user.dart';
import '../widgets/enquiry_form.dart';
import '../models/enrolled_course.dart';
import '../models/user.dart';



class CourseDetailScreen extends StatefulWidget {
  final Course course;

  const CourseDetailScreen({
    super.key,
    required this.course,
  });

  @override
  State<CourseDetailScreen> createState() => _CourseDetailScreenState();
}

class _CourseDetailScreenState extends State<CourseDetailScreen> {
  void _joinFreeClass() {
  // Create an EnrolledCourse object for the free course
  final newEnrollment = EnrolledCourse(
    courseId: widget.course.id,
    enrollmentDate: DateTime.now(),
    status: EnrollmentStatus.active, // Start as active for free courses
    isOnline: widget.course.deliveryMethods?.contains('OLL') ?? false,
    // Set next session to 3 days from now
    nextSessionDate: DateTime.now().add(const Duration(days: 3)), 
    nextSessionTime: '10:00 AM - 12:00 PM',
    location: widget.course.deliveryMethods?.contains('OLL') ?? false 
        ? 'https://online.itel.com.sg'
        : 'ITEL Training Center (Room 101)',
    progress: '0% complete', // Start with 0% progress
  );
  
  // Update the user's enrolled courses
  User.currentUser = User.currentUser.enrollInCourse(newEnrollment);
  
  // Show success message
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('You have successfully joined the class!'),
          Text(
            'Check your Profile to access the course materials',
            style: TextStyle(fontSize: 12),
          ),
        ],
      ),
      backgroundColor: Colors.green,
      duration: Duration(seconds: 4),
    ),
  );
}
  late bool isFavorite;
  bool _showEnquiryForm = false;
  final Map<String, bool> _expandedSections = {};
  
  // For Related Courses Section
  late List<Course> relatedCourses;

  @override
  void initState() {
    super.initState();
    isFavorite = User.currentUser.favoriteCoursesIds.contains(widget.course.id);
    
    // Initialize all outline sections as collapsed
    if (widget.course.outline != null) {
      for (var key in widget.course.outline!.keys) {
        _expandedSections[key] = false;
      }
    }
    
    // Get related courses (same category or certification type)
    relatedCourses = Course.sampleCourses.where((course) {
      return course.id != widget.course.id && 
             (course.category == widget.course.category || 
              course.certType == widget.course.certType);
    }).take(5).toList();
  }

  void _toggleFavorite() {
    setState(() {
      List<String> updatedFavorites = List.from(User.currentUser.favoriteCoursesIds);
      if (isFavorite) {
        updatedFavorites.remove(widget.course.id);
      } else {
        updatedFavorites.add(widget.course.id);
      }
      User.currentUser = User.currentUser.copyWith(
        favoriteCoursesIds: updatedFavorites,
      );
      isFavorite = !isFavorite;
    });
  }

  void _toggleSection(String sectionKey) {
    setState(() {
      _expandedSections[sectionKey] = !(_expandedSections[sectionKey] ?? false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Course Details'),
        actions: [
          IconButton(
            icon: Icon(
              isFavorite ? Icons.favorite : Icons.favorite_border,
              color: isFavorite ? Colors.pink : null,
            ),
            onPressed: _toggleFavorite,
          ),
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              // Share functionality would go here
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Share functionality coming soon!')),
              );
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Course header
                Container(
                  width: double.infinity,
                  color: Colors.blue[700],
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              widget.course.courseCode,
                              style: TextStyle(
                                color: Colors.blue[700],
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.course.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              widget.course.category,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          if (widget.course.certType != null) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.blue[900],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                widget.course.certType!,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Icon(
                            Icons.star,
                            color: Colors.amber,
                            size: 20,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            widget.course.rating.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 16),
                          if (widget.course.startDate != null) ...[
                            Icon(
                              Icons.calendar_today,
                              color: Colors.white,
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Starts ${widget.course.startDate}',
                              style: const TextStyle(
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                
                // Course information
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Course Details
                      _buildSectionTitle('Course Details'),
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
                            _buildDetailRow('Duration', widget.course.duration),
                            _buildDetailRow('Next Available Course', widget.course.nextAvailableDate ?? 'Contact us for availability'),
                            _buildDetailRow(
                              'Delivery Mode',
                              widget.course.deliveryMethods?.map((mode) {
                                if (mode == 'OLL') return 'Online Live Learning (OLL)';
                                if (mode == 'ILT') return 'Instructor-led Training (ILT)';
                                return mode;
                              }).join(', ') ?? 'Not specified',
                            ),
                            _buildDetailRow('Fees (before funding)', widget.course.price),
                            if (widget.course.funding != null)
                              _buildDetailRow('Funding Status', widget.course.funding!),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                      // Course Description
                      if (widget.course.description != null) ...[
                        _buildSectionTitle('Course Description'),
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
                          child: Text(
                            widget.course.description!,
                            style: TextStyle(
                              height: 1.5,
                              color: Colors.grey[800],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                      
                      // Course Outline
                      if (widget.course.outline != null) ...[
                        _buildSectionTitle('Course Outline'),
                        const SizedBox(height: 12),
                        Container(
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
                          child: ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: widget.course.outline!.length,
                            separatorBuilder: (context, index) => Divider(height: 1),
                            itemBuilder: (context, index) {
                              String sectionKey = widget.course.outline!.keys.elementAt(index);
                              List<String> sectionItems = widget.course.outline![sectionKey] ?? [];
                              bool isExpanded = _expandedSections[sectionKey] ?? false;
                              
                              return Column(
                                children: [
                                  InkWell(
                                    onTap: () => _toggleSection(sectionKey),
                                    child: Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              sectionKey,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          Icon(
                                            isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                                            color: Colors.grey[600],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  if (isExpanded)
                                    Padding(
                                      padding: const EdgeInsets.only(
                                        left: 16,
                                        right: 16,
                                        bottom: 16,
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: sectionItems.map((item) {
                                          return Padding(
                                            padding: const EdgeInsets.symmetric(vertical: 4),
                                            child: Row(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text('• ', style: TextStyle(color: Colors.blue[700])),
                                                Expanded(child: Text(item)),
                                              ],
                                            ),
                                          );
                                        }).toList(),
                                      ),
                                    ),
                                ],
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                      
                      // Course Fee Structure
                      if (widget.course.feeStructure != null) ...[
                        _buildSectionTitle('Course Fee Structure'),
                        const SizedBox(height: 12),
                        Container(
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
                              _buildFeeTable(),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                      
                      // Prerequisites
                      if (widget.course.prerequisites != null) ...[
                        _buildSectionTitle('Prerequisites'),
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
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: widget.course.prerequisites!.map((prerequisite) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Icon(
                                      Icons.check_circle,
                                      color: Colors.green[600],
                                      size: 20,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(prerequisite),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                      
                      // Who Should Attend
                      if (widget.course.whoShouldAttend != null) ...[
                        _buildSectionTitle('Who Should Attend'),
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
                          child: Text(
                            widget.course.whoShouldAttend!,
                            style: TextStyle(
                              height: 1.5,
                              color: Colors.grey[800],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                      
                      // Important Notes - Updated to use white background
                      if (widget.course.importantNotes != null) ...[
                        _buildSectionTitle('Important Notes'),
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
                          child: Text(
                            widget.course.importantNotes!,
                            style: TextStyle(
                              height: 1.5,
                              color: Colors.grey[800],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                      
                      // Related Courses
                      if (relatedCourses.isNotEmpty) ...[
                        _buildSectionTitle('Related Courses'),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 160,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: relatedCourses.length,
                            separatorBuilder: (context, index) => const SizedBox(width: 12),
                            itemBuilder: (context, index) {
                              final course = relatedCourses[index];
                              return InkWell(
                                onTap: () {
                                  Navigator.pushReplacement(
                                    context, 
                                    MaterialPageRoute(
                                      builder: (context) => CourseDetailScreen(course: course),
                                    ),
                                  );
                                },
                                child: Container(
                                  width: 220,
                                  padding: const EdgeInsets.all(12),
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
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        course.title,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        course.category,
                                        style: TextStyle(
                                          color: Colors.grey[500],
                                          fontSize: 12,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          Icon(Icons.star, color: Colors.amber, size: 14),
                                          const SizedBox(width: 4),
                                          Text(
                                            course.rating.toString(),
                                            style: const TextStyle(fontSize: 12),
                                          ),
                                          const SizedBox(width: 8),
                                          Icon(Icons.access_time, color: Colors.grey[400], size: 14),
                                          const SizedBox(width: 4),
                                          Text(
                                            course.duration,
                                            style: const TextStyle(fontSize: 12),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        course.price,
                                        style: TextStyle(
                                          color: Colors.blue[600],
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                      if (course.certType != null) ...[
                                        const SizedBox(height: 4),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: Colors.blue[50],
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            course.certType!,
                                            style: TextStyle(
                                              color: Colors.blue[700],
                                              fontSize: 10,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                      
                      const SizedBox(height: 60), // Space for the bottom button
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Enquiry form overlay
          if (_showEnquiryForm)
            GestureDetector(
              onTap: () {
                setState(() {
                  _showEnquiryForm = false;
                });
              },
              child: Container(
                color: Colors.black.withOpacity(0.5),
                child: Center(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 24),
                    height: MediaQuery.of(context).size.height * 0.8, // 80% of screen height
                    child: EnquiryForm(
                      course: widget.course,
                      onCancel: () {
                        setState(() {
                          _showEnquiryForm = false;
                        });
                      },
                      onSubmit: () {
                        setState(() {
                          _showEnquiryForm = false;
                        });
                      },
                    ),
                  ),
                ),
              ),
            ),
          
          // Bottom button - Enquire Now
          if (!_showEnquiryForm)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
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
                    // Check if the course is free
                    if (widget.course.price == '\$0' || 
                        widget.course.price.contains('Free') || 
                        widget.course.funding == 'Complimentary') {
                      // Directly add to enrolled courses without form
                      _joinFreeClass();
                    } else {
                      // Show enquiry form for paid courses
                      setState(() {
                        _showEnquiryForm = true;
                      });
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: widget.course.price == '\$0' || 
                                    widget.course.price.contains('Free') || 
                                    widget.course.funding == 'Complimentary' 
                                  ? Colors.green[600] : Colors.blue[600],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    widget.course.price == '\$0' || 
                    widget.course.price.contains('Free') || 
                    widget.course.funding == 'Complimentary'
                    ? 'Join the Class Now'
                    : 'Enquire Now',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
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
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey[700],
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
  
Widget _buildFeeTable() {
  final feeStructure = widget.course.feeStructure;
  if (feeStructure == null) return Container();
  
  final userTier = User.currentUser.tier;
  final isProMember = userTier == MembershipTier.pro;
  final isDiscountEligible = widget.course.isDiscountEligible();
  
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      if (isProMember && isDiscountEligible)
        Container(
          padding: const EdgeInsets.all(10),
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.blue[200]!),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.blue[700],
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'PRO',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'As a PRO member, you receive a 25% discount on this course!',
                  style: TextStyle(
                    color: Colors.blue[800],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      Table(
        border: TableBorder.all(
          color: Colors.grey[300]!,
          width: 1,
        ),
        columnWidths: const {
          0: FlexColumnWidth(2.5),
          1: FlexColumnWidth(1),
          2: FlexColumnWidth(1),
          3: FlexColumnWidth(1),
        },
        children: [
          // Table header
          TableRow(
            decoration: BoxDecoration(
              color: Colors.blue[700],
            ),
            children: [
              _buildTableHeaderCell('Criteria', isFirstColumn: true),
              _buildTableHeaderCell('Individual'),
              _buildTableHeaderCell('Company Sponsored (Non-SME)'),
              _buildTableHeaderCell('Company Sponsored (SME)'),
            ],
          ),
          // Full course fee row
          if (feeStructure.containsKey('Full Course Fee'))
            TableRow(
              decoration: BoxDecoration(
                color: Colors.grey[100],
              ),
              children: [
                _buildTableCell('Full Course Fee', isHeader: true),
                _buildTableCell(''),
                _buildTableCell(''),
                _buildTableCell(
                  isProMember && isDiscountEligible
                    ? '${feeStructure['Full Course Fee']?['Price'] ?? ''}\n(PRO: ${widget.course.getDiscountedPrice(userTier)})'
                    : feeStructure['Full Course Fee']?['Price'] ?? ''
                ),
              ],
            ),
          // Other fee rows with PRO discount applied if eligible
          ...feeStructure.entries.where((entry) => entry.key != 'Full Course Fee').map((entry) {
            return TableRow(
              children: [
                _buildTableCell(entry.key, isHeader: true),
                _buildTableCell(
                  isProMember && isDiscountEligible && entry.value['Individual'] != null
                    ? '${entry.value['Individual']}\n(PRO: ${_getDiscountedValue(entry.value['Individual'])})'
                    : entry.value['Individual'] ?? ''
                ),
                _buildTableCell(
                  isProMember && isDiscountEligible && entry.value['Company Sponsored (Non-SME)'] != null
                    ? '${entry.value['Company Sponsored (Non-SME)']}\n(PRO: ${_getDiscountedValue(entry.value['Company Sponsored (Non-SME)'])})'
                    : entry.value['Company Sponsored (Non-SME)'] ?? ''
                ),
                _buildTableCell(
                  isProMember && isDiscountEligible && entry.value['Company Sponsored (SME)'] != null
                    ? '${entry.value['Company Sponsored (SME)']}\n(PRO: ${_getDiscountedValue(entry.value['Company Sponsored (SME)'])})'
                    : entry.value['Company Sponsored (SME)'] ?? ''
                ),
              ],
            );
          }),
        ],
      ),
    ],
  );
}

// Helper method to calculate discounted price for the fee table
String _getDiscountedValue(String? priceString) {
  if (priceString == null || priceString.isEmpty) return '';
  
  // Extract numeric value
  final valueString = priceString.replaceAll(RegExp(r'[^\d.]'), '');
  if (valueString.isEmpty) return priceString;
  
  try {
    double value = double.parse(valueString);
    double discountedValue = value * 0.75; // 25% discount
    
    // Format with same currency symbol
    if (priceString.contains('\$')) {
      return '\$${discountedValue.toStringAsFixed(2)}';
    } else {
      return discountedValue.toStringAsFixed(2);
    }
  } catch (e) {
    return priceString;
  }
}

  Widget _buildTableHeaderCell(String text, {bool isFirstColumn = false}) {
    return Container(
      padding: const EdgeInsets.all(10),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
        textAlign: isFirstColumn ? TextAlign.left : TextAlign.center,
      ),
    );
  }
  
  Widget _buildTableCell(String text, {bool isHeader = false}) {
    return Container(
      padding: const EdgeInsets.all(10),
      child: Text(
        text,
        style: TextStyle(
          fontWeight: isHeader ? FontWeight.bold : FontWeight.normal,
          fontSize: 12,
        ),
        textAlign: isHeader ? TextAlign.left : TextAlign.center,
      ),
    );
  }
}