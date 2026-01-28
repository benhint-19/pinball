import 'package:pinball_theme/pinball_theme.dart';

/// {@template shiba_theme}
/// Defines Shiba character theme assets and attributes.
/// {@endtemplate}
class ShibaTheme extends CharacterTheme {
  /// {@macro shiba_theme}
  const ShibaTheme();

  @override
  AssetGenImage get ball => Assets.images.shiba.ball;

  @override
  String get name => 'Shiba';

  @override
  AssetGenImage get background => Assets.images.shiba.background;

  @override
  AssetGenImage get icon => Assets.images.shiba.icon;

  @override
  AssetGenImage get leaderboardIcon => Assets.images.shiba.leaderboardIcon;

  @override
  AssetGenImage get animation => Assets.images.shiba.animation;
}
