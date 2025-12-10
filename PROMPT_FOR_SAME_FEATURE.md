# Complete Prompt to Implement Multi-Account Switcher Feature

Copy and paste this entire prompt to Claude Code:

---

I want to implement a multi-account switcher feature for my Flutter app, exactly like Instagram's account switcher. Users should be able to:
1. Login with multiple accounts (email/password and Google Sign-In)
2. See a dropdown arrow next to their name in the profile header
3. Tap their name to see a bottom sheet with all saved accounts
4. Switch between accounts quickly with proper password handling
5. Remove accounts from the saved list

## App Context:

My Flutter app uses:
- **Firebase Authentication** (email/password + Google Sign-In)
- **Firestore** for user data storage in `users/{uid}` collection
- **SharedPreferences** for local storage
- User has a static singleton: `User.currentUser`

User profile structure in Firestore:
```dart
{
  'name': String,
  'email': String,
  'phone': String,
  'company': String,
  'jobTitle': String?,
  'companyAddress': String?,
  'accountType': String,  // 'private' or 'corporate'
  'tier': String,  // 'standard', 'tier1', 'tier2', 'tier3'
  'membershipExpiryDate': String,
  'favoriteCoursesIds': List<String>,
  'enrolledCourses': List<Map>,
  'courseHistory': List<Map>,
  'giveAccess': int,
  'trainingCredits': double,
  'trainingCreditHistory': List<Map>,
}
```

## Implementation Requirements:

### 1. Add Provider Package
Add to `pubspec.yaml`:
```yaml
dependencies:
  provider: ^6.1.1  # State management for multi-account support
```

### 2. Create SavedAccount Model

Create file: `lib/models/saved_account.dart`
```dart
// lib/models/saved_account.dart
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;

class SavedAccount {
  final String uid;
  final String email;
  final String displayName;
  final String? photoUrl;
  final String accountType;
  final String authMethod;
  final DateTime lastUsed;

  SavedAccount({
    required this.uid,
    required this.email,
    required this.displayName,
    this.photoUrl,
    this.accountType = 'private',
    this.authMethod = 'email',
    required this.lastUsed,
  });

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

### 3. Create UserProvider

Create file: `lib/providers/user_provider.dart`
```dart
// lib/providers/user_provider.dart
import 'package:flutter/foundation.dart';
import '../models/user.dart';
import '../models/saved_account.dart';

class UserProvider with ChangeNotifier, DiagnosticableTreeMixin {
  User? _currentUser;
  List<SavedAccount> _savedAccounts = [];
  bool _isLoading = false;

  User? get currentUser => _currentUser;
  List<SavedAccount> get savedAccounts => List.unmodifiable(_savedAccounts);
  bool get isAuthenticated => _currentUser != null && _currentUser!.id.isNotEmpty;
  bool get isGuest => _currentUser == null || _currentUser!.id.isEmpty || _currentUser!.email.isEmpty;
  bool get isLoading => _isLoading;

  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void setUser(User? user) {
    _currentUser = user;
    notifyListeners();
  }

  void updateUser(User updatedUser) {
    _currentUser = updatedUser;
    notifyListeners();
  }

  void clearUser() {
    _currentUser = null;
    notifyListeners();
  }

  void setSavedAccounts(List<SavedAccount> accounts) {
    _savedAccounts = accounts;
    notifyListeners();
  }

  void addSavedAccount(SavedAccount account) {
    _savedAccounts.removeWhere((acc) => acc.uid == account.uid);
    _savedAccounts.insert(0, account);
    notifyListeners();
  }

  void removeSavedAccount(String uid) {
    _savedAccounts.removeWhere((acc) => acc.uid == uid);
    notifyListeners();
  }

  void updateAccountLastUsed(String uid) {
    final index = _savedAccounts.indexWhere((acc) => acc.uid == uid);
    if (index != -1) {
      final account = _savedAccounts[index];
      _savedAccounts[index] = account.copyWith(lastUsed: DateTime.now());
      final updatedAccount = _savedAccounts.removeAt(index);
      _savedAccounts.insert(0, updatedAccount);
      notifyListeners();
    }
  }

  int get savedAccountCount => _savedAccounts.length;

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

### 4. Create AccountManagerService

Create file: `lib/services/account_manager_service.dart`
```dart
// lib/services/account_manager_service.dart
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/saved_account.dart';

class AccountManagerService {
  static const String _savedAccountsKey = 'saved_accounts_list';

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

      accounts.sort((a, b) => b.lastUsed.compareTo(a.lastUsed));

      print('Loaded ${accounts.length} saved accounts');
      return accounts;
    } catch (e) {
      print('Error loading saved accounts: $e');
      return [];
    }
  }

  Future<void> saveSavedAccounts(List<SavedAccount> accounts) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final accountsList = accounts.map((account) => account.toJson()).toList();
      final accountsJson = json.encode(accountsList);
      await prefs.setString(_savedAccountsKey, accountsJson);
      print('Saved ${accounts.length} accounts to storage');
    } catch (e) {
      print('Error saving accounts: $e');
    }
  }

  Future<void> addOrUpdateAccount(SavedAccount account) async {
    try {
      final accounts = await loadSavedAccounts();
      accounts.removeWhere((acc) => acc.uid == account.uid);
      accounts.insert(0, account);
      if (accounts.length > 10) {
        accounts.removeLast();
      }
      await saveSavedAccounts(accounts);
    } catch (e) {
      print('Error adding/updating account: $e');
    }
  }

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

  Future<void> updateLastUsed(String uid) async {
    try {
      final accounts = await loadSavedAccounts();
      final index = accounts.indexWhere((acc) => acc.uid == uid);

      if (index != -1) {
        final account = accounts[index];
        accounts[index] = account.copyWith(lastUsed: DateTime.now());
        final updatedAccount = accounts.removeAt(index);
        accounts.insert(0, updatedAccount);
        await saveSavedAccounts(accounts);
      }
    } catch (e) {
      print('Error updating last used: $e');
    }
  }

  Future<bool> hasAccount(String uid) async {
    try {
      final accounts = await loadSavedAccounts();
      return accounts.any((acc) => acc.uid == uid);
    } catch (e) {
      print('Error checking account existence: $e');
      return false;
    }
  }

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

### 5. Update AuthService

Add these imports and methods to your existing `lib/services/auth_service.dart`:

```dart
// Add these imports at the top
import '../models/saved_account.dart';
import 'account_manager_service.dart';

// Add this field to the class
final AccountManagerService _accountManager = AccountManagerService();

// Add this helper method
Future<void> _saveAccountAfterLogin(firebase_auth.User firebaseUser, String authMethod) async {
  try {
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

// Add these methods to the class
Future<User?> switchToAccount(SavedAccount account) async {
  try {
    print('Switching to account: ${account.email}');
    await signOut();

    if (account.authMethod == 'google') {
      return await signInWithGoogle();
    } else {
      print('Email account requires password - returning null');
      return null;
    }
  } catch (e) {
    print('Error switching account: $e');
    rethrow;
  }
}

Future<void> removeAccount(String uid) async {
  try {
    await _accountManager.removeAccount(uid);
    print('Removed account from saved list: $uid');
  } catch (e) {
    print('Error removing account: $e');
    rethrow;
  }
}

// Update all sign-in methods to call _saveAccountAfterLogin
// In signInWithGoogle - add after line that loads user data:
await _saveAccountAfterLogin(userCredential.user!, 'google');

// In signInWithEmailPassword - add after line that loads user data:
await _saveAccountAfterLogin(credential.user!, 'email');

// In registerWithEmailPassword - add after line that loads user data:
await _saveAccountAfterLogin(credential.user!, 'email');
```

### 6. Update main.dart

```dart
// Add these imports
import 'package:provider/provider.dart';
import 'providers/user_provider.dart';
import 'services/account_manager_service.dart';
import 'models/user.dart';

// Wrap MaterialApp with ChangeNotifierProvider in MyApp class:
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => UserProvider(),
      child: MaterialApp(
        // ... rest of your MaterialApp config
      ),
    );
  }
}

// In _AuthWrapperState, add AccountManagerService:
final AccountManagerService _accountManager = AccountManagerService();

// Update _checkAuthState method to load saved accounts:
Future<void> _checkAuthState() async {
  setState(() => _isLoading = true);

  final userProvider = Provider.of<UserProvider>(context, listen: false);

  try {
    final savedAccounts = await _accountManager.loadSavedAccounts();
    userProvider.setSavedAccounts(savedAccounts);
    print('Loaded ${savedAccounts.length} saved accounts');

    _isLoggedIn = _authService.isAuthenticated;

    if (_isLoggedIn) {
      try {
        await _authService.loadUserData();
        userProvider.setUser(User.currentUser);
      } catch (e) {
        print('Error loading user data: $e');
        _isLoggedIn = false;
        userProvider.clearUser();
      }
    } else {
      userProvider.clearUser();
    }
  } catch (e) {
    print('Error checking auth state: $e');
    _isLoggedIn = false;
    userProvider.clearUser();
  }

  setState(() => _isLoading = false);
}

// Update _handleLoginStatusChanged:
void _handleLoginStatusChanged(bool isLoggedIn) async {
  final userProvider = Provider.of<UserProvider>(context, listen: false);

  setState(() { _isLoading = true; });
  userProvider.setLoading(true);

  _isLoggedIn = isLoggedIn;

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

  setState(() { _isLoading = false; });
  userProvider.setLoading(false);
}

// Update _handleSignOut:
Future<void> _handleSignOut() async {
  final userProvider = Provider.of<UserProvider>(context, listen: false);

  try {
    await _authService.signOut();
    userProvider.clearUser();

    setState(() {
      _isLoggedIn = false;
    });
  } catch (e) {
    print('Sign out error: $e');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Sign out failed: ${e.toString()}')),
    );
  }
}
```

### 7. Create AccountSwitcher Widget

Create file: `lib/widgets/account_switcher.dart`

(COPY THE ENTIRE CONTENT FROM THE EXISTING account_switcher.dart FILE - it's too long to include here, but it contains:)
- AccountSwitcher widget
- _switchToAccount method with password dialog
- _showPasswordDialog method
- _removeAccount method
- _AccountListItem widget

**IMPORTANT UI SPECIFICATIONS:**
- Account name font size: **15**
- Email font size: **13**
- Account type font size: **11**
- Password dialog width: **85% of screen width**
- "Sign In" button: **blue background (#0056AC)**, **white text**
- Dialog auto-focuses on password field
- Bottom sheet with rounded top corners

### 8. Update Profile Screen

In your `lib/screens/profile_screen.dart`:

```dart
// Add these imports at the top:
import 'package:provider/provider.dart';
import '../widgets/account_switcher.dart';
import '../providers/user_provider.dart';

// In the profile header where user name is displayed, replace the name Text with:
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

// Add this method to _ProfileScreenState class:
void _showAccountSwitcherBottomSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) => AccountSwitcher(
      onAccountSwitched: () {
        Navigator.pop(context);
        _reloadUserData();
      },
    ),
  );
}
```

### 9. Run flutter pub get

```bash
flutter pub get
```

## Expected Behavior:

1. **After logging in with 2+ accounts**: Dropdown arrow appears next to name in profile header
2. **Tap name**: Bottom sheet slides up showing all accounts
3. **Current account**: Highlighted with blue "Current" badge
4. **Other accounts**: Show X button to remove
5. **Email accounts**: Tap → Password dialog → Enter password → Switch
6. **Google accounts**: Tap → Google picker (if multiple) → Switch
7. **Remove account**: Tap X → Confirmation → Remove from list

## Security Notes:
- ✅ No passwords stored locally
- ✅ Firebase handles all auth tokens
- ✅ Email accounts require password re-entry
- ✅ Only basic profile info cached (name, email, photo)

## Testing Checklist:
- [ ] Login with account 1 → Account saved
- [ ] Login with account 2 → Dropdown arrow appears
- [ ] Tap name → Bottom sheet appears
- [ ] Tap email account → Password dialog appears (width 85%, white "Sign In" text)
- [ ] Enter password → Account switches successfully
- [ ] Tap Google account → Switches or shows Google picker
- [ ] Remove account → Confirmation → Account removed
- [ ] Restart app → Saved accounts persist
- [ ] Font sizes correct (name: 15, email: 13, type: 11)

Please implement exactly as described with proper error handling and user feedback!
