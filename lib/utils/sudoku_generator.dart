import 'dart:math';

/// Generates Sudoku puzzles and their solutions.
class SudokuGenerator {
  /// Generates a Sudoku puzzle map containing the 'puzzle' board and the 'solution' board.
  /// [cellsToRemove] determines the difficulty by specifying how many numbers to remove.
  static Map<String, List<List<int>>> generateSudoku({int cellsToRemove = 45}) {
    List<List<int>> board = List.generate(9, (i) => List.generate(9, (j) => 0));
    _fillBoard(board); // Generate a fully solved board
    // Keep a copy of the solved board
    List<List<int>> solvedBoard = List.generate(9, (i) => List.from(board[i]));
    // Remove numbers to create the puzzle
    _removeNumbers(board, cellsToRemove);
    return {'puzzle': board, 'solution': solvedBoard};
  }

  /// Recursive backtracking algorithm to fill the Sudoku board completely.
  static bool _fillBoard(List<List<int>> board) {
    for (int row = 0; row < 9; row++) {
      for (int col = 0; col < 9; col++) {
        if (board[row][col] == 0) {
          List<int> numbers = List.generate(9, (i) => i + 1)..shuffle(Random());
          for (int num in numbers) {
            if (_isValid(board, row, col, num)) {
              board[row][col] = num;
              if (_fillBoard(board)) return true; // Recurse
              board[row][col] = 0; // Backtrack
            }
          }
          return false; // No valid number found for this cell
        }
      }
    }
    return true; // Board is full
  }

  /// Removes a specified number of cells from a solved board to create a puzzle.
  /// Includes safety checks to avoid removing too many cells or getting stuck.
  static void _removeNumbers(List<List<int>> board, int cellsToRemove) {
    Random random = Random();

    // Cap the number of cells to remove to ensure a reasonable minimum number of clues (e.g., 17)
    int currentFilledCells =
        board.expand((row) => row).where((cell) => cell != 0).length;
    int maxRemovable = currentFilledCells - 17;
    cellsToRemove = min(cellsToRemove, maxRemovable);
    cellsToRemove = max(0, cellsToRemove);

    int removedCount = 0;
    int safetyBreak = 0;
    int maxAttempts =
        81 * 3; // Limit attempts to prevent potential infinite loops

    // Randomly remove cells until the target count is reached or max attempts exceeded
    while (removedCount < cellsToRemove && safetyBreak < maxAttempts) {
      int row = random.nextInt(9);
      int col = random.nextInt(9);
      if (board[row][col] != 0) {
        // Note: A more robust generator would check for unique solvability here.
        board[row][col] = 0;
        removedCount++;
      }
      safetyBreak++;
    }
    if (safetyBreak >= maxAttempts) {
      print(
        "Warning: Could not remove the desired number of cells ($cellsToRemove). Removed $removedCount.",
      );
    }
  }

  /// Checks if placing [num] at [row], [col] is valid during board generation.
  static bool _isValid(List<List<int>> board, int row, int col, int num) {
    // Check row
    for (int x = 0; x < 9; x++) {
      if (board[row][x] == num) return false;
    }
    // Check column
    for (int x = 0; x < 9; x++) {
      if (board[x][col] == num) return false;
    }
    // Check 3x3 box
    int startRow = row - row % 3;
    int startCol = col - col % 3;
    for (int i = 0; i < 3; i++) {
      for (int j = 0; j < 3; j++) {
        if (board[i + startRow][j + startCol] == num) return false;
      }
    }
    return true;
  }

  /// Checks if placing [num] at [row], [col] is a valid move according to Sudoku rules (ignoring the cell itself).
  static bool isValidMove(List<List<int>> board, int row, int col, int num) {
    // Check row (excluding the cell itself)
    for (int x = 0; x < 9; x++) {
      if (x != col && board[row][x] == num) return false;
    }
    // Check column (excluding the cell itself)
    for (int x = 0; x < 9; x++) {
      if (x != row && board[x][col] == num) return false;
    }
    // Check 3x3 box (excluding the cell itself)
    int startRow = row - row % 3;
    int startCol = col - col % 3;
    for (int i = 0; i < 3; i++) {
      for (int j = 0; j < 3; j++) {
        int currentRow = i + startRow;
        int currentCol = j + startCol;
        if (currentRow != row &&
            currentCol != col &&
            board[currentRow][currentCol] == num) {
          return false;
        }
      }
    }
    return true;
  }

  /// Checks if the given board represents a fully solved and valid Sudoku puzzle.
  static bool isSolved(List<List<int>> board) {
    for (int i = 0; i < 9; i++) {
      for (int j = 0; j < 9; j++) {
        // Check if any cell is empty
        if (board[i][j] == 0) return false;
        // Check if the number in the cell is valid according to Sudoku rules
        if (!isValidMove(board, i, j, board[i][j])) return false;
      }
    }
    return true; // All cells filled and valid
  }
}
