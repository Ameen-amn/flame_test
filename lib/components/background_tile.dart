import 'dart:async';

import 'package:flame/components.dart';
import 'package:flame/parallax.dart';
import 'package:flutter/painting.dart';

//sprite component is used becz it can pass in an image
// ParallaxComponent have HasGameRef<PixelAdventure> ( used to get the cache images)
class BackgroundTile extends ParallaxComponent {
  final String color;

  BackgroundTile({this.color = 'Gray', position}) : super(position: position);

  final double scrollSpeed = 35;

  @override
  FutureOr<void> onLoad() async {
    priority = -1;
    size = Vector2.all(64);
    parallax = await game.loadParallax(
      [ParallaxImageData('Background/$color.png')],
      baseVelocity: Vector2(0, -scrollSpeed),
      fill: LayerFill.none,
      repeat: ImageRepeat.repeat,
    );
    // sprite = Sprite(game.images.fromCache('Background/$color.png'));
    return super.onLoad();
  }
}
