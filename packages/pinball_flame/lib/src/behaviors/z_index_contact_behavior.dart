import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:pinball_flame/pinball_flame.dart';

/// {@template z_index_contact_behavior}
/// Switches the z-index of any [ZIndex] body that contacts with it.
/// {@endtemplate}
class ZIndexContactBehavior extends ContactBehavior<BodyComponent> {
  /// {@macro z_index_contact_behavior}
  ZIndexContactBehavior({
    required int zIndex,
    bool onBegin = true,
  })  : _zIndex = zIndex,
        _onBegin = onBegin;

  final int _zIndex;
  final bool _onBegin;

  @override
  void beginContact(Object other, Contact contact) {
    super.beginContact(other, contact);
    if (_onBegin) _changeZIndex(other);
  }

  @override
  void endContact(Object other, Contact contact) {
    super.endContact(other, contact);
    if (!_onBegin) _changeZIndex(other);
  }

  void _changeZIndex(Object other) {
    if (other is! ZIndex) return;
    if (other.zIndex == _zIndex) return;
    other.zIndex = _zIndex;
  }
}
