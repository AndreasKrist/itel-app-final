import 'package:flutter/material.dart';
import '../models/course.dart';
import '../services/form_submission_service.dart';
import '../models/enrolled_course.dart';
import '../models/user.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';
import '../services/user_preferences_service.dart';

class EnquiryForm extends StatefulWidget {
  final Course course;
  final Function() onCancel;
  final Function() onSubmit;

  const EnquiryForm({
    super.key,
    required this.course,
    required this.onCancel,
    required this.onSubmit,
  });

  @override
  State<EnquiryForm> createState() => _EnquiryFormState();
}

class _EnquiryFormState extends State<EnquiryForm> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _experienceController = TextEditingController();

  String? _selectedAgeGroup;
  String? _selectedJobIndustry;
  String? _selectedJobTitle;
  String? _selectedConsultant;
  final TextEditingController _remarksController = TextEditingController();
  final TextEditingController _detailsController = TextEditingController();

  // Add service instances
  final AuthService _authService = AuthService();
  final UserPreferencesService _preferencesService = UserPreferencesService();

  bool _coursePrice = false;
  bool _courseSchedule = false;
  bool _chatWithSomeone = false;
  bool _others = false;

  bool _internetSearch = false;
  bool _emailMarketing = false;
  bool _itelStaff = false;
  bool _linkedin = false;
  bool _facebook = false;
  bool _instagram = false;
  bool _otherSource = false;

  bool _consentToPrivacyPolicy = false;
  bool _joinMailingList = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    // Pre-fill with user data if available
    final currentUser = _authService.currentUser;
    if (currentUser != null) {
      _nameController.text = currentUser.name;
      _emailController.text = currentUser.email;
      _phoneController.text = currentUser.phone;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _experienceController.dispose();
    _remarksController.dispose();
    _detailsController.dispose();
    super.dispose();
  }

// Replace the entire _submitForm method in EnquiryForm with this version

// Replace the _submitForm method in EnquiryForm with this improved version:

void _submitForm() async {
  if (_formKey.currentState!.validate()) {
    // Show loading indicator
    setState(() {
      _isSubmitting = true;
    });
    
    try {
      print("Starting form submission...");
      
      // Create a map with all form values
      final Map<String, dynamic> formData = {
        'name': _nameController.text,
        'email': _emailController.text,
        'phone': _phoneController.text,
        'ageGroup': _selectedAgeGroup ?? '',
        'jobIndustry': _selectedJobIndustry ?? '',
        'jobTitle': _selectedJobTitle ?? '',
        'experience': _experienceController.text,
        'course': widget.course.title,
        'courseCode': widget.course.courseCode,
        'enquiryType': _getEnquiryTypes(),
        'consultant': _selectedConsultant ?? '',
        'heardFrom': _getHeardFromSources(),
        'remarks': _remarksController.text,
        'joinMailingList': _joinMailingList.toString(),
        'consentToPrivacyPolicy': _consentToPrivacyPolicy.toString(),
      };
      
      print("Form data prepared, submitting to service...");
      
      // Submit to Google Sheets via Google Apps Script
      final result = await FormSubmissionService.submitEnquiry(formData);
      
      print("Form submission result: $result");
      
      // IMPORTANT NEW PART: Create an enrollment record with pending status
      final currentUser = firebase_auth.FirebaseAuth.instance.currentUser;
      
      if (currentUser != null) {
        print("Creating pending enrollment for course: ${widget.course.id}");
        
        // Create an EnrolledCourse object with pending status
        final newEnrollment = EnrolledCourse(
          courseId: widget.course.id,
          enrollmentDate: DateTime.now(),
          status: EnrollmentStatus.pending, // Set as pending for enquiries
          isOnline: widget.course.deliveryMethods?.contains('OLL') ?? false,
          // Next session date is typically provided after confirmation
          nextSessionDate: null,
          nextSessionTime: null,
          // Location depends on delivery method
          location: widget.course.deliveryMethods?.contains('OLL') ?? false 
              ? 'Online (to be confirmed)' 
              : 'ITEL Training Center (to be confirmed)',
          progress: null, // No progress for pending courses
        );
        
        // 1. Save to subcollection first
        try {
          print("Saving pending enrollment to Firebase subcollection...");
          await _saveEnrollmentToFirebase(newEnrollment);
          print("Successfully saved to Firebase subcollection");
        } catch (e) {
          print("Error saving to Firebase subcollection: $e");
        }
        
        // 2. Update the user's enrolled courses locally - VERY IMPORTANT!
        print("Updating local User model...");
        User.currentUser = User.currentUser.enrollInCourse(newEnrollment);
        
        // Print current enrollments for debugging
        print("Updated User.currentUser enrollments:");
        for (var enrollment in User.currentUser.enrolledCourses) {
          print("Course ID: ${enrollment.courseId}, Status: ${enrollment.status}");
        }
        
        // 3. Then save to the main user document
        try {
          print("Saving to main user document...");
          // Get user from authentication service
          final authUser = _authService.currentUser;
          
          if (authUser != null) {
            await _preferencesService.saveUserProfile(
              userId: currentUser.uid,
              name: authUser.name,
              email: authUser.email,
              phone: authUser.phone,
              company: authUser.company,
              tier: authUser.tier,
              membershipExpiryDate: authUser.membershipExpiryDate,
              favoriteCoursesIds: authUser.favoriteCoursesIds,
              enrolledCourses: User.currentUser.enrolledCourses,
            );
          } else {
            // Fallback with form data if auth user isn't available
            await _preferencesService.saveUserProfile(
              userId: currentUser.uid,
              name: _nameController.text,
              email: _emailController.text,
              phone: _phoneController.text,
              enrolledCourses: User.currentUser.enrolledCourses,
            );
          }
          print("Successfully saved to user document");
        } catch (e) {
          print("Error saving to user document: $e");
        }
      } else {
        print("No logged in user found, cannot create enrollment record");
      }
      
      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  'Thank you, enquiry submitted successfully',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
                ),
                SizedBox(height: 4),
                Text(
                  'Confirmation email will be sent to',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13),
                ),
                SizedBox(height: 2),
                Text(
                  _emailController.text,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white),
                ),
              ],
            ),
            backgroundColor: Color(0xFF00FF00),
            duration: Duration(seconds: 5),
            padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          ),
        );
      }
      
      // Close the form after successful submission
      widget.onSubmit();
      
    } catch (e) {
      print("Error in form submission: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('An error occurred: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      // Always reset loading state, even if there's an error
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }
}

// Add this function to save to Firebase
Future<void> _saveEnrollmentToFirebase(EnrolledCourse enrollment) async {
  try {
    // Get current user
    final currentUser = firebase_auth.FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;
    
    print('Saving enrollment to Firebase subcollection for course: ${enrollment.courseId}');
    
    // Convert enum to string properly
    String statusString;
    switch (enrollment.status) {
      case EnrollmentStatus.pending:
        statusString = 'pending';
        break;
      case EnrollmentStatus.confirmed:
        statusString = 'confirmed';
        break;
      case EnrollmentStatus.active:
        statusString = 'active';
        break;
      case EnrollmentStatus.completed:
        statusString = 'completed';
        break;
      case EnrollmentStatus.cancelled:
        statusString = 'cancelled';
        break;
      default:
        statusString = 'pending';
    }
    
    // Create enrollment data to save
    final enrollmentData = {
      'courseId': enrollment.courseId,
      'enrollmentDate': enrollment.enrollmentDate.toIso8601String(),
      'status': statusString, // Use simple string instead of enum string
      'isOnline': enrollment.isOnline,
      'nextSessionDate': enrollment.nextSessionDate?.toIso8601String(),
      'nextSessionTime': enrollment.nextSessionTime,
      'location': enrollment.location,
      'progress': enrollment.progress,
      'timestamp': FieldValue.serverTimestamp(),
    };
    
    // Save to Firestore subcollection
    await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser.uid)
        .collection('enrolledCourses')
        .doc(enrollment.courseId)
        .set(enrollmentData);
    
    // Also add to the main user document's enrolledCourses array
    try {
      // Get current enrolled courses
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .get();
      
      List<Map<String, dynamic>> enrolledCourses = [];
      
      if (userDoc.exists && userDoc.data()!.containsKey('enrolledCourses')) {
        // Extract existing enrolled courses
        final existingEnrolledCourses = userDoc.data()!['enrolledCourses'] as List<dynamic>;
        
        // Convert to proper format and filter out this course if it exists
        enrolledCourses = existingEnrolledCourses
            .where((item) => item['courseId'] != enrollment.courseId)
            .map((item) => Map<String, dynamic>.from(item))
            .toList();
      }
      
      // Add the new/updated enrollment
      enrolledCourses.add(enrollmentData);
      
      // Update the user document
      await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .update({
            'enrolledCourses': enrolledCourses,
          });
      
      print('Enrollment saved to main user document successfully');
    } catch (e) {
      print('Error updating main user document: $e');
      // Continue anyway since we saved to subcollection
    }
        
    print('Enrollment saved to Firebase successfully');
  } catch (e) {
    print('Error saving enrollment to Firebase: $e');
    rethrow; // Rethrow to let the caller handle it
  }
}

  // Helper methods to get the selected enquiry types and heard-from sources
  String _getEnquiryTypes() {
    List<String> types = [];
    if (_coursePrice) types.add('Course Price');
    if (_courseSchedule) types.add('Course Date & Schedule');
    if (_chatWithSomeone) types.add('Chat with someone');
    if (_others) types.add('Others: ${_detailsController.text}');
    return types.join(', ');
  }

  String _getHeardFromSources() {
    List<String> sources = [];
    if (_internetSearch) sources.add('Internet Search');
    if (_emailMarketing) sources.add('ITEL EDM/Email');
    if (_itelStaff) sources.add('ITEL Staff');
    if (_linkedin) sources.add('LinkedIn');
    if (_facebook) sources.add('Facebook');
    if (_instagram) sources.add('Instagram');
    if (_otherSource) sources.add('Others');
    return sources.join(', ');
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Course Enquiry for ${widget.course.title}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: widget.onCancel,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '"*" indicates required fields',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16),
            
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name field
                    _buildFieldLabel('Name', true),
                    _buildTextField(
                      controller: _nameController,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    // Email Address
                    _buildFieldLabel('Email Address', true),
                    _buildTextField(
                      controller: _emailController,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your email';
                        } else if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                          return 'Please enter a valid email';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    // Contact Number
                    _buildFieldLabel('Contact Number', true),
                    _buildTextField(
                      controller: _phoneController,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your phone number';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Age Group
                    _buildFieldLabel('Age Group', true),
                    _buildDropdown(
                      value: _selectedAgeGroup,
                      hint: 'Select your age group',
                      items: ['Male', 'Female', 'Non-binary/Non-conforming'],
                      onChanged: (value) {
                        setState(() {
                          _selectedAgeGroup = value;
                        });
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please select your age group';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Job Industry
                    _buildFieldLabel('Job Industry / Sector', true),
                    _buildDropdown(
                      value: _selectedJobIndustry,
                      hint: 'Select your Job Industry / Sector',
                      items: [
                        'Information Technology / IT Services',
                        'Telecommunications',
                        'Finance / Banking / Insurance',
                        'Accounting / Audit / Tax',
                        'Engineering (Mechanical, Electrical, Civil, etc.)',
                        'Education / Training',
                        'Healthcare / Medical / Pharmaceuticals',
                        'Retail / E-Commerce',
                        'Manufacturing/Production',
                        'Construction / Property/Real Estate',
                        'Oil & Gas / Energy / Utilities',
                        'Transportation / Logistics/Supply Chain',
                        'Hospitality / F&B / Tourism',
                        'Legal / Law',
                        'Government/Public Sector',
                        'Media/Advertising/PR',
                        'Arts / Design / Creative',
                        'Human Resources / Recruitment',
                        'Customer Service / Call Center',
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedJobIndustry = value;
                        });
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please select your job industry';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Job Title
                    _buildFieldLabel('Job Title', true),
                    _buildDropdown(
                      value: _selectedJobTitle,
                      hint: 'Select your Job Title',
                      items: [
                        'Administrative/Clerical',
                        'Customer Service / Support',
                        'Sales / Business Development',
                        'Marketing / Digital Marketing',
                        'Management / Operations',
                        'Technical / IT Support',
                        'Software / Web Development',
                        'Data / Analytics / Research',
                        'Engineering / Technical',
                        'Human Resources / Recruitment',
                        'Teaching/Training/Coaching',
                        'Healthcare / Medical Services',
                        'Creative / Design/Multimedia',
                        'Legal / Compliance',
                        'Finance / Accounting',
                        'Project Management',
                        'Student / Intern',
                        'Entrepreneur / Business Owner',
                        'Freelance / Consultant',
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedJobTitle = value;
                        });
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please select your job title';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    // Experience
                    _buildFieldLabel('Experiences in IT/Tech, if any:', false),
                    _buildTextField(
                      controller: _experienceController,
                      hintText: 'MS Office, Desktop Publishing, Programming, Networking, Project Management, etc.',
                    ),
                    const SizedBox(height: 16),
                    
                    // Course Name
                    _buildFieldLabel('Course Name', true),
                    _buildTextField(
                      controller: TextEditingController(text: widget.course.title),
                      enabled: false,
                    ),
                    const SizedBox(height: 16),
                    
                    // Enquiry Purpose
                    _buildFieldLabel('I want to find out more about:', false),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            children: [
                              _buildCheckboxItem('Course Price', _coursePrice, (value) {
                                setState(() => _coursePrice = value!);
                              }),
                              _buildCheckboxItem('Course Date & Schedule', _courseSchedule, (value) {
                                setState(() => _courseSchedule = value!);
                              }),
                              _buildCheckboxItem('I\'d like to chat with someone', _chatWithSomeone, (value) {
                                setState(() => _chatWithSomeone = value!);
                              }),
                              _buildCheckboxItem('Others', _others, (value) {
                                setState(() => _others = value!);
                              }),
                            ],
                          ),
                        ),
                        if (_others)
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(left: 16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildFieldLabel('Kindly provide details, if you selected "Others"', false),
                                  _buildTextField(
                                    controller: _detailsController,
                                    maxLines: 4,
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    // Consultant
                    _buildFieldLabel('Consultant\'s Name', false),
                    _buildDropdown(
                      value: _selectedConsultant,
                      hint: 'Kindly select the ITEL Representative who assisted you',
                      items: [
                        'Irish M',
                        'Ann Loh',
                        'Jovelyn Balili',
                        'Leslie Carsula',
                        'Stanley Lim',
                        'Melvin Tan',
                        'Marvin Costales',
                        'Jennifer Tan',
                        'Ian Morrison',
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedConsultant = value;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    // Where did you hear about ITEL
                    _buildFieldLabel('Where did you hear of ITEL?', true),
                    Wrap(
                      spacing: 16,
                      runSpacing: 0,
                      children: [
                        SizedBox(
                          width: 160,
                          child: _buildCheckboxItem('Internet Search', _internetSearch, (value) {
                            setState(() => _internetSearch = value!);
                          }),
                        ),
                        SizedBox(
                          width: 160,
                          child: _buildCheckboxItem('ITEL EDM/Email', _emailMarketing, (value) {
                            setState(() => _emailMarketing = value!);
                          }),
                        ),
                        SizedBox(
                          width: 160,
                          child: _buildCheckboxItem('ITEL Staff', _itelStaff, (value) {
                            setState(() => _itelStaff = value!);
                          }),
                        ),
                        SizedBox(
                          width: 160,
                          child: _buildCheckboxItem('LinkedIn', _linkedin, (value) {
                            setState(() => _linkedin = value!);
                          }),
                        ),
                        SizedBox(
                          width: 160,
                          child: _buildCheckboxItem('Facebook', _facebook, (value) {
                            setState(() => _facebook = value!);
                          }),
                        ),
                        SizedBox(
                          width: 160,
                          child: _buildCheckboxItem('Instagram', _instagram, (value) {
                            setState(() => _instagram = value!);
                          }),
                        ),
                        SizedBox(
                          width: 160,
                          child: _buildCheckboxItem('Others', _otherSource, (value) {
                            setState(() => _otherSource = value!);
                          }),
                        ),
                      ],
                    ),
                    Text(
                      '*Note: If you chose Others, kindly provide more information in the Remarks/Comments/Questions box.',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 16),
                    
                    // Remarks
                    _buildFieldLabel('Remarks/Comments/Questions', false),
                    _buildTextField(
                      controller: _remarksController,
                      maxLines: 4,
                    ),
                    const SizedBox(height: 16),
                    
                    // Consent
                    _buildFieldLabel('Consent', true),
                    _buildCheckboxItem(
                      'By providing your information, you acknowledge and give consent for ITEL to utilize and/or retain your personal data within the organization. For further details, please refer to our Privacy Policy.',
                      _consentToPrivacyPolicy,
                      (value) {
                        setState(() => _consentToPrivacyPolicy = value!);
                      },
                    ),
                    _buildCheckboxItem(
                      'Join our mailing list and receive the latest updates on our courses, promotions and events.',
                      _joinMailingList,
                      (value) {
                        setState(() => _joinMailingList = value!);
                      },
                    ),
                    const SizedBox(height: 24),
                    
                    // Submit button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _consentToPrivacyPolicy ? _submitForm : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF0056AC),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          disabledBackgroundColor: Colors.grey[300],
                        ),
                        child: _isSubmitting
                          ? SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 3,
                              ),
                            )
                          : const Text('Submit'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFieldLabel(String label, bool isRequired) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: RichText(
        text: TextSpan(
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[800],
            fontWeight: FontWeight.w500,
          ),
          children: [
            TextSpan(text: label),
            if (isRequired)
              TextSpan(
                text: ' *',
                style: TextStyle(
                  color: Colors.red[700],
                  fontWeight: FontWeight.bold,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    String? Function(String?)? validator,
    int maxLines = 1,
    String? hintText,
    bool enabled = true,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      maxLines: maxLines,
      enabled: enabled,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
        filled: true,
        fillColor: enabled ? Colors.white : Colors.grey[100],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.blue[300]!),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.red[300]!),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }

  Widget _buildCheckboxItem(String label, bool value, void Function(bool?) onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 24,
            height: 24,
            child: Checkbox(
              value: value,
              onChanged: onChanged,
              activeColor: Color(0xFF0056AC),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[800],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown({
    required String? value,
    required String hint,
    required List<String> items,
    required void Function(String?) onChanged,
    String? Function(String?)? validator,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.blue[300]!),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.red[300]!),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      items: items.map((String item) {
        return DropdownMenuItem<String>(
          value: item,
          child: Text(
            item,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[800],
            ),
          ),
        );
      }).toList(),
      onChanged: onChanged,
      validator: validator,
      isExpanded: true,
      icon: Icon(Icons.arrow_drop_down, color: Colors.grey[600]),
    );
  }
}