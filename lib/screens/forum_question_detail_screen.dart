import 'package:flutter/material.dart';
import '../models/forum_question.dart';
import '../models/forum_answer.dart';
import '../models/user.dart';
import '../services/forum_service.dart';
import '../widgets/forum_answer_card.dart';

class ForumQuestionDetailScreen extends StatefulWidget {
  final String questionId;

  const ForumQuestionDetailScreen({
    super.key,
    required this.questionId,
  });

  @override
  State<ForumQuestionDetailScreen> createState() =>
      _ForumQuestionDetailScreenState();
}

class _ForumQuestionDetailScreenState extends State<ForumQuestionDetailScreen> {
  final ForumService _forumService = ForumService();
  final TextEditingController _answerController = TextEditingController();
  final FocusNode _answerFocusNode = FocusNode();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _answerController.dispose();
    _answerFocusNode.dispose();
    super.dispose();
  }

  Future<void> _submitAnswer(ForumQuestion question) async {
    final currentUser = User.currentUser;
    final isGuest = currentUser.id.isEmpty || currentUser.email.isEmpty;

    if (isGuest) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please sign in to answer questions'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_answerController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your answer'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      await _forumService.createAnswer(
        questionId: widget.questionId,
        authorId: currentUser.id,
        authorName: currentUser.name,
        authorEmail: currentUser.email,
        content: _answerController.text.trim(),
      );
      _answerController.clear();
      _answerFocusNode.unfocus();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Answer posted successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error posting answer: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _acceptAnswer(String answerId) async {
    try {
      await _forumService.acceptAnswer(
        questionId: widget.questionId,
        answerId: answerId,
        currentUserId: User.currentUser.id,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Answer accepted!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = User.currentUser;
    final isGuest = currentUser.id.isEmpty || currentUser.email.isEmpty;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Question'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: StreamBuilder<ForumQuestion?>(
        stream: _forumService.getQuestionStream(widget.questionId),
        builder: (context, questionSnapshot) {
          if (questionSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final question = questionSnapshot.data;
          if (question == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 48, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'Question not found',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Go Back'),
                  ),
                ],
              ),
            );
          }

          final isAuthor = currentUser.id == question.authorId;

          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Question card
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey[200]!),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Status badge and date
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: question.status ==
                                            QuestionStatus.resolved
                                        ? Colors.green[50]
                                        : Colors.orange[50],
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        question.status ==
                                                QuestionStatus.resolved
                                            ? Icons.check_circle
                                            : Icons.help_outline,
                                        size: 14,
                                        color: question.status ==
                                                QuestionStatus.resolved
                                            ? Colors.green
                                            : const Color(0xFFFF6600),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        question.status ==
                                                QuestionStatus.resolved
                                            ? 'Resolved'
                                            : 'Open',
                                        style: TextStyle(
                                          color: question.status ==
                                                  QuestionStatus.resolved
                                              ? Colors.green
                                              : const Color(0xFFFF6600),
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  _formatDate(question.createdAt),
                                  style: TextStyle(
                                    color: Colors.grey[500],
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),

                            // Title
                            Text(
                              question.title,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),

                            // Content
                            Text(
                              question.content,
                              style: TextStyle(
                                fontSize: 15,
                                color: Colors.grey[700],
                                height: 1.6,
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Tags
                            if (question.tags.isNotEmpty)
                              Wrap(
                                spacing: 8,
                                runSpacing: 6,
                                children: question.tags.map((tag) {
                                  return Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 5,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.blue[50],
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      tag,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFF0056AC),
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),

                            const SizedBox(height: 16),
                            const Divider(),
                            const SizedBox(height: 12),

                            // Author info
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 16,
                                  backgroundColor: const Color(0xFF0056AC),
                                  child: Text(
                                    question.authorName.isNotEmpty
                                        ? question.authorName[0].toUpperCase()
                                        : '?',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      question.authorName,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                      ),
                                    ),
                                    Text(
                                      'Asked ${_formatDate(question.createdAt)}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[500],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Answers section header
                      Row(
                        children: [
                          Text(
                            'Answers',
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0056AC),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${question.answerCount}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Answers list
                      StreamBuilder<List<ForumAnswer>>(
                        stream:
                            _forumService.getAnswersStream(widget.questionId),
                        builder: (context, answersSnapshot) {
                          if (answersSnapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                              child: Padding(
                                padding: EdgeInsets.all(24),
                                child: CircularProgressIndicator(),
                              ),
                            );
                          }

                          final answers = answersSnapshot.data ?? [];

                          if (answers.isEmpty) {
                            return Container(
                              padding: const EdgeInsets.all(32),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey[200]!),
                              ),
                              child: Center(
                                child: Column(
                                  children: [
                                    Icon(Icons.chat_bubble_outline,
                                        size: 40, color: Colors.grey[400]),
                                    const SizedBox(height: 12),
                                    Text(
                                      'No answers yet',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Be the first to help!',
                                      style: TextStyle(color: Colors.grey[500]),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }

                          // Sort answers: accepted first, then by date
                          final sortedAnswers = List<ForumAnswer>.from(answers);
                          sortedAnswers.sort((a, b) {
                            if (a.isAccepted && !b.isAccepted) return -1;
                            if (!a.isAccepted && b.isAccepted) return 1;
                            return a.createdAt.compareTo(b.createdAt);
                          });

                          return ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: sortedAnswers.length,
                            separatorBuilder: (context, index) =>
                                const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final answer = sortedAnswers[index];
                              return ForumAnswerCard(
                                answer: answer,
                                isQuestionAuthor: isAuthor,
                                onAccept: isAuthor &&
                                        !answer.isAccepted &&
                                        question.status != QuestionStatus.resolved
                                    ? () => _acceptAnswer(answer.id)
                                    : null,
                              );
                            },
                          );
                        },
                      ),

                      // Add some bottom padding for the input field
                      const SizedBox(height: 80),
                    ],
                  ),
                ),
              ),

              // Answer input (only for logged-in users)
              if (!isGuest)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border(
                      top: BorderSide(color: Colors.grey[200]!),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: SafeArea(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _answerController,
                            focusNode: _answerFocusNode,
                            decoration: InputDecoration(
                              hintText: 'Write your answer...',
                              hintStyle: TextStyle(color: Colors.grey[400]),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(24),
                                borderSide:
                                    BorderSide(color: Colors.grey[300]!),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(24),
                                borderSide:
                                    BorderSide(color: Colors.grey[300]!),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(24),
                                borderSide: const BorderSide(
                                    color: Color(0xFF0056AC)),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 12,
                              ),
                              filled: true,
                              fillColor: Colors.grey[50],
                            ),
                            maxLines: 4,
                            minLines: 1,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF0056AC),
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: IconButton(
                            onPressed: _isSubmitting
                                ? null
                                : () => _submitAnswer(question),
                            icon: _isSubmitting
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(
                                    Icons.send,
                                    color: Colors.white,
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              // Guest prompt
              if (isGuest)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.orange[50],
                    border: Border(
                      top: BorderSide(color: Colors.orange[200]!),
                    ),
                  ),
                  child: SafeArea(
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.orange[700]),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Sign in to answer this question',
                            style: TextStyle(color: Colors.orange[700]),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';

    return '${date.day}/${date.month}/${date.year}';
  }
}
