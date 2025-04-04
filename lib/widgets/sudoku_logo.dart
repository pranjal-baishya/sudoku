import 'package:flutter/material.dart';

class SudokuLogo extends StatelessWidget {
  final double size;
  final Color? color;

  const SudokuLogo({super.key, this.size = 120.0, this.color});

  @override
  Widget build(BuildContext context) {
    final baseColor = color ?? Colors.blue[800]!;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: baseColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: baseColor, width: 2),
      ),
      child: CustomPaint(
        painter: SudokuGridPainter(baseColor),
        child: Center(
          child: Text(
            '9',
            style: TextStyle(
              fontSize: size * 0.4,
              fontWeight: FontWeight.bold,
              color: baseColor,
            ),
          ),
        ),
      ),
    );
  }
}

class SudokuGridPainter extends CustomPainter {
  final Color color;

  SudokuGridPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = color
          ..strokeWidth = 1.0
          ..style = PaintingStyle.stroke;

    final boldPaint =
        Paint()
          ..color = color
          ..strokeWidth = 2.0
          ..style = PaintingStyle.stroke;

    // Draw the grid lines
    final cellSize = size.width / 3;

    // Draw horizontal lines
    for (int i = 1; i < 3; i++) {
      final y = cellSize * i;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), boldPaint);
    }

    // Draw vertical lines
    for (int i = 1; i < 3; i++) {
      final x = cellSize * i;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), boldPaint);
    }

    // Draw inner cell lines
    final innerCellSize = cellSize / 3;

    // Inner horizontal lines
    for (int i = 1; i < 9; i++) {
      if (i % 3 == 0) continue; // Skip lines already drawn
      final y = innerCellSize * i;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }

    // Inner vertical lines
    for (int i = 1; i < 9; i++) {
      if (i % 3 == 0) continue; // Skip lines already drawn
      final x = innerCellSize * i;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
