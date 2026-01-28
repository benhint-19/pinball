import 'package:pinball_theme/pinball_theme.dart';

/// {@template dev_theme}
/// Defines Dev character theme assets and attributes.
/// {@endtemplate}
class DevTheme extends CharacterTheme {
  /// {@macro dev_theme}
  const DevTheme();

  @override
  String get name => 'Dev';

  @override
  AssetGenImage get ball => Assets.images.dev.ball;

  @override
  AssetGenImage get background => Assets.images.dev.background;

  @override
  AssetGenImage get icon => Assets.images.dev.icon;

  @override
  AssetGenImage get leaderboardIcon => Assets.images.dev.leaderboardIcon;

  @override
  AssetGenImage get animation => Assets.images.dev.animation;
}
