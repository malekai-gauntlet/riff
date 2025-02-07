import 'package:flutter/material.dart';

class FeedToggle extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onToggle;

  const FeedToggle({
    super.key,
    required this.selectedIndex,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildToggleButton('Following', 0),
        const SizedBox(width: 24),
        _buildToggleButton('For You', 1),
      ],
    );
  }

  Widget _buildToggleButton(String text, int index) {
    final isSelected = selectedIndex == index;
    return GestureDetector(
      onTap: () => onToggle(index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            text,
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          const SizedBox(height: 2),
          // Indicator line
          Container(
            width: 24,
            height: 2,
            decoration: BoxDecoration(
              color: isSelected ? Colors.white : Colors.transparent,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ],
      ),
    );
  }
} 