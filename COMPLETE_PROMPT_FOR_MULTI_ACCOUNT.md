# COMPLETE Multi-Account Switcher Implementation Prompt

Copy this ENTIRE prompt to Claude Code to implement the exact multi-account switcher feature:

---

I want to implement a multi-account switcher feature for my Flutter app, exactly like Instagram's account switcher. This should allow users to switch between multiple logged-in accounts seamlessly.

## Requirements:

**UI Behavior:**
1. Dropdown arrow next to user's name in profile header (only shows if 2+ accounts)
2. Tap name → Bottom sheet slides up with all saved accounts
3. Instagram-style account list with proper styling
4. Email accounts show password dialog when switching
5. Google accounts switch directly (or show Google picker)
6. Remove accounts with confirmation dialog

**Technical:**
- Use Provider for state management
- Store saved accounts in SharedPreferences
- Integrate with existing Firebase Auth
- Proper password handling (never store passwords)
- All font sizes and colors match exactly

## Step 1: Add Provider Package

Update `pubspec.yaml`:
```yaml
dependencies:
  provider: ^6.1.1  # Add this line
  # ... rest of your dependencies
```

Then run:
```bash
flutter pub get
```

## Step 2: Create SavedAccount Model

Create file: `lib/models/saved_account.dart`

```dart
// lib/models/saved_account.dart
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;

/// Represents a saved account that a user has previously logged into
/// This model stores minimal information to display in account switcher
class SavedAccount {
  final String uid;           // Firebase UID
  final String email;         // User email
  final String displayName;   // User display name
  final String? photoUrl;     // Profile photo URL (from Google)
  final String accountType;   // 'private' or 'corporate'
  final String authMethod;    // 'google' or 'email'
  final DateTime lastUsed;    // When this account was last active

  SavedAccount({
    required this.uid,
    required this.email,
    required this.displayName,
    this.photoUrl,
    this.accountType = 'private',
    this.authMethod = 'email',
    required this.lastUsed,
  });

  /// Convert SavedAccount to Map for storage in SharedPreferences
  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'accountType': accountType,
      'authMethod': authMethod,
      'lastUsed': lastUsed.toIso8601String(),
    };
  }

  /// Create SavedAccount from Map stored in SharedPreferences
  factory SavedAccount.fromJson(Map<String, dynamic> json) {
    return SavedAccount(
      uid: json['uid'] as String,
      email: json['email'] as String,
      displayName: json['displayName'] as String,
      photoUrl: json['photoUrl'] as String?,
      accountType: json['accountType'] as String? ?? 'private',
      authMethod: json['authMethod'] as String? ?? 'email',
      lastUsed: DateTime.parse(json['lastUsed'] as String),
    );
  }

  /// Create SavedAccount from Firebase User
  factory SavedAccount.fromFirebaseUser(
    firebase_auth.User firebaseUser, {
    String accountType = 'private',
    String authMethod = 'email',
  }) {
    return SavedAccount(
      uid: firebaseUser.uid,
      email: firebaseUser.email ?? '',
      displayName: firebaseUser.displayName ?? 'User',
      photoUrl: firebaseUser.photoURL,
      accountType: accountType,
      authMethod: authMethod,
      lastUsed: DateTime.now(),
    );
  }

  /// Create a copy with updated fields
  SavedAccount copyWith({
    String? uid,
    String? email,
    String? displayName,
    String? photoUrl,
    String? accountType,
    String? authMethod,
    DateTime? lastUsed,
  }) {
    return SavedAccount(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      accountType: accountType ?? this.accountType,
      authMethod: authMethod ?? this.authMethod,
      lastUsed: lastUsed ?? this.lastUsed,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SavedAccount && other.uid == uid;
  }

  @override
  int get hashCode => uid.hashCode;
}
```

## Step 3: Create UserProvider

Create file: `lib/providers/user_provider.dart`

```dart
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
```

## Step 4: Create AccountManagerService

Create file: `lib/services/account_manager_service.dart`

```dart
// lib/services/account_manager_service.dart
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/saved_account.dart';

/// Service for managing saved accounts in local storage
/// Handles persisting and retrieving the list of accounts user has logged into
class AccountManagerService {
  static const String _savedAccountsKey = 'saved_accounts_list';

  /// Load all saved accounts from SharedPreferences
  Future<List<SavedAccount>> loadSavedAccounts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? accountsJson = prefs.getString(_savedAccountsKey);

      if (accountsJson == null || accountsJson.isEmpty) {
        return [];
      }

      final List<dynamic> accountsList = json.decode(accountsJson);
      final accounts = accountsList
          .map((accountMap) => SavedAccount.fromJson(accountMap as Map<String, dynamic>))
          .toList();

      // Sort by last used (most recent first)
      accounts.sort((a, b) => b.lastUsed.compareTo(a.lastUsed));

      print('Loaded ${accounts.length} saved accounts');
      return accounts;
    } catch (e) {
      print('Error loading saved accounts: $e');
      return [];
    }
  }

  /// Save the list of accounts to SharedPreferences
  Future<void> saveSavedAccounts(List<SavedAccount> accounts) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Convert accounts to JSON
      final accountsList = accounts.map((account) => account.toJson()).toList();
      final accountsJson = json.encode(accountsList);

      await prefs.setString(_savedAccountsKey, accountsJson);
      print('Saved ${accounts.length} accounts to storage');
    } catch (e) {
      print('Error saving accounts: $e');
    }
  }

  /// Add or update a saved account
  Future<void> addOrUpdateAccount(SavedAccount account) async {
    try {
      final accounts = await loadSavedAccounts();

      // Remove existing account with same UID
      accounts.removeWhere((acc) => acc.uid == account.uid);

      // Add the new/updated account at the beginning
      accounts.insert(0, account);

      // Limit to 10 saved accounts max (optional, can be changed)
      if (accounts.length > 10) {
        accounts.removeLast();
      }

      await saveSavedAccounts(accounts);
    } catch (e) {
      print('Error adding/updating account: $e');
    }
  }

  /// Remove a saved account by UID
  Future<void> removeAccount(String uid) async {
    try {
      final accounts = await loadSavedAccounts();
      accounts.removeWhere((acc) => acc.uid == uid);
      await saveSavedAccounts(accounts);
      print('Removed account: $uid');
    } catch (e) {
      print('Error removing account: $e');
    }
  }

  /// Update the last used timestamp for an account
  Future<void> updateLastUsed(String uid) async {
    try {
      final accounts = await loadSavedAccounts();
      final index = accounts.indexWhere((acc) => acc.uid == uid);

      if (index != -1) {
        final account = accounts[index];
        accounts[index] = account.copyWith(lastUsed: DateTime.now());

        // Move to front of list
        final updatedAccount = accounts.removeAt(index);
        accounts.insert(0, updatedAccount);

        await saveSavedAccounts(accounts);
      }
    } catch (e) {
      print('Error updating last used: $e');
    }
  }

  /// Check if an account with given UID exists
  Future<bool> hasAccount(String uid) async {
    try {
      final accounts = await loadSavedAccounts();
      return accounts.any((acc) => acc.uid == uid);
    } catch (e) {
      print('Error checking account existence: $e');
      return false;
    }
  }

  /// Get a specific saved account by UID
  Future<SavedAccount?> getAccount(String uid) async {
    try {
      final accounts = await loadSavedAccounts();
      return accounts.firstWhere(
        (acc) => acc.uid == uid,
        orElse: () => throw Exception('Account not found'),
      );
    } catch (e) {
      print('Error getting account: $e');
      return null;
    }
  }

  /// Clear all saved accounts (useful for debugging or privacy)
  Future<void> clearAllAccounts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_savedAccountsKey);
      print('Cleared all saved accounts');
    } catch (e) {
      print('Error clearing accounts: $e');
    }
  }
}
```

## Step 5: Update AuthService

In your existing `lib/services/auth_service.dart`, add these imports at the top:

```dart
import '../models/saved_account.dart';
import 'account_manager_service.dart';
```

Add this field to the AuthService class:

```dart
final AccountManagerService _accountManager = AccountManagerService();
```

Add this helper method to save accounts after login:

```dart
// Helper method to save account after successful login
Future<void> _saveAccountAfterLogin(firebase_auth.User firebaseUser, String authMethod) async {
  try {
    // Get account type from Firestore
    final userProfile = await _preferencesService.getUserProfile(firebaseUser.uid);
    final accountType = userProfile?['accountType'] ?? 'private';

    final savedAccount = SavedAccount.fromFirebaseUser(
      firebaseUser,
      accountType: accountType,
      authMethod: authMethod,
    );

    await _accountManager.addOrUpdateAccount(savedAccount);
    print('Saved account: ${firebaseUser.email}');
  } catch (e) {
    print('Error saving account: $e');
  }
}
```

Add these methods for account switching:

```dart
// Switch to a different saved account
// This will sign out current user and prompt for password/re-auth
Future<User?> switchToAccount(SavedAccount account) async {
  try {
    print('Switching to account: ${account.email}');

    // Sign out current user first
    await signOut();

    // For email accounts, we can't auto-login (need password)
    // For Google accounts, we can try silent sign-in if still authenticated
    if (account.authMethod == 'google') {
      // Try to sign in with Google
      return await signInWithGoogle();
    } else {
      // For email accounts, we need to return null to show login screen
      // The login screen can be pre-filled with the email
      print('Email account requires password - returning null');
      return null;
    }
  } catch (e) {
    print('Error switching account: $e');
    rethrow;
  }
}

// Remove an account from saved accounts list
Future<void> removeAccount(String uid) async {
  try {
    await _accountManager.removeAccount(uid);
    print('Removed account from saved list: $uid');
  } catch (e) {
    print('Error removing account: $e');
    rethrow;
  }
}
```

Update ALL your sign-in methods to call `_saveAccountAfterLogin`:

**In `signInWithGoogle()` method, add after successful login:**
```dart
// Save account to saved accounts list
await _saveAccountAfterLogin(userCredential.user!, 'google');
```

**In `signInWithEmailPassword()` method, add after successful login:**
```dart
// Save account to saved accounts list
await _saveAccountAfterLogin(credential.user!, 'email');
```

**In `registerWithEmailPassword()` method, add after successful registration:**
```dart
// Save account to saved accounts list
await _saveAccountAfterLogin(credential.user!, 'email');
```

## Step 6: Update main.dart

Add these imports to `lib/main.dart`:

```dart
import 'package:provider/provider.dart';
import 'providers/user_provider.dart';
import 'services/account_manager_service.dart';
import 'models/user.dart';
```

Wrap your MaterialApp with ChangeNotifierProvider in the MyApp class:

```dart
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => UserProvider(),
      child: MaterialApp(
        title: 'ITEL App',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          scaffoldBackgroundColor: Colors.grey[100],
          fontFamily: 'DINRoundPro',
          textTheme: TextTheme(
            bodyLarge: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            bodyMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
        ),
        home: const AuthWrapper(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
```

In the `_AuthWrapperState` class, add the AccountManagerService field:

```dart
final AccountManagerService _accountManager = AccountManagerService();
```

Update the `_checkAuthState()` method to load saved accounts:

```dart
Future<void> _checkAuthState() async {
  setState(() => _isLoading = true);

  final userProvider = Provider.of<UserProvider>(context, listen: false);

  try {
    // Load saved accounts from storage
    final savedAccounts = await _accountManager.loadSavedAccounts();
    userProvider.setSavedAccounts(savedAccounts);
    print('Loaded ${savedAccounts.length} saved accounts');

    // Check if user is already authenticated
    _isLoggedIn = _authService.isAuthenticated;

    // If logged in, load user data including favorites
    if (_isLoggedIn) {
      try {
        await _authService.loadUserData();
        // Update provider with loaded user
        userProvider.setUser(User.currentUser);
      } catch (e) {
        print('Error loading user data: $e');
        // If loading user data fails, continue as guest
        _isLoggedIn = false;
        userProvider.clearUser();
      }
    } else {
      userProvider.clearUser();
    }
  } catch (e) {
    print('Error checking auth state: $e');
    // If auth check fails, default to not logged in
    _isLoggedIn = false;
    userProvider.clearUser();
  }

  setState(() => _isLoading = false);
}
```

Update `_handleLoginStatusChanged()`:

```dart
void _handleLoginStatusChanged(bool isLoggedIn) async {
  final userProvider = Provider.of<UserProvider>(context, listen: false);

  // Set loading state
  setState(() {
    _isLoading = true;
  });
  userProvider.setLoading(true);

  // Update login status
  _isLoggedIn = isLoggedIn;

  // If logged in, load user data
  if (isLoggedIn) {
    try {
      await _authService.loadUserData();
      userProvider.setUser(User.currentUser);
    } catch (e) {
      print('Error loading user data: $e');
      userProvider.clearUser();
    }
  } else {
    userProvider.clearUser();
  }

  setState(() {
    _isLoading = false;
  });
  userProvider.setLoading(false);
}
```

Update `_handleSignOut()`:

```dart
// This method will be passed to the AppMockup to handle sign out
Future<void> _handleSignOut() async {
  final userProvider = Provider.of<UserProvider>(context, listen: false);

  try {
    await _authService.signOut();
    userProvider.clearUser();

    // Update state to trigger re-render to login screen
    setState(() {
      _isLoggedIn = false;
    });
  } catch (e) {
    print('Sign out error: $e');
    // Show error message to user
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Sign out failed: ${e.toString()}')),
    );
  }
}
```

## Step 7: Create AccountSwitcher Widget

Create file: `lib/widgets/account_switcher.dart`

```dart
// PASTE THE COMPLETE ACCOUNT_SWITCHER.DART CODE HERE
// This is the full 401-line file that includes:
// - AccountSwitcher widget with header and account list
// - _switchToAccount method with password dialog for email accounts
// - _showPasswordDialog with proper styling (85% width, white "Sign In" text)
// - _removeAccount with confirmation dialog
// - _AccountListItem with proper font sizes (15, 13, 11)
```

**THE COMPLETE account_switcher.dart CODE IS IN THE EXISTING FILE - COPY IT EXACTLY AS IS**

Key features in the widget:
- Password dialog width: `MediaQuery.of(context).size.width * 0.85`
- Sign In button: `backgroundColor: Color(0xFF0056AC), foregroundColor: Colors.white`
- Font sizes: displayName (15), email (13), accountType (11)
- Current account badge in blue
- X button to remove accounts
- Proper error handling and loading states

## Step 8: Update Profile Screen

In `lib/screens/profile_screen.dart`, add these imports:

```dart
import 'package:provider/provider.dart';
import '../widgets/account_switcher.dart';
import '../providers/user_provider.dart';
```

In the profile header where the user's name is displayed, replace the name Text widget with this:

```dart
// Name with dropdown arrow (Instagram style)
Consumer<UserProvider>(
  builder: (context, userProvider, child) {
    final hasMultipleAccounts = userProvider.savedAccounts.length > 1;

    return GestureDetector(
      onTap: hasMultipleAccounts ? () => _showAccountSwitcherBottomSheet(context) : null,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Text(
              currentUser.name,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (hasMultipleAccounts) ...[
            const SizedBox(width: 8),
            Icon(
              Icons.keyboard_arrow_down,
              color: Colors.white,
              size: 28,
            ),
          ],
        ],
      ),
    );
  },
),
```

Add this method to the `_ProfileScreenState` class:

```dart
// Instagram-style account switcher bottom sheet
void _showAccountSwitcherBottomSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) => AccountSwitcher(
      onAccountSwitched: () {
        // Close the bottom sheet
        Navigator.pop(context);
        // Reload user data after switching accounts
        _reloadUserData();
      },
    ),
  );
}
```

## Step 9: Test the Feature

Run your app and test:

1. ✅ Login with first account → Account saved
2. ✅ Sign out → Login with second account
3. ✅ Go to Profile → See dropdown arrow next to name
4. ✅ Tap name → Bottom sheet appears with both accounts
5. ✅ Current account shows "Current" badge
6. ✅ Tap email account → Password dialog appears (85% width, white "Sign In" text)
7. ✅ Enter password → Switches successfully
8. ✅ Tap Google account → Switches (may show Google picker)
9. ✅ Tap X on account → Confirmation → Account removed
10. ✅ Restart app → Saved accounts persist
11. ✅ Font sizes correct: name (15), email (13), type (11)

## Important Notes:

- **Security**: Passwords are NEVER stored - Firebase handles all auth tokens
- **Backwards Compatible**: Static `User.currentUser` still works
- **Database Safe**: No Firestore or Firebase Auth changes needed
- **Max Accounts**: Limited to 10 (configurable in AccountManagerService)
- **UI**: Matches Instagram's design exactly with proper colors and font sizes

That's it! Your app now has a complete multi-account switcher feature exactly like Instagram! 🎉
