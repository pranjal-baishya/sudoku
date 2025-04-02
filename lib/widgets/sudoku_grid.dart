import 'package:flutter/material.dart';
import '../providers/sudoku_provider.dart';

class SudokuGrid extends StatelessWidget {
  final SudokuProvider provider;

  const SudokuGrid({Key? key, required this.provider}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4.0),
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
              provider.selectedRow == row && provider.selectedCol == col;
          bool isRelated = _isRelated(row, col);
          bool isIncorrect = provider.isIncorrectCell(row, col);

          // Check for same number highlight
          bool isSameNumber = false;
          int? selectedValue =
              (provider.selectedRow != null && provider.selectedCol != null)
                  ? provider.currentBoard[provider.selectedRow!][provider
                      .selectedCol!]
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
                            .shade100 // Incorrect cells
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
                        : Colors.white, // Normal empty cells
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
                                    : isSameNumber && !isSelected && !isInitial
                                    ? Colors.blue.shade700
                                    : isInitial
                                    ? Colors.black
                                    : Colors.blue.shade900,
                          ),
                        )
                        : hasNotes
                        ? _buildNotesWidget(notes)
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
  Widget _buildNotesWidget(Set<int> notes) {
    List<int> sortedNotes = notes.toList()..sort();
    // Simple text display for notes
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
  }
}
