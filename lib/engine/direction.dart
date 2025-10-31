enum Direction {
  up(0, -1, 'UP'),
  down(0, 1, 'DOWN'),
  left(-1, 0, 'LEFT'),
  right(1, 0, 'RIGHT');

  const Direction(this.dx, this.dy, this.label);

  final int dx;
  final int dy;
  final String label;

  bool isOpposite(Direction other) => dx + other.dx == 0 && dy + other.dy == 0;
}
