bool checkCollision({required player, required block}) {
  final hitbox = player.hitbox;
  final playerX = player.position.x+hitbox.offsetX;
  final playerY = player.position.y+hitbox.offsetY;
  final playerWidth = hitbox.width;
  final playerHeight = hitbox.height;

  final blockX = block.x;
  final blockY = block.y;
  final blockWidth = block.width;
  final blockHeight = block.height;
  //while moving left the player gets horizontally fliped which effects the axis
  // hitbox.offsetX*2 : the width space b/w 2 sides
  final fixedX = player.scale.x < 0 ? playerX -(hitbox.offsetX*2)- playerWidth : playerX;
  //while jumping  if the block is platform
  final fixedY = block.isPlatform ? playerY + playerHeight : playerY;
  return (fixedY < blockY + blockHeight &&
      fixedY + playerHeight > blockY &&
      fixedX < blockX + blockWidth &&
      fixedX + playerWidth > blockX);
}
