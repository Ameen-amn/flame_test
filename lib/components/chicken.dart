import 'dart:async';
import 'dart:ui';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame_audio/flame_audio.dart';
import 'package:flame_test/components/player.dart';
import 'package:flame_test/pixel_adventure.dart';

//SpriteAnimationGroupComponent: it is used to handle different states
enum ChickenState { hit, idle, run }

class Chicken extends SpriteAnimationGroupComponent
    with HasGameRef<PixelAdventure>, CollisionCallbacks {
  final double offNeg;
  final double offPos;
  Chicken({this.offNeg = 0, this.offPos = 0, super.position, super.size});
  static const stepTime = 0.05;
  final textureSize = Vector2(32, 34);
  static const tileSize = 16;

  Vector2 velocity = Vector2.zero();
  double runSpeed = 80;
  double rangeNeg = 0;
  double moveDirection = 0;
  double bounceHeight = 260;
  double rangePos = 0;
  int targetDirection = 0;
  bool _gotStomped = false;
  late SpriteAnimation _hitAnimation;
  late SpriteAnimation _idleAnimation;
  late SpriteAnimation _runAnimation;
  late final Player player;

  @override
  FutureOr<void> onLoad() {
    // debugMode = true;
    player = game.player;
    add(RectangleHitbox(position: Vector2(4, 6), size: Vector2(24, 26)));
    _loadallAnimaion();
    _calculateRange();
    return super.onLoad();
  }

  @override
  void update(double dt) {
    if (!_gotStomped) {
      _updateState();
      _movement(dt);
    }
    super.update(dt);
  }

  void _loadallAnimaion() {
    _idleAnimation = _spriteAnimation(state: 'Idle', amount: 14);
    _runAnimation = _spriteAnimation(state: 'Run', amount: 13);
    _hitAnimation = _spriteAnimation(state: 'Hit', amount: 15)..loop = false;

    animations = {
      ChickenState.idle: _idleAnimation,
      ChickenState.run: _runAnimation,
      ChickenState.hit: _hitAnimation,
    };
    current = ChickenState.idle;
  }

  SpriteAnimation _spriteAnimation(
      {required String state, required int amount}) {
    return SpriteAnimation.fromFrameData(
        game.images.fromCache('Enemies/Chicken/$state (32x34).png'),
        SpriteAnimationData.sequenced(
            amount: amount, stepTime: stepTime, textureSize: textureSize));
  }

  void _calculateRange() {
    rangeNeg = position.x - offNeg * tileSize;
    rangePos = position.x + offPos * tileSize;
  }

  void _movement(double dt) {
    velocity.x = 0;
    double playerOffset = (player.scale.x > 0) ? 0 : -player.width;
    double chickenOffset = (scale.x > 0) ? 0 : -width;
    //player in range of chicken
    if (playerInRange()) {
      targetDirection =
          (player.x + playerOffset < position.x + chickenOffset) ? -1 : 1;
      velocity.x = targetDirection * runSpeed;
    }
    moveDirection = lerpDouble(moveDirection, targetDirection, 0.1) ?? 1;
    position.x += velocity.x * dt;
  }

  bool playerInRange() {
    double playerOffSet = (player.scale.x > 0) ? 0 : -player.width;

    return player.x + playerOffSet >=
            rangeNeg && // player entered to range from left
        player.x + playerOffSet <=
            rangePos && // player entered to range from right
        player.y + player.height > position.y &&
        player.y < position.y + height;
  }

  void _updateState() {
    current = (velocity.x != 0) ? ChickenState.run : ChickenState.idle;
    if ((moveDirection > 0 && scale.x > 0) ||
        (moveDirection < 0 && scale.x < 0)) {
      flipHorizontallyAroundCenter();
    }
  }

  void collidedWithPlayer() async {
    // checking the player is falling and botton of the player is hiting the chicken head
    if (player.velocity.y > 0 && player.y + player.height > position.y) {
      if (game.playSounds) {
        FlameAudio.play('bounce.wav', volume: game.soundVolume);
      }
      _gotStomped = true;
      current = ChickenState.hit;
      player.velocity.y = -bounceHeight;
      await animationTicker?.completed;
      removeFromParent();
    } else {
      player.collidedWithEnemy();
    }
  }
}
