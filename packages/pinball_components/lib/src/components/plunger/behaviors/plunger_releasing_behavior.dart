import 'package:flame/components.dart';
import 'package:flame_bloc/flame_bloc.dart';
import 'package:pinball_components/pinball_components.dart';

class PlungerReleasingBehavior extends Component
    with FlameBlocListenable<PlungerCubit, PlungerState> {
  PlungerReleasingBehavior({
    required double strength,
    required double compressionDistance,
  })  : assert(strength >= 0, "Strength can't be negative."),
        _strength = strength,
        _compressionDistance = compressionDistance;

  final double _strength;
  final double _compressionDistance;

  late final Plunger _plunger;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    _plunger = parent!.parent! as Plunger;
  }

  @override
  void onNewState(PlungerState state) {
    super.onNewState(state);
    if (state.isReleasing) {
      // Use fixed max-compression velocity for consistent launches.
      // Reading body.position here is unreliable because the prismatic
      // joint motor (speed 1000) may have already pushed the plunger
      // back between the physics step and this state-change callback.
      final velocity = -_compressionDistance * _strength;
      _plunger.body.linearVelocity = Vector2(0, velocity);
    }
  }
}
