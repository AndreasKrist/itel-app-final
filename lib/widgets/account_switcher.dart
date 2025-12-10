// lib/widgets/account_switcher.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/saved_account.dart';
import '../models/user.dart';
import '../providers/user_provider.dart';
import '../services/auth_service.dart';
import '../services/account_manager_service.dart';

/// Widget that displays a list of saved accounts for quick switching
/// Similar to Instagram's account switcher
class AccountSwitcher extends StatelessWidget {
  final VoidCallback? onAccountSwitched;

  const AccountSwitcher({
    super.key,
    this.onAccountSwitched,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<UserProvider>(
      builder: (context, userProvider, child) {
        final savedAccounts = userProvider.savedAccounts;
        final currentUser = userProvider.currentUser;

        if (savedAccounts.isEmpty) {
          return const SizedBox.shrink();
        }

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Switch Account',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0056AC),
                      ),
                    ),
                    Text(
                      '${savedAccounts.length} account${savedAccounts.length > 1 ? 's' : ''}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Divider(height: 1, color: Colors.grey[200]),
              ...savedAccounts.map((account) {
                final isCurrentUser = currentUser?.id == account.uid;
                return _AccountListItem(
                  account: account,
                  isCurrentUser: isCurrentUser,
                  onTap: () => _switchToAccount(context, account),
                  onRemove: () => _removeAccount(context, account),
                );
              }).toList(),
            ],
          ),
        );
      },
    );
  }

  Future<void> _switchToAccount(BuildContext context, SavedAccount account) async {
    final authService = AuthService();
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final accountManager = AccountManagerService();

    try {
      // For email accounts, show password dialog instead of just a message
      if (account.authMethod == 'email') {
        final password = await _showPasswordDialog(context, account);

        if (password == null || password.isEmpty) {
          // User cancelled
          return;
        }

        // Show loading dialog
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => Center(
            child: CircularProgressIndicator(),
          ),
        );

        // Sign out current user
        await authService.signOut();

        // Try to sign in with email and password
        try {
          final user = await authService.signInWithEmailPassword(account.email, password);

          // Close loading dialog
          Navigator.of(context).pop();

          if (user != null) {
            // Successfully switched
            userProvider.setUser(User.currentUser);

            // Update last used timestamp
            await accountManager.updateLastUsed(account.uid);
            final updatedAccounts = await accountManager.loadSavedAccounts();
            userProvider.setSavedAccounts(updatedAccounts);

            // Notify parent
            onAccountSwitched?.call();

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Switched to ${account.displayName}'),
                backgroundColor: Colors.green,
              ),
            );
          }
        } catch (e) {
          // Close loading dialog
          Navigator.of(context).pop();

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Incorrect password or sign-in failed'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } else {
        // For Google accounts, use the existing flow
        // Show loading dialog
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => Center(
            child: CircularProgressIndicator(),
          ),
        );

        // Switch account
        final user = await authService.switchToAccount(account);

        // Close loading dialog
        Navigator.of(context).pop();

        if (user != null) {
          // Successfully switched - update provider
          userProvider.setUser(User.currentUser);

          // Update last used timestamp
          await accountManager.updateLastUsed(account.uid);
          final updatedAccounts = await accountManager.loadSavedAccounts();
          userProvider.setSavedAccounts(updatedAccounts);

          // Notify parent
          onAccountSwitched?.call();

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Switched to ${account.displayName}'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      // Close loading dialog if still open
      try {
        Navigator.of(context).pop();
      } catch (_) {}

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to switch account: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<String?> _showPasswordDialog(BuildContext context, SavedAccount account) async {
    final passwordController = TextEditingController();

    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Enter Password'),
        content: Container(
          width: MediaQuery.of(context).size.width * 0.85, // Make dialog wider
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Sign in as ${account.displayName}'),
              Text(
                account.email,
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: passwordController,
                obscureText: true,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock),
                ),
                onSubmitted: (value) {
                  Navigator.pop(context, value);
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, null),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context, passwordController.text);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF0056AC),
              foregroundColor: Colors.white, // White text color
            ),
            child: Text('Sign In'),
          ),
        ],
      ),
    );
  }

  Future<void> _removeAccount(BuildContext context, SavedAccount account) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Remove Account'),
        content: Text(
          'Remove ${account.displayName} (${account.email}) from saved accounts?\n\nYou can always sign in again later.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final authService = AuthService();
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final accountManager = AccountManagerService();

      try {
        await authService.removeAccount(account.uid);

        // Reload saved accounts
        final updatedAccounts = await accountManager.loadSavedAccounts();
        userProvider.setSavedAccounts(updatedAccounts);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Removed ${account.displayName} from saved accounts'),
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to remove account: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

class _AccountListItem extends StatelessWidget {
  final SavedAccount account;
  final bool isCurrentUser;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  const _AccountListItem({
    required this.account,
    required this.isCurrentUser,
    required this.onTap,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isCurrentUser ? Color(0xFF0056AC).withOpacity(0.05) : Colors.white,
        border: Border(
          bottom: BorderSide(color: Colors.grey[200]!),
        ),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Color(0xFF0056AC),
          backgroundImage: account.photoUrl != null ? NetworkImage(account.photoUrl!) : null,
          child: account.photoUrl == null
              ? Text(
                  account.displayName.isNotEmpty ? account.displayName[0].toUpperCase() : 'U',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                )
              : null,
        ),
        title: Text(
          account.displayName,
          style: TextStyle(
            fontWeight: isCurrentUser ? FontWeight.bold : FontWeight.normal,
            fontSize: 15, // Smaller font size
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              account.email,
              style: TextStyle(fontSize: 13), // Smaller font size
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  account.authMethod == 'google' ? Icons.g_mobiledata : Icons.email,
                  size: 16,
                  color: Colors.grey[600],
                ),
                const SizedBox(width: 4),
                Text(
                  account.accountType == 'corporate' ? 'Corporate' : 'Private',
                  style: TextStyle(
                    fontSize: 11, // Smaller font size
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: isCurrentUser
            ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Color(0xFF0056AC),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Current',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )
            : IconButton(
                icon: Icon(Icons.close, color: Colors.grey[400]),
                onPressed: onRemove,
              ),
        onTap: isCurrentUser ? null : onTap,
      ),
    );
  }
}
