import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user.dart';
import 'user_preferences_service.dart';

class MembershipService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final UserPreferencesService _preferencesService = UserPreferencesService();

  // Simulate membership purchase (replace with Xendit integration later)
  Future<bool> purchaseMembership({
    required String userId,
    required MembershipTier tier,
    required User currentUser,
  }) async {
    try {
      // Calculate expiry date
      DateTime expiryDate;
      if (tier == MembershipTier.tier1) {
        expiryDate = DateTime.now().add(const Duration(days: 365)); // 1 year free
      } else {
        expiryDate = DateTime.now().add(const Duration(days: 365)); // 1 year paid
      }
      
      // Update user profile with new tier
      await _preferencesService.saveUserProfile(
        userId: userId,
        name: currentUser.name,
        email: currentUser.email,
        phone: currentUser.phone,
        company: currentUser.company,
        tier: tier,
        membershipExpiryDate: _formatDate(expiryDate),
        favoriteCoursesIds: currentUser.favoriteCoursesIds,
        enrolledCourses: currentUser.enrolledCourses,
      );
      
      // Update local user
      User.currentUser = currentUser.copyWith(
        tier: tier,
        membershipExpiryDate: _formatDate(expiryDate),
      );
      
      return true;
    } catch (e) {
      print('Error purchasing membership: $e');
      return false;
    }
  }
  
  String _formatDate(DateTime date) {
    return '${_getMonthName(date.month)} ${date.day}, ${date.year}';
  }
  
  String _getMonthName(int month) {
    const months = [
      '', 'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return months[month];
  }
}