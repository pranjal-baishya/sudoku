import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math';
import 'dart:async'; // Import async for Timer

void main() {
  runApp(MyApp());
}

// Enum defining the different difficulty levels
enum Difficulty { easy, medium, hard, expert, master, extreme }

// Maps each difficulty level to the number of cells to remove from the solved board
final Map<Difficulty, int> difficultyCellsToRemove = {
  Difficulty.easy: 35,
  Difficulty.medium: 45,
  Difficulty.hard: 50,
  Difficulty.expert: 55,
  Difficulty.master: 60,
  Difficulty.extreme: 64,
};

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

  /// Checks if placing [num] at [row], [col] is valid during board generation (doesn't check the 3x3 rule strictly yet).
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
  List<Move> _moveHistory = [];

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
        // Optionally trigger game over state change
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
        bool wasIncorrect = incorrectCells.contains(cellKey);

        // Using a hint should not count as a mistake or fix one in terms of score
        // It just reveals the number.
        incorrectCells.remove(cellKey); // Remove incorrect mark if it existed

        // Update the cell value directly (don't use updateCell to avoid mistake logic/history)
        currentBoard[targetRow][targetCol] = correctValue;
        notesBoard[targetRow][targetCol].clear(); // Clear notes

        // Don't add hint usage to undo history
        // We could potentially add a special "HintMove" if needed

        hintsUsed++;
        isComplete = SudokuGenerator.isSolved(
          currentBoard,
        ); // Re-check completion
        notifyListeners();
      } else {
        // Cell already had the correct value (e.g., user guessed right on an incorrect cell before hitting hint)
        // Still consume the hint
        hintsUsed++;
        notifyListeners();
      }
    } else {
      // No suitable cell found (board might be correct or full)
      print("No cell found for hint.");
      // Optionally show a message to the user
    }
  }

  // Method to change difficulty and start a new game
  void changeDifficulty(Difficulty newDifficulty) {
    if (newDifficulty != currentDifficulty) {
      currentDifficulty = newDifficulty;
      // Generate a new puzzle with the selected difficulty
      // This will automatically reset everything else via generateNewSudoku
      generateNewSudoku();
      // Timer reset needs to happen in the UI state that calls this
    }
  }
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => SudokuProvider(),
      child: MaterialApp(home: SudokuScreen()),
    );
  }
}

class SudokuScreen extends StatefulWidget {
  @override
  _SudokuScreenState createState() => _SudokuScreenState();
}

class _SudokuScreenState extends State<SudokuScreen> {
  Timer? _timer;
  Duration _elapsedTime = Duration.zero;

  // Add a boolean to track pause state
  bool _isPaused = false;

  @override
  void initState() {
    super.initState();
    // Start timer when the screen initializes
    _startTimer();

    // Optional: Listen to provider changes to restart timer on new game
    // This is slightly complex as initState runs before provider is fully ready sometimes.
    // A better approach might be to call _resetAndStartTimer from the New Game button action.
  }

  @override
  void dispose() {
    _stopTimer(); // Cancel timer when the screen is disposed
    super.dispose();
  }

  // Update the timer methods to handle pause state
  void _startTimer() {
    _timer?.cancel(); // Cancel any existing timer
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      // Check if the game provider still exists and if the game is not complete/over and not paused
      final provider = Provider.of<SudokuProvider>(context, listen: false);
      if (mounted &&
          !provider.isComplete &&
          provider.mistakes < provider.maxMistakes &&
          !_isPaused) {
        // Only increment if not paused
        setState(() {
          _elapsedTime = _elapsedTime + Duration(seconds: 1);
        });
      } else if (provider.isComplete ||
          provider.mistakes >= provider.maxMistakes) {
        timer.cancel(); // Stop timer if game ends
      }
      // If paused, timer still runs but doesn't increment _elapsedTime
    });
  }

  void _stopTimer() {
    _timer?.cancel();
  }

  void _resetAndStartTimer() {
    _stopTimer();
    setState(() {
      _elapsedTime = Duration.zero;
    });
    _startTimer();
  }

  // Helper to format duration to HH:MM:SS or MM:SS
  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    if (duration.inHours > 0) {
      return "${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds";
    } else {
      return "$twoDigitMinutes:$twoDigitSeconds";
    }
  }

  void _togglePause() {
    setState(() {
      _isPaused = !_isPaused;
    });
    // No need to stop/start timer, we just check _isPaused in the timer callback
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<SudokuProvider>(context);

    return Scaffold(
      appBar: AppBar(
        // Remove the title from here
        title: null,
        centerTitle: true,
        // Create an empty app bar (we'll add the title in the content below)
        automaticallyImplyLeading: false,
      ),
      body: Center(
        // Center everything horizontally
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 700, // Set maximum width to 700 logical pixels
          ),
          child: Column(
            children: [
              // Custom app bar content that respects the width constraint
              Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 12.0,
                  horizontal: 16.0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Game title
                    Text(
                      "Sudoku Game",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    // Action buttons (moved from the AppBar)
                    Row(
                      children: [
                        // Pause/Play button
                        IconButton(
                          icon: Icon(
                            _isPaused ? Icons.play_arrow : Icons.pause,
                          ),
                          onPressed: _togglePause,
                          tooltip: _isPaused ? "Resume" : "Pause",
                        ),

                        // Completion indicator
                        if (provider.isComplete)
                          Padding(
                            padding: const EdgeInsets.only(left: 8.0),
                            child: Icon(
                              Icons.check_circle,
                              color: Colors.green,
                              size: 30,
                            ),
                          ),

                        // Game over indicator
                        if (!provider.isComplete &&
                            provider.mistakes >= provider.maxMistakes)
                          Padding(
                            padding: const EdgeInsets.only(left: 8.0),
                            child: Icon(
                              Icons.cancel,
                              color: Colors.red,
                              size: 30,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),

              Divider(height: 1), // Add a divider for visual separation
              // Rest of your existing content
              Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 4.0,
                  horizontal: 16.0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Difficulty Dropdown
                    DropdownButton<Difficulty>(
                      value: provider.currentDifficulty,
                      items:
                          Difficulty.values.map((Difficulty difficulty) {
                            return DropdownMenuItem<Difficulty>(
                              value: difficulty,
                              // Capitalize the enum name for display
                              child: Text(
                                difficulty.name[0].toUpperCase() +
                                    difficulty.name.substring(1),
                              ),
                            );
                          }).toList(),
                      onChanged: (Difficulty? newValue) {
                        if (newValue != null) {
                          provider.changeDifficulty(newValue);
                          _resetAndStartTimer(); // Reset timer when difficulty changes
                        }
                      },
                      // Optional styling
                      underline: Container(
                        height: 2,
                        color: Theme.of(context).primaryColor,
                      ), // Example underline
                      style: TextStyle(fontSize: 16, color: Colors.black),
                      icon: Icon(
                        Icons.arrow_drop_down,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                    // Display Mistakes and Timer
                    Row(
                      children: [
                        Text(
                          "Mistakes: ${provider.mistakes}/${provider.maxMistakes}",
                          style: TextStyle(
                            fontSize: 16,
                            color:
                                provider.mistakes >= provider.maxMistakes
                                    ? Colors.red
                                    : Colors.black,
                            fontWeight:
                                provider.mistakes > 0
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                          ),
                        ),
                        SizedBox(width: 20), // Spacing
                        Icon(Icons.timer, size: 18),
                        SizedBox(width: 4),
                        Text(
                          _formatDuration(_elapsedTime), // Use formatted time
                          style: TextStyle(fontSize: 16, letterSpacing: 1.2),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(
                flex: 7,
                child: AspectRatio(
                  aspectRatio: 1.0,
                  child: Stack(
                    children: [
                      // Hide the grid completely when paused
                      Visibility(
                        visible: !_isPaused,
                        maintainState: true,
                        child: Container(
                          padding: const EdgeInsets.all(4.0),
                          child: GridView.builder(
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 9,
                                  childAspectRatio: 1,
                                ),
                            itemCount: 81,
                            itemBuilder: (context, index) {
                              int row = index ~/ 9;
                              int col = index % 9;
                              bool isInitial = provider.isInitialCell(row, col);
                              bool isSelected =
                                  provider.selectedRow == row &&
                                  provider.selectedCol == col;
                              bool isRelated = _isRelated(provider, row, col);
                              // Check if the cell is marked incorrect
                              bool isIncorrect = provider.isIncorrectCell(
                                row,
                                col,
                              );

                              // Check for same number highlight (only if the cell is not empty)
                              bool isSameNumber = false;
                              int? selectedValue =
                                  (provider.selectedRow != null &&
                                          provider.selectedCol != null)
                                      ? provider.currentBoard[provider
                                          .selectedRow!][provider.selectedCol!]
                                      : 0;
                              if (selectedValue != 0 &&
                                  provider.currentBoard[row][col] ==
                                      selectedValue) {
                                isSameNumber = true;
                              }

                              // Check for notes
                              Set<int> notes = provider.notesBoard[row][col];
                              bool hasNotes = notes.isNotEmpty;
                              int cellValue = provider.currentBoard[row][col];

                              return GestureDetector(
                                onTap: () {
                                  provider.selectCell(row, col);
                                },
                                child: Container(
                                  margin: EdgeInsets.all(0.5),
                                  decoration: BoxDecoration(
                                    border: Border(
                                      top: BorderSide(
                                        width: (row % 3 == 0) ? 1.5 : 0.5,
                                        color: Colors.black,
                                      ),
                                      left: BorderSide(
                                        width: (col % 3 == 0) ? 1.5 : 0.5,
                                        color: Colors.black,
                                      ),
                                      right: BorderSide(
                                        width: (col == 8) ? 1.5 : 0.5,
                                        color: Colors.black,
                                      ),
                                      bottom: BorderSide(
                                        width: (row == 8) ? 1.5 : 0.5,
                                        color: Colors.black,
                                      ),
                                    ),
                                    color:
                                        isIncorrect
                                            ? Colors
                                                .red
                                                .shade100 // Highlight incorrect cells
                                            : isSelected
                                            ? Colors
                                                .blue
                                                .shade100 // Selected cell
                                            : isRelated
                                            ? isInitial
                                                ? Colors
                                                    .blueGrey
                                                    .shade200 // Related INITIAL cells
                                                : Colors
                                                    .lightBlue
                                                    .shade50 // Related USER cells
                                            : isInitial
                                            ? Colors
                                                .grey
                                                .shade300 // Normal initial cells
                                            : Colors
                                                .white, // Normal empty cells
                                  ),
                                  child: Center(
                                    child:
                                        cellValue != 0
                                            ? Text(
                                              cellValue.toString(),
                                              style: TextStyle(
                                                fontSize: 20,
                                                fontWeight: FontWeight.bold,
                                                color:
                                                    isIncorrect
                                                        ? Colors.red.shade700
                                                        : isSameNumber &&
                                                            !isSelected &&
                                                            !isInitial
                                                        ? Colors.blue.shade700
                                                        : isInitial
                                                        ? Colors.black
                                                        : Colors.blue.shade900,
                                              ),
                                            )
                                            : hasNotes // Display notes if cell is empty and notes exist
                                            ? _buildNotesWidget(
                                              notes,
                                            ) // Use helper widget
                                            : Container(), // Empty container if no number and no notes
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),

                      // Pause overlay
                      if (_isPaused)
                        Container(
                          color: Colors.black, // Black background
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.pause_circle_outline,
                                  color: Colors.white,
                                  size: 70,
                                ),
                                SizedBox(height: 24),
                                Text(
                                  "GAME PAUSED",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.5,
                                  ),
                                ),
                                SizedBox(height: 16),
                                ElevatedButton.icon(
                                  icon: Icon(Icons.play_arrow),
                                  label: Text("RESUME GAME"),
                                  onPressed: _togglePause,
                                  style: ElevatedButton.styleFrom(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 24,
                                      vertical: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                      // Game Over overlay
                      if (!_isPaused &&
                          !provider.isComplete &&
                          provider.mistakes >= provider.maxMistakes)
                        Container(
                          color: Colors.red.withOpacity(0.9),
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.error_outline,
                                  color: Colors.white,
                                  size: 70,
                                ),
                                SizedBox(height: 24),
                                Text(
                                  "GAME OVER",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.5,
                                  ),
                                ),
                                SizedBox(height: 16),
                                Text(
                                  "Too many mistakes!",
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.8),
                                    fontSize: 18,
                                  ),
                                ),
                                SizedBox(height: 24),
                                ElevatedButton.icon(
                                  icon: Icon(Icons.refresh),
                                  label: Text("NEW GAME"),
                                  onPressed: () {
                                    provider.generateNewSudoku();
                                    _resetAndStartTimer();
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    foregroundColor: Colors.red.shade800,
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 24,
                                      vertical: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                      // Puzzle Solved overlay
                      if (!_isPaused && provider.isComplete)
                        Container(
                          color: Colors.green.withOpacity(0.9),
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.emoji_events,
                                  color: Colors.white,
                                  size: 70,
                                ),
                                SizedBox(height: 24),
                                Text(
                                  "PUZZLE SOLVED!",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.5,
                                  ),
                                ),
                                Text(
                                  "Difficulty: ${provider.currentDifficulty.name}",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.5,
                                  ),
                                ),
                                SizedBox(height: 16),
                                Text(
                                  "Time: ${_formatDuration(_elapsedTime)}",
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.8),
                                    fontSize: 18,
                                  ),
                                ),
                                SizedBox(height: 24),
                                ElevatedButton.icon(
                                  icon: Icon(Icons.refresh),
                                  label: Text("NEW GAME"),
                                  onPressed: () {
                                    provider.generateNewSudoku();
                                    _resetAndStartTimer();
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    foregroundColor: Colors.green.shade800,
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 24,
                                      vertical: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              Expanded(
                flex: 1,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8.0,
                    vertical: 4.0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      IconButton(
                        icon: Icon(Icons.undo),
                        onPressed: _isPaused ? null : provider.undoLastMove,
                        tooltip: "Undo",
                        iconSize: 24,
                        color:
                            _isPaused
                                ? Colors.grey
                                : provider.moveHistory.isNotEmpty
                                ? Theme.of(context).primaryColor
                                : Colors.grey,
                      ),
                      // Wire up Erase button
                      IconButton(
                        icon: Icon(Icons.edit_off),
                        onPressed: _isPaused ? null : provider.eraseCell,
                        tooltip: "Erase",
                        iconSize: 24,
                        color: _isPaused ? Colors.grey : null,
                      ),
                      IconButton(
                        icon: Icon(
                          provider.isNotesMode ? Icons.edit_note : Icons.edit,
                        ),
                        onPressed: _isPaused ? null : provider.toggleNotesMode,
                        tooltip:
                            "Notes (${provider.isNotesMode ? 'On' : 'Off'})",
                        iconSize: 24,
                        color:
                            _isPaused
                                ? Colors.grey
                                : provider.isNotesMode
                                ? Theme.of(context).colorScheme.secondary
                                : null,
                      ),
                      Badge(
                        label: Text(
                          '${provider.maxHints - provider.hintsUsed}',
                          style: TextStyle(fontSize: 10),
                        ),
                        isLabelVisible:
                            provider.hintsUsed < provider.maxHints &&
                            !provider.isComplete &&
                            !_isPaused,
                        child: IconButton(
                          icon: Icon(Icons.lightbulb_outline),
                          onPressed: _isPaused ? null : provider.useHint,
                          tooltip:
                              "Hint (${provider.maxHints - provider.hintsUsed} left)",
                          iconSize: 24,
                          color:
                              _isPaused ||
                                      provider.hintsUsed >= provider.maxHints ||
                                      provider.isComplete
                                  ? Colors.grey
                                  : null,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                flex: 1,
                child: NumberInputPad(
                  isDisabled: _isPaused, // Pass pause state to NumberInputPad
                  onNumberSelected: (number) {
                    if (_isPaused) return; // Prevent input when paused

                    if (provider.selectedRow != null &&
                        provider.selectedCol != null) {
                      if (provider.isNotesMode) {
                        provider.updateNote(
                          provider.selectedRow!,
                          provider.selectedCol!,
                          number,
                        );
                      } else {
                        provider.updateCell(
                          provider.selectedRow!,
                          provider.selectedCol!,
                          number,
                        );
                      }
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool _isRelated(SudokuProvider provider, int row, int col) {
    if (provider.selectedRow == null || provider.selectedCol == null) {
      return false;
    }
    // Don't highlight self as related
    if (row == provider.selectedRow && col == provider.selectedCol) {
      return false;
    }

    // Check row or column match
    if (row == provider.selectedRow || col == provider.selectedCol) return true;

    // Check 3x3 block match
    int startRow = provider.selectedRow! - provider.selectedRow! % 3;
    int startCol = provider.selectedCol! - provider.selectedCol! % 3;
    if (row >= startRow &&
        row < startRow + 3 &&
        col >= startCol &&
        col < startCol + 3) {
      return true;
    }

    return false;
  }

  // Helper widget to display notes within a cell
  Widget _buildNotesWidget(Set<int> notes) {
    List<int> sortedNotes = notes.toList()..sort();
    // Simple text display for now, can be replaced with a mini-grid
    return Text(
      sortedNotes.join(' '), // Join numbers with space
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: 10, // Smaller font size for notes
        color: Colors.grey.shade700,
      ),
      maxLines: 2, // Limit lines if too many notes
      overflow: TextOverflow.ellipsis, // Handle overflow
    );

    /* // Alternative: Mini-Grid Display (more complex)
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero, // Remove padding
      mainAxisSpacing: 1,
      crossAxisSpacing: 1,
      childAspectRatio: 1, // Make cells square
      children: List.generate(9, (index) {
        final num = index + 1;
        return Center(
          child: Text(
            notes.contains(num) ? '$num' : '',
            style: TextStyle(
              fontSize: 8, // Very small font for mini-grid
              color: Colors.grey.shade700,
            ),
          ),
        );
      }),
    );
    */
  }
}

class NumberInputPad extends StatelessWidget {
  final Function(int) onNumberSelected;
  final bool isDisabled;

  const NumberInputPad({
    Key? key,
    required this.onNumberSelected,
    this.isDisabled = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: SizedBox(
        height: 120,
        child: GridView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 9,
            childAspectRatio: 1.0,
            crossAxisSpacing: 4,
            mainAxisSpacing: 4,
          ),
          itemCount: 9,
          itemBuilder: (context, index) {
            final number = index + 1;
            return ElevatedButton(
              onPressed: isDisabled ? null : () => onNumberSelected(number),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              child: Text(
                '$number',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            );
          },
        ),
      ),
    );
  }
}
