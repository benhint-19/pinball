import 'package:flame/components.dart';
import 'package:flame_bloc/flame_bloc.dart';
import 'package:pinball/game/game.dart';
import 'package:pinball/select_character/select_character.dart';
import 'package:pinball_audio/pinball_audio.dart';
import 'package:pinball_components/pinball_components.dart';
import 'package:pinball_flame/pinball_flame.dart';

/// Listens to the [GameBloc] and updates the game accordingly.
class GameBlocStatusListener extends Component
    with FlameBlocListenable<GameBloc, GameState>, HasGameRef {
  @override
  bool listenWhen(GameState? previousState, GameState newState) {
    return previousState?.status != newState.status;
  }

  @override
  void onNewState(GameState state) {
    try {
      switch (state.status) {
        case GameStatus.waiting:
          break;
        case GameStatus.playing:
          readProvider<PinballAudioPlayer>()
              .play(PinballAudio.backgroundMusic);
          _resetBonuses();
          gameRef
              .descendants()
              .whereType<Flipper>()
              .forEach(_addFlipperBehaviors);
          gameRef
              .descendants()
              .whereType<Plunger>()
              .forEach(_addPlungerBehaviors);
          gameRef.overlays.remove(PinballGame.playButtonOverlay);
          gameRef.overlays.remove(PinballGame.replayButtonOverlay);
          break;
        case GameStatus.gameOver:
          readProvider<PinballAudioPlayer>()
              .play(PinballAudio.gameOverVoiceOver);
          gameRef
              .descendants()
              .whereType<Backbox>()
              .firstOrNull
              ?.requestInitials(
                score: state.displayScore,
                character:
                    readBloc<CharacterThemeCubit, CharacterThemeState>()
                        .state
                        .characterTheme,
              );
          gameRef
              .descendants()
              .whereType<Flipper>()
              .forEach(_removeFlipperBehaviors);
          gameRef
              .descendants()
              .whereType<Plunger>()
              .forEach(_removePlungerBehaviors);
          break;
      }
    } catch (_) {
      // Prevent unhandled exceptions from crashing the game loop.
    }
  }

  void _resetBonuses() {
    gameRef
        .descendants()
        .whereType<FlameBlocProvider<GoogleWordCubit, GoogleWordState>>()
        .firstOrNull
        ?.bloc
        .onReset();
    gameRef
        .descendants()
        .whereType<FlameBlocProvider<DashBumpersCubit, DashBumpersState>>()
        .firstOrNull
        ?.bloc
        .onReset();
    gameRef
        .descendants()
        .whereType<FlameBlocProvider<SignpostCubit, SignpostState>>()
        .firstOrNull
        ?.bloc
        .onReset();
  }

  void _addPlungerBehaviors(Plunger plunger) {
    final provider =
        plunger.firstChild<FlameBlocProvider<PlungerCubit, PlungerState>>();
    if (provider == null) return;
    provider.addAll([
      PlungerPullingBehavior(strength: 7),
      PlungerAutoPullingBehavior(),
      PlungerKeyControllingBehavior(),
    ]);
  }

  void _removePlungerBehaviors(Plunger plunger) {
    plunger.children
        .whereType<PlungerPullingBehavior>()
        .forEach(plunger.remove);
    plunger.children
        .whereType<PlungerAutoPullingBehavior>()
        .forEach(plunger.remove);
    plunger.children
        .whereType<PlungerKeyControllingBehavior>()
        .forEach(plunger.remove);
  }

  void _addFlipperBehaviors(Flipper flipper) {
    final provider =
        flipper.firstChild<FlameBlocProvider<FlipperCubit, FlipperState>>();
    if (provider == null) return;
    provider.add(FlipperKeyControllingBehavior());
  }

  void _removeFlipperBehaviors(Flipper flipper) => flipper.children
      .whereType<FlipperKeyControllingBehavior>()
      .forEach(flipper.remove);
}
