import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pinball_audio/pinball_audio.dart';
import 'package:pinball_ui/pinball_ui.dart';

class SoundToggleOverlay extends StatefulWidget {
  const SoundToggleOverlay({Key? key}) : super(key: key);

  @override
  State<SoundToggleOverlay> createState() => _SoundToggleOverlayState();
}

class _SoundToggleOverlayState extends State<SoundToggleOverlay> {
  bool _muted = false;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      iconSize: 40,
      icon: Icon(
        _muted ? Icons.volume_off : Icons.volume_up,
        color: PinballColors.white,
      ),
      onPressed: () {
        final audioPlayer = context.read<PinballAudioPlayer>();
        audioPlayer.toggleMute();
        setState(() {
          _muted = audioPlayer.muted;
        });
      },
    );
  }
}
