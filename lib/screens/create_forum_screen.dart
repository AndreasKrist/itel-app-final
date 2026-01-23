// lib/screens/create_forum_screen.dart
import 'package:flutter/material.dart';
import '../models/forum_group.dart';
import '../models/user.dart';
import '../services/forum_group_service.dart';

class CreateForumScreen extends StatefulWidget {
  const CreateForumScreen({super.key});

  @override
  State<CreateForumScreen> createState() => _CreateForumScreenState();
}

class _CreateForumScreenState extends State<CreateForumScreen> {
  final ForumGroupService _forumService = ForumGroupService();
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _emailSearchController = TextEditingController();

  ForumVisibility _visibility = ForumVisibility.public;
  bool _isCreating = false;
  bool _isSearching = false;
  List<Map<String, String>> _searchResults = [];
  List<Map<String, String>> _selectedMembers = [];

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _emailSearchController.dispose();
    super.dispose();
  }

  Future<void> _searchUsers(String query) async {
    if (query.length < 3) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    setState(() => _isSearching = true);

    try {
      final results = await _forumService.searchUsersByEmail(query);
      // Filter out already selected members and current user
      final currentUser = User.currentUser;
      final filteredResults = results.where((user) {
        final userId = user['userId']!;
        return userId != currentUser.id &&
            !_selectedMembers.any((m) => m['userId'] == userId);
      }).toList();

      if (mounted) {
        setState(() {
          _searchResults = filteredResults;
          _isSearching = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _searchResults = [];
          _isSearching = false;
        });
      }
    }
  }

  void _addMember(Map<String, String> user) {
    setState(() {
      _selectedMembers.add(user);
      _searchResults = [];
      _emailSearchController.clear();
    });
  }

  void _removeMember(String odGptUserId) {
    setState(() {
      _selectedMembers.removeWhere((m) => m['userId'] == odGptUserId);
    });
  }

  Future<void> _createForum() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isCreating = true);

    try {
      final currentUser = User.currentUser;
      final forumId = await _forumService.createForum(
        creatorId: currentUser.id,
        creatorName: currentUser.name,
        creatorEmail: currentUser.email,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        visibility: _visibility,
        initialMembers: _selectedMembers,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Forum created! Waiting for staff approval before it becomes visible.'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating forum: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isCreating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Create Forum'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title field
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Forum Details',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: 'Forum Title',
                        hintText: 'Enter a title for your forum',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.title),
                      ),
                      maxLength: 50,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter a title';
                        }
                        if (value.trim().length < 3) {
                          return 'Title must be at least 3 characters';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        hintText: 'What is this forum about?',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.description),
                        alignLabelWithHint: true,
                      ),
                      maxLines: 3,
                      maxLength: 200,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Visibility selection
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Visibility',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    RadioListTile<ForumVisibility>(
                      value: ForumVisibility.public,
                      groupValue: _visibility,
                      onChanged: (value) =>
                          setState(() => _visibility = value!),
                      title: const Row(
                        children: [
                          Icon(Icons.public, color: Colors.green),
                          SizedBox(width: 8),
                          Text('Public'),
                        ],
                      ),
                      subtitle: const Text(
                          'Anyone can see and join this forum directly'),
                      contentPadding: EdgeInsets.zero,
                    ),
                    RadioListTile<ForumVisibility>(
                      value: ForumVisibility.private,
                      groupValue: _visibility,
                      onChanged: (value) =>
                          setState(() => _visibility = value!),
                      title: const Row(
                        children: [
                          Icon(Icons.lock, color: Colors.orange),
                          SizedBox(width: 8),
                          Text('Private'),
                        ],
                      ),
                      subtitle: const Text(
                          'Others can see the forum but need your approval to join'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Member invitation
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Invite Members (Optional)',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Search users by email to add them to your forum',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _emailSearchController,
                      decoration: InputDecoration(
                        labelText: 'Search by email',
                        hintText: 'Enter email address',
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.email_outlined),
                        suffixIcon: _isSearching
                            ? const Padding(
                                padding: EdgeInsets.all(12),
                                child: SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                              )
                            : null,
                      ),
                      onChanged: (value) => _searchUsers(value.trim()),
                    ),

                    // Search results
                    if (_searchResults.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Container(
                        constraints: const BoxConstraints(maxHeight: 150),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: _searchResults.length,
                          itemBuilder: (context, index) {
                            final user = _searchResults[index];
                            return ListTile(
                              leading: CircleAvatar(
                                backgroundColor: const Color(0xFF0056AC),
                                child: Text(
                                  user['userName']![0].toUpperCase(),
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ),
                              title: Text(user['userName']!),
                              subtitle: Text(
                                user['userEmail']!,
                                style: const TextStyle(fontSize: 12),
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.add_circle,
                                    color: Colors.green),
                                onPressed: () => _addMember(user),
                              ),
                              dense: true,
                            );
                          },
                        ),
                      ),
                    ],

                    // Selected members
                    if (_selectedMembers.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Text(
                        'Selected Members (${_selectedMembers.length})',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _selectedMembers.map((member) {
                          return Chip(
                            avatar: CircleAvatar(
                              backgroundColor: const Color(0xFF0056AC),
                              child: Text(
                                member['userName']![0].toUpperCase(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            label: Text(member['userName']!),
                            deleteIcon: const Icon(Icons.close, size: 18),
                            onDeleted: () => _removeMember(member['userId']!),
                          );
                        }).toList(),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Info box
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue[700]),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Your forum will be reviewed by ITEL staff before becoming visible to others.',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.blue[700],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Create button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isCreating ? null : _createForum,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0056AC),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isCreating
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Create Forum',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
