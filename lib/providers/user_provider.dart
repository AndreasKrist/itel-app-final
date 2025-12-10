// lib/providers/user_provider.dart
import 'package:flutter/foundation.dart';
import '../models/user.dart';
import '../models/saved_account.dart';

/// Provider for managing user state across the app
/// Replaces the static User.currentUser singleton pattern
class UserProvider with ChangeNotifier, DiagnosticableTreeMixin {
  User? _currentUser;
  List<SavedAccount> _savedAccounts = [];
  bool _isLoading = false;

  /// Get the current logged-in user
  User? get currentUser => _currentUser;

  /// Get list of all saved accounts
  List<SavedAccount> get savedAccounts => List.unmodifiable(_savedAccounts);

  /// Check if user is authenticated
  bool get isAuthenticated => _currentUser != null && _currentUser!.id.isNotEmpty;

  /// Check if user is a guest
  bool get isGuest => _currentUser == null || _currentUser!.id.isEmpty || _currentUser!.email.isEmpty;

  /// Loading state
  bool get isLoading => _isLoading;

  /// Set loading state
  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  /// Update the current user
  void setUser(User? user) {
    _currentUser = user;
    notifyListeners();
  }

  /// Update current user data (for profile edits, favorites, etc.)
  void updateUser(User updatedUser) {
    _currentUser = updatedUser;
    notifyListeners();
  }

  /// Clear current user (sign out)
  void clearUser() {
    _currentUser = null;
    notifyListeners();
  }

  /// Set the list of saved accounts
  void setSavedAccounts(List<SavedAccount> accounts) {
    _savedAccounts = accounts;
    notifyListeners();
  }

  /// Add a saved account to the list
  void addSavedAccount(SavedAccount account) {
    // Remove existing account with same UID if present
    _savedAccounts.removeWhere((acc) => acc.uid == account.uid);

    // Add the new/updated account
    _savedAccounts.insert(0, account);

    notifyListeners();
  }

  /// Remove a saved account from the list
  void removeSavedAccount(String uid) {
    _savedAccounts.removeWhere((acc) => acc.uid == uid);
    notifyListeners();
  }

  /// Update last used timestamp for an account
  void updateAccountLastUsed(String uid) {
    final index = _savedAccounts.indexWhere((acc) => acc.uid == uid);
    if (index != -1) {
      final account = _savedAccounts[index];
      _savedAccounts[index] = account.copyWith(lastUsed: DateTime.now());

      // Move to front of list
      final updatedAccount = _savedAccounts.removeAt(index);
      _savedAccounts.insert(0, updatedAccount);

      notifyListeners();
    }
  }

  /// Get the number of saved accounts (for displaying in UI)
  int get savedAccountCount => _savedAccounts.length;

  /// Check if a specific account is saved
  bool hasAccount(String uid) {
    return _savedAccounts.any((acc) => acc.uid == uid);
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<User?>('currentUser', currentUser));
    properties.add(IntProperty('savedAccountCount', savedAccountCount));
    properties.add(FlagProperty('isAuthenticated', value: isAuthenticated, ifTrue: 'authenticated'));
    properties.add(FlagProperty('isLoading', value: isLoading, ifTrue: 'loading'));
  }
}
