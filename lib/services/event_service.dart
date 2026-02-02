import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/event.dart';
import '../models/event_voucher.dart';
import '../models/event_message.dart';
import '../models/event_ban.dart';
import '../models/claimed_voucher.dart';

class EventService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collection references
  CollectionReference get _eventsRef => _firestore.collection('events');
  CollectionReference get _eventVouchersRef => _firestore.collection('event_vouchers');
  CollectionReference get _eventBansRef => _firestore.collection('event_bans');
  CollectionReference get _claimedVouchersRef => _firestore.collection('user_vouchers');
  CollectionReference get _globalChatRef => _firestore.collection('global_chat');

  // ============ EVENT MANAGEMENT (Staff Only) ============

  /// Create a new event (staff only)
  Future<String> createEvent({
    required String title,
    required String description,
    required DateTime startTime,
    required DateTime endTime,
    required String createdBy,
    required String createdByName,
  }) async {
    final event = Event(
      id: '',
      title: title,
      description: description,
      startTime: startTime,
      endTime: endTime,
      createdAt: DateTime.now(),
      createdBy: createdBy,
      createdByName: createdByName,
      isSharedToGlobalChat: false,
    );

    final docRef = await _eventsRef.add(event.toFirestore());
    return docRef.id;
  }

  /// Get stream of active events (for floating widget)
  Stream<List<Event>> getActiveEventsStream() {
    final now = DateTime.now();
    return _eventsRef
        .where('endTime', isGreaterThan: Timestamp.fromDate(now))
        .orderBy('endTime')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => Event.fromFirestore(doc))
          .where((e) => e.isActive || e.isPending)
          .toList();
    });
  }

  /// Get stream of all events (admin view)
  Stream<List<Event>> getAllEventsStream() {
    return _eventsRef
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Event.fromFirestore(doc)).toList();
    });
  }

  /// Get a single event by ID
  Future<Event?> getEvent(String eventId) async {
    final doc = await _eventsRef.doc(eventId).get();
    if (!doc.exists) return null;
    return Event.fromFirestore(doc);
  }

  /// Get a single event stream by ID
  Stream<Event?> getEventStream(String eventId) {
    return _eventsRef.doc(eventId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return Event.fromFirestore(doc);
    });
  }

  /// Delete an event (staff only)
  Future<void> deleteEvent(String eventId) async {
    // Delete all messages in the event
    final messagesSnapshot = await _eventsRef.doc(eventId).collection('messages').get();
    for (final doc in messagesSnapshot.docs) {
      await doc.reference.delete();
    }

    // Delete all vouchers for this event
    final vouchersSnapshot = await _eventVouchersRef.where('eventId', isEqualTo: eventId).get();
    for (final doc in vouchersSnapshot.docs) {
      await doc.reference.delete();
    }

    // Delete all bans for this event
    final bansSnapshot = await _eventBansRef.where('eventId', isEqualTo: eventId).get();
    for (final doc in bansSnapshot.docs) {
      await doc.reference.delete();
    }

    // Delete the event
    await _eventsRef.doc(eventId).delete();
  }

  // ============ VOUCHER MANAGEMENT (Staff Only) ============

  /// Create a voucher for an event (staff only)
  Future<String> createEventVoucher({
    required String eventId,
    required String code,
    required String description,
    required DiscountType discountType,
    required double discountValue,
    int? maxClaims,
    DateTime? expiresAt,
    required String createdBy,
    required String createdByName,
  }) async {
    final voucher = EventVoucher(
      id: '',
      eventId: eventId,
      code: code.toUpperCase(),
      description: description,
      discountType: discountType,
      discountValue: discountValue,
      maxClaims: maxClaims,
      currentClaims: 0,
      createdAt: DateTime.now(),
      createdBy: createdBy,
      createdByName: createdByName,
      isActive: true,
      expiresAt: expiresAt,
    );

    final docRef = await _eventVouchersRef.add(voucher.toFirestore());
    return docRef.id;
  }

  /// Get all vouchers for an event
  Stream<List<EventVoucher>> getEventVouchersStream(String eventId) {
    return _eventVouchersRef
        .where('eventId', isEqualTo: eventId)
        .snapshots()
        .map((snapshot) {
      final vouchers = snapshot.docs.map((doc) => EventVoucher.fromFirestore(doc)).toList();
      // Sort on client side to avoid needing composite index
      vouchers.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return vouchers;
    });
  }

  /// Get a single voucher by ID
  Future<EventVoucher?> getEventVoucher(String voucherId) async {
    final doc = await _eventVouchersRef.doc(voucherId).get();
    if (!doc.exists) return null;
    return EventVoucher.fromFirestore(doc);
  }

  /// Toggle voucher active status (staff only)
  Future<void> toggleVoucherActive(String voucherId, bool isActive) async {
    await _eventVouchersRef.doc(voucherId).update({'isActive': isActive});
  }

  /// Delete a voucher (staff only)
  Future<void> deleteVoucher(String voucherId) async {
    await _eventVouchersRef.doc(voucherId).delete();
  }

  // ============ CHAT ============

  /// Get messages stream for an event
  Stream<List<EventMessage>> getMessagesStream(String eventId) {
    return _eventsRef
        .doc(eventId)
        .collection('messages')
        .orderBy('createdAt', descending: true)
        .limit(100)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => EventMessage.fromJson(doc.data(), doc.id))
          .where((m) => !m.isDeleted)
          .toList();
    });
  }

  /// Send a message in event chat
  Future<void> sendMessage({
    required String eventId,
    required String senderId,
    required String senderName,
    required String senderEmail,
    required String content,
    EventMessageType type = EventMessageType.text,
  }) async {
    // Check if user is banned from this event
    final banStatus = await getUserBanStatus(eventId, senderId);
    if (banStatus != null && banStatus.isActive) {
      if (banStatus.banType == EventBanType.kicked) {
        throw Exception('You have been kicked from this event');
      } else {
        throw Exception('You are on cooldown. Please wait ${banStatus.remainingTimeFormatted}');
      }
    }

    final message = EventMessage(
      id: '',
      eventId: eventId,
      senderId: senderId,
      senderName: senderName,
      senderEmail: senderEmail,
      content: content,
      createdAt: DateTime.now(),
      type: type,
    );

    await _eventsRef
        .doc(eventId)
        .collection('messages')
        .add(message.toJson());
  }

  /// Delete own message
  Future<void> deleteMessage({
    required String eventId,
    required String messageId,
    required String currentUserId,
  }) async {
    final messageDoc = await _eventsRef
        .doc(eventId)
        .collection('messages')
        .doc(messageId)
        .get();

    if (!messageDoc.exists) {
      throw Exception('Message not found');
    }

    final message = EventMessage.fromJson(messageDoc.data()!, messageId);
    if (message.senderId != currentUserId) {
      throw Exception('You can only delete your own messages');
    }

    await _eventsRef
        .doc(eventId)
        .collection('messages')
        .doc(messageId)
        .update({
      'deletedAt': Timestamp.fromDate(DateTime.now()),
      'deletedBy': currentUserId,
    });
  }

  /// Staff delete message (moderation)
  Future<void> staffDeleteMessage({
    required String eventId,
    required String messageId,
    required String staffId,
    required bool isStaff,
  }) async {
    if (!isStaff) {
      throw Exception('Only staff can moderate messages');
    }

    // Hard delete the message (no trace)
    await _eventsRef
        .doc(eventId)
        .collection('messages')
        .doc(messageId)
        .delete();
  }

  // ============ MODERATION (Staff Only) ============

  /// Give a user a cooldown in event chat
  Future<void> giveCooldown({
    required String eventId,
    required String userId,
    required String userName,
    required String userEmail,
    required String staffId,
    required String staffName,
    required Duration duration,
    String? reason,
  }) async {
    final ban = EventBan(
      id: '',
      eventId: eventId,
      userId: userId,
      userName: userName,
      userEmail: userEmail,
      banType: EventBanType.cooldown,
      bannedById: staffId,
      bannedByName: staffName,
      bannedAt: DateTime.now(),
      expiresAt: DateTime.now().add(duration),
      reason: reason,
    );

    await _eventBansRef.add(ban.toJson());
  }

  /// Kick a user from event chat (permanent ban for this event)
  Future<void> kickUser({
    required String eventId,
    required String userId,
    required String userName,
    required String userEmail,
    required String staffId,
    required String staffName,
    String? reason,
  }) async {
    final ban = EventBan(
      id: '',
      eventId: eventId,
      userId: userId,
      userName: userName,
      userEmail: userEmail,
      banType: EventBanType.kicked,
      bannedById: staffId,
      bannedByName: staffName,
      bannedAt: DateTime.now(),
      expiresAt: null, // Permanent
      reason: reason,
    );

    await _eventBansRef.add(ban.toJson());
  }

  /// Get user's ban status for an event
  Future<EventBan?> getUserBanStatus(String eventId, String userId) async {
    final snapshot = await _eventBansRef
        .where('eventId', isEqualTo: eventId)
        .where('userId', isEqualTo: userId)
        .orderBy('bannedAt', descending: true)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) return null;

    final ban = EventBan.fromJson(
      snapshot.docs.first.data() as Map<String, dynamic>,
      snapshot.docs.first.id,
    );

    // Return ban only if still active
    return ban.isActive ? ban : null;
  }

  /// Get user's ban status stream for an event
  Stream<EventBan?> getUserBanStatusStream(String eventId, String userId) {
    return _eventBansRef
        .where('eventId', isEqualTo: eventId)
        .where('userId', isEqualTo: userId)
        .orderBy('bannedAt', descending: true)
        .limit(1)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isEmpty) return null;

      final ban = EventBan.fromJson(
        snapshot.docs.first.data() as Map<String, dynamic>,
        snapshot.docs.first.id,
      );

      return ban.isActive ? ban : null;
    });
  }

  // ============ VOUCHER CLAIMING ============

  /// Claim a specific event voucher
  Future<ClaimedVoucher> claimEventVoucher({
    required String eventId,
    required String voucherId,
    required String userId,
    required String userEmail,
    required String userName,
  }) async {
    // Use transaction to ensure atomic operation
    return await _firestore.runTransaction<ClaimedVoucher>((transaction) async {
      // Get the event
      final eventDoc = await transaction.get(_eventsRef.doc(eventId));
      if (!eventDoc.exists) {
        throw Exception('Event not found');
      }

      final event = Event.fromFirestore(eventDoc);

      // Validate event is active
      if (!event.isActive) {
        if (event.isPending) {
          throw Exception('This event has not started yet');
        } else {
          throw Exception('This event has ended');
        }
      }

      // Get the voucher
      final voucherDoc = await transaction.get(_eventVouchersRef.doc(voucherId));
      if (!voucherDoc.exists) {
        throw Exception('e-Voucher not found');
      }

      final voucher = EventVoucher.fromFirestore(voucherDoc);

      // Validate voucher
      if (!voucher.isActive) {
        throw Exception('This e-Voucher is no longer active');
      }

      if (voucher.isExpired) {
        throw Exception('This e-Voucher has expired');
      }

      if (voucher.isFullyClaimed) {
        throw Exception('All e-Vouchers have been claimed');
      }

      // Check if user already claimed this specific voucher
      final existingClaim = await _claimedVouchersRef
          .where('odGptUserId', isEqualTo: userId)
          .where('eventVoucherId', isEqualTo: voucherId)
          .limit(1)
          .get();

      if (existingClaim.docs.isNotEmpty) {
        throw Exception('You have already claimed this e-Voucher');
      }

      // Calculate claim delay in seconds
      final now = DateTime.now();
      final claimDelaySeconds = now.difference(event.startTime).inSeconds;

      // Generate unique code: base code + claim number (1-indexed)
      final claimNumber = voucher.currentClaims + 1;
      final uniqueCode = '${voucher.code}$claimNumber';

      // Create claimed voucher record
      final claimedVoucher = ClaimedVoucher(
        id: '',
        odGptUserId: userId,
        odGptUserEmail: userEmail,
        odGptUserName: userName,
        voucherId: voucherId,
        voucherCode: uniqueCode,
        voucherDescription: voucher.description,
        discountText: voucher.discountText,
        claimedAt: now,
        claimDelaySeconds: claimDelaySeconds,
        voucherStartTime: event.startTime,
        isUsed: false,
      );

      // Increment voucher claim count
      transaction.update(_eventVouchersRef.doc(voucherId), {
        'currentClaims': FieldValue.increment(1),
      });

      return claimedVoucher;
    }).then((claimedVoucher) async {
      // Add the claimed voucher document with eventId and eventVoucherId fields
      final claimData = claimedVoucher.toFirestore();
      claimData['eventId'] = eventId;
      claimData['eventVoucherId'] = voucherId;
      final docRef = await _claimedVouchersRef.add(claimData);
      return claimedVoucher.copyWith(id: docRef.id);
    });
  }

  /// Check if user has already claimed a specific event voucher
  Future<bool> hasUserClaimedEventVoucher({
    required String userId,
    required String voucherId,
  }) async {
    final snapshot = await _claimedVouchersRef
        .where('odGptUserId', isEqualTo: userId)
        .where('eventVoucherId', isEqualTo: voucherId)
        .limit(1)
        .get();

    return snapshot.docs.isNotEmpty;
  }

  /// Get all vouchers claimed by user for an event
  Future<List<String>> getUserClaimedVoucherIds({
    required String userId,
    required String eventId,
  }) async {
    final snapshot = await _claimedVouchersRef
        .where('odGptUserId', isEqualTo: userId)
        .where('eventId', isEqualTo: eventId)
        .get();

    return snapshot.docs
        .map((doc) => (doc.data() as Map<String, dynamic>)['eventVoucherId'] as String?)
        .where((id) => id != null)
        .cast<String>()
        .toList();
  }

  /// Get full claimed voucher data for user
  Future<List<ClaimedVoucher>> getUserClaimedVouchers({
    required String userId,
    required String eventId,
  }) async {
    final snapshot = await _claimedVouchersRef
        .where('odGptUserId', isEqualTo: userId)
        .where('eventId', isEqualTo: eventId)
        .get();

    return snapshot.docs
        .map((doc) => ClaimedVoucher.fromFirestore(doc))
        .toList();
  }

  // ============ SHARE ============

  /// Share event to global chat
  Future<void> shareToGlobalChat({
    required String eventId,
    required String staffId,
    required String staffName,
  }) async {
    // Get the event
    final event = await getEvent(eventId);
    if (event == null) {
      throw Exception('Event not found');
    }

    // Get voucher count for the event
    final vouchersSnapshot = await _eventVouchersRef
        .where('eventId', isEqualTo: eventId)
        .where('isActive', isEqualTo: true)
        .get();
    final voucherCount = vouchersSnapshot.docs.length;

    // Create system message in global chat
    await _globalChatRef.add({
      'authorId': 'system',
      'authorName': 'ITEL Events',
      'authorEmail': '',
      'content': '${event.title}\n\n${event.description}\n\n${voucherCount > 0 ? '$voucherCount e-Voucher${voucherCount > 1 ? 's' : ''} available!' : 'Join the event!'}',
      'createdAt': Timestamp.fromDate(DateTime.now()),
      'type': 'event_share',
      'eventId': eventId,
    });

    // Update event as shared
    await _eventsRef.doc(eventId).update({
      'isSharedToGlobalChat': true,
      'sharedAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  // ============ ANALYTICS ============

  /// Get claim statistics for a voucher
  Future<Map<String, dynamic>> getVoucherClaimStats(String voucherId) async {
    final claimsSnapshot = await _claimedVouchersRef
        .where('eventVoucherId', isEqualTo: voucherId)
        .orderBy('claimDelaySeconds')
        .get();

    final claims = claimsSnapshot.docs
        .map((doc) => ClaimedVoucher.fromFirestore(doc))
        .toList();

    if (claims.isEmpty) {
      return {
        'totalClaims': 0,
        'fastestClaimSeconds': null,
        'averageClaimSeconds': null,
        'claimsWithin5Seconds': 0,
        'claimsWithin30Seconds': 0,
        'claimsWithin1Minute': 0,
        'claimsWithin5Minutes': 0,
      };
    }

    final delays = claims.map((c) => c.claimDelaySeconds).toList();
    final totalClaims = claims.length;
    final fastestClaim = delays.reduce((a, b) => a < b ? a : b);
    final averageClaim = delays.reduce((a, b) => a + b) / totalClaims;

    return {
      'totalClaims': totalClaims,
      'fastestClaimSeconds': fastestClaim,
      'averageClaimSeconds': averageClaim.round(),
      'claimsWithin5Seconds': delays.where((d) => d <= 5).length,
      'claimsWithin30Seconds': delays.where((d) => d <= 30).length,
      'claimsWithin1Minute': delays.where((d) => d <= 60).length,
      'claimsWithin5Minutes': delays.where((d) => d <= 300).length,
    };
  }
}
