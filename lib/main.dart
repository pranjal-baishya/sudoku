import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math';
import 'dart:async'; // Import async for Timer

void main() {
  runApp(MyApp());
}

enum Difficulty {
  easy,
  medium,
  hard,
  expert,
  master, // Added from image
  extreme, // Added from image
}

// Map difficulty to number of cells to remove
final Map<Difficulty, int> difficultyCellsToRemove = {
  Difficulty.easy: 35, // Fewer removed = easier
  Difficulty.medium: 45,
  Difficulty.hard: 50,
  Difficulty.expert: 55,
  Difficulty.master: 60,
  Difficulty.extreme: 64, // Very few clues
};

class SudokuGenerator {
  static Map<String, List<List<int>>> generateSudoku({int cellsToRemove = 45}) {
    List<List<int>> board = List.generate(9, (i) => List.generate(9, (j) => 0));
    _fillBoard(board);
    List<List<int>> solvedBoard = List.generate(9, (i) => List.from(board[i]));
    _removeNumbers(board, cellsToRemove);
    return {'puzzle': board, 'solution': solvedBoard};
  }

  static bool _fillBoard(List<List<int>> board) {
    for (int row = 0; row < 9; row++) {
      for (int col = 0; col < 9; col++) {
        if (board[row][col] == 0) {
          List<int> numbers = List.generate(9, (i) => i + 1);
          numbers.shuffle(Random());

          for (int num in numbers) {
            if (_isValid(board, row, col, num)) {
              board[row][col] = num;
              if (_fillBoard(board)) return true;
              board[row][col] = 0;
            }
          }
          return false;
        }
      }
    }
    return true;
  }

  static void _removeNumbers(List<List<int>> board, int cellsToRemove) {
    Random random = Random();
    // Use the passed count
    // int cellsToRemove = 45; // Adjust difficulty by changing this number

    // Make sure we don't try to remove more cells than possible while leaving a unique solution
    // (Advanced: Ensure unique solution check would go here)
    // For now, just cap removal count reasonably. 64 is a common max.
    int currentFilledCells =
        board.expand((row) => row).where((cell) => cell != 0).length;
    int maxRemovable =
        currentFilledCells -
        17; // Ensure at least 17 clues remain (common minimum)
    cellsToRemove = min(cellsToRemove, maxRemovable);
    cellsToRemove = max(0, cellsToRemove); // Ensure non-negative

    int removedCount = 0;
    // Add a safety break to prevent infinite loops if something goes wrong
    int safetyBreak = 0;
    int maxAttempts = 81 * 3; // Try roughly 3 times per cell

    while (removedCount < cellsToRemove && safetyBreak < maxAttempts) {
      int row = random.nextInt(9);
      int col = random.nextInt(9);
      if (board[row][col] != 0) {
        // Advanced: Check if removing this cell maintains a unique solution
        // For simplicity, we skip this check for now.
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

  static bool isValidMove(List<List<int>> board, int row, int col, int num) {
    // Check row
    for (int x = 0; x < 9; x++) {
      if (x != col && board[row][x] == num) return false;
    }

    // Check column
    for (int x = 0; x < 9; x++) {
      if (x != row && board[x][col] == num) return false;
    }

    // Check 3x3 box
    int startRow = row - row % 3;
    int startCol = col - col % 3;
    for (int i = 0; i < 3; i++) {
      for (int j = 0; j < 3; j++) {
        int currentRow = i + startRow;
        int currentCol = j + startCol;
        if (currentRow != row &&
            currentCol != col &&
            board[currentRow][currentCol] == num)
          return false;
      }
    }

    return true;
  }

  static bool isSolved(List<List<int>> board) {
    for (int i = 0; i < 9; i++) {
      for (int j = 0; j < 9; j++) {
        if (board[i][j] == 0) return false;
        if (!isValidMove(board, i, j, board[i][j])) return false;
      }
    }
    return true;
  }
}

// Add this class definition somewhere, e.g., before SudokuProvider
class Move {
  final int row;
  final int col;
  final int oldValue;
  final int newValue;
  final bool
  wasIncorrectBefore; // Track if the cell was incorrect before this move
  final bool becameIncorrect; // Track if this move made the cell incorrect

  Move({
    required this.row,
    required this.col,
    required this.oldValue,
    required this.newValue,
    required this.wasIncorrectBefore,
    required this.becameIncorrect,
  });
}

class SudokuProvider extends ChangeNotifier {
  List<List<int>> currentBoard = List.generate(
    9,
    (i) => List.generate(9, (j) => 0),
  );
  List<List<int>> initialBoard = List.generate(
    9,
    (i) => List.generate(9, (j) => 0),
  );
  List<List<int>> solvedBoard = List.generate(
    9,
    (i) => List.generate(9, (j) => 0),
  );
  bool isComplete = false;
  int? selectedRow;
  int? selectedCol;

  // Add state for mistakes
  int mistakes = 0;
  final int maxMistakes = 3; // Set the maximum allowed mistakes

  // Add state to track cells with incorrect values
  Set<String> incorrectCells = {}; // Store as "row,col" strings

  // History stack for undo
  List<Move> _moveHistory = [];

  // State for notes
  List<List<Set<int>>> notesBoard = List.generate(
    9,
    (i) => List.generate(9, (j) => <int>{}),
  );
  bool isNotesMode = false;

  // State for Hints
  int hintsUsed = 0;
  final int maxHints = 3; // Example limit

  // State for Difficulty
  Difficulty currentDifficulty = Difficulty.medium; // Default difficulty

  SudokuProvider() {
    generateNewSudoku();
  }

  void generateNewSudoku() {
    // Get cells to remove based on current difficulty
    int cellsToRemove = difficultyCellsToRemove[currentDifficulty] ?? 45;
    final generated = SudokuGenerator.generateSudoku(
      cellsToRemove: cellsToRemove,
    );
    initialBoard = generated['puzzle']!;
    currentBoard = List.generate(9, (i) => List.from(initialBoard[i]));
    solvedBoard = generated['solution']!;
    isComplete = false;
    selectedRow = null;
    selectedCol = null;
    mistakes = 0;
    incorrectCells.clear();
    _moveHistory.clear(); // Clear history on new game
    isNotesMode = false; // Reset notes mode
    // Reset notes board
    notesBoard = List.generate(9, (i) => List.generate(9, (j) => <int>{}));
    hintsUsed = 0; // Reset hints used
    notifyListeners();
    // TODO: Restart timer here
  }

  void selectCell(int row, int col) {
    if (selectedRow == row && selectedCol == col) {
      // Optional: Deselect if tapping the same cell again
      // selectedRow = null;
      // selectedCol = null;
    } else {
      selectedRow = row;
      selectedCol = col;
    }
    notifyListeners();
  }

  @override
  void updateCell(int row, int col, int value) {
    if (isComplete || mistakes >= maxMistakes || initialBoard[row][col] != 0)
      return;

    int oldValue = currentBoard[row][col];
    // Don't record a move if the value didn't change
    if (oldValue == value) return;

    String cellKey = "$row,$col";
    bool wasIncorrect = incorrectCells.contains(cellKey);
    bool becomesIncorrect = false;

    // Check correctness and update mistakes/incorrectCells
    if (solvedBoard[row][col] != value) {
      if (!wasIncorrect) {
        // Only increment mistake if it wasn't already wrong
        mistakes++;
      }
      incorrectCells.add(cellKey);
      becomesIncorrect = true;
      if (mistakes >= maxMistakes) {
        print("Game Over - Too many mistakes!");
        // Don't proceed further if game over
      }
    } else {
      // Correct value entered
      if (wasIncorrect) {
        // If it was previously incorrect, remove the mark.
        // Don't decrement mistakes here, as mistakes usually count permanent errors.
        incorrectCells.remove(cellKey);
      }
    }

    // Record the move *before* updating the board
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

    // Clear notes when a final value is placed
    if (initialBoard[row][col] == 0 && solvedBoard[row][col] == value) {
      // Only clear notes if correct value is placed
      notesBoard[row][col].clear();
    }

    currentBoard[row][col] = value;
    isComplete = SudokuGenerator.isSolved(currentBoard);
    notifyListeners(); // Notify listeners AFTER clearing notes
  }

  @override
  void eraseCell() {
    if (selectedRow != null && selectedCol != null) {
      int row = selectedRow!;
      int col = selectedCol!;
      int oldValue = currentBoard[row][col];

      // Only erase non-initial cells that actually have a value
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

      // Revert incorrect status and mistakes
      String cellKey = "${lastMove.row},${lastMove.col}";
      if (lastMove.becameIncorrect && !lastMove.wasIncorrectBefore) {
        // This move caused a new mistake, so decrement mistakes
        mistakes--;
        incorrectCells.remove(cellKey); // Should have been added, so remove
      } else if (!lastMove.becameIncorrect && lastMove.wasIncorrectBefore) {
        // This move corrected a mistake (or was correct on a previously incorrect cell),
        // so restore the incorrect mark. Do not adjust mistakes count.
        incorrectCells.add(cellKey);
      } else if (lastMove.wasIncorrectBefore) {
        // If it was incorrect before and after (or erased while incorrect), ensure it's still marked incorrect
        incorrectCells.add(cellKey);
      } else {
        // If it was correct before and after (or erased while correct), ensure mark is removed
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

  List<Move> get moveHistory =>
      List.unmodifiable(_moveHistory); // Read-only view

  // Toggle notes mode
  void toggleNotesMode() {
    isNotesMode = !isNotesMode;
    notifyListeners();
  }

  // Add/Remove Note
  void updateNote(int row, int col, int number) {
    if (isComplete || mistakes >= maxMistakes || initialBoard[row][col] != 0)
      return;
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

  void _startTimer() {
    _timer?.cancel(); // Cancel any existing timer
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      // Check if the game provider still exists and if the game is not complete/over
      final provider = Provider.of<SudokuProvider>(context, listen: false);
      if (mounted &&
          !provider.isComplete &&
          provider.mistakes < provider.maxMistakes) {
        setState(() {
          _elapsedTime = _elapsedTime + Duration(seconds: 1);
        });
      } else {
        timer.cancel(); // Stop timer if game ends or widget is unmounted
      }
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

  @override
  Widget build(BuildContext context) {
    // Access provider within build method
    final provider = Provider.of<SudokuProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text("Sudoku Game"),
        actions: [
          if (provider.isComplete)
            Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: Icon(Icons.check_circle, color: Colors.green, size: 30),
            ),
          // Optional: Display Game Over indicator
          if (!provider.isComplete && provider.mistakes >= provider.maxMistakes)
            Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: Icon(Icons.cancel, color: Colors.red, size: 30),
            ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
              vertical: 8.0,
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
            child: AspectRatio(
              aspectRatio: 1.0,
              child: Container(
                padding: const EdgeInsets.all(8.0),
                child: GridView.builder(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
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
                    bool isIncorrect = provider.isIncorrectCell(row, col);

                    // Check for same number highlight (only if the cell is not empty)
                    bool isSameNumber = false;
                    int? selectedValue =
                        (provider.selectedRow != null &&
                                provider.selectedCol != null)
                            ? provider.currentBoard[provider
                                .selectedRow!][provider.selectedCol!]
                            : 0;
                    if (selectedValue != 0 &&
                        provider.currentBoard[row][col] == selectedValue) {
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
                                  ? Colors.blue.shade100
                                  : isRelated
                                  ? Colors.lightBlue.shade50
                                  : isInitial
                                  ? Colors.grey.shade300
                                  : Colors.white,
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
          ),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                  icon: Icon(Icons.undo),
                  // Disable if history is empty
                  onPressed: provider.undoLastMove, // Call the provider method
                  tooltip: "Undo",
                  iconSize: 30,
                  color:
                      provider.moveHistory.isNotEmpty
                          ? Theme.of(context).primaryColor
                          : Colors.grey, // Visual cue
                ),
                // Wire up Erase button
                IconButton(
                  icon: Icon(Icons.edit_off),
                  onPressed: provider.eraseCell, // Call the provider method
                  tooltip: "Erase",
                  iconSize: 30,
                ),
                IconButton(
                  icon: Icon(
                    provider.isNotesMode ? Icons.edit_note : Icons.edit,
                  ),
                  onPressed: provider.toggleNotesMode,
                  tooltip: "Notes (${provider.isNotesMode ? 'On' : 'Off'})",
                  iconSize: 30,
                  color:
                      provider.isNotesMode
                          ? Theme.of(context).colorScheme.secondary
                          : null,
                ),
                Badge(
                  // Add a Badge for hint count
                  label: Text('${provider.maxHints - provider.hintsUsed}'),
                  isLabelVisible:
                      provider.hintsUsed < provider.maxHints &&
                      !provider.isComplete,
                  child: IconButton(
                    icon: Icon(Icons.lightbulb_outline),
                    onPressed: provider.useHint, // Call the provider method
                    tooltip:
                        "Hint (${provider.maxHints - provider.hintsUsed} left)",
                    iconSize: 30,
                    color:
                        (provider.hintsUsed >= provider.maxHints ||
                                provider.isComplete)
                            ? Colors.grey
                            : null, // Disable visually
                  ),
                ),
              ],
            ),
          ),
          NumberInputPad(
            onNumberSelected: (number) {
              if (provider.selectedRow != null &&
                  provider.selectedCol != null) {
                // Check if notes mode is active
                if (provider.isNotesMode) {
                  provider.updateNote(
                    provider.selectedRow!,
                    provider.selectedCol!,
                    number,
                  );
                } else {
                  // Otherwise, update the cell value as before
                  provider.updateCell(
                    provider.selectedRow!,
                    provider.selectedCol!,
                    number,
                  );
                }
              }
            },
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Display Game Over message instead of Solved if applicable
                if (!provider.isComplete &&
                    provider.mistakes >= provider.maxMistakes)
                  Text(
                    "Game Over!",
                    style: TextStyle(
                      color: Colors.red,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                else if (provider.isComplete)
                  Text(
                    "Puzzle Solved!",
                    style: TextStyle(
                      color: Colors.green,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                else
                  Container(width: 100), // Placeholder to maintain spacing

                ElevatedButton(
                  // Reset and start timer on New Game
                  onPressed: () {
                    provider.generateNewSudoku();
                    _resetAndStartTimer(); // Call the state method
                  },
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                  ),
                  child: Text("New Game", style: TextStyle(fontSize: 16)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  bool _isRelated(SudokuProvider provider, int row, int col) {
    if (provider.selectedRow == null || provider.selectedCol == null)
      return false;
    // Don't highlight self as related
    if (row == provider.selectedRow && col == provider.selectedCol)
      return false;

    // Check row or column match
    if (row == provider.selectedRow || col == provider.selectedCol) return true;

    // Check 3x3 block match
    int startRow = provider.selectedRow! - provider.selectedRow! % 3;
    int startCol = provider.selectedCol! - provider.selectedCol! % 3;
    if (row >= startRow &&
        row < startRow + 3 &&
        col >= startCol &&
        col < startCol + 3)
      return true;

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

  const NumberInputPad({Key? key, required this.onNumberSelected})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: GridView.builder(
        shrinkWrap: true,
        physics: NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 5,
          childAspectRatio: 1.2,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
        ),
        itemCount: 9,
        itemBuilder: (context, index) {
          final number = index + 1;
          return ElevatedButton(
            onPressed: () => onNumberSelected(number),
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.zero,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              '$number',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          );
        },
      ),
    );
  }
}
