import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:chuoi_xanh_viet/core/config/firebase_config.dart';
import 'package:chuoi_xanh_viet/core/network/dio_client.dart';
import 'package:chuoi_xanh_viet/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:chuoi_xanh_viet/features/auth/domain/repositories/auth_repository.dart';

final secureStorageProvider = Provider<FlutterSecureStorage>(
  (_) => const FlutterSecureStorage(),
);

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return AuthRepositoryImpl(
    remote: AuthRemoteDataSource(dio),
    local: AuthLocalDataSource(ref.watch(secureStorageProvider)),
    firebaseAuth: Firebase.apps.isEmpty ? null : FirebaseAuth.instance,
    googleSignIn: GoogleSignIn(
      serverClientId: FirebaseConfig.googleWebClientId,
    ),
  );
});
