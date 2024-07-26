import 'dart:async';
import 'dart:developer';

import 'package:flame/components.dart';
import 'package:flame_test/components/background_tile.dart';
import 'package:flame_test/components/checkpoint.dart';
import 'package:flame_test/components/chicken.dart';
import 'package:flame_test/components/collision_block.dart';
import 'package:flame_test/components/fruits.dart';
import 'package:flame_test/components/player.dart';
import 'package:flame_test/components/saw.dart';
import 'package:flame_test/pixel_adventure.dart';
import 'package:flame_tiled/flame_tiled.dart';

class Level extends World with HasGameRef<PixelAdventure> {
  final String levelName;
  final Player player;
  late TiledComponent level;
  Level({required this.levelName, required this.player});

  final List<CollisionBlock> collistionBlock = [];

  @override
  FutureOr<void> onLoad() async {
    try {
      level = await TiledComponent.load('$levelName.tmx', Vector2.all(16));
    } catch (e) {
      log(e.toString());
    }
    //adding to the game
    add(level);
    _scrollingBackground();
    _spawningObject();
    _addCollisions();
    /*Finding the layer for the character named spawnpoints from the map, then loop through the layer
    till finding the class here Player and add the player to that point [we have to pass the positon to place it exactly at the specified point]
*/

    return super.onLoad();
  }

  void _scrollingBackground() {
    final backgroundLayer = level.tileMap.getLayer('Background');
    if (backgroundLayer != null) {
      final backgroundColor =
          backgroundLayer.properties.getValue('BackgroundColor');
      final backgroundTile = BackgroundTile(
          //one tilesize is subtracted to add the scrolllig efffect
          color: backgroundColor ?? 'Gray',
          position: Vector2(0, 0));
      add(backgroundTile);
    }
  }

  void _spawningObject() {
    final spawnPointLayer = level.tileMap.getLayer<ObjectGroup>('Spawnpoints');
    if (spawnPointLayer != null) {
      for (final spawnPoint in spawnPointLayer.objects) {
        switch (spawnPoint.class_) {
          case 'Player':
            player.position = Vector2(spawnPoint.x, spawnPoint.y);
            player.scale.x = 1;
            add(player);
            break;

          case 'Fruits':
            final fruit = Fruit(
              fruit: spawnPoint.name,
              position: Vector2(spawnPoint.x, spawnPoint.y),
              size: Vector2(spawnPoint.width, spawnPoint.height),
            );

            add(fruit);
            break;
          case 'Saw':
            final isVertical = spawnPoint.properties.getValue('vertical');
            final offNeg = spawnPoint.properties.getValue('offNeg');
            final offPos = spawnPoint.properties.getValue('offPos');

            final saw = Saw(
              isVertical: isVertical,
              offNeg: offNeg,
              offPos: offPos,
              position: Vector2(spawnPoint.x, spawnPoint.y),
              size: Vector2(spawnPoint.width, spawnPoint.height),
            );
            add(saw);
            break;

          case 'Checkpoint':
            final checkpoint = Checkpoint(
              position: Vector2(spawnPoint.x, spawnPoint.y),
              size: Vector2(spawnPoint.width, spawnPoint.height),
            );
            add(checkpoint);
            break;
          case 'Chicken':
            final offNeg = spawnPoint.properties.getValue('offNeg');
            final offPos = spawnPoint.properties.getValue('offPos');
            final chicken = Chicken(
              position: Vector2(spawnPoint.x, spawnPoint.y),
              size: Vector2(spawnPoint.width, spawnPoint.height),
              offNeg: offNeg,
              offPos: offPos,
            );
            add(chicken);
            break;
          default:
        }
      }
    }
  }

  void _addCollisions() {
    final collisionsLayer = level.tileMap.getLayer<ObjectGroup>('Collision');
    if (collisionsLayer != null) {
      for (final collision in collisionsLayer.objects) {
        switch (collision.class_) {
          case 'Platform':
            final platform = CollisionBlock(
                position: Vector2(collision.x, collision.y),
                size: Vector2(collision.width, collision.height),
                isPlatform: true);

            collistionBlock.add(platform);
            add(platform);
            break;
          default:
            final block = CollisionBlock(
              position: Vector2(collision.x, collision.y),
              size: Vector2(collision.width, collision.height),
            );
            collistionBlock.add(block);
            add(block);
        }
      }
    }
    player.collisionBlocks = collistionBlock;
  }
}
