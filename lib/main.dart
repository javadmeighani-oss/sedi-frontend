import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'app.dart';
import 'core/locale/sedi_locale_controller.dart';
import 'core/notifications/notification_bootstrap.dart';
import 'core/profile/profile_snapshot_cache.dart';

/// App entry — shared bootstrap only.
/// A1 session/visual logic lives under intro + SessionGateResolver.
/// A4 notification/FCM bootstrap is isolated in [NotificationBootstrap].
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Resolve cached locale before the first frame so A1 does not flash EN→FA/AR.
  // Do not wait for Firebase / NotificationBootstrap here.
  await SediLocaleController.instance.bootstrapFromCache();

  // The profile page opens filled even on the first open after a restart (device copy; no waiting for it here).
  unawaited(ProfileSnapshotCache.restore());

  runApp(const SediApp());

  unawaited(_bootstrapFirebaseAfterUi());
}

Future<void> _bootstrapFirebaseAfterUi() async {
  try {
    await Firebase.initializeApp();
    debugPrint('[FCM] Firebase initialized ok');
    await NotificationBootstrap.setup();
  } catch (e) {
    // Graceful if google-services.json missing / Firebase unavailable.
    debugPrint('[main] Firebase/FCM setup skipped: $e');
  }
}
