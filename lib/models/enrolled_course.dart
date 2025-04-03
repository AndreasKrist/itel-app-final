// Define the possible enrollment statuses
enum EnrollmentStatus {
  pending,   // Enquiry submitted but not confirmed
  confirmed, // Confirmed but not started
  active,    // Currently in progress
  completed, // Finished the course
  cancelled  // Cancelled enrollment
}

class EnrolledCourse {
  final String courseId;
  final DateTime enrollmentDate;
  final EnrollmentStatus status;
  final bool isOnline;
  final DateTime? nextSessionDate;
  final String? nextSessionTime;
  final String? location; // Either room location or online URL
  final String? instructorName;
  final String? progress;
  final String? gradeOrCertificate;

  EnrolledCourse({
    required this.courseId,
    required this.enrollmentDate,
    required this.status,
    required this.isOnline,
    this.nextSessionDate,
    this.nextSessionTime,
    this.location,
    this.instructorName,
    this.progress,
    this.gradeOrCertificate,
  });

  EnrolledCourse copyWith({
    String? courseId,
    DateTime? enrollmentDate,
    EnrollmentStatus? status,
    bool? isOnline,
    DateTime? nextSessionDate,
    String? nextSessionTime,
    String? location,
    String? instructorName,
    String? progress,
    String? gradeOrCertificate,
  }) {
    return EnrolledCourse(
      courseId: courseId ?? this.courseId,
      enrollmentDate: enrollmentDate ?? this.enrollmentDate,
      status: status ?? this.status,
      isOnline: isOnline ?? this.isOnline,
      nextSessionDate: nextSessionDate ?? this.nextSessionDate,
      nextSessionTime: nextSessionTime ?? this.nextSessionTime,
      location: location ?? this.location,
      instructorName: instructorName ?? this.instructorName,
      progress: progress ?? this.progress,
      gradeOrCertificate: gradeOrCertificate ?? this.gradeOrCertificate,
    );
  }
  
}