import 'package:pinball_theme/pinball_theme.dart';

/// {@template degen_theme}
/// Defines Degen character theme assets and attributes.
/// {@endtemplate}
class DegenTheme extends CharacterTheme {
  /// {@macro degen_theme}
  const DegenTheme();

  @override
  String get name => 'Degen';

  @override
  AssetGenImage get ball => Assets.images.degen.ball;

  @override
  AssetGenImage get background => Assets.images.degen.background;

  @override
  AssetGenImage get icon => Assets.images.degen.icon;

  @override
  AssetGenImage get leaderboardIcon => Assets.images.degen.leaderboardIcon;

  @override
  AssetGenImage get animation => Assets.images.degen.animation;
}
