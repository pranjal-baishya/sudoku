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
