import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/chat_services.dart'; // Check if your file is named chat_service.dart or chat_services.dart
import 'chat_screen.dart';

class ChatListScreen extends StatelessWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ChatService chatService = ChatService();
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text("My Messages", style: TextStyle(color: Colors.white)),
        backgroundColor: const Color.fromARGB(255, 7, 12, 156),
        iconTheme: const IconThemeData(color: Colors.amber),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color.fromARGB(255, 7, 12, 156), Color.fromARGB(255, 4, 3, 49)],
          ),
        ),
        child: StreamBuilder<QuerySnapshot>(
          stream: chatService.getUserChats(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              debugPrint("Firestore Error: ${snapshot.error}");
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    "Error: ${snapshot.error}", 
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Center(child: Text("No messages yet", style: TextStyle(color: Colors.white)));
            }

            return ListView.builder(
              itemCount: snapshot.data!.docs.length,
              itemBuilder: (context, index) {
                final doc = snapshot.data!.docs[index];
                final data = doc.data() as Map<String, dynamic>;
                
                // --- 1. Identify Participants ---
                final participants = List<String>.from(data['participants']);
                final otherUserId = participants.firstWhere((id) => id != currentUserId, orElse: () => 'Unknown');
                final names = Map<String, dynamic>.from(data['participantNames'] ?? {});
                final otherUserName = names[otherUserId] ?? 'User';

                // --- 2. Check Unread Status ---
                final unreadCounts = data['unreadCounts'] as Map<String, dynamic>?;
                // Get the count specifically for ME
                final myUnreadCount = (unreadCounts?[currentUserId] as num? ?? 0).toInt();
                final isUnread = myUnreadCount > 0;

                return Card(
                  // Highlight card slightly if unread
                  color: isUnread ? Colors.amber.withOpacity(0.1) : Colors.white.withOpacity(0.05),
                  margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  child: ListTile(
                    leading: Stack(
                      children: [
                        const CircleAvatar(
                          backgroundColor: Colors.amber,
                          child: Icon(Icons.person, color: Colors.black),
                        ),
                        // Red Dot on Avatar if unread
                        if (isUnread)
                          Positioned(
                            right: 0,
                            top: 0,
                            child: Container(
                              width: 12,
                              height: 12,
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                      ],
                    ),
                    title: Text(
                      otherUserName, 
                      style: TextStyle(
                        color: Colors.amber, 
                        // Bold if unread
                        fontWeight: isUnread ? FontWeight.bold : FontWeight.normal
                      )
                    ),
                    subtitle: Text(
                      data['lastMessage'] ?? '', 
                      maxLines: 1, 
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        // Bright white if unread, dimmed if read
                        color: isUnread ? Colors.white : Colors.white70, 
                        fontWeight: isUnread ? FontWeight.bold : FontWeight.normal
                      )
                    ),
                    // Trailing Counter Badge
                    trailing: isUnread 
                      ? CircleAvatar(
                          radius: 12,
                          backgroundColor: Colors.red,
                          child: Text(
                            "$myUnreadCount", 
                            style: const TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.bold)
                          ),
                        )
                      : null,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ChatScreen(
                            chatId: doc.id,
                            otherUserName: otherUserName,
                            otherUserId: otherUserId,
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}