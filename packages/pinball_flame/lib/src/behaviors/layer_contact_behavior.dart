import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:pinball_flame/pinball_flame.dart';

/// {@template layer_contact_behavior}
/// Switches the [Layer] of any [Layered] body that contacts with it.
/// {@endtemplate}
class LayerContactBehavior extends ContactBehavior<BodyComponent> {
  /// {@macro layer_contact_behavior}
  LayerContactBehavior({
    required Layer layer,
    bool onBegin = true,
  })  : _layer = layer,
        _onBegin = onBegin;

  final Layer _layer;
  final bool _onBegin;

  @override
  void beginContact(Object other, Contact contact) {
    super.beginContact(other, contact);
    if (_onBegin) _changeLayer(other);
  }

  @override
  void endContact(Object other, Contact contact) {
    super.endContact(other, contact);
    if (!_onBegin) _changeLayer(other);
  }

  void _changeLayer(Object other) {
    if (other is! Layered) return;
    if (other.layer == _layer) return;
    other.layer = _layer;
  }
}
