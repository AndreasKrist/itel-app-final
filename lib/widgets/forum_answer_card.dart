import 'package:flutter/material.dart';
import '../models/forum_answer.dart';

class ForumAnswerCard extends StatelessWidget {
  final ForumAnswer answer;
  final bool isQuestionAuthor;
  final VoidCallback? onAccept;

  const ForumAnswerCard({
    super.key,
    required this.answer,
    required this.isQuestionAuthor,
    this.onAccept,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: answer.isAccepted ? Colors.green[50] : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: answer.isAccepted ? Colors.green[300]! : Colors.grey[200]!,
          width: answer.isAccepted ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Badges row (Staff + Accepted)
          Row(
            children: [
              // ITEL Staff badge
              if (answer.isStaffAnswer)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  margin: const EdgeInsets.only(right: 8, bottom: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0056AC),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.verified, size: 14, color: Colors.white),
                      SizedBox(width: 4),
                      Text(
                        'ITEL Staff',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              // Accepted badge
              if (answer.isAccepted)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle, size: 14, color: Colors.white),
                      SizedBox(width: 4),
                      Text(
                        'Accepted Answer',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),

          // Content
          Text(
            answer.content,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[800],
              height: 1.5,
            ),
          ),

          const SizedBox(height: 12),

          // Author and actions row
          Row(
            children: [
              CircleAvatar(
                radius: 12,
                backgroundColor: const Color(0xFF0056AC),
                child: Text(
                  answer.authorName.isNotEmpty
                      ? answer.authorName[0].toUpperCase()
                      : '?',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      answer.authorName,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      _formatDate(answer.createdAt),
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ),

              // Accept button (only for question author and non-accepted answers)
              if (isQuestionAuthor && !answer.isAccepted && onAccept != null)
                TextButton.icon(
                  onPressed: onAccept,
                  icon: const Icon(Icons.check, size: 16, color: Colors.green),
                  label: const Text(
                    'Accept',
                    style: TextStyle(color: Colors.green),
                  ),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                ),
            ],
          ),
        ],
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
