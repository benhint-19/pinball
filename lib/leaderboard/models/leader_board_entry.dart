import 'package:equatable/equatable.dart';
import 'package:leaderboard_repository/leaderboard_repository.dart';
import 'package:pinball_theme/pinball_theme.dart';

/// {@template leaderboard_entry}
/// A model representing a leaderboard entry containing the ranking position,
/// player's initials, score, and chosen character.
///
/// {@endtemplate}
class LeaderboardEntry extends Equatable {
  /// {@macro leaderboard_entry}
  const LeaderboardEntry({
    required this.rank,
    required this.playerInitials,
    required this.score,
    required this.character,
  });

  /// Ranking position for [LeaderboardEntry].
  final String rank;

  /// Player's chosen initials for [LeaderboardEntry].
  final String playerInitials;

  /// Score for [LeaderboardEntry].
  final int score;

  /// [CharacterTheme] for [LeaderboardEntry].
  final AssetGenImage character;

  @override
  List<Object?> get props => [rank, playerInitials, score, character];
}

/// Converts [LeaderboardEntryData] from repository to [LeaderboardEntry].
extension LeaderboardEntryDataX on LeaderboardEntryData {
  /// Conversion method to [LeaderboardEntry]
  LeaderboardEntry toEntry(int position) {
    return LeaderboardEntry(
      rank: position.toString(),
      playerInitials: playerInitials,
      score: score,
      character: character.toTheme.leaderboardIcon,
    );
  }
}

/// Converts [CharacterType] to [CharacterTheme] to show on UI character theme
/// from repository.
extension CharacterTypeX on CharacterType {
  /// Conversion method to [CharacterTheme]
  CharacterTheme get toTheme {
    switch (this) {
      case CharacterType.dev:
        return const DevTheme();
      case CharacterType.shiba:
        return const ShibaTheme();
      case CharacterType.miner:
        return const MinerTheme();
      case CharacterType.degen:
        return const DegenTheme();
    }
  }
}

/// Converts [CharacterTheme] to [CharacterType] to persist at repository the
/// character theme from UI.
extension CharacterThemeX on CharacterTheme {
  /// Conversion method to [CharacterType]
  CharacterType get toType {
    switch (runtimeType) {
      case DevTheme:
        return CharacterType.dev;
      case ShibaTheme:
        return CharacterType.shiba;
      case MinerTheme:
        return CharacterType.miner;
      case DegenTheme:
        return CharacterType.degen;
      default:
        return CharacterType.dev;
    }
  }
}
