part of 'character_theme_cubit.dart';

class CharacterThemeState extends Equatable {
  const CharacterThemeState(this.characterTheme);

  const CharacterThemeState.initial() : characterTheme = const DevTheme();

  final CharacterTheme characterTheme;

  bool get isShibaSelected => characterTheme == const ShibaTheme();

  bool get isDevSelected => characterTheme == const DevTheme();

  bool get isMinerSelected => characterTheme == const MinerTheme();

  bool get isDegenSelected => characterTheme == const DegenTheme();

  @override
  List<Object> get props => [characterTheme];
}
