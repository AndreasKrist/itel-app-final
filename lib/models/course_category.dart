enum CourseCategory {
  aiAndIot('AI & IoT'),
  bigDataAnalytics('Big Data | Analytics | Database'),
  businessOperations('Business Operations'),
  cloudComputing('Cloud Computing & Virtualization'),
  cybersecurity('Cybersecurity'),
  devOps('DevOps'),
  itBusinessManagement('IT Business Management & Strategy'),
  mobileAppTechnology('Mobile & App Technology'),
  networkingInfrastructure('Networking Infrastructure & Architecture'),
  programming('Programming');

  const CourseCategory(this.displayName);

  final String displayName;

  static CourseCategory? fromString(String value) {
    for (CourseCategory category in CourseCategory.values) {
      if (category.displayName == value) {
        return category;
      }
    }
    return null;
  }

  static List<String> getAllDisplayNames() {
    return CourseCategory.values.map((category) => category.displayName).toList();
  }
}