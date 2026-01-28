part of 'ball_cubit.dart';

class BallState extends Equatable {
  const BallState({required this.characterTheme});

  const BallState.initial() : this(characterTheme: const DevTheme());

  final CharacterTheme characterTheme;

  @override
  List<Object> get props => [characterTheme];
}
