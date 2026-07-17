import 'package:cloud_firestore/cloud_firestore.dart';

class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.senderUid,
    required this.senderName,
    required this.text,
    required this.sentAt,
  });

  final String id;
  final String senderUid;
  final String senderName;
  final String text;

  /// Null only briefly while the serverTimestamp is being written.
  final DateTime? sentAt;

  Map<String, dynamic> toMap() => {
        'senderUid': senderUid,
        'senderName': senderName,
        'text': text,
        'sentAt': FieldValue.serverTimestamp(),
      };

  factory ChatMessage.fromMap(String id, Map<String, dynamic> m) => ChatMessage(
        id: id,
        senderUid: (m['senderUid'] ?? '') as String,
        senderName: (m['senderName'] ?? '') as String,
        text: (m['text'] ?? '') as String,
        sentAt: (m['sentAt'] as Timestamp?)?.toDate(),
      );
}
