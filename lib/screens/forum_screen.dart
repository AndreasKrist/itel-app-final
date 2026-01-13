import 'package:flutter/material.dart';
import '../models/forum_question.dart';
import '../models/user.dart';
import '../services/forum_service.dart';
import '../widgets/forum_question_card.dart';
import 'forum_question_detail_screen.dart';
import 'forum_create_question_screen.dart';

class ForumScreen extends StatefulWidget {
  const ForumScreen({super.key});

  @override
  State<ForumScreen> createState() => _ForumScreenState();
}

class _ForumScreenState extends State<ForumScreen> {
  final ForumService _forumService = ForumService();
  String _filterStatus = 'all'; // 'all', 'open', 'resolved'

  @override
  Widget build(BuildContext context) {
    final currentUser = User.currentUser;
    final isGuest = currentUser.id.isEmpty || currentUser.email.isEmpty;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              color: Colors.white,
              padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.04),
              child: Row(
                children: [
                  Container(
                    width: MediaQuery.of(context).size.width * 0.1,
                    height: MediaQuery.of(context).size.width * 0.1,
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Image.asset(
                      'assets/images/itel.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Forum Q&A',
                          style:
                              Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                        Text(
                          'Ask questions, share knowledge',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Filter dropdown
                  PopupMenuButton<String>(
                    icon: Icon(
                      Icons.filter_list,
                      color: _filterStatus != 'all'
                          ? const Color(0xFF0056AC)
                          : Colors.grey[600],
                    ),
                    onSelected: (value) {
                      setState(() => _filterStatus = value);
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'all',
                        child: Row(
                          children: [
                            Icon(
                              Icons.list,
                              size: 18,
                              color: _filterStatus == 'all'
                                  ? const Color(0xFF0056AC)
                                  : Colors.grey,
                            ),
                            const SizedBox(width: 8),
                            const Text('All Questions'),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'open',
                        child: Row(
                          children: [
                            Icon(
                              Icons.help_outline,
                              size: 18,
                              color: _filterStatus == 'open'
                                  ? const Color(0xFFFF6600)
                                  : Colors.grey,
                            ),
                            const SizedBox(width: 8),
                            const Text('Open'),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'resolved',
                        child: Row(
                          children: [
                            Icon(
                              Icons.check_circle,
                              size: 18,
                              color: _filterStatus == 'resolved'
                                  ? Colors.green
                                  : Colors.grey,
                            ),
                            const SizedBox(width: 8),
                            const Text('Resolved'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Filter indicator
            if (_filterStatus != 'all')
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                color: Colors.white,
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _filterStatus == 'open'
                            ? Colors.orange[50]
                            : Colors.green[50],
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: _filterStatus == 'open'
                              ? Colors.orange[200]!
                              : Colors.green[200]!,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _filterStatus == 'open'
                                ? Icons.help_outline
                                : Icons.check_circle,
                            size: 14,
                            color: _filterStatus == 'open'
                                ? const Color(0xFFFF6600)
                                : Colors.green,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Showing: ${_filterStatus == 'open' ? 'Open' : 'Resolved'}',
                            style: TextStyle(
                              fontSize: 12,
                              color: _filterStatus == 'open'
                                  ? const Color(0xFFFF6600)
                                  : Colors.green,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 4),
                          GestureDetector(
                            onTap: () => setState(() => _filterStatus = 'all'),
                            child: Icon(
                              Icons.close,
                              size: 14,
                              color: _filterStatus == 'open'
                                  ? const Color(0xFFFF6600)
                                  : Colors.green,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

            // Questions list
            Expanded(
              child: StreamBuilder<List<ForumQuestion>>(
                stream: _forumService.getQuestionsStream(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 16),
                          Text('Loading questions...'),
                        ],
                      ),
                    );
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.error_outline,
                                size: 48, color: Colors.red),
                            const SizedBox(height: 16),
                            Text(
                              'Error loading questions',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[700],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${snapshot.error}',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[500],
                              ),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: () => setState(() {}),
                              icon: const Icon(Icons.refresh),
                              label: const Text('Retry'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF0056AC),
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  var questions = snapshot.data ?? [];

                  // Apply filter
                  if (_filterStatus == 'open') {
                    questions = questions
                        .where((q) => q.status == QuestionStatus.open)
                        .toList();
                  } else if (_filterStatus == 'resolved') {
                    questions = questions
                        .where((q) => q.status == QuestionStatus.resolved)
                        .toList();
                  }

                  if (questions.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.forum_outlined,
                                size: 64, color: Colors.grey[400]),
                            const SizedBox(height: 16),
                            Text(
                              _filterStatus == 'all'
                                  ? 'No questions yet'
                                  : 'No ${_filterStatus} questions',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _filterStatus == 'all'
                                  ? 'Be the first to ask a question!'
                                  : 'Try a different filter',
                              style: TextStyle(color: Colors.grey[500]),
                            ),
                            if (!isGuest && _filterStatus == 'all') ...[
                              const SizedBox(height: 24),
                              ElevatedButton.icon(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const ForumCreateQuestionScreen(),
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.add),
                                label: const Text('Ask a Question'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF0056AC),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 24,
                                    vertical: 12,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  }

                  return RefreshIndicator(
                    onRefresh: () async => setState(() {}),
                    child: ListView.separated(
                      padding: EdgeInsets.all(
                          MediaQuery.of(context).size.width * 0.04),
                      itemCount: questions.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final question = questions[index];
                        return ForumQuestionCard(
                          question: question,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ForumQuestionDetailScreen(
                                  questionId: question.id,
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: isGuest
          ? null
          : FloatingActionButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ForumCreateQuestionScreen(),
                  ),
                );
              },
              backgroundColor: const Color(0xFF0056AC),
              child: const Icon(Icons.add, color: Colors.white),
            ),
    );
  }
}
