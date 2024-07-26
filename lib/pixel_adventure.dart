import 'dart:async';

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flame/input.dart';
import 'package:flame_test/components/jump_button.dart';
import 'package:flame_test/components/levels.dart';
import 'package:flame_test/components/player.dart';
import 'package:flutter/painting.dart';

//HasKeyboardHandlerComponents : We need the components to be handled by keyboard
//HasCollisionDetection : used for collision detection, classes which collide must have collision callbacks

class PixelAdventure extends FlameGame
    with HasKeyboardHandlerComponents, DragCallbacks, HasCollisionDetection {
  @override
  Color backgroundColor() => const Color(0xff211f30);
  final player = Player(character: 'Mask Dude');

  late CameraComponent cam;
  late final JoystickComponent joyStick;
  bool showControlls = false;
  bool playSounds = true;
  final List<String> levelNames = ['level_02', 'level_02'];
  int currentLevelIndex = 0;
  double soundVolume = 1.0;
  @override
  FutureOr<void> onLoad() async {
    //cache images
    await images.loadAllImages();

    _loadLevel();
    if (showControlls) {
      addJoyStick();
      add(JumpButton());
    }
    return super.onLoad();
  }

  @override
  void update(double dt) {
    if (showControlls) {
      _updateJoyStick();
    }
    super.update(dt);
  }

  void addJoyStick() {
    priority = 10;
    joyStick = JoystickComponent(
      priority: 1,
      knob: SpriteComponent(sprite: Sprite(images.fromCache('HUD/Knob.png'))),
      background:
          SpriteComponent(sprite: Sprite(images.fromCache('HUD/Joystick.png'))),
    );
    add(HudMarginComponent(
        children: [joyStick],
        margin: const EdgeInsets.only(left: 32, bottom: 32)));
  }

  void _updateJoyStick() {
    switch (joyStick.direction) {
      case JoystickDirection.left:
      case JoystickDirection.upLeft:
      case JoystickDirection.downLeft:
        player.horizontalMovement -= 1;
        break;
      case JoystickDirection.right:
      case JoystickDirection.upRight:
      case JoystickDirection.downRight:
        player.horizontalMovement += 1;
        break;
      default:
      // PlayerDirection.none;
    }
  }

  void loadNextLevel() {
    removeWhere((component) => component is Level);
    if (currentLevelIndex < levelNames.length - 1) {
      currentLevelIndex++;
      _loadLevel();
    } else {
      currentLevelIndex = 0;
      _loadLevel();
    }
  }

  void _loadLevel() {
    Future.delayed(const Duration(seconds: 1), () {
      Level world =
          Level(levelName: levelNames[currentLevelIndex], player: player);
      cam = CameraComponent.withFixedResolution(
          height: 360, width: 640, world: world);
      cam.viewfinder.anchor = Anchor.topLeft;
      addAll([cam, world]);
    });
  }
}
