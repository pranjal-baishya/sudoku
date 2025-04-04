import 'package:flutter/material.dart';
import '../providers/sudoku_provider.dart';

class SudokuGrid extends StatelessWidget {
  final SudokuProvider provider;

  const SudokuGrid({super.key, required this.provider});

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDarkMode ? Colors.grey[600] : Colors.black;

    return Container(
      padding: const EdgeInsets.all(4.0),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 9,
          childAspectRatio: 1,
        ),
        itemCount: 81,
        itemBuilder: (context, index) {
          int row = index ~/ 9;
          int col = index % 9;
          bool isInitial = provider.isInitialCell(row, col);
          bool isSelected =
              provider.selectedRow == row && provider.selectedCol == col;
          bool isRelated = _isRelated(row, col);
          bool isIncorrect = provider.isIncorrectCell(row, col);

          // Check for same number highlight
          bool isSameNumber = false;
          int? selectedValue =
              (provider.selectedRow != null && provider.selectedCol != null)
                  ? provider.currentBoard[provider.selectedRow!]
                      [provider.selectedCol!]
                  : 0;
          if (selectedValue != 0 &&
              provider.currentBoard[row][col] == selectedValue) {
            isSameNumber = true;
          }

          // Check for notes
          Set<int> notes = provider.notesBoard[row][col];
          bool hasNotes = notes.isNotEmpty;
          int cellValue = provider.currentBoard[row][col];

          // Define colors based on theme
          Color cellBackground;
          Color textColor;

          if (isDarkMode) {
            // Dark theme colors
            if (isIncorrect) {
              cellBackground = Colors.red.shade900.withOpacity(0.4);
              textColor = Colors.red.shade300;
            } else if (isSelected) {
              cellBackground = Colors.blue.shade900.withOpacity(0.7);
              textColor = Colors.white;
            } else if (isRelated) {
              if (isInitial) {
                cellBackground = Colors.blueGrey.shade800;
                textColor = Colors.grey.shade300;
              } else {
                cellBackground = Colors.blue.shade900.withOpacity(0.3);
                textColor = Colors.blue.shade200;
              }
            } else if (isInitial) {
              cellBackground = Colors.grey.shade800;
              textColor = Colors.white;
            } else {
              cellBackground = Colors.grey.shade900;
              textColor =
                  isSameNumber ? Colors.blue.shade300 : Colors.blue.shade100;
            }
          } else {
            // Light theme colors
            if (isIncorrect) {
              cellBackground = Colors.red.shade100;
              textColor = Colors.red.shade700;
            } else if (isSelected) {
              cellBackground = Colors.blue.shade100;
              textColor = Colors.black;
            } else if (isRelated) {
              if (isInitial) {
                cellBackground = Colors.blueGrey.shade200;
                textColor = Colors.black;
              } else {
                cellBackground = Colors.lightBlue.shade50;
                textColor = Colors.blue.shade900;
              }
            } else if (isInitial) {
              cellBackground = Colors.grey.shade300;
              textColor = Colors.black;
            } else {
              cellBackground = Colors.white;
              textColor = isSameNumber && !isSelected
                  ? Colors.blue.shade700
                  : Colors.blue.shade900;
            }
          }

          return GestureDetector(
            onTap: () {
              provider.selectCell(row, col);
            },
            child: Container(
              margin: const EdgeInsets.all(0.5),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    width: (row % 3 == 0) ? 1.5 : 0.5,
                    color: borderColor!,
                  ),
                  left: BorderSide(
                    width: (col % 3 == 0) ? 1.5 : 0.5,
                    color: borderColor,
                  ),
                  right: BorderSide(
                    width: (col == 8) ? 1.5 : 0.5,
                    color: borderColor,
                  ),
                  bottom: BorderSide(
                    width: (row == 8) ? 1.5 : 0.5,
                    color: borderColor,
                  ),
                ),
                color: cellBackground,
              ),
              child: Center(
                child: cellValue != 0
                    ? Text(
                        cellValue.toString(),
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      )
                    : hasNotes
                        ? _buildNotesWidget(notes, context)
                        : Container(),
              ),
            ),
          );
        },
      ),
    );
  }

  bool _isRelated(int row, int col) {
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
  Widget _buildNotesWidget(Set<int> notes, BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final notesColor = isDarkMode ? Colors.grey.shade400 : Colors.grey.shade700;

    List<int> sortedNotes = notes.toList()..sort();
    // Simple text display for notes
    return Text(
      sortedNotes.join(' '), // Join numbers with space
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: 10, // Smaller font size for notes
        color: notesColor,
      ),
      maxLines: 2, // Limit lines if too many notes
      overflow: TextOverflow.ellipsis, // Handle overflow
    );
  }
}
