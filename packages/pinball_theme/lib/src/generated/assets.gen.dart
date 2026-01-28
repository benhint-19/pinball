/// GENERATED CODE - DO NOT MODIFY BY HAND
/// *****************************************************
///  FlutterGen
/// *****************************************************

// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: directives_ordering,unnecessary_import,implicit_dynamic_list_literal,deprecated_member_use

import 'package:flutter/widgets.dart';

class $AssetsImagesGen {
  const $AssetsImagesGen();

  $AssetsImagesDegenGen get degen => const $AssetsImagesDegenGen();
  $AssetsImagesDevGen get dev => const $AssetsImagesDevGen();
  $AssetsImagesMinerGen get miner => const $AssetsImagesMinerGen();

  /// File path: assets/images/pinball_button.png
  AssetGenImage get pinballButton =>
      const AssetGenImage('assets/images/pinball_button.png');

  /// File path: assets/images/select_character_background.png
  AssetGenImage get selectCharacterBackground =>
      const AssetGenImage('assets/images/select_character_background.png');

  $AssetsImagesShibaGen get shiba => const $AssetsImagesShibaGen();

  /// List of all assets
  List<AssetGenImage> get values => [pinballButton, selectCharacterBackground];
}

class $AssetsImagesDegenGen {
  const $AssetsImagesDegenGen();

  /// File path: assets/images/degen/animation.png
  AssetGenImage get animation =>
      const AssetGenImage('assets/images/degen/animation.png');

  /// File path: assets/images/degen/background.jpg
  AssetGenImage get background =>
      const AssetGenImage('assets/images/degen/background.jpg');

  /// File path: assets/images/degen/ball.png
  AssetGenImage get ball => const AssetGenImage('assets/images/degen/ball.png');

  /// File path: assets/images/degen/icon.png
  AssetGenImage get icon => const AssetGenImage('assets/images/degen/icon.png');

  /// File path: assets/images/degen/leaderboard_icon.png
  AssetGenImage get leaderboardIcon =>
      const AssetGenImage('assets/images/degen/leaderboard_icon.png');

  /// List of all assets
  List<AssetGenImage> get values =>
      [animation, background, ball, icon, leaderboardIcon];
}

class $AssetsImagesDevGen {
  const $AssetsImagesDevGen();

  /// File path: assets/images/dev/animation.png
  AssetGenImage get animation =>
      const AssetGenImage('assets/images/dev/animation.png');

  /// File path: assets/images/dev/background.jpg
  AssetGenImage get background =>
      const AssetGenImage('assets/images/dev/background.jpg');

  /// File path: assets/images/dev/ball.png
  AssetGenImage get ball => const AssetGenImage('assets/images/dev/ball.png');

  /// File path: assets/images/dev/icon.png
  AssetGenImage get icon => const AssetGenImage('assets/images/dev/icon.png');

  /// File path: assets/images/dev/leaderboard_icon.png
  AssetGenImage get leaderboardIcon =>
      const AssetGenImage('assets/images/dev/leaderboard_icon.png');

  /// List of all assets
  List<AssetGenImage> get values =>
      [animation, background, ball, icon, leaderboardIcon];
}

class $AssetsImagesMinerGen {
  const $AssetsImagesMinerGen();

  /// File path: assets/images/miner/animation.png
  AssetGenImage get animation =>
      const AssetGenImage('assets/images/miner/animation.png');

  /// File path: assets/images/miner/background.jpg
  AssetGenImage get background =>
      const AssetGenImage('assets/images/miner/background.jpg');

  /// File path: assets/images/miner/ball.png
  AssetGenImage get ball => const AssetGenImage('assets/images/miner/ball.png');

  /// File path: assets/images/miner/icon.png
  AssetGenImage get icon => const AssetGenImage('assets/images/miner/icon.png');

  /// File path: assets/images/miner/leaderboard_icon.png
  AssetGenImage get leaderboardIcon =>
      const AssetGenImage('assets/images/miner/leaderboard_icon.png');

  /// List of all assets
  List<AssetGenImage> get values =>
      [animation, background, ball, icon, leaderboardIcon];
}

class $AssetsImagesShibaGen {
  const $AssetsImagesShibaGen();

  /// File path: assets/images/shiba/animation.png
  AssetGenImage get animation =>
      const AssetGenImage('assets/images/shiba/animation.png');

  /// File path: assets/images/shiba/background.jpg
  AssetGenImage get background =>
      const AssetGenImage('assets/images/shiba/background.jpg');

  /// File path: assets/images/shiba/ball.png
  AssetGenImage get ball => const AssetGenImage('assets/images/shiba/ball.png');

  /// File path: assets/images/shiba/icon.png
  AssetGenImage get icon => const AssetGenImage('assets/images/shiba/icon.png');

  /// File path: assets/images/shiba/leaderboard_icon.png
  AssetGenImage get leaderboardIcon =>
      const AssetGenImage('assets/images/shiba/leaderboard_icon.png');

  /// List of all assets
  List<AssetGenImage> get values =>
      [animation, background, ball, icon, leaderboardIcon];
}

class Assets {
  Assets._();

  static const String package = 'pinball_theme';

  static const $AssetsImagesGen images = $AssetsImagesGen();
}

class AssetGenImage {
  const AssetGenImage(this._assetName);

  final String _assetName;

  static const String package = 'pinball_theme';

  Image image({
    Key? key,
    AssetBundle? bundle,
    ImageFrameBuilder? frameBuilder,
    ImageErrorWidgetBuilder? errorBuilder,
    String? semanticLabel,
    bool excludeFromSemantics = false,
    double? scale,
    double? width,
    double? height,
    Color? color,
    Animation<double>? opacity,
    BlendMode? colorBlendMode,
    BoxFit? fit,
    AlignmentGeometry alignment = Alignment.center,
    ImageRepeat repeat = ImageRepeat.noRepeat,
    Rect? centerSlice,
    bool matchTextDirection = false,
    bool gaplessPlayback = false,
    bool isAntiAlias = false,
    @Deprecated('Do not specify package for a generated library asset')
        String? package = package,
    FilterQuality filterQuality = FilterQuality.low,
    int? cacheWidth,
    int? cacheHeight,
  }) {
    return Image.asset(
      _assetName,
      key: key,
      bundle: bundle,
      frameBuilder: frameBuilder,
      errorBuilder: errorBuilder,
      semanticLabel: semanticLabel,
      excludeFromSemantics: excludeFromSemantics,
      scale: scale,
      width: width,
      height: height,
      color: color,
      opacity: opacity,
      colorBlendMode: colorBlendMode,
      fit: fit,
      alignment: alignment,
      repeat: repeat,
      centerSlice: centerSlice,
      matchTextDirection: matchTextDirection,
      gaplessPlayback: gaplessPlayback,
      isAntiAlias: isAntiAlias,
      package: package,
      filterQuality: filterQuality,
      cacheWidth: cacheWidth,
      cacheHeight: cacheHeight,
    );
  }

  ImageProvider provider({
    AssetBundle? bundle,
    @Deprecated('Do not specify package for a generated library asset')
        String? package = package,
  }) {
    return AssetImage(
      _assetName,
      bundle: bundle,
      package: package,
    );
  }

  String get path => _assetName;

  String get keyName => 'packages/pinball_theme/$_assetName';
}
