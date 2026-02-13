import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pinball/assets_manager/assets_manager.dart';
import 'package:pinball/assets_manager/widgets/solana_pixel_logo.dart';
import 'package:pinball/l10n/l10n.dart';
import 'package:pinball_ui/pinball_ui.dart';

/// {@template assets_loading_page}
/// Widget used to indicate the loading progress of the different assets used
/// in the game
/// {@endtemplate}
class AssetsLoadingPage extends StatelessWidget {
  /// {@macro assets_loading_page}
  const AssetsLoadingPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final displayLarge = Theme.of(context).textTheme.displayLarge;
    return Container(
      decoration: const CrtBackground(),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SolanaPixelLogo(width: 180),
            const SizedBox(height: 24),
            ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(
                colors: [Color(0xFF9945FF), Color(0xFF14F195)],
              ).createShader(bounds),
              child: Text(
                'SOLANA SEEKER',
                style: displayLarge?.copyWith(
                  fontSize: 32,
                  color: PinballColors.white,
                ),
              ),
            ),
            const SizedBox(height: 40),
            AnimatedEllipsisText(
              l10n.loading,
              style: displayLarge,
            ),
            const SizedBox(height: 40),
            FractionallySizedBox(
              widthFactor: 0.8,
              child: BlocBuilder<AssetsManagerCubit, AssetsManagerState>(
                builder: (context, state) {
                  return PinballLoadingIndicator(value: state.progress);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
