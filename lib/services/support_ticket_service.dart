import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/support_ticket.dart';
import '../models/support_message.dart';

class SupportTicketService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference get _ticketsCollection =>
      _firestore.collection('support_tickets');

  CollectionReference _messagesCollection(String ticketId) =>
      _ticketsCollection.doc(ticketId).collection('messages');

  // ============ TICKETS ============

  /// Stream of all tickets (for staff view)
  Stream<List<SupportTicket>> getAllTicketsStream() {
    return _ticketsCollection
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return SupportTicket.fromJson(
          doc.data() as Map<String, dynamic>,
          doc.id,
        );
      }).toList();
    });
  }

  /// Stream of tickets created by a specific user
  Stream<List<SupportTicket>> getUserTicketsStream(String userId) {
    return _ticketsCollection
        .where('creatorId', isEqualTo: userId)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return SupportTicket.fromJson(
          doc.data() as Map<String, dynamic>,
          doc.id,
        );
      }).toList();
    });
  }

  /// Stream of a single ticket
  Stream<SupportTicket?> getTicketStream(String ticketId) {
    return _ticketsCollection.doc(ticketId).snapshots().map((doc) {
      if (doc.exists) {
        return SupportTicket.fromJson(
          doc.data() as Map<String, dynamic>,
          doc.id,
        );
      }
      return null;
    });
  }

  /// Get a single ticket (non-stream)
  Future<SupportTicket?> getTicket(String ticketId) async {
    try {
      final doc = await _ticketsCollection.doc(ticketId).get();
      if (doc.exists) {
        return SupportTicket.fromJson(
          doc.data() as Map<String, dynamic>,
          doc.id,
        );
      }
      return null;
    } catch (e) {
      print('Error getting ticket: $e');
      return null;
    }
  }

  /// Create a new support ticket with initial message
  Future<String> createTicket({
    required String creatorId,
    required String creatorName,
    required String creatorEmail,
    required String subject,
    required String initialMessage,
  }) async {
    try {
      final now = DateTime.now();

      // Create the ticket
      final ticketRef = await _ticketsCollection.add({
        'creatorId': creatorId,
        'creatorName': creatorName,
        'creatorEmail': creatorEmail,
        'subject': subject,
        'createdAt': Timestamp.fromDate(now),
        'updatedAt': Timestamp.fromDate(now),
        'status': 'open',
        'lastMessage': initialMessage,
        'lastMessageBy': creatorName,
        'lastMessageAt': Timestamp.fromDate(now),
        'messageCount': 1,
        'viewedByStaff': [],       // No staff has viewed yet
        'hasStaffReply': false,    // No staff reply yet
      });

      // Create initial message
      await _messagesCollection(ticketRef.id).add({
        'ticketId': ticketRef.id,
        'senderId': creatorId,
        'senderName': creatorName,
        'senderEmail': creatorEmail,
        'content': initialMessage,
        'createdAt': Timestamp.fromDate(now),
        'type': 'text',
        'isStaffMessage': false,
      });

      print('Support ticket created with ID: ${ticketRef.id}');
      return ticketRef.id;
    } catch (e) {
      print('Error creating ticket: $e');
      rethrow;
    }
  }

  /// Update ticket status
  Future<void> updateTicketStatus(String ticketId, TicketStatus status) async {
    try {
      String statusString;
      switch (status) {
        case TicketStatus.resolved:
          statusString = 'resolved';
          break;
        case TicketStatus.closed:
          statusString = 'closed';
          break;
        case TicketStatus.open:
          statusString = 'open';
          break;
      }

      await _ticketsCollection.doc(ticketId).update({
        'status': statusString,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      print('Ticket $ticketId status updated to: $statusString');
    } catch (e) {
      print('Error updating ticket status: $e');
      rethrow;
    }
  }

  /// Delete a ticket (only by creator or staff)
  Future<void> deleteTicket(String ticketId, String currentUserId, bool isStaff) async {
    try {
      final ticketDoc = await _ticketsCollection.doc(ticketId).get();
      if (!ticketDoc.exists) {
        throw Exception('Ticket not found');
      }

      final ticketData = ticketDoc.data() as Map<String, dynamic>;
      if (ticketData['creatorId'] != currentUserId && !isStaff) {
        throw Exception('Only the ticket creator or staff can delete this ticket');
      }

      // Delete all messages first
      final messagesSnapshot = await _messagesCollection(ticketId).get();
      final batch = _firestore.batch();
      for (var doc in messagesSnapshot.docs) {
        batch.delete(doc.reference);
      }

      // Delete the ticket
      batch.delete(_ticketsCollection.doc(ticketId));
      await batch.commit();

      print('Ticket $ticketId deleted');
    } catch (e) {
      print('Error deleting ticket: $e');
      rethrow;
    }
  }

  /// Mark a ticket as viewed by a staff member
  /// This adds the staff ID to the viewedByStaff list if not already present
  Future<void> markAsViewedByStaff(String ticketId, String staffId) async {
    try {
      await _ticketsCollection.doc(ticketId).update({
        'viewedByStaff': FieldValue.arrayUnion([staffId]),
      });
      print('Ticket $ticketId marked as viewed by staff $staffId');
    } catch (e) {
      print('Error marking ticket as viewed: $e');
      // Don't rethrow - this is a non-critical operation
    }
  }

  /// Stream of count of tickets needing staff attention
  /// A ticket needs attention if: status is 'open' AND hasStaffReply is false
  Stream<int> getUnattendedTicketsCountStream() {
    return _ticketsCollection
        .where('status', isEqualTo: 'open')
        .where('hasStaffReply', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  /// Stream of all open tickets that haven't been replied to by staff
  /// Used for staff notification badge
  Stream<List<SupportTicket>> getUnattendedTicketsStream() {
    return _ticketsCollection
        .where('status', isEqualTo: 'open')
        .where('hasStaffReply', isEqualTo: false)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return SupportTicket.fromJson(
          doc.data() as Map<String, dynamic>,
          doc.id,
        );
      }).toList();
    });
  }

  // ============ MESSAGES ============

  /// Stream of messages for a ticket
  Stream<List<SupportMessage>> getMessagesStream(String ticketId) {
    return _messagesCollection(ticketId)
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return SupportMessage.fromJson(
          doc.data() as Map<String, dynamic>,
          doc.id,
        );
      }).toList();
    });
  }

  /// Send a message in a ticket
  /// Only ticket creator and staff can send messages
  Future<String> sendMessage({
    required String ticketId,
    required String senderId,
    required String senderName,
    required String senderEmail,
    required String content,
    required bool isStaff,
  }) async {
    try {
      // Verify user can send message
      final ticketDoc = await _ticketsCollection.doc(ticketId).get();
      if (!ticketDoc.exists) {
        throw Exception('Ticket not found');
      }

      final ticketData = ticketDoc.data() as Map<String, dynamic>;
      final creatorId = ticketData['creatorId'] as String;

      if (senderId != creatorId && !isStaff) {
        throw Exception('Only the ticket creator and ITEL staff can reply');
      }

      final now = DateTime.now();
      final batch = _firestore.batch();

      // Create message
      final messageRef = _messagesCollection(ticketId).doc();
      batch.set(messageRef, {
        'ticketId': ticketId,
        'senderId': senderId,
        'senderName': senderName,
        'senderEmail': senderEmail,
        'content': content,
        'createdAt': Timestamp.fromDate(now),
        'type': 'text',
        'isStaffMessage': isStaff,
      });

      // Update ticket
      final updateData = {
        'lastMessage': content,
        'lastMessageBy': senderName,
        'lastMessageAt': Timestamp.fromDate(now),
        'updatedAt': Timestamp.fromDate(now),
        'messageCount': FieldValue.increment(1),
      };

      // If staff is replying, mark hasStaffReply as true
      if (isStaff) {
        updateData['hasStaffReply'] = true;
      }

      batch.update(_ticketsCollection.doc(ticketId), updateData);

      await batch.commit();
      print('Message sent in ticket $ticketId');
      return messageRef.id;
    } catch (e) {
      print('Error sending message: $e');
      rethrow;
    }
  }

  /// Delete a message (only by sender)
  Future<void> deleteMessage({
    required String ticketId,
    required String messageId,
    required String currentUserId,
  }) async {
    try {
      final messageDoc = await _messagesCollection(ticketId).doc(messageId).get();
      if (!messageDoc.exists) {
        throw Exception('Message not found');
      }

      final messageData = messageDoc.data() as Map<String, dynamic>;
      if (messageData['senderId'] != currentUserId) {
        throw Exception('Only the message sender can delete this message');
      }

      // Soft delete
      await _messagesCollection(ticketId).doc(messageId).update({
        'deletedAt': FieldValue.serverTimestamp(),
        'deletedBy': currentUserId,
      });

      print('Message $messageId deleted');
    } catch (e) {
      print('Error deleting message: $e');
      rethrow;
    }
  }
}
