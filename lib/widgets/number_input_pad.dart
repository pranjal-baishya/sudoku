import 'package:flutter/material.dart';

class NumberInputPad extends StatelessWidget {
  final Function(int) onNumberSelected;
  final bool isDisabled;

  const NumberInputPad({
    super.key,
    required this.onNumberSelected,
    this.isDisabled = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

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
                backgroundColor:
                    isDarkMode
                        ? Colors.grey.shade800
                        : Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
                disabledBackgroundColor:
                    isDarkMode
                        ? Colors.grey.shade900.withOpacity(0.3)
                        : Colors.grey.shade300,
                disabledForegroundColor:
                    isDarkMode ? Colors.grey.shade600 : Colors.grey.shade700,
                elevation: isDarkMode ? 4 : 2,
                shadowColor:
                    isDarkMode
                        ? Colors.black.withOpacity(0.5)
                        : Colors.black.withOpacity(0.3),
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
