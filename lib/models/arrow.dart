import 'enums.dart';

class Arrow {
  final Direction direction;
  final int number; // Number displayed on the arrow
  double position = 0.0; // 0.0 = bottom, 1.0 = top target
  bool isHit = false;
  HitRating? hitRating;

  Arrow(this.direction, this.number);
}
