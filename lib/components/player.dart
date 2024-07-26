import 'dart:async';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame_audio/flame_audio.dart';
import 'package:flame_test/components/checkpoint.dart';
import 'package:flame_test/components/chicken.dart';
import 'package:flame_test/components/collision_block.dart';
import 'package:flame_test/components/fruits.dart';
import 'package:flame_test/components/player_hitbox.dart';
import 'package:flame_test/components/saw.dart';
import 'package:flame_test/components/util.dart';
import 'package:flame_test/pixel_adventure.dart';
import 'package:flutter/services.dart';

enum PlayerState {
  idle,
  running,
  jumping,
  falling,
  hit,
  appearing,
  disappearing
}

//CollisionCallbacks : used for collision detection
class Player extends SpriteAnimationGroupComponent
    with HasGameRef<PixelAdventure>, KeyboardHandler, CollisionCallbacks {
//To place the avatar on the point we need we have to pass the position to the SpriteAnimationGroupComponent using super
  Player({super.position, this.character = 'Ninja Frog'});

  late final SpriteAnimation idleAnimation;
  late final SpriteAnimation runningAnimation;
  late final SpriteAnimation jumpingAnimation;
  late final SpriteAnimation fallingAnimation;
  late final SpriteAnimation hitAnimation;
  late final SpriteAnimation appearingAnimation;
  late final SpriteAnimation disappearingAnimation;
  final double steptime = 0.05;
  final String character;
  final double _gravity = 9.8;
  final double _jumpForce = 300.0;
  final double _terminalVelocity = 300;
  double moveSpeed = 100;
  double horizontalMovement = 0;
  double fixedDeltaTime = 1 / 60; // Fixing to 60FPS
  double accumulatedTime = 0;
  bool isOnGround = false;
  bool hasJumbed = false;
  bool gotHit = false;
  bool reachedCheckpoint = false;
  bool showControlls = false;
  Vector2 velocity = Vector2.zero();
  Vector2 startingPosition = Vector2.zero();
  bool isFacingRight = true;
  List<CollisionBlock> collisionBlocks = [];
  CustomHitBox hitbox =
      CustomHitBox(offsetX: 10, offsetY: 4, width: 14, height: 28);
  @override
  FutureOr<void> onLoad() {
    _loadAllAnimtion();
    // debugMode = true;
    //starting position of player when game is starting
    startingPosition = Vector2(position.x, position.y);
    add(RectangleHitbox(
        position: Vector2(hitbox.offsetX, hitbox.offsetY),
        size: Vector2(hitbox.width, hitbox.height)));
    return super.onLoad();
  }

  @override
  void update(double dt) {
    //dt is  Delta time
    accumulatedTime += fixedDeltaTime;
    while (accumulatedTime >= fixedDeltaTime) {
      if (!gotHit && !reachedCheckpoint) {
        _updatePlayerState();
        _updatePlayerMovement(deltaTime: fixedDeltaTime);
        _checkHorizontalCollision();
        _applyGravity(fixedDeltaTime);
        _checkVerticalCollisions();
      }
      accumulatedTime -= fixedDeltaTime;
    }
    super.update(dt);
  }

//KeyboardHandler : Controlling avatar with keyboard
  @override
  bool onKeyEvent(KeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
    horizontalMovement = 0;
    final isLeftKeyPressed = keysPressed.contains(LogicalKeyboardKey.arrowUp) ||
        keysPressed.contains(LogicalKeyboardKey.keyA);
    final isRightKeyPressed =
        keysPressed.contains(LogicalKeyboardKey.arrowDown) ||
            keysPressed.contains(LogicalKeyboardKey.keyD);
    horizontalMovement += isLeftKeyPressed ? -1 : 0;
    horizontalMovement += isRightKeyPressed ? 1 : 0;
    hasJumbed = keysPressed.contains(LogicalKeyboardKey.space);
    return super.onKeyEvent(event, keysPressed);
  }

//onCollisionStart : It only triggers once
  @override
  void onCollisionStart(
      Set<Vector2> intersectionPoints, PositionComponent other) {
    if (!reachedCheckpoint) {
      if (other is Fruit) other.collidedWithPlayer();
      if (other is Saw) _respawn();
      if (other is Chicken) other.collidedWithPlayer();
      if (other is Checkpoint) _reachedCheckpoint();
    }
    super.onCollisionStart(intersectionPoints, other);
  }

  void _loadAllAnimtion() {
    idleAnimation = _spriteAnimation(state: 'Idle', amount: 11);
    runningAnimation = _spriteAnimation(state: 'Run', amount: 12);
    jumpingAnimation = _spriteAnimation(state: 'Jump', amount: 1);
    fallingAnimation = _spriteAnimation(state: 'Fall', amount: 1);
    hitAnimation = _spriteAnimation(state: 'Hit', amount: 7)..loop = false;
    appearingAnimation = _specialSpriteAnimation(state: 'Appearing', amount: 7);
    disappearingAnimation =
        _specialSpriteAnimation(state: 'Desappearing', amount: 7);

//linking our animations to enum
//List of all animation
    animations = {
      PlayerState.idle: idleAnimation,
      PlayerState.running: runningAnimation,
      PlayerState.falling: fallingAnimation,
      PlayerState.jumping: jumpingAnimation,
      PlayerState.hit: hitAnimation,
      PlayerState.appearing: appearingAnimation,
      PlayerState.disappearing: disappearingAnimation,
    };
//current animation
    current = PlayerState.running;
  }

  SpriteAnimation _spriteAnimation(
      {required String state, required int amount}) {
    return SpriteAnimation.fromFrameData(
        game.images.fromCache('Main Characters/$character/$state (32x32).png'),
        SpriteAnimationData.sequenced(
          amount: amount,
          stepTime: steptime,
          textureSize: Vector2.all(32),
          loop: false,
        ));
  }

  // Appearing and Disappearing
  SpriteAnimation _specialSpriteAnimation(
      {required String state, required int amount}) {
    return SpriteAnimation.fromFrameData(
        game.images.fromCache('Main Characters/$state (96x96).png'),
        SpriteAnimationData.sequenced(
          amount: amount,
          stepTime: steptime,
          textureSize: Vector2.all(96),
          loop: false,
        ));
  }

  void _updatePlayerMovement({required double deltaTime}) {
    //Checking if already jumping to prevent from jumping again (NOT WORKING PROPERLY)
    if (hasJumbed && isOnGround) _playerJump(deltaTime);
    //Preventing from jumping before reaching ground
    if (velocity.y > _gravity) isOnGround = false;
    velocity.x = horizontalMovement * moveSpeed;
    position.x += velocity.x * deltaTime;
  }

  void _playerJump(dt) {
    if (game.playSounds) FlameAudio.play('jump.wav', volume: game.soundVolume);
    velocity.y = -_jumpForce;
    position.y += velocity.y * dt;
    hasJumbed = false;
    isOnGround = false;
  }

  void _updatePlayerState() {
    PlayerState playerState = PlayerState.idle;
    // scale is used for Flip,  to check if we are looking to the opposite direction while moving in another direction
    if (velocity.x < 0 && scale.x > 0) {
      flipHorizontallyAroundCenter();
    } else if (velocity.x > 0 && scale.x < 0) {
      flipHorizontallyAroundCenter();
    }
    // Check if moving , set running
    if (velocity.x > 0 || velocity.x < 0) playerState = PlayerState.running;

    //Check if falling , set to falling
    if (velocity.y > 0) playerState = PlayerState.falling;
    //Check if jumping , set to jumping
    if (velocity.y < 0) playerState = PlayerState.jumping;

    current = playerState;
  }

  void _checkHorizontalCollision() {
    for (final block in collisionBlocks) {
      if (!block.isPlatform) {
        if (checkCollision(player: this, block: block)) {
          if (velocity.x > 0) {
            velocity.x = 0;
            position.x = block.x - hitbox.offsetX - hitbox.width;
            break;
          }
          if (velocity.x < 0) {
            velocity.x = 0;
            position.x = block.x + block.width + hitbox.width + hitbox.offsetX;
            break;
          }
        }
      }
    }
  }

  void _applyGravity(double dt) {
    velocity.y += _gravity;
    velocity.y = velocity.y.clamp(-_jumpForce, _terminalVelocity);
    position.y += velocity.y * dt;
  }

  void _checkVerticalCollisions() {
    for (final block in collisionBlocks) {
      //In platform user can stand
      if (checkCollision(player: this, block: block)) {
        if (velocity.y > 0) {
          velocity.y = 0;
          position.y = block.y - hitbox.height - hitbox.offsetY;
          isOnGround = true;
          break;
        }
      }
      if (block.isPlatform) {
      } else {
        if (checkCollision(player: this, block: block)) {
          if (velocity.y > 0) {
            velocity.y = 0;
            position.y = block.y - hitbox.height - hitbox.offsetY;
            isOnGround = true;
            break;
          }
          // jumping up
          if (velocity.y < 0) {
            velocity.y = 0;
            position.y = block.y + block.height - hitbox.offsetY;
          }
        }
      }
    }
  }

  void _respawn() async {
    if (game.playSounds) FlameAudio.play('hit.wav', volume: game.soundVolume);

    gotHit = true;
    current = PlayerState.hit;
    await animationTicker?.completed;
    animationTicker?.reset();
    scale.x = 1;
    position = startingPosition -
        Vector2.all(96 -
            64); // Size of appearing image is 96 so need to subtract offset to get to the starting pos
    current = PlayerState.appearing;

    await animationTicker?.completed;
    animationTicker?.reset();
    velocity = Vector2.zero();
    position = startingPosition;
    _updatePlayerState();
    const canMoveDuration = Duration(milliseconds: 350);
    Future.delayed(canMoveDuration, () => gotHit = false);
  }

  void _reachedCheckpoint() async {
    if (game.playSounds) {
      FlameAudio.play('disappear.wav', volume: game.soundVolume);
    }

    reachedCheckpoint = true;
    if (scale.x > 0) {
      position = position - Vector2.all(32);
    } else if (scale.x < 0) {
      position = position - Vector2(32, -32);
    }
    current = PlayerState.disappearing;
    await animationTicker?.completed;
    animationTicker?.reset();
    reachedCheckpoint = false;
    position = Vector2.all(-640);

    const waitToChangeDuration = Duration(seconds: 3);
    Future.delayed(waitToChangeDuration, () => game.loadNextLevel());
  }

  void collidedWithEnemy() => _respawn();
}
