# Flutter Sudoku Game

A functional Sudoku game application built with Flutter, featuring responsive design and comprehensive game mechanics.

## Features

*   **Responsive Design:**
    *   Optimized layout with a maximum width constraint (700px) for better display on larger screens.
    *   Centered content that scales appropriately across different device sizes.

*   **Dynamic Sudoku Generation:** Creates unique Sudoku puzzles with varying difficulty levels.

*   **Difficulty Levels:** Choose from multiple difficulty settings (Easy, Medium, Hard, Expert, Master, Extreme) which adjust the number of initial clues.

*   **Interactive Grid:**
    *   Tap to select cells.
    *   Visual highlighting for:
        *   Selected cell.
        *   Cells in the same row, column, and 3x3 block as the selected cell.
        *   Cells containing the same number as the selected cell.

*   **Game Status Overlays:**
    *   Pause screen with resume button when game is paused.
    *   Game Over overlay when the mistake limit is reached.
    *   Victory overlay when puzzle is successfully solved, displaying completion time.
    *   All overlays include direct "New Game" options.

*   **Number Input:** Enter numbers using a dedicated on-screen number pad (1-9).

*   **Mistake Tracking:**
    *   Tracks incorrect entries against the solved puzzle.
    *   Limited number of mistakes allowed (currently 3).
    *   Visual indication (red color) for incorrect cells/numbers.

*   **Notes Mode (Pencil Marks):**
    *   Toggle a "Notes" mode to enter small potential numbers (1-9) into empty cells.
    *   Notes are displayed visually within the cell.

*   **Undo:** Revert the last action (number input, erase, or note change).

*   **Erase:** Clear the user-entered number or notes from the selected cell.

*   **Hint System:**
    *   Reveal the correct number for an incorrect or empty cell.
    *   Limited number of hints available per game (currently 3).

*   **Game Timer:** 
    *   Tracks the time elapsed since starting the current puzzle.
    *   Timer pauses when game is paused.

*   **Pause Functionality:** 
    *   Temporarily hide the board and pause the timer.
    *   Resume gameplay from where you left off.

*   **State Management:** Uses the `provider` package for efficient state management across the application.

## How to Run

1.  Ensure you have the Flutter SDK installed.
2.  Clone the repository (if applicable).
3.  Navigate to the project directory.
4.  Run `flutter pub get` to install dependencies.
5.  Run `flutter run` to launch the application on a connected device or emulator.
