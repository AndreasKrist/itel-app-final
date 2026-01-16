import 'package:flutter/material.dart';
import '../models/forum_question.dart';

class ForumQuestionCard extends StatelessWidget {
  final ForumQuestion question;
  final VoidCallback onTap;
  final VoidCallback? onTapAuthor;  // Callback for tapping on author to start DM

  const ForumQuestionCard({
    super.key,
    required this.question,
    required this.onTap,
    this.onTapAuthor,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey[200]!),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status and answer count row
            Row(
              children: [
                // Status badge
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: question.status == QuestionStatus.resolved
                        ? Colors.green[50]
                        : Colors.orange[50],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        question.status == QuestionStatus.resolved
                            ? Icons.check_circle
                            : Icons.help_outline,
                        size: 12,
                        color: question.status == QuestionStatus.resolved
                            ? Colors.green
                            : const Color(0xFFFF6600),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        question.status == QuestionStatus.resolved
                            ? 'Resolved'
                            : 'Open',
                        style: TextStyle(
                          color: question.status == QuestionStatus.resolved
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
                // Answer count
                Row(
                  children: [
                    Icon(Icons.chat_bubble_outline,
                        size: 14, color: Colors.grey[500]),
                    const SizedBox(width: 4),
                    Text(
                      '${question.answerCount} ${question.answerCount == 1 ? 'answer' : 'answers'}',
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Title
            Text(
              question.title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),

            const SizedBox(height: 8),

            // Content preview
            Text(
              question.content,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),

            const SizedBox(height: 12),

            // Tags
            if (question.tags.isNotEmpty)
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: question.tags.take(3).map((tag) {
                  return Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      tag,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF0056AC),
                      ),
                    ),
                  );
                }).toList(),
              ),

            const SizedBox(height: 12),

            // Author and time row
            Row(
              children: [
                // Tappable author for DM
                GestureDetector(
                  onTap: onTapAuthor,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircleAvatar(
                        radius: 12,
                        backgroundColor: const Color(0xFF0056AC),
                        child: Text(
                          question.authorName.isNotEmpty
                              ? question.authorName[0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        question.authorName,
                        style: TextStyle(
                          fontSize: 12,
                          color: onTapAuthor != null
                              ? const Color(0xFF0056AC)
                              : Colors.grey[700],
                          fontWeight: onTapAuthor != null
                              ? FontWeight.w500
                              : FontWeight.normal,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Text(
                  _formatDate(question.createdAt),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ],
        ),
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
