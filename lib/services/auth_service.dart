import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../models/app_user.dart';

class AuthException implements Exception {
  AuthException(this.message);
  final String message;
  @override
  String toString() => message;
}

class AuthService {
  AuthService(this._auth, this._db);
  final FirebaseAuth _auth;
  final FirebaseFirestore _db;

  Stream<User?> authState() => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  Future<void> signIn(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw AuthException(_mapError(e));
    }
  }

  Future<void> signUp({
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final uid = cred.user!.uid;
      await cred.user!.updateDisplayName(displayName.trim());
      // Timezone is chosen on first login (empty until then).
      final user = AppUser(
        uid: uid,
        name: displayName.trim(),
        email: email.trim(),
        timezone: '',
      );
      // The Auth account already exists at this point. If the Firestore write
      // is rejected (e.g. security rules not deployed yet) don't fail signup —
      // ensureUserDoc() will retry on next login once rules allow it.
      try {
        await _db.collection('users').doc(uid).set(user.toMap());
      } on FirebaseException catch (e) {
        debugPrint('signUp: user doc write failed (${e.code}): ${e.message}');
      }
    } on FirebaseAuthException catch (e) {
      throw AuthException(_mapError(e));
    }
  }

  /// Creates the users/{uid} document if it is missing (self-heals accounts
  /// whose doc was never written, e.g. when signup ran before rules existed).
  /// Rethrows FirebaseException so the caller can surface permission errors.
  Future<void> ensureUserDoc() async {
    final u = _auth.currentUser;
    if (u == null) return;
    final ref = _db.collection('users').doc(u.uid);
    final snap = await ref.get();
    if (snap.exists) return;
    final user = AppUser(
      uid: u.uid,
      name: u.displayName ?? '',
      email: u.email ?? '',
      timezone: '',
    );
    await ref.set(user.toMap());
  }

  Future<void> signOut() => _auth.signOut();

  String _mapError(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':
        return 'البريد الإلكتروني غير صالح';
      case 'user-disabled':
        return 'هذا الحساب معطّل';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'البريد الإلكتروني أو كلمة المرور غير صحيحة';
      case 'email-already-in-use':
        return 'هذا البريد مستخدم بالفعل';
      case 'weak-password':
        return 'كلمة المرور ضعيفة (٦ أحرف على الأقل)';
      case 'network-request-failed':
        return 'تحقق من اتصالك بالإنترنت';
      default:
        return e.message ?? 'تعذّر إتمام العملية';
    }
  }
}
