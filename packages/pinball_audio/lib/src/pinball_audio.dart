import 'dart:js_interop';
import 'dart:math';

import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:pinball_audio/gen/assets.gen.dart';

// ---------------------------------------------------------------------------
// Minimal JS interop for HTML Audio – bypasses audioplayers entirely.
// ---------------------------------------------------------------------------

@JS('Audio')
extension type _JSAudio._(JSObject _) implements JSObject {
  external factory _JSAudio([String src]);
  external JSPromise<JSAny?> play();
  external set volume(double v);
  external double get volume;
  external set loop(bool v);
  external set currentTime(double v);
  external void load();
  external void pause();
}

/// Build the web URL for an asset inside this package.
///
/// Flutter web serves package assets at:
///   `assets/packages/<pkg>/assets/<subpath>`
///
/// [Assets.sfx.launcher] returns `'assets/sfx/launcher.mp3'` so we just
/// prepend `'assets/packages/pinball_audio/'`.
String _webUrl(String assetGenPath) =>
    'assets/packages/pinball_audio/$assetGenPath';

// ---------------------------------------------------------------------------
// Sound identifiers
// ---------------------------------------------------------------------------

/// Sounds available to play.
enum PinballAudio {
  google,
  bumper,
  cowMoo,
  backgroundMusic,
  ioPinballVoiceOver,
  gameOverVoiceOver,
  launcher,
  kicker,
  rollover,
  sparky,
  android,
  dino,
  dash,
  flipper,
}

// ---------------------------------------------------------------------------
// Internal audio wrappers (all use raw JS Audio)
// ---------------------------------------------------------------------------

abstract class _Audio {
  void play();
  Future<void> load();
}

/// A simple one-shot sound.
class _SimpleAudio extends _Audio {
  _SimpleAudio({required this.path, this.volume = 1.0});

  final String path;
  final double volume;
  late final String _url = _webUrl(path);

  @override
  Future<void> load() async {
    // Pre-fetch so the browser caches the file.
    final a = _JSAudio(_url);
    a.volume = 0;
    a.load();
  }

  @override
  void play() {
    final a = _JSAudio(_url);
    a.volume = volume;
    a.play().toDart.catchError((_) => null);
  }
}

/// A looping sound (background music). Only plays once even if play() is
/// called multiple times.
class _LoopAudio extends _Audio {
  _LoopAudio({required this.path, this.volume = 1.0});

  final String path;
  final double volume;
  late final String _url = _webUrl(path);

  _JSAudio? _player;
  bool _playing = false;

  @override
  Future<void> load() async {
    final a = _JSAudio(_url);
    a.volume = 0;
    a.load();
  }

  @override
  void play() {
    if (_playing) return;
    _playing = true;
    final a = _JSAudio(_url);
    a.volume = volume;
    a.loop = true;
    _player = a;
    a.play().toDart.catchError((_) {
      // Browser blocked autoplay – retry on next user gesture.
      _playing = false;
      return null;
    });
  }

  void stop() {
    _player?.pause();
    _playing = false;
  }
}

/// Randomly picks between two sounds.
class _RandomABAudio extends _Audio {
  _RandomABAudio({
    required this.pathA,
    required this.pathB,
    required this.seed,
    this.volume = 1.0,
  });

  final String pathA;
  final String pathB;
  final Random seed;
  final double volume;
  late final String _urlA = _webUrl(pathA);
  late final String _urlB = _webUrl(pathB);

  @override
  Future<void> load() async {
    _JSAudio(_urlA).load();
    _JSAudio(_urlB).load();
  }

  @override
  void play() {
    final url = seed.nextBool() ? _urlA : _urlB;
    final a = _JSAudio(url);
    a.volume = volume;
    a.play().toDart.catchError((_) => null);
  }
}

/// A throttled sound that won't replay within [duration].
class _ThrottledAudio extends _Audio {
  _ThrottledAudio({
    required this.path,
    required this.duration,
    this.volume = 1.0,
  });

  final String path;
  final Duration duration;
  final double volume;
  late final String _url = _webUrl(path);
  DateTime? _lastPlayed;

  @override
  Future<void> load() async {
    _JSAudio(_url).load();
  }

  @override
  void play() {
    final now = clock.now();
    if (_lastPlayed == null || now.difference(_lastPlayed!) > duration) {
      _lastPlayed = now;
      final a = _JSAudio(_url);
      a.volume = volume;
      a.play().toDart.catchError((_) => null);
    }
  }
}

// ---------------------------------------------------------------------------
// These typedefs are kept for test compatibility (tests mock them).
// ---------------------------------------------------------------------------

/// Defines the contract of the creation of an [AudioPool].
typedef CreateAudioPool = Future<void> Function({
  required dynamic source,
  required int maxPlayers,
  dynamic audioCache,
  int minPlayers,
});

/// Defines the contract for playing a single audio.
typedef PlaySingleAudio = Future<void> Function(String, {double volume});

/// Defines the contract for looping a single audio.
typedef LoopSingleAudio = Future<void> Function(String, {double volume});

/// Defines the contract for pre fetching an audio.
typedef PreCacheSingleAudio = Future<void> Function(String);

/// Defines the contract for configuring an audio cache instance.
typedef ConfigureAudioCache = void Function(dynamic);

// ---------------------------------------------------------------------------
// Public API
// ---------------------------------------------------------------------------

/// {@template pinball_audio_player}
/// Sound manager for the pinball game.
/// {@endtemplate}
class PinballAudioPlayer {
  /// {@macro pinball_audio_player}
  PinballAudioPlayer({
    // These parameters exist only for test compatibility; the real
    // implementation ignores them and uses raw JS Audio.
    CreateAudioPool? createAudioPool,
    PlaySingleAudio? playSingleAudio,
    LoopSingleAudio? loopSingleAudio,
    PreCacheSingleAudio? preCacheSingleAudio,
    ConfigureAudioCache? configureAudioCache,
    Random? seed,
  }) : _seed = seed ?? Random() {
    audios = {
      PinballAudio.google: _SimpleAudio(path: Assets.sfx.google),
      PinballAudio.sparky: _SimpleAudio(path: Assets.sfx.sparky),
      PinballAudio.dino: _ThrottledAudio(
        path: Assets.sfx.dino,
        duration: const Duration(seconds: 6),
      ),
      PinballAudio.dash: _SimpleAudio(path: Assets.sfx.dash),
      PinballAudio.android: _SimpleAudio(path: Assets.sfx.android),
      PinballAudio.launcher: _SimpleAudio(path: Assets.sfx.launcher),
      PinballAudio.rollover: _SimpleAudio(
        path: Assets.sfx.rollover,
        volume: 0.3,
      ),
      PinballAudio.flipper: _SimpleAudio(path: Assets.sfx.flipper),
      PinballAudio.ioPinballVoiceOver: _SimpleAudio(
        path: Assets.sfx.ioPinballVoiceOver,
      ),
      PinballAudio.gameOverVoiceOver: _SimpleAudio(
        path: Assets.sfx.gameOverVoiceOver,
      ),
      PinballAudio.bumper: _RandomABAudio(
        pathA: Assets.sfx.bumperA,
        pathB: Assets.sfx.bumperB,
        seed: _seed,
        volume: 0.6,
      ),
      PinballAudio.kicker: _RandomABAudio(
        pathA: Assets.sfx.kickerA,
        pathB: Assets.sfx.kickerB,
        seed: _seed,
        volume: 0.6,
      ),
      PinballAudio.cowMoo: _ThrottledAudio(
        path: Assets.sfx.cowMoo,
        duration: const Duration(seconds: 2),
      ),
      PinballAudio.backgroundMusic: _LoopAudio(
        path: Assets.music.background,
        volume: 0.6,
      ),
    };
  }

  final Random _seed;

  bool _muted = false;

  /// Whether audio playback is currently muted.
  bool get muted => _muted;

  /// Toggles the mute state.
  void toggleMute() {
    _muted = !_muted;
  }

  /// Registered audios on the Player.
  @visibleForTesting
  // ignore: library_private_types_in_public_api
  late final Map<PinballAudio, _Audio> audios;

  /// Loads the sounds effects into the memory.
  List<Future<void> Function()> load() {
    return audios.values.map((a) => a.load).toList();
  }

  /// Plays the received audio. Does nothing if muted.
  void play(PinballAudio audio) {
    if (_muted) return;
    try {
      audios[audio]?.play();
    } catch (_) {
      // Silently ignore – audio failure must never crash the game loop.
    }
  }
}
