import 'dart:math';
import 'package:flutter/material.dart';
import '../models/difficulty.dart';
import '../models/move.dart';
import '../utils/sudoku_generator.dart';

/// Manages the state of the Sudoku game using ChangeNotifier.
class SudokuProvider extends ChangeNotifier {
  /// The current state of the board being modified by the user.
  List<List<int>> currentBoard = List.generate(
    9,
    (i) => List.generate(9, (j) => 0),
  );

  /// The initial puzzle board state (read-only during gameplay).
  List<List<int>> initialBoard = List.generate(
    9,
    (i) => List.generate(9, (j) => 0),
  );

  /// The fully solved version of the current puzzle (for validation).
  List<List<int>> solvedBoard = List.generate(
    9,
    (i) => List.generate(9, (j) => 0),
  );

  /// Flag indicating if the puzzle has been successfully solved.
  bool isComplete = false;

  /// Currently selected row index (null if none selected).
  int? selectedRow;

  /// Currently selected column index (null if none selected).
  int? selectedCol;

  /// Number of mistakes made by the user.
  int mistakes = 0;

  /// Maximum number of mistakes allowed before game over.
  final int maxMistakes = 3;

  /// Set storing coordinates ("row,col") of cells currently marked as incorrect.
  Set<String> incorrectCells = {};

  /// History of moves made by the user for the Undo feature.
  final List<Move> _moveHistory = [];

  /// Public read-only view of the move history.
  List<Move> get moveHistory => List.unmodifiable(_moveHistory);

  /// Stores user-entered notes (pencil marks) for each cell.
  List<List<Set<int>>> notesBoard = List.generate(
    9,
    (i) => List.generate(9, (j) => <int>{}),
  );

  /// Flag indicating if the user is currently in "Notes" input mode.
  bool isNotesMode = false;

  /// Number of hints used by the user in the current game.
  int hintsUsed = 0;

  /// Maximum number of hints allowed per game.
  final int maxHints = 3;

  /// Currently selected game difficulty level.
  Difficulty currentDifficulty = Difficulty.medium;

  /// Initializes the provider and generates the first puzzle.
  SudokuProvider() {
    generateNewSudoku();
  }

  /// Generates a new Sudoku puzzle based on the [currentDifficulty].
  /// Resets all game state variables (mistakes, history, notes, hints, selection).
  void generateNewSudoku() {
    int cellsToRemove = difficultyCellsToRemove[currentDifficulty] ?? 45;
    final generated = SudokuGenerator.generateSudoku(
      cellsToRemove: cellsToRemove,
    );

    // Set up the boards
    initialBoard = generated['puzzle']!;
    currentBoard = List.generate(
      9,
      (i) => List.from(initialBoard[i]),
    ); // Deep copy
    solvedBoard = generated['solution']!;

    // Reset game state
    isComplete = false;
    selectedRow = null;
    selectedCol = null;
    mistakes = 0;
    incorrectCells.clear();
    _moveHistory.clear();
    isNotesMode = false;
    notesBoard = List.generate(
      9,
      (i) => List.generate(9, (j) => <int>{}),
    ); // Reset notes
    hintsUsed = 0;

    notifyListeners(); // Update UI
  }

  /// Updates the currently selected cell.
  void selectCell(int row, int col) {
    if (selectedRow == row && selectedCol == col) {
      // Optional: Deselect if tapping the same cell again (currently disabled)
    } else {
      selectedRow = row;
      selectedCol = col;
    }
    notifyListeners();
  }

  /// Updates the value of a cell if it's a valid move.
  /// Handles mistake counting, incorrect cell marking, move history, and note clearing.
  void updateCell(int row, int col, int value) {
    // Prevent updates if game is over, won, or cell is part of initial puzzle
    if (isComplete || mistakes >= maxMistakes || initialBoard[row][col] != 0) {
      return;
    }

    int oldValue = currentBoard[row][col];
    // Ignore if the value is the same as the current one
    if (oldValue == value) return;

    String cellKey = "$row,$col";
    bool wasIncorrect = incorrectCells.contains(cellKey);
    bool becomesIncorrect = false;

    // Check if the entered value is incorrect
    if (solvedBoard[row][col] != value) {
      // Only increment mistake count if the cell wasn't already marked incorrect
      if (!wasIncorrect) {
        mistakes++;
      }
      incorrectCells.add(cellKey); // Mark/keep marked as incorrect
      becomesIncorrect = true;
      if (mistakes >= maxMistakes) {
        print("Game Over - Too many mistakes!");
      }
    } else {
      // Correct value entered
      // If it was previously incorrect, remove the incorrect mark
      if (wasIncorrect) {
        incorrectCells.remove(cellKey);
      }
    }

    // Add the move to the history stack *before* changing the board state
    _moveHistory.add(
      Move(
        row: row,
        col: col,
        oldValue: oldValue,
        newValue: value,
        wasIncorrectBefore: wasIncorrect,
        becameIncorrect: becomesIncorrect,
      ),
    );

    // If a correct final value is placed, clear any notes in that cell
    if (initialBoard[row][col] == 0 && solvedBoard[row][col] == value) {
      notesBoard[row][col].clear();
    }

    // Update the board
    currentBoard[row][col] = value;
    // Check if the puzzle is now solved
    isComplete = SudokuGenerator.isSolved(currentBoard);
    notifyListeners(); // Update UI
  }

  /// Erases the value and notes from the currently selected cell, if applicable.
  /// Records the erasure as a move in the history.
  void eraseCell() {
    if (selectedRow != null && selectedCol != null) {
      int row = selectedRow!;
      int col = selectedCol!;
      int oldValue = currentBoard[row][col];

      // Can only erase non-initial cells that currently have a value
      if (initialBoard[row][col] == 0 && oldValue != 0) {
        String cellKey = "$row,$col";
        bool wasIncorrect = incorrectCells.contains(cellKey);

        // Record the move (erasing means newValue is 0)
        _moveHistory.add(
          Move(
            row: row,
            col: col,
            oldValue: oldValue,
            newValue: 0,
            wasIncorrectBefore: wasIncorrect,
            becameIncorrect: false, // Erasing never makes a cell incorrect
          ),
        );

        // Remove incorrect mark if it existed
        if (wasIncorrect) {
          incorrectCells.remove(cellKey);
          // Do NOT decrement mistakes when erasing an incorrect number
        }

        // Also clear notes when erasing
        notesBoard[row][col].clear();

        currentBoard[row][col] = 0; // Set to empty
        isComplete = false;
        notifyListeners();
      }
    }
  }

  // Method to undo the last move
  void undoLastMove() {
    if (_moveHistory.isNotEmpty) {
      Move lastMove = _moveHistory.removeLast();

      // Revert the board state
      currentBoard[lastMove.row][lastMove.col] = lastMove.oldValue;

      // Revert incorrect status but DON'T adjust the mistake count
      String cellKey = "${lastMove.row},${lastMove.col}";

      // Remove or add cell to incorrectCells as needed, but don't change mistake count
      if (lastMove.becameIncorrect && !lastMove.wasIncorrectBefore) {
        // The move made the cell incorrect, but DON'T decrement mistakes
        incorrectCells.remove(cellKey);
      } else if (!lastMove.becameIncorrect && lastMove.wasIncorrectBefore) {
        // The move fixed an incorrect cell, restore the incorrect mark
        incorrectCells.add(cellKey);
      } else if (lastMove.wasIncorrectBefore) {
        // If it was incorrect before, make sure it's still marked incorrect
        incorrectCells.add(cellKey);
      } else {
        // If it was correct before, make sure it's not marked incorrect
        incorrectCells.remove(cellKey);
      }

      isComplete = SudokuGenerator.isSolved(
        currentBoard,
      ); // Re-check completion
      notifyListeners();
    }
  }

  bool isInitialCell(int row, int col) {
    return initialBoard[row][col] != 0;
  }

  // Helper to check if a cell is marked as incorrect
  bool isIncorrectCell(int row, int col) {
    return incorrectCells.contains("$row,$col");
  }

  // Toggle notes mode
  void toggleNotesMode() {
    isNotesMode = !isNotesMode;
    notifyListeners();
  }

  // Add/Remove Note
  void updateNote(int row, int col, int number) {
    if (isComplete || mistakes >= maxMistakes || initialBoard[row][col] != 0) {
      return;
    }
    // Cannot add notes if a number is already placed
    if (currentBoard[row][col] != 0) return;

    final notes = notesBoard[row][col];
    if (notes.contains(number)) {
      notes.remove(number);
    } else {
      notes.add(number);
    }
    notifyListeners();
  }

  // Use a Hint
  void useHint() {
    if (isComplete || mistakes >= maxMistakes || hintsUsed >= maxHints) return;

    // Find a cell to reveal
    int? targetRow, targetCol;

    // Priority 1: Find an incorrect cell
    if (incorrectCells.isNotEmpty) {
      String cellKey = incorrectCells.first; // Get the first incorrect cell
      List<String> parts = cellKey.split(',');
      targetRow = int.parse(parts[0]);
      targetCol = int.parse(parts[1]);
    } else {
      // Priority 2: Find an empty, non-initial cell
      List<List<int>> possibleCells = [];
      for (int r = 0; r < 9; r++) {
        for (int c = 0; c < 9; c++) {
          if (currentBoard[r][c] == 0 && initialBoard[r][c] == 0) {
            possibleCells.add([r, c]);
          }
        }
      }

      if (possibleCells.isNotEmpty) {
        possibleCells.shuffle(Random()); // Pick a random empty cell
        targetRow = possibleCells[0][0];
        targetCol = possibleCells[0][1];
      }
    }

    // If a target cell was found
    if (targetRow != null && targetCol != null) {
      int correctValue = solvedBoard[targetRow][targetCol];
      int oldValue = currentBoard[targetRow][targetCol];

      // Check if the hint actually changes the board
      if (oldValue != correctValue) {
        String cellKey = "$targetRow,$targetCol";

        // Using a hint should not count as a mistake or fix one in terms of score
        // It just reveals the number.
        incorrectCells.remove(cellKey); // Remove incorrect mark if it existed

        // Update the cell value directly (don't use updateCell to avoid mistake logic/history)
        currentBoard[targetRow][targetCol] = correctValue;
        notesBoard[targetRow][targetCol].clear(); // Clear notes

        hintsUsed++;
        isComplete = SudokuGenerator.isSolved(
          currentBoard,
        ); // Re-check completion
        notifyListeners();
      } else {
        // Cell already had the correct value
        // Still consume the hint
        hintsUsed++;
        notifyListeners();
      }
    } else {
      // No suitable cell found (board might be correct or full)
      print("No cell found for hint.");
    }
  }

  // Method to change difficulty and start a new game
  void changeDifficulty(Difficulty newDifficulty) {
    if (newDifficulty != currentDifficulty) {
      currentDifficulty = newDifficulty;
      // Generate a new puzzle with the selected difficulty
      generateNewSudoku();
    }
  }
}
