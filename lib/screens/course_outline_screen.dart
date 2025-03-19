import 'package:flutter/material.dart';
import '../models/course.dart';

class CourseOutlineScreen extends StatefulWidget {
  final Course course;

  const CourseOutlineScreen({
    super.key,
    required this.course,
  });

  @override
  State<CourseOutlineScreen> createState() => _CourseOutlineScreenState();
}

class _CourseOutlineScreenState extends State<CourseOutlineScreen> {
  Map<String, bool> _expandedSections = {};
  late Course _currentCourse;
  late Map<String, List<String>> _outlineData;

  @override
  void initState() {
    super.initState();
    // Store a local copy of the course
    _currentCourse = widget.course;
    
    // Initialize outline data
    _initializeOutlineData();
    
    // Initialize section expansion states
    for (var i = 0; i < _outlineData.keys.length; i++) {
      String key = _outlineData.keys.elementAt(i);
      _expandedSections[key] = (i == 0); // First one expanded
    }
  }
  
  void _initializeOutlineData() {
    // Use the course's outline if available
    if (_currentCourse.outline != null && _currentCourse.outline!.isNotEmpty) {
      _outlineData = _currentCourse.outline!;
      return;
    }
    
    // Try to find a matching course from sample courses
    final matchingCourse = Course.sampleCourses.firstWhere(
      (c) => c.id == _currentCourse.id || c.title == _currentCourse.title,
      orElse: () => Course.sampleCourses.firstWhere(
        (c) => c.outline != null && c.outline!.isNotEmpty,
        orElse: () => _currentCourse,
      ),
    );
    
    // If we found a course with an outline, use its outline
    if (matchingCourse.outline != null && matchingCourse.outline!.isNotEmpty) {
      _outlineData = matchingCourse.outline!;
      return;
    }
    
    // Use default outline data if nothing else is available
    _outlineData = {
      'Lesson 1: Cloud Computing Fundamentals': [
        'Introduction to cloud computing concepts',
        'Service models (IaaS, PaaS, SaaS)',
        'Deployment models (Public, Private, Hybrid)',
        'Cloud architecture principles',
      ],
      'Lesson 2: AWS/Azure/GCP Services': [
        'Compute services overview',
        'Storage options and data management',
        'Networking in the cloud',
        'Identity and access management',
      ],
      'Lesson 3: Infrastructure as Code': [
        'Configuration management principles',
        'Terraform basics and workflow',
        'Infrastructure automation best practices',
        'CI/CD pipeline integration',
      ],
      'Lesson 4: Cloud Security': [
        'Security responsibilities in the cloud',
        'Encryption and key management',
        'Network security and firewalls',
        'Compliance frameworks and best practices',
      ],
    };
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
        title: const Text('Course Outline'),
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Course information header
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.blue[700],
            width: double.infinity,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _currentCourse.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
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
                        _currentCourse.category,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (_currentCourse.certType != null) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.blue[900],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _currentCourse.certType!,
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
              ],
            ),
          ),
          
          // Course outline heading
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(
                  Icons.menu_book,
                  color: Colors.blue[700],
                ),
                const SizedBox(width: 8),
                Text(
                  'Course Outline',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[700],
                  ),
                ),
              ],
            ),
          ),
          
          // Course outline sections
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _outlineData.length,
              itemBuilder: (context, index) {
                String sectionKey = _outlineData.keys.elementAt(index);
                List<String> sectionItems = _outlineData[sectionKey] ?? [];
                bool isExpanded = _expandedSections[sectionKey] ?? false;
                
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  elevation: 1,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      // Section header
                      InkWell(
                        onTap: () => _toggleSection(sectionKey),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  sectionKey,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue[800],
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
                      
                      // Section content (only if expanded)
                      if (isExpanded)
                        Container(
                          padding: const EdgeInsets.only(
                            left: 16,
                            right: 16,
                            bottom: 16,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: const BorderRadius.only(
                              bottomLeft: Radius.circular(8),
                              bottomRight: Radius.circular(8),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: sectionItems.map((item) {
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 6),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      margin: const EdgeInsets.only(top: 5),
                                      width: 6,
                                      height: 6,
                                      decoration: BoxDecoration(
                                        color: Colors.blue[600],
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        item,
                                        style: TextStyle(
                                          color: Colors.grey[800],
                                          height: 1.3,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}