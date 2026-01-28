// ignore_for_file: prefer_const_constructors

import 'package:flutter_test/flutter_test.dart';
import 'package:leaderboard_repository/leaderboard_repository.dart';
import 'package:pinball/leaderboard/models/leader_board_entry.dart';
import 'package:pinball_theme/pinball_theme.dart';

void main() {
  group('LeaderboardEntry', () {
    group('toEntry', () {
      test('returns the correct from a to entry data', () {
        expect(
          LeaderboardEntryData.empty.toEntry(1),
          LeaderboardEntry(
            rank: '1',
            playerInitials: '',
            score: 0,
            character: CharacterType.dev.toTheme.leaderboardIcon,
          ),
        );
      });
    });

    group('CharacterType', () {
      test('toTheme returns the correct theme', () {
        expect(CharacterType.dev.toTheme, equals(DevTheme()));
        expect(CharacterType.shiba.toTheme, equals(ShibaTheme()));
        expect(CharacterType.miner.toTheme, equals(MinerTheme()));
        expect(CharacterType.degen.toTheme, equals(DegenTheme()));
      });
    });

    group('CharacterTheme', () {
      test('toType returns the correct type', () {
        expect(DevTheme().toType, equals(CharacterType.dev));
        expect(ShibaTheme().toType, equals(CharacterType.shiba));
        expect(MinerTheme().toType, equals(CharacterType.miner));
        expect(DegenTheme().toType, equals(CharacterType.degen));
      });
    });
  });
}
