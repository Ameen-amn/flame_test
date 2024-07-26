import 'dart:async';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame_audio/flame_audio.dart';
import 'package:flame_test/components/player_hitbox.dart';
import 'package:flame_test/pixel_adventure.dart';
//CollisionCallbacks : used for collision detection

class Fruit extends SpriteAnimationComponent
    with HasGameRef<PixelAdventure>, CollisionCallbacks {
  final String fruit;
  bool isCollected = false;
  Fruit({this.fruit = 'Apple', position, size})
      : super(position: position, size: size);

  final double stepTime = 0.05;
  final hitbox = CustomHitBox(offsetX: 10, offsetY: 10, width: 12, height: 12);
  @override
  FutureOr<void> onLoad() {
    // debugMode = true;
    priority = -1;
    add(RectangleHitbox(
      position: Vector2(hitbox.offsetX, hitbox.offsetY),
      size: Vector2(hitbox.width, hitbox.height),
      collisionType: CollisionType.passive,
    ));
    animation = SpriteAnimation.fromFrameData(
        game.images.fromCache('Items/Fruits/$fruit.png'),
        SpriteAnimationData.sequenced(
            amount: 17, stepTime: stepTime, textureSize: Vector2.all(32)));
    return super.onLoad();
  }

  void collidedWithPlayer() async {
    if (!isCollected) {
      isCollected = true;
      if (game.playSounds) {
        FlameAudio.play('collect_fruit.wav', volume: game.soundVolume);
      }
      animation = SpriteAnimation.fromFrameData(
          game.images.fromCache('Items/Fruits/Collected.png'),
          SpriteAnimationData.sequenced(
              amount: 6,
              stepTime: stepTime,
              textureSize: Vector2.all(32),
              loop: false));
    }

    await animationTicker?.completed;
    removeFromParent();
  }
}
