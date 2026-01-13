import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/forum_question.dart';
import '../models/forum_answer.dart';

class ForumService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference get _questionsCollection =>
      _firestore.collection('forum_questions');

  CollectionReference _answersCollection(String questionId) =>
      _questionsCollection.doc(questionId).collection('answers');

  // ============ QUESTIONS ============

  /// Stream of all questions ordered by newest first
  Stream<List<ForumQuestion>> getQuestionsStream() {
    return _questionsCollection
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return ForumQuestion.fromJson(
          doc.data() as Map<String, dynamic>,
          doc.id,
        );
      }).toList();
    });
  }

  /// Stream of a single question
  Stream<ForumQuestion?> getQuestionStream(String questionId) {
    return _questionsCollection.doc(questionId).snapshots().map((doc) {
      if (doc.exists) {
        return ForumQuestion.fromJson(
          doc.data() as Map<String, dynamic>,
          doc.id,
        );
      }
      return null;
    });
  }

  /// Get a single question (non-stream)
  Future<ForumQuestion?> getQuestion(String questionId) async {
    try {
      final doc = await _questionsCollection.doc(questionId).get();
      if (doc.exists) {
        return ForumQuestion.fromJson(
          doc.data() as Map<String, dynamic>,
          doc.id,
        );
      }
      return null;
    } catch (e) {
      print('Error getting question: $e');
      return null;
    }
  }

  /// Create a new question
  Future<String> createQuestion({
    required String authorId,
    required String authorName,
    required String authorEmail,
    required String title,
    required String content,
    List<String> tags = const [],
  }) async {
    try {
      final now = DateTime.now();
      final docRef = await _questionsCollection.add({
        'authorId': authorId,
        'authorName': authorName,
        'authorEmail': authorEmail,
        'title': title,
        'content': content,
        'tags': tags,
        'createdAt': Timestamp.fromDate(now),
        'updatedAt': Timestamp.fromDate(now),
        'answerCount': 0,
        'status': 'open',
        'acceptedAnswerId': null,
      });
      print('Question created with ID: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      print('Error creating question: $e');
      rethrow;
    }
  }

  /// Update question status
  Future<void> updateQuestionStatus(
      String questionId, QuestionStatus status) async {
    try {
      await _questionsCollection.doc(questionId).update({
        'status': status == QuestionStatus.resolved ? 'resolved' : 'open',
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error updating question status: $e');
      rethrow;
    }
  }

  /// Delete a question (only by author)
  Future<void> deleteQuestion(String questionId, String currentUserId) async {
    try {
      final questionDoc = await _questionsCollection.doc(questionId).get();
      if (!questionDoc.exists) {
        throw Exception('Question not found');
      }

      final questionData = questionDoc.data() as Map<String, dynamic>;
      if (questionData['authorId'] != currentUserId) {
        throw Exception('Only the question author can delete this question');
      }

      // Delete all answers first
      final answersSnapshot = await _answersCollection(questionId).get();
      final batch = _firestore.batch();
      for (var doc in answersSnapshot.docs) {
        batch.delete(doc.reference);
      }

      // Delete the question
      batch.delete(_questionsCollection.doc(questionId));
      await batch.commit();

      print('Question $questionId deleted');
    } catch (e) {
      print('Error deleting question: $e');
      rethrow;
    }
  }

  // ============ ANSWERS ============

  /// Stream of answers for a question
  Stream<List<ForumAnswer>> getAnswersStream(String questionId) {
    return _answersCollection(questionId)
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return ForumAnswer.fromJson(
          doc.data() as Map<String, dynamic>,
          doc.id,
        );
      }).toList();
    });
  }

  /// Create a new answer
  Future<String> createAnswer({
    required String questionId,
    required String authorId,
    required String authorName,
    required String authorEmail,
    required String content,
  }) async {
    try {
      final batch = _firestore.batch();

      // Create answer document
      final answerRef = _answersCollection(questionId).doc();
      batch.set(answerRef, {
        'questionId': questionId,
        'authorId': authorId,
        'authorName': authorName,
        'authorEmail': authorEmail,
        'content': content,
        'createdAt': Timestamp.fromDate(DateTime.now()),
        'isAccepted': false,
      });

      // Increment answer count on question
      final questionRef = _questionsCollection.doc(questionId);
      batch.update(questionRef, {
        'answerCount': FieldValue.increment(1),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      await batch.commit();
      print('Answer created with ID: ${answerRef.id}');
      return answerRef.id;
    } catch (e) {
      print('Error creating answer: $e');
      rethrow;
    }
  }

  /// Mark answer as accepted (only question author can do this)
  Future<void> acceptAnswer({
    required String questionId,
    required String answerId,
    required String currentUserId,
  }) async {
    try {
      // Verify user is question author
      final questionDoc = await _questionsCollection.doc(questionId).get();
      if (!questionDoc.exists) {
        throw Exception('Question not found');
      }

      final questionData = questionDoc.data() as Map<String, dynamic>;
      if (questionData['authorId'] != currentUserId) {
        throw Exception('Only the question author can accept an answer');
      }

      final batch = _firestore.batch();

      // Unaccept previously accepted answer if exists
      final previousAcceptedId = questionData['acceptedAnswerId'] as String?;
      if (previousAcceptedId != null && previousAcceptedId.isNotEmpty) {
        final previousAnswerRef =
            _answersCollection(questionId).doc(previousAcceptedId);
        batch.update(previousAnswerRef, {'isAccepted': false});
      }

      // Accept new answer
      final answerRef = _answersCollection(questionId).doc(answerId);
      batch.update(answerRef, {'isAccepted': true});

      // Update question with accepted answer and status
      batch.update(_questionsCollection.doc(questionId), {
        'acceptedAnswerId': answerId,
        'status': 'resolved',
        'updatedAt': FieldValue.serverTimestamp(),
      });

      await batch.commit();
      print('Answer $answerId accepted for question $questionId');
    } catch (e) {
      print('Error accepting answer: $e');
      rethrow;
    }
  }

  /// Delete an answer (only by author)
  Future<void> deleteAnswer({
    required String questionId,
    required String answerId,
    required String currentUserId,
  }) async {
    try {
      final answerDoc =
          await _answersCollection(questionId).doc(answerId).get();
      if (!answerDoc.exists) {
        throw Exception('Answer not found');
      }

      final answerData = answerDoc.data() as Map<String, dynamic>;
      if (answerData['authorId'] != currentUserId) {
        throw Exception('Only the answer author can delete this answer');
      }

      final batch = _firestore.batch();

      // Delete the answer
      batch.delete(_answersCollection(questionId).doc(answerId));

      // Decrement answer count on question
      batch.update(_questionsCollection.doc(questionId), {
        'answerCount': FieldValue.increment(-1),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // If this was the accepted answer, clear it
      final questionDoc = await _questionsCollection.doc(questionId).get();
      if (questionDoc.exists) {
        final questionData = questionDoc.data() as Map<String, dynamic>;
        if (questionData['acceptedAnswerId'] == answerId) {
          batch.update(_questionsCollection.doc(questionId), {
            'acceptedAnswerId': null,
            'status': 'open',
          });
        }
      }

      await batch.commit();
      print('Answer $answerId deleted');
    } catch (e) {
      print('Error deleting answer: $e');
      rethrow;
    }
  }
}
