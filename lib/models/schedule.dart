class Schedule {
  final String id;
  final String title;
  final String courseTitle;
  final String courseId;
  final DateTime date;
  final String startTime;
  final String endTime;
  final bool isPending;
  final String? instructorName;
  final String? location;

  Schedule({
    required this.id,
    required this.title,
    required this.courseTitle,
    required this.courseId,
    required this.date,
    required this.startTime,
    required this.endTime,
    this.isPending = false,
    this.instructorName,
    this.location,
  });

  // Generate dummy schedules for demonstration
  static List<Schedule> getDummySchedules() {
    // Current date for reference
    final now = DateTime.now();
    
    return [
      // Today's schedule
      Schedule(
        id: '1',
        title: 'Module 1: Introduction to Networking',
        courseTitle: 'Network Security Fundamentals',
        courseId: '1',
        date: DateTime(now.year, now.month, now.day),
        startTime: '10:00 AM',
        endTime: '11:30 AM',
        isPending: false,
        instructorName: 'Dr. Sarah Chen',
        location: 'Online (Zoom)',
      ),
      
      // Tomorrow's schedule
      Schedule(
        id: '2',
        title: 'Lab Session: Network Configuration',
        courseTitle: 'Network Security Fundamentals',
        courseId: '1',
        date: DateTime(now.year, now.month, now.day + 1),
        startTime: '2:00 PM',
        endTime: '4:00 PM',
        isPending: true,
        instructorName: 'Michael Wong',
        location: 'Lab Room 302',
      ),
      
      // Next week's schedule
      Schedule(
        id: '3',
        title: 'Module 2: Threat Detection',
        courseTitle: 'Network Security Fundamentals',
        courseId: '1',
        date: DateTime(now.year, now.month, now.day + 7),
        startTime: '1:00 PM',
        endTime: '3:30 PM',
        isPending: true,
        instructorName: 'Dr. Sarah Chen',
        location: 'Online (Zoom)',
      ),
      
      // Schedule for another course
      Schedule(
        id: '4',
        title: 'AWS Services Overview',
        courseTitle: 'Cloud Infrastructure Management',
        courseId: '2',
        date: DateTime(now.year, now.month, now.day + 3),
        startTime: '9:00 AM',
        endTime: '11:00 AM',
        isPending: true,
        instructorName: 'James Rodriguez',
        location: 'Online (Teams)',
      ),
    ];
  }
}