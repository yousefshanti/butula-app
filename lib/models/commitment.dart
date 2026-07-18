import 'package:cloud_firestore/cloud_firestore.dart';

/// A private personal commitment document (users/{uid}/commitment/main).
class Commitment {
  const Commitment({
    required this.text,
    this.createdAt,
    this.updatedAt,
  });

  final String text;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  bool get isEdited =>
      createdAt != null &&
      updatedAt != null &&
      updatedAt!.difference(createdAt!).inMinutes > 1;

  factory Commitment.fromMap(Map<String, dynamic> m) => Commitment(
        text: (m['text'] ?? '') as String,
        createdAt: (m['createdAt'] as Timestamp?)?.toDate(),
        updatedAt: (m['updatedAt'] as Timestamp?)?.toDate(),
      );
}
