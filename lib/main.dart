import 'dart:async';

import 'package:authentication_repository/authentication_repository.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:leaderboard_repository/leaderboard_repository.dart';
import 'package:pinball/app/app.dart';
import 'package:pinball/bootstrap.dart';
import 'package:pinball/firebase_options.dart';
import 'package:pinball_audio/pinball_audio.dart';
import 'package:platform_helper/platform_helper.dart';
import 'package:share_repository/share_repository.dart';

Future<App> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  final leaderboardRepository =
      LeaderboardRepository(FirebaseFirestore.instance);
  const shareRepository =
      ShareRepository(appUrl: ShareRepository.pinballGameUrl);
  final authenticationRepository =
      AuthenticationRepository(FirebaseAuth.instance);
  final pinballAudioPlayer = PinballAudioPlayer();
  final platformHelper = PlatformHelper();

  // Try to authenticate anonymously, but don't crash if it fails
  try {
    await authenticationRepository.authenticateAnonymously();
  } catch (e) {
    // ignore: avoid_print
    print('Anonymous authentication failed: $e');
    // App can still run without authentication for basic gameplay
  }

  return App(
    authenticationRepository: authenticationRepository,
    leaderboardRepository: leaderboardRepository,
    shareRepository: shareRepository,
    pinballAudioPlayer: pinballAudioPlayer,
    platformHelper: platformHelper,
  );
}

void main() async {
  Bloc.observer = AppBlocObserver();
  runApp(await bootstrap());
}
