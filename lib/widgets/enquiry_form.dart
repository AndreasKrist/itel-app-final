import 'package:flutter/material.dart';
import '../models/course.dart';
import '../services/form_submission_service.dart';

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
  final TextEditingController _occupationController = TextEditingController();
  final TextEditingController _experienceController = TextEditingController();
  final TextEditingController _consultantController = TextEditingController();
  final TextEditingController _remarksController = TextEditingController();
  final TextEditingController _detailsController = TextEditingController();

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
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _occupationController.dispose();
    _experienceController.dispose();
    _consultantController.dispose();
    _remarksController.dispose();
    _detailsController.dispose();
    super.dispose();
  }

  void _submitForm() async {
  if (_formKey.currentState!.validate()) {
    // Show loading indicator
    setState(() {
      _isSubmitting = true;
    });
    
    // Create a map with all form values
    final Map<String, dynamic> formData = {
      'name': _nameController.text,
      'email': _emailController.text,
      'phone': _phoneController.text,
      'occupation': _occupationController.text,
      'experience': _experienceController.text,
      'course': widget.course.title,
      'courseCode': widget.course.courseCode,
      'enquiryType': _getEnquiryTypes(),
      'consultant': _consultantController.text,
      'heardFrom': _getHeardFromSources(),
      'remarks': _remarksController.text,
      'joinMailingList': _joinMailingList,
      'consentToPrivacyPolicy': _consentToPrivacyPolicy,
    };
    
    // Submit the form data to Google Sheets
    final result = await FormSubmissionService.submitEnquiry(formData);
    
    // Hide loading indicator
    setState(() {
      _isSubmitting = false;
    });
    
    // Show success or error message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(result['success'] 
                ? 'Enquiry submitted successfully!' 
                : 'Failed to submit enquiry'),
            Text(
              result['success']
                ? 'A confirmation email will be sent to ${_emailController.text}'
                : result['message'],
              style: TextStyle(fontSize: 12),
            ),
          ],
        ),
        backgroundColor: result['success'] ? Colors.green : Colors.red,
        duration: Duration(seconds: 5),
      ),
    );
    
    // Only close the form if submission was successful
    if (result['success']) {
      widget.onSubmit();
    }
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
                    
                    // Occupation
                    _buildFieldLabel('Occupation', false),
                    _buildTextField(
                      controller: _occupationController,
                      hintText: 'IT Manager, Student, Unemployed, etc.',
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
                    _buildFieldLabel('Consultant Name, if any:', false),
                    _buildTextField(controller: _consultantController),
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
                          backgroundColor: Colors.blue[600],
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
              activeColor: Colors.blue[600],
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
}