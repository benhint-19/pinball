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

  $AssetsImagesBonusAnimationGen get bonusAnimation =>
      const $AssetsImagesBonusAnimationGen();
  $AssetsImagesComponentsGen get components =>
      const $AssetsImagesComponentsGen();
  $AssetsImagesLoadingGameGen get loadingGame =>
      const $AssetsImagesLoadingGameGen();
  $AssetsImagesScoreGen get score => const $AssetsImagesScoreGen();
}

class $AssetsImagesBonusAnimationGen {
  const $AssetsImagesBonusAnimationGen();

  /// File path: assets/images/bonus_animation/android_spaceship.png
  AssetGenImage get androidSpaceship => const AssetGenImage(
      'assets/images/bonus_animation/android_spaceship.png');

  /// File path: assets/images/bonus_animation/dash_nest.png
  AssetGenImage get dashNest =>
      const AssetGenImage('assets/images/bonus_animation/dash_nest.png');

  /// File path: assets/images/bonus_animation/dino_chomp.png
  AssetGenImage get dinoChomp =>
      const AssetGenImage('assets/images/bonus_animation/dino_chomp.png');

  /// File path: assets/images/bonus_animation/google_word.png
  AssetGenImage get googleWord =>
      const AssetGenImage('assets/images/bonus_animation/google_word.png');

  /// File path: assets/images/bonus_animation/sparky_turbo_charge.png
  AssetGenImage get sparkyTurboCharge => const AssetGenImage(
      'assets/images/bonus_animation/sparky_turbo_charge.png');

  /// List of all assets
  List<AssetGenImage> get values =>
      [androidSpaceship, dashNest, dinoChomp, googleWord, sparkyTurboCharge];
}

class $AssetsImagesComponentsGen {
  const $AssetsImagesComponentsGen();

  /// File path: assets/images/components/key.png
  AssetGenImage get key =>
      const AssetGenImage('assets/images/components/key.png');

  /// File path: assets/images/components/space.png
  AssetGenImage get space =>
      const AssetGenImage('assets/images/components/space.png');

  /// List of all assets
  List<AssetGenImage> get values => [key, space];
}

class $AssetsImagesLoadingGameGen {
  const $AssetsImagesLoadingGameGen();

  /// File path: assets/images/loading_game/io_pinball.png
  AssetGenImage get ioPinball =>
      const AssetGenImage('assets/images/loading_game/io_pinball.png');

  /// List of all assets
  List<AssetGenImage> get values => [ioPinball];
}

class $AssetsImagesScoreGen {
  const $AssetsImagesScoreGen();

  /// File path: assets/images/score/mini_score_background.png
  AssetGenImage get miniScoreBackground =>
      const AssetGenImage('assets/images/score/mini_score_background.png');

  /// List of all assets
  List<AssetGenImage> get values => [miniScoreBackground];
}

class Assets {
  Assets._();

  static const String package = 'pinball';

  static const $AssetsImagesGen images = $AssetsImagesGen();
}

class AssetGenImage {
  const AssetGenImage(this._assetName);

  final String _assetName;

  static const String package = 'pinball';

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

  String get keyName => 'packages/pinball/$_assetName';
}
