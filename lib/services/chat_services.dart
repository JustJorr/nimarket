import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // 1. Get or Create Chat (Updated to initialize unreadCounts)
  Future<String> getOrCreateChatRoom(String otherUserId, String otherUserName) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) throw Exception("User not logged in");

    final userDoc = await _firestore.collection('users').doc(currentUser.uid).get();
    final currentUserName = userDoc.data()?['username'] ?? 'User';

    final querySnapshot = await _firestore.collection('chats')
        .where('participants', arrayContains: currentUser.uid)
        .get();

    for (var doc in querySnapshot.docs) {
      final participants = List<String>.from(doc['participants']);
      if (participants.contains(otherUserId)) {
        return doc.id;
      }
    }

    // Create new chat with unreadCounts initialized to 0
    final newChatDoc = await _firestore.collection('chats').add({
      'participants': [currentUser.uid, otherUserId],
      'participantNames': {
        currentUser.uid: currentUserName,
        otherUserId: otherUserName,
      },
      'unreadCounts': {
        currentUser.uid: 0,
        otherUserId: 0,
      },
      'lastMessage': '',
      'lastMessageTime': FieldValue.serverTimestamp(),
    });

    return newChatDoc.id;
  }

  // 2. Send Message (Increments the OTHER user's unread count)
  Future<void> sendMessage(String chatId, String message, String otherUserId) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    final timestamp = FieldValue.serverTimestamp();

    await _firestore.collection('chats').doc(chatId).collection('messages').add({
      'senderId': currentUser.uid,
      'text': message,
      'timestamp': timestamp,
    });

    // Update main doc: Update last message AND increment other user's unread count
    await _firestore.collection('chats').doc(chatId).update({
      'lastMessage': message,
      'lastMessageTime': timestamp,
      'unreadCounts.$otherUserId': FieldValue.increment(1), 
    });
  }

  // 3. Mark Chat as Read (Resets YOUR unread count)
  Future<void> markChatAsRead(String chatId) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    await _firestore.collection('chats').doc(chatId).update({
      'unreadCounts.${currentUser.uid}': 0,
    });
  }

  // 4. Stream Messages
  Stream<QuerySnapshot> getMessages(String chatId) {
    return _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  // 5. Stream User's Chat List
  Stream<QuerySnapshot> getUserChats() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return const Stream.empty();

    return _firestore
        .collection('chats')
        .where('participants', arrayContains: uid)
        .orderBy('lastMessageTime', descending: true)
        .snapshots();
  }

  // 6. Get Total Unread Count for Home Screen Badge
  Stream<int> getTotalUnreadCount() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return Stream.value(0);

    return _firestore
        .collection('chats')
        .where('participants', arrayContains: uid)
        .snapshots()
        .map((snapshot) {
          int total = 0;
          for (var doc in snapshot.docs) {
            final data = doc.data();
            final counts = data['unreadCounts'] as Map<String, dynamic>?;
            if (counts != null) {
              total += (counts[uid] as num? ?? 0).toInt();
            }
          }
          return total;
        });
  }
}