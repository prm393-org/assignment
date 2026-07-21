import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Streams Firebase Auth's own sign-in state. Cart/forum/notification
/// providers watch this (not `authNotifierProvider`) because the backend
/// session and the Firebase shadow sign-in it triggers (see
/// `AuthRepositoryImpl._ensureFirebaseShadowAccount`) complete at slightly
/// different times.
final firebaseAuthStateProvider = StreamProvider<User?>((ref) {
  return FirebaseAuth.instance.authStateChanges();
});

/// The uid Firestore security rules key on, or `null` for a guest/unsynced
/// session. Never compare this against the backend's `AuthUser.id` — for
/// email/password users the two are different id spaces.
final currentFirebaseUidProvider = Provider<String?>((ref) {
  return ref.watch(firebaseAuthStateProvider).valueOrNull?.uid;
});
