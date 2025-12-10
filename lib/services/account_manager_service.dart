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
