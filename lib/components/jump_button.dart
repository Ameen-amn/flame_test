import 'dart:async';

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame_test/pixel_adventure.dart';

class JumpButton extends SpriteComponent
    with HasGameRef<PixelAdventure>, TapCallbacks {
  JumpButton();
  final margin = 0;
  final buttonSize = 64;
  @override
  FutureOr<void> onLoad() {
    priority = 100;
    sprite = Sprite(game.images.fromCache('HUD/jump.png'));
    position = Vector2(
        game.size.x - margin - buttonSize, game.size.y - margin - buttonSize);
  }

  @override
  void onTapDown(TapDownEvent event) {
    game.player.hasJumbed = true;
    super.onTapDown(event);
  }

  @override
  void onTapUp(TapUpEvent event) {
    game.player.hasJumbed = false;
    super.onTapUp(event);
  }
}
