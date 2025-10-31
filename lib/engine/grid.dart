import 'direction.dart';

class GridPosition {
  const GridPosition(this.x, this.y);

  final int x;
  final int y;

  GridPosition offset(Direction direction) =>
      GridPosition(x + direction.dx, y + direction.dy);

  @override
  bool operator ==(Object other) =>
      other is GridPosition && other.x == x && other.y == y;

  @override
  int get hashCode => Object.hash(x, y);
}
