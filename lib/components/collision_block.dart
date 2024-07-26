import 'package:flame/components.dart';

//Position component is to give position and also widht and height
class CollisionBlock extends PositionComponent {
  bool isPlatform;
  //position and size are required by the PostionComponent
  CollisionBlock({position, size, this.isPlatform = false})
      : super(position: position, size: size) {
    // debugMode = true;
  }
}
