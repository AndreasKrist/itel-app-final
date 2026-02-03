import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/forum_group.dart';
import '../models/forum_member.dart';
import '../models/forum_message.dart';
import '../models/forum_join_request.dart';
import '../models/forum_kick_log.dart';
import '../models/forum_invitation.dart';

class ForumGroupService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference get _forumsCollection =>
      _firestore.collection('forum_groups');

  CollectionReference _membersCollection(String forumId) =>
      _forumsCollection.doc(forumId).collection('members');

  CollectionReference _messagesCollection(String forumId) =>
      _forumsCollection.doc(forumId).collection('messages');

  CollectionReference _joinRequestsCollection(String forumId) =>
      _forumsCollection.doc(forumId).collection('join_requests');

  CollectionReference get _kickLogsCollection =>
      _firestore.collection('forum_kick_logs');

  CollectionReference get _invitationsCollection =>
      _firestore.collection('forum_invitations');

  // ============ FORUM CRUD ============

  /// Stream of approved forums (for public view)
  Stream<List<ForumGroup>> getApprovedForumsStream() {
    return _forumsCollection
        .where('approvalStatus', isEqualTo: 'approved')
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return ForumGroup.fromJson(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
    });
  }

  /// Stream of all forums (for staff/admin moderation)
  Stream<List<ForumGroup>> getAllForumsStream() {
    return _forumsCollection
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return ForumGroup.fromJson(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
    });
  }

  /// Stream of pending forums (for staff approval)
  Stream<List<ForumGroup>> getPendingForumsStream() {
    return _forumsCollection
        .where('approvalStatus', isEqualTo: 'pending')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return ForumGroup.fromJson(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
    });
  }

  /// Stream of forums user is a member of (includes rejected forums if user is creator)
  Stream<List<ForumGroup>> getUserForumsStream(String odGptUserId) {
    // Get approved forums where user is a member
    final approvedForumsStream = _forumsCollection
        .where('memberIds', arrayContains: odGptUserId)
        .where('approvalStatus', isEqualTo: 'approved')
        .orderBy('updatedAt', descending: true)
        .snapshots();

    // Get rejected forums where user is the creator
    final rejectedForumsStream = _forumsCollection
        .where('creatorId', isEqualTo: odGptUserId)
        .where('approvalStatus', isEqualTo: 'rejected')
        .snapshots();

    // Get pending forums where user is the creator
    final pendingForumsStream = _forumsCollection
        .where('creatorId', isEqualTo: odGptUserId)
        .where('approvalStatus', isEqualTo: 'pending')
        .snapshots();

    // Combine all streams
    return approvedForumsStream.asyncMap((approvedSnapshot) async {
      final approvedForums = approvedSnapshot.docs.map((doc) {
        return ForumGroup.fromJson(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();

      // Get rejected forums
      final rejectedSnapshot = await _forumsCollection
          .where('creatorId', isEqualTo: odGptUserId)
          .where('approvalStatus', isEqualTo: 'rejected')
          .get();
      final rejectedForums = rejectedSnapshot.docs.map((doc) {
        return ForumGroup.fromJson(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();

      // Get pending forums
      final pendingSnapshot = await _forumsCollection
          .where('creatorId', isEqualTo: odGptUserId)
          .where('approvalStatus', isEqualTo: 'pending')
          .get();
      final pendingForums = pendingSnapshot.docs.map((doc) {
        return ForumGroup.fromJson(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();

      // Combine and sort by updatedAt
      final allForums = [...approvedForums, ...rejectedForums, ...pendingForums];
      allForums.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      return allForums;
    });
  }

  /// Stream of a single forum
  Stream<ForumGroup?> getForumStream(String forumId) {
    return _forumsCollection.doc(forumId).snapshots().map((doc) {
      if (doc.exists) {
        return ForumGroup.fromJson(doc.data() as Map<String, dynamic>, doc.id);
      }
      return null;
    });
  }

  /// Get a single forum (non-stream)
  Future<ForumGroup?> getForum(String forumId) async {
    try {
      final doc = await _forumsCollection.doc(forumId).get();
      if (doc.exists) {
        return ForumGroup.fromJson(doc.data() as Map<String, dynamic>, doc.id);
      }
      return null;
    } catch (e) {
      print('Error getting forum: $e');
      return null;
    }
  }

  /// Create a new forum (initial members will be invited, not auto-added)
  Future<String> createForum({
    required String creatorId,
    required String creatorName,
    required String creatorEmail,
    required String title,
    required String description,
    required ForumVisibility visibility,
    List<Map<String, String>> initialMembers = const [], // [{userId, userName, userEmail}]
  }) async {
    try {
      final now = DateTime.now();
      // Only creator is a member initially
      final memberIds = [creatorId];

      // Create forum document
      final forumRef = await _forumsCollection.add({
        'title': title,
        'description': description,
        'creatorId': creatorId,
        'creatorName': creatorName,
        'creatorEmail': creatorEmail,
        'createdAt': Timestamp.fromDate(now),
        'updatedAt': Timestamp.fromDate(now),
        'visibility': visibility == ForumVisibility.public ? 'public' : 'private',
        'approvalStatus': 'pending',
        'memberCount': 1, // Only creator
        'memberIds': memberIds,
        // Store pending invites to send after approval
        'pendingInvites': initialMembers,
      });

      final batch = _firestore.batch();

      // Add creator as member
      final creatorMemberRef = _membersCollection(forumRef.id).doc();
      batch.set(creatorMemberRef, {
        'forumId': forumRef.id,
        'userId': creatorId,
        'userName': creatorName,
        'userEmail': creatorEmail,
        'role': 'creator',
        'joinedAt': Timestamp.fromDate(now),
        'isActive': true,
      });

      await batch.commit();
      print('Forum created with ID: ${forumRef.id}');
      return forumRef.id;
    } catch (e) {
      print('Error creating forum: $e');
      rethrow;
    }
  }

  /// Approve a forum (staff/admin only)
  /// This also sends invitations to any pending invites from creation
  Future<void> approveForum({
    required String forumId,
    required String approvedById,
  }) async {
    try {
      // Get the forum to check for pending invites
      final forum = await getForum(forumId);
      if (forum == null) {
        throw Exception('Forum not found');
      }

      // Get pending invites from forum document BEFORE updating
      final forumDoc = await _forumsCollection.doc(forumId).get();
      final forumData = forumDoc.data() as Map<String, dynamic>?;
      final pendingInvites = forumData?['pendingInvites'] as List<dynamic>? ?? [];

      // Update approval status and remove pending invites
      await _forumsCollection.doc(forumId).update({
        'approvalStatus': 'approved',
        'approvedBy': approvedById,
        'approvedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'pendingInvites': FieldValue.delete(), // Remove pending invites after processing
      });

      // Send invitations to pending members
      for (final invite in pendingInvites) {
        final inviteMap = invite as Map<String, dynamic>;
        try {
          await _invitationsCollection.add({
            'forumId': forumId,
            'forumTitle': forum.title,
            'invitedUserId': inviteMap['userId'],
            'invitedUserName': inviteMap['userName'],
            'invitedUserEmail': inviteMap['userEmail'],
            'invitedById': forum.creatorId,
            'invitedByName': forum.creatorName,
            'invitedAt': Timestamp.now(),
            'status': 'pending',
          });
          print('Invitation sent to ${inviteMap['userName']} for forum ${forum.title}');
        } catch (e) {
          print('Error sending invitation to ${inviteMap['userId']}: $e');
        }
      }

      print('Forum $forumId approved, ${pendingInvites.length} invitations sent');
    } catch (e) {
      print('Error approving forum: $e');
      rethrow;
    }
  }

  /// Reject a forum (staff/admin only)
  Future<void> rejectForum({
    required String forumId,
    required String rejectedById,
    String? reason,
  }) async {
    try {
      await _forumsCollection.doc(forumId).update({
        'approvalStatus': 'rejected',
        'rejectionReason': reason,
        'approvedBy': rejectedById,
        'approvedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      print('Forum $forumId rejected');
    } catch (e) {
      print('Error rejecting forum: $e');
      rethrow;
    }
  }

  /// Remove/delete a forum (staff only)
  Future<void> removeForum({
    required String forumId,
    required String removedById,
    required String removedByName,
    required String removedByEmail,
    required bool isStaff,
  }) async {
    try {
      if (!isStaff) {
        throw Exception('Only staff can remove forums');
      }

      final forum = await getForum(forumId);
      if (forum == null) {
        throw Exception('Forum not found');
      }

      final batch = _firestore.batch();

      // Log the removal for all members
      for (final odGptUserId in forum.memberIds) {
        final member = await getMember(forumId, odGptUserId);
        if (member != null) {
          final logRef = _kickLogsCollection.doc();
          batch.set(logRef, {
            'forumId': forumId,
            'forumTitle': forum.title,
            'kickedUserId': member.odGptUserId,
            'kickedUserName': member.userName,
            'kickedUserEmail': member.userEmail,
            'kickedById': removedById,
            'kickedByName': removedByName,
            'kickedByEmail': removedByEmail,
            'kickedByStaff': true,
            'kickType': 'forumRemoved',
            'reason': 'Forum removed by staff',
            'kickedAt': FieldValue.serverTimestamp(),
          });
        }
      }

      // Delete all messages
      final messagesSnapshot = await _messagesCollection(forumId).get();
      for (var doc in messagesSnapshot.docs) {
        batch.delete(doc.reference);
      }

      // Delete all members
      final membersSnapshot = await _membersCollection(forumId).get();
      for (var doc in membersSnapshot.docs) {
        batch.delete(doc.reference);
      }

      // Delete all join requests
      final requestsSnapshot = await _joinRequestsCollection(forumId).get();
      for (var doc in requestsSnapshot.docs) {
        batch.delete(doc.reference);
      }

      // Delete the forum
      batch.delete(_forumsCollection.doc(forumId));

      await batch.commit();
      print('Forum $forumId removed by staff');
    } catch (e) {
      print('Error removing forum: $e');
      rethrow;
    }
  }

  // ============ MEMBERS ============

  /// Stream of active members for a forum
  Stream<List<ForumMember>> getMembersStream(String forumId) {
    return _membersCollection(forumId)
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
      final members = snapshot.docs.map((doc) {
        return ForumMember.fromJson(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
      // Sort by joinedAt in memory to avoid composite index
      members.sort((a, b) => a.joinedAt.compareTo(b.joinedAt));
      return members;
    });
  }

  /// Get a specific member
  Future<ForumMember?> getMember(String forumId, String odGptUserId) async {
    try {
      // Single field query, filter isActive in memory
      final snapshot = await _membersCollection(forumId)
          .where('userId', isEqualTo: odGptUserId)
          .get();

      // Find the active member
      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        if (data['isActive'] == true) {
          return ForumMember.fromJson(data, doc.id);
        }
      }
      return null;
    } catch (e) {
      print('Error getting member: $e');
      return null;
    }
  }

  /// Check if user is a member of forum
  Future<bool> isMember(String forumId, String odGptUserId) async {
    final member = await getMember(forumId, odGptUserId);
    return member != null;
  }

  /// Add a member directly to forum (for public forums join or after invitation accepted)
  Future<void> addMemberDirectly({
    required String forumId,
    required String odGptUserId,
    required String userName,
    required String userEmail,
    String? invitedBy,
  }) async {
    try {
      final batch = _firestore.batch();

      // Add member
      final memberRef = _membersCollection(forumId).doc();
      batch.set(memberRef, {
        'forumId': forumId,
        'userId': odGptUserId,
        'userName': userName,
        'userEmail': userEmail,
        'role': 'member',
        'joinedAt': FieldValue.serverTimestamp(),
        'invitedBy': invitedBy,
        'isActive': true,
      });

      // Update forum member count and memberIds
      batch.update(_forumsCollection.doc(forumId), {
        'memberCount': FieldValue.increment(1),
        'memberIds': FieldValue.arrayUnion([odGptUserId]),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Add system message
      final messageRef = _messagesCollection(forumId).doc();
      batch.set(messageRef, {
        'forumId': forumId,
        'senderId': 'system',
        'senderName': 'System',
        'senderEmail': '',
        'content': '$userName joined the forum',
        'createdAt': FieldValue.serverTimestamp(),
        'type': 'system',
      });

      await batch.commit();
      print('Member $odGptUserId added to forum $forumId');
    } catch (e) {
      print('Error adding member: $e');
      rethrow;
    }
  }

  /// Invite a member to forum (creates invitation that user must accept)
  Future<void> inviteMember({
    required String forumId,
    required String odGptUserId,
    required String userName,
    required String userEmail,
    required String invitedById,
    required String invitedByName,
  }) async {
    try {
      // Get forum title
      final forum = await getForum(forumId);
      if (forum == null) {
        throw Exception('Forum not found');
      }

      // Check if already a member
      if (await isMember(forumId, odGptUserId)) {
        throw Exception('User is already a member of this forum');
      }

      // Check for existing pending invitation (simplified - single field query)
      final userInvitations = await _invitationsCollection
          .where('invitedUserId', isEqualTo: odGptUserId)
          .get();

      // Filter in memory to avoid composite index
      final hasPendingInvitation = userInvitations.docs.any((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return data['forumId'] == forumId && data['status'] == 'pending';
      });

      if (hasPendingInvitation) {
        throw Exception('User already has a pending invitation to this forum');
      }

      await _invitationsCollection.add({
        'forumId': forumId,
        'forumTitle': forum.title,
        'invitedUserId': odGptUserId,
        'invitedUserName': userName,
        'invitedUserEmail': userEmail,
        'invitedById': invitedById,
        'invitedByName': invitedByName,
        'invitedAt': Timestamp.now(),
        'status': 'pending',
      });
      print('Invitation sent to $odGptUserId for forum $forumId');
    } catch (e) {
      print('Error inviting member: $e');
      rethrow;
    }
  }

  /// Legacy method - now creates invitation instead of direct add when invitedBy is provided
  Future<void> addMember({
    required String forumId,
    required String odGptUserId,
    required String userName,
    required String userEmail,
    String? invitedBy,
  }) async {
    // If no inviter, add directly (for public forum self-join)
    if (invitedBy == null || invitedBy.isEmpty) {
      await addMemberDirectly(
        forumId: forumId,
        odGptUserId: odGptUserId,
        userName: userName,
        userEmail: userEmail,
      );
    } else {
      // Create invitation instead of direct add
      // Get inviter name
      final inviterDoc = await _firestore.collection('users').doc(invitedBy).get();
      final inviterName = inviterDoc.exists
          ? (inviterDoc.data()?['name'] as String? ?? 'Unknown')
          : 'Unknown';

      await inviteMember(
        forumId: forumId,
        odGptUserId: odGptUserId,
        userName: userName,
        userEmail: userEmail,
        invitedById: invitedBy,
        invitedByName: inviterName,
      );
    }
  }

  /// Kick a member from forum
  Future<void> kickMember({
    required String forumId,
    required String odGptUserId,
    required String kickedById,
    required String kickedByName,
    required String kickedByEmail,
    required bool kickedByStaff,
    required String reason,
  }) async {
    try {
      final forum = await getForum(forumId);
      if (forum == null) {
        throw Exception('Forum not found');
      }

      final member = await getMember(forumId, odGptUserId);
      if (member == null) {
        throw Exception('Member not found');
      }

      // Creator cannot kick themselves
      if (member.isCreator) {
        throw Exception('Cannot kick the forum creator');
      }

      // Non-staff creator must provide reason
      if (!kickedByStaff && reason.isEmpty) {
        throw Exception('Reason is required when kicking a member');
      }

      final batch = _firestore.batch();

      // Mark member as inactive
      final memberSnapshot = await _membersCollection(forumId)
          .where('userId', isEqualTo: odGptUserId)
          .where('isActive', isEqualTo: true)
          .limit(1)
          .get();

      if (memberSnapshot.docs.isNotEmpty) {
        batch.update(memberSnapshot.docs.first.reference, {
          'isActive': false,
        });
      }

      // Update forum member count and memberIds
      batch.update(_forumsCollection.doc(forumId), {
        'memberCount': FieldValue.increment(-1),
        'memberIds': FieldValue.arrayRemove([odGptUserId]),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Add kick log
      final logRef = _kickLogsCollection.doc();
      batch.set(logRef, {
        'forumId': forumId,
        'forumTitle': forum.title,
        'kickedUserId': member.odGptUserId,
        'kickedUserName': member.userName,
        'kickedUserEmail': member.userEmail,
        'kickedById': kickedById,
        'kickedByName': kickedByName,
        'kickedByEmail': kickedByEmail,
        'kickedByStaff': kickedByStaff,
        'kickType': kickedByStaff ? 'kickedByStaff' : 'kickedByCreator',
        'reason': reason,
        'kickedAt': FieldValue.serverTimestamp(),
      });

      // Add system message
      final messageRef = _messagesCollection(forumId).doc();
      batch.set(messageRef, {
        'forumId': forumId,
        'senderId': 'system',
        'senderName': 'System',
        'senderEmail': '',
        'content': '${member.userName} was removed from the forum',
        'createdAt': FieldValue.serverTimestamp(),
        'type': 'system',
      });

      await batch.commit();
      print('Member $odGptUserId kicked from forum $forumId');
    } catch (e) {
      print('Error kicking member: $e');
      rethrow;
    }
  }

  /// Leave a forum (member leaves voluntarily)
  Future<void> leaveForum({
    required String forumId,
    required String odGptUserId,
    required String userName,
  }) async {
    try {
      final member = await getMember(forumId, odGptUserId);
      if (member == null) {
        throw Exception('You are not a member of this forum');
      }

      if (member.isCreator) {
        throw Exception('Creator cannot leave the forum. Transfer ownership or delete the forum.');
      }

      final batch = _firestore.batch();

      // Mark member as inactive
      final memberSnapshot = await _membersCollection(forumId)
          .where('userId', isEqualTo: odGptUserId)
          .where('isActive', isEqualTo: true)
          .limit(1)
          .get();

      if (memberSnapshot.docs.isNotEmpty) {
        batch.update(memberSnapshot.docs.first.reference, {
          'isActive': false,
        });
      }

      // Update forum
      batch.update(_forumsCollection.doc(forumId), {
        'memberCount': FieldValue.increment(-1),
        'memberIds': FieldValue.arrayRemove([odGptUserId]),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Add system message
      final messageRef = _messagesCollection(forumId).doc();
      batch.set(messageRef, {
        'forumId': forumId,
        'senderId': 'system',
        'senderName': 'System',
        'senderEmail': '',
        'content': '$userName left the forum',
        'createdAt': FieldValue.serverTimestamp(),
        'type': 'system',
      });

      await batch.commit();
      print('Member $odGptUserId left forum $forumId');
    } catch (e) {
      print('Error leaving forum: $e');
      rethrow;
    }
  }

  // ============ JOIN REQUESTS ============

  /// Stream of pending join requests for a forum
  Stream<List<ForumJoinRequest>> getJoinRequestsStream(String forumId) {
    // Query only by status to avoid composite index requirement on subcollection
    // Sort in memory instead
    return _joinRequestsCollection(forumId)
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((snapshot) {
      final requests = snapshot.docs.map((doc) {
        return ForumJoinRequest.fromJson(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
      // Sort by requestedAt in memory
      requests.sort((a, b) => a.requestedAt.compareTo(b.requestedAt));
      return requests;
    });
  }

  /// Request to join a private forum
  Future<void> requestJoin({
    required String forumId,
    required String odGptUserId,
    required String userName,
    required String userEmail,
  }) async {
    try {
      // Check if already a member
      if (await isMember(forumId, odGptUserId)) {
        throw Exception('You are already a member of this forum');
      }

      // Check for existing pending request (simplified - single field query)
      final allUserRequests = await _joinRequestsCollection(forumId)
          .where('userId', isEqualTo: odGptUserId)
          .get();

      // Filter pending requests in memory to avoid composite index
      final hasPendingRequest = allUserRequests.docs.any(
        (doc) => (doc.data() as Map<String, dynamic>)['status'] == 'pending'
      );

      if (hasPendingRequest) {
        throw Exception('You already have a pending request to join this forum');
      }

      await _joinRequestsCollection(forumId).add({
        'forumId': forumId,
        'userId': odGptUserId,
        'userName': userName,
        'userEmail': userEmail,
        'requestedAt': Timestamp.now(),
        'status': 'pending',
      });
      print('Join request submitted for forum $forumId by user $odGptUserId');
    } catch (e) {
      print('Error requesting to join: $e');
      rethrow;
    }
  }

  /// Approve a join request
  Future<void> approveJoinRequest({
    required String forumId,
    required String requestId,
    required String approvedById,
  }) async {
    try {
      final requestDoc = await _joinRequestsCollection(forumId).doc(requestId).get();
      if (!requestDoc.exists) {
        throw Exception('Join request not found');
      }

      final request = ForumJoinRequest.fromJson(
        requestDoc.data() as Map<String, dynamic>,
        requestDoc.id,
      );

      // Update request status
      await _joinRequestsCollection(forumId).doc(requestId).update({
        'status': 'approved',
        'processedBy': approvedById,
        'processedAt': FieldValue.serverTimestamp(),
      });

      // Add as member directly (not invitation since they requested to join)
      await addMemberDirectly(
        forumId: forumId,
        odGptUserId: request.odGptUserId,
        userName: request.userName,
        userEmail: request.userEmail,
        invitedBy: approvedById,
      );

      print('Join request $requestId approved');
    } catch (e) {
      print('Error approving join request: $e');
      rethrow;
    }
  }

  /// Reject a join request
  Future<void> rejectJoinRequest({
    required String forumId,
    required String requestId,
    required String rejectedById,
    String? reason,
  }) async {
    try {
      await _joinRequestsCollection(forumId).doc(requestId).update({
        'status': 'rejected',
        'processedBy': rejectedById,
        'processedAt': FieldValue.serverTimestamp(),
        'rejectionReason': reason,
      });
      print('Join request $requestId rejected');
    } catch (e) {
      print('Error rejecting join request: $e');
      rethrow;
    }
  }

  // ============ MESSAGES ============

  /// Stream of messages for a forum
  Stream<List<ForumMessage>> getMessagesStream(String forumId, {int limit = 100}) {
    return _messagesCollection(forumId)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return ForumMessage.fromJson(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
    });
  }

  /// Send a message in forum
  Future<void> sendMessage({
    required String forumId,
    required String senderId,
    required String senderName,
    required String senderEmail,
    required String content,
  }) async {
    try {
      final batch = _firestore.batch();

      // Add message
      final messageRef = _messagesCollection(forumId).doc();
      batch.set(messageRef, {
        'forumId': forumId,
        'senderId': senderId,
        'senderName': senderName,
        'senderEmail': senderEmail,
        'content': content,
        'createdAt': FieldValue.serverTimestamp(),
        'type': 'text',
      });

      // Update forum last message
      batch.update(_forumsCollection.doc(forumId), {
        'lastMessage': content,
        'lastMessageBy': senderName,
        'lastMessageAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      await batch.commit();
      print('Message sent in forum $forumId');
    } catch (e) {
      print('Error sending message: $e');
      rethrow;
    }
  }

  /// Delete a message (only by sender)
  Future<void> deleteMessage({
    required String forumId,
    required String messageId,
    required String currentUserId,
  }) async {
    try {
      final messageDoc = await _messagesCollection(forumId).doc(messageId).get();
      if (!messageDoc.exists) {
        throw Exception('Message not found');
      }

      final messageData = messageDoc.data() as Map<String, dynamic>;
      if (messageData['senderId'] != currentUserId) {
        throw Exception('You can only delete your own messages');
      }

      await _messagesCollection(forumId).doc(messageId).update({
        'deletedAt': FieldValue.serverTimestamp(),
        'deletedBy': currentUserId,
      });
      print('Message $messageId deleted');
    } catch (e) {
      print('Error deleting message: $e');
      rethrow;
    }
  }

  /// Staff delete any message
  Future<void> staffDeleteMessage({
    required String forumId,
    required String messageId,
    required String staffId,
    required bool isStaff,
  }) async {
    if (!isStaff) {
      throw Exception('Only staff can perform this action');
    }

    try {
      final messageDoc = await _messagesCollection(forumId).doc(messageId).get();
      if (!messageDoc.exists) {
        throw Exception('Message not found');
      }

      await _messagesCollection(forumId).doc(messageId).update({
        'deletedAt': FieldValue.serverTimestamp(),
        'deletedBy': staffId,
        'deletedByStaff': true,
      });
    } catch (e) {
      rethrow;
    }
  }

  // ============ INVITATIONS ============

  /// Stream of pending invitations for a user
  Stream<List<ForumInvitation>> getUserInvitationsStream(String userId) {
    // Single field query to avoid composite index requirement
    return _invitationsCollection
        .where('invitedUserId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      // Filter pending in memory and sort by invitedAt
      final invitations = snapshot.docs
          .map((doc) => ForumInvitation.fromJson(doc.data() as Map<String, dynamic>, doc.id))
          .where((inv) => inv.status == InvitationStatus.pending)
          .toList();
      // Sort by invitedAt descending
      invitations.sort((a, b) => b.invitedAt.compareTo(a.invitedAt));
      return invitations;
    });
  }

  /// Get count of pending invitations for a user
  Stream<int> getUserInvitationsCountStream(String userId) {
    // Single field query to avoid composite index requirement
    return _invitationsCollection
        .where('invitedUserId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      // Filter pending in memory
      return snapshot.docs.where((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return data['status'] == 'pending';
      }).length;
    });
  }

  /// Accept a forum invitation
  Future<void> acceptInvitation(String invitationId) async {
    try {
      final invitationDoc = await _invitationsCollection.doc(invitationId).get();
      if (!invitationDoc.exists) {
        throw Exception('Invitation not found');
      }

      final invitation = ForumInvitation.fromJson(
        invitationDoc.data() as Map<String, dynamic>,
        invitationDoc.id,
      );

      if (invitation.status != InvitationStatus.pending) {
        throw Exception('This invitation has already been responded to');
      }

      // Update invitation status
      await _invitationsCollection.doc(invitationId).update({
        'status': 'accepted',
        'respondedAt': FieldValue.serverTimestamp(),
      });

      // Add user as member
      await addMemberDirectly(
        forumId: invitation.forumId,
        odGptUserId: invitation.invitedUserId,
        userName: invitation.invitedUserName,
        userEmail: invitation.invitedUserEmail,
        invitedBy: invitation.invitedById,
      );

      print('Invitation $invitationId accepted');
    } catch (e) {
      print('Error accepting invitation: $e');
      rethrow;
    }
  }

  /// Decline a forum invitation
  Future<void> declineInvitation(String invitationId) async {
    try {
      final invitationDoc = await _invitationsCollection.doc(invitationId).get();
      if (!invitationDoc.exists) {
        throw Exception('Invitation not found');
      }

      final invitation = ForumInvitation.fromJson(
        invitationDoc.data() as Map<String, dynamic>,
        invitationDoc.id,
      );

      if (invitation.status != InvitationStatus.pending) {
        throw Exception('This invitation has already been responded to');
      }

      await _invitationsCollection.doc(invitationId).update({
        'status': 'declined',
        'respondedAt': FieldValue.serverTimestamp(),
      });

      print('Invitation $invitationId declined');
    } catch (e) {
      print('Error declining invitation: $e');
      rethrow;
    }
  }

  // ============ KICK LOGS ============

  /// Stream of kick logs for a forum
  Stream<List<ForumKickLog>> getKickLogsStream(String forumId) {
    return _kickLogsCollection
        .where('forumId', isEqualTo: forumId)
        .orderBy('kickedAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return ForumKickLog.fromJson(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
    });
  }

  /// Get kick logs for a user (to show why they were kicked)
  Future<List<ForumKickLog>> getUserKickLogs(String odGptUserId) async {
    try {
      final snapshot = await _kickLogsCollection
          .where('kickedUserId', isEqualTo: odGptUserId)
          .orderBy('kickedAt', descending: true)
          .get();
      return snapshot.docs.map((doc) {
        return ForumKickLog.fromJson(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
    } catch (e) {
      print('Error getting user kick logs: $e');
      return [];
    }
  }

  // ============ USER SEARCH ============

  /// Search users by email for inviting to forum
  Future<List<Map<String, String>>> searchUsersByEmail(String email) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .where('email', isGreaterThanOrEqualTo: email)
          .where('email', isLessThanOrEqualTo: '$email\uf8ff')
          .limit(10)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'userId': doc.id,
          'userName': data['name'] as String? ?? 'Unknown',
          'userEmail': data['email'] as String? ?? '',
        };
      }).toList();
    } catch (e) {
      print('Error searching users: $e');
      return [];
    }
  }
}
