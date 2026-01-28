import 'package:pinball_theme/pinball_theme.dart';

/// {@template miner_theme}
/// Defines Miner character theme assets and attributes.
/// {@endtemplate}
class MinerTheme extends CharacterTheme {
  /// {@macro miner_theme}
  const MinerTheme();

  @override
  String get name => 'Miner';

  @override
  AssetGenImage get ball => Assets.images.miner.ball;

  @override
  AssetGenImage get background => Assets.images.miner.background;

  @override
  AssetGenImage get icon => Assets.images.miner.icon;

  @override
  AssetGenImage get leaderboardIcon => Assets.images.miner.leaderboardIcon;

  @override
  AssetGenImage get animation => Assets.images.miner.animation;
}
