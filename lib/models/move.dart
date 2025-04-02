/// Represents a single user action (placing/erasing a number) for the Undo functionality.
class Move {
  final int row;
  final int col;
  final int oldValue; // Value before the move
  final int newValue; // Value after the move
  final bool
  wasIncorrectBefore; // Was the cell marked incorrect before this move?
  final bool
  becameIncorrect; // Did this move result in the cell being marked incorrect?

  Move({
    required this.row,
    required this.col,
    required this.oldValue,
    required this.newValue,
    required this.wasIncorrectBefore,
    required this.becameIncorrect,
  });
}
