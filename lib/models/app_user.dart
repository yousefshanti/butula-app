import 'package:cloud_firestore/cloud_firestore.dart';

class AppUser {
  const AppUser({
    required this.uid,
    required this.name,
    required this.email,
    required this.timezone,
    this.createdAt,
    this.chatLastReadAt,
  });

  final String uid;
  final String name;
  final String email;
  final String timezone; // IANA name, e.g. "Asia/Gaza"
  final DateTime? createdAt;

  /// Last time this user opened the group chat (for the unread badge).
  final DateTime? chatLastReadAt;

  bool get hasTimezone => timezone.isNotEmpty;

  Map<String, dynamic> toMap() => {
        'name': name,
        'email': email,
        'timezone': timezone,
        'createdAt': createdAt == null
            ? FieldValue.serverTimestamp()
            : Timestamp.fromDate(createdAt!),
      };

  factory AppUser.fromMap(String uid, Map<String, dynamic> m) => AppUser(
        uid: uid,
        name: (m['name'] ?? '') as String,
        email: (m['email'] ?? '') as String,
        timezone: (m['timezone'] ?? '') as String,
        createdAt: (m['createdAt'] as Timestamp?)?.toDate(),
        chatLastReadAt: (m['chatLastReadAt'] as Timestamp?)?.toDate(),
      );

  AppUser copyWith({String? name, String? timezone}) => AppUser(
        uid: uid,
        name: name ?? this.name,
        email: email,
        timezone: timezone ?? this.timezone,
        createdAt: createdAt,
      );
}
