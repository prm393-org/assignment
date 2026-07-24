import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chuoi_xanh_viet/app.dart';
import 'package:chuoi_xanh_viet/core/firebase/crashlytics_service.dart';
import 'package:chuoi_xanh_viet/core/firebase/messaging_service.dart';
import 'package:chuoi_xanh_viet/firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Must run before runApp so a push received while the app is terminated is
  // handled in the background isolate.
  MessagingService.registerBackgroundHandler();

  CrashlyticsService.bindFlutterFatals();
  await CrashlyticsService.bootstrap(
    appVersion: '1.0.0',
    buildNumber: '1',
  );

  runApp(const ProviderScope(child: ChuoiXanhVietApp()));
}
