enum MembershipTier {
  standard,
  pro,
}

class User {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String? company;
  final String? profileImage;
  final MembershipTier tier;
  final String membershipExpiryDate;
  final List<String> favoriteCoursesIds;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    this.company,
    this.profileImage,
    required this.tier,
    required this.membershipExpiryDate,
    this.favoriteCoursesIds = const [],
  });

  User copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    String? company,
    String? profileImage,
    MembershipTier? tier,
    String? membershipExpiryDate,
    List<String>? favoriteCoursesIds,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      company: company ?? this.company,
      profileImage: profileImage ?? this.profileImage,
      tier: tier ?? this.tier,
      membershipExpiryDate: membershipExpiryDate ?? this.membershipExpiryDate,
      favoriteCoursesIds: favoriteCoursesIds ?? this.favoriteCoursesIds,
    );
  }

  static User currentUser = User(
    id: '1',
    name: 'Andreas Kristianto',
    email: 'andreaskrist2004@gmail.com',
    phone: '+62 82111508130',
    company: 'Lilo Store LTD',
    tier: MembershipTier.pro,
    membershipExpiryDate: 'March 7, 2027',
    favoriteCoursesIds: ['1', '3'],
  );
}