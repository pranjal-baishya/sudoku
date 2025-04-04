import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../providers/sudoku_provider.dart';
import '../providers/theme_provider.dart';
import '../widgets/number_input_pad.dart';
import '../widgets/sudoku_grid.dart';
import '../models/difficulty.dart';
import '../screens/settings_screen.dart';

class SudokuScreen extends StatefulWidget {
  const SudokuScreen({super.key});

  @override
  _SudokuScreenState createState() => _SudokuScreenState();
}

class _SudokuScreenState extends State<SudokuScreen> {
  Timer? _timer;
  Duration _elapsedTime = Duration.zero;
  bool _isPaused = false;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _stopTimer();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final provider = Provider.of<SudokuProvider>(context, listen: false);
      if (mounted &&
          !provider.isComplete &&
          provider.mistakes < provider.maxMistakes &&
          !_isPaused) {
        setState(() {
          _elapsedTime = _elapsedTime + const Duration(seconds: 1);
        });
      } else if (provider.isComplete ||
          provider.mistakes >= provider.maxMistakes) {
        timer.cancel();
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
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<SudokuProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: null,
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SettingsScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 700),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 12.0,
                  horizontal: 16.0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Sudoku Game",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: Icon(
                            themeProvider.isDarkMode
                                ? Icons.light_mode
                                : Icons.dark_mode,
                          ),
                          onPressed: themeProvider.toggleTheme,
                          tooltip: themeProvider.isDarkMode
                              ? "Switch to Light Mode"
                              : "Switch to Dark Mode",
                        ),
                        IconButton(
                          icon: Icon(
                            _isPaused ? Icons.play_arrow : Icons.pause,
                          ),
                          onPressed: _togglePause,
                          tooltip: _isPaused ? "Resume" : "Pause",
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const Divider(height: 1),

              Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 4.0,
                  horizontal: 16.0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    DropdownButton<Difficulty>(
                      value: provider.currentDifficulty,
                      items: Difficulty.values.map((Difficulty difficulty) {
                        return DropdownMenuItem<Difficulty>(
                          value: difficulty,
                          child: Text(
                            difficulty.name[0].toUpperCase() +
                                difficulty.name.substring(1),
                          ),
                        );
                      }).toList(),
                      onChanged: (Difficulty? newValue) {
                        if (newValue != null) {
                          provider.changeDifficulty(newValue);
                          _resetAndStartTimer();
                        }
                      },
                      underline: Container(
                        height: 2,
                        color: Theme.of(context).primaryColor,
                      ),
                      style: TextStyle(
                        fontSize: 16,
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                      ),
                      icon: Icon(
                        Icons.arrow_drop_down,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                    Row(
                      children: [
                        Text(
                          "Mistakes: ${provider.mistakes}/${provider.maxMistakes}",
                          style: TextStyle(
                            fontSize: 16,
                            color: provider.mistakes >= provider.maxMistakes
                                ? Colors.red
                                : Theme.of(
                                    context,
                                  ).textTheme.bodyLarge?.color,
                            fontWeight: provider.mistakes > 0
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                        const SizedBox(width: 20),
                        Icon(
                          Icons.timer,
                          size: 18,
                          color: Theme.of(context).iconTheme.color,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _formatDuration(_elapsedTime),
                          style: TextStyle(
                            fontSize: 16,
                            letterSpacing: 1.2,
                            color: Theme.of(context).textTheme.bodyLarge?.color,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              Expanded(
                child: Center(
                  child: AspectRatio(
                    aspectRatio: 1.0,
                    child: Stack(
                      children: [
                        Visibility(
                          visible: !_isPaused,
                          maintainState: true,
                          child: SudokuGrid(provider: provider),
                        ),
                        if (_isPaused)
                          Container(
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                    ? Colors.black.withOpacity(0.9)
                                    : Colors.black,
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.pause_circle_outline,
                                    color: Colors.white,
                                    size: 70,
                                  ),
                                  const SizedBox(height: 24),
                                  const Text(
                                    "GAME PAUSED",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1.5,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  ElevatedButton.icon(
                                    icon: const Icon(Icons.play_arrow),
                                    label: const Text("RESUME GAME"),
                                    onPressed: _togglePause,
                                    style: ElevatedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 24,
                                        vertical: 12,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        if (!_isPaused &&
                            !provider.isComplete &&
                            provider.mistakes >= provider.maxMistakes)
                          Container(
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                    ? Colors.red.shade900.withOpacity(0.85)
                                    : Colors.red.withOpacity(0.9),
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.error_outline,
                                    color: Colors.white,
                                    size: 70,
                                  ),
                                  const SizedBox(height: 24),
                                  const Text(
                                    "GAME OVER",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1.5,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    "Too many mistakes!",
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.8),
                                      fontSize: 18,
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                  ElevatedButton.icon(
                                    icon: const Icon(Icons.refresh),
                                    label: const Text("NEW GAME"),
                                    onPressed: () {
                                      provider.generateNewSudoku();
                                      _resetAndStartTimer();
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.white,
                                      foregroundColor:
                                          Theme.of(context).brightness ==
                                                  Brightness.dark
                                              ? Colors.red.shade900
                                              : Colors.red.shade800,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 24,
                                        vertical: 12,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        if (!_isPaused && provider.isComplete)
                          Container(
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                    ? Colors.green.shade900.withOpacity(0.85)
                                    : Colors.green.withOpacity(0.9),
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.emoji_events,
                                    color: Colors.white,
                                    size: 70,
                                  ),
                                  const SizedBox(height: 24),
                                  const Text(
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
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    "Time: ${_formatDuration(_elapsedTime)}",
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.8),
                                      fontSize: 18,
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                  ElevatedButton.icon(
                                    icon: const Icon(Icons.refresh),
                                    label: const Text("NEW GAME"),
                                    onPressed: () {
                                      provider.generateNewSudoku();
                                      _resetAndStartTimer();
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.white,
                                      foregroundColor:
                                          Theme.of(context).brightness ==
                                                  Brightness.dark
                                              ? Colors.green.shade900
                                              : Colors.green.shade800,
                                      padding: const EdgeInsets.symmetric(
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
              ),

              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8.0,
                  vertical: 4.0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.undo),
                      onPressed: _isPaused ? null : provider.undoLastMove,
                      tooltip: "Undo",
                      iconSize: 24,
                      color: _isPaused
                          ? Colors.grey
                          : provider.moveHistory.isNotEmpty
                              ? Theme.of(context).primaryColor
                              : Colors.grey,
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit_off),
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
                      tooltip: "Notes (${provider.isNotesMode ? 'On' : 'Off'})",
                      iconSize: 24,
                      color: _isPaused
                          ? Colors.grey
                          : provider.isNotesMode
                              ? Theme.of(context).colorScheme.secondary
                              : null,
                    ),
                    Badge(
                      label: Text(
                        '${provider.maxHints - provider.hintsUsed}',
                        style: const TextStyle(fontSize: 10),
                      ),
                      isLabelVisible: provider.hintsUsed < provider.maxHints &&
                          !provider.isComplete &&
                          !_isPaused,
                      child: IconButton(
                        icon: const Icon(Icons.lightbulb_outline),
                        onPressed: _isPaused ? null : provider.useHint,
                        tooltip:
                            "Hint (${provider.maxHints - provider.hintsUsed} left)",
                        iconSize: 24,
                        color: _isPaused ||
                                provider.hintsUsed >= provider.maxHints ||
                                provider.isComplete
                            ? Colors.grey
                            : null,
                      ),
                    ),
                  ],
                ),
              ),

              NumberInputPad(
                isDisabled: _isPaused,
                onNumberSelected: (number) {
                  if (_isPaused) return;

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

              // Developer credit and Privacy Policy
              Padding(
                padding: const EdgeInsets.only(top: 8.0, bottom: 12.0),
                child: Column(
                  children: [
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          'Developed by Pranjal Baishya',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '© All rights reserved 2025',
                      style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
