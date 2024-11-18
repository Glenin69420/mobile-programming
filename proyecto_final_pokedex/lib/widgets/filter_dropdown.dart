import 'package:flutter/material.dart';

class FilterDropdown extends StatelessWidget {
  final String title;
  final String? selectedValue;
  final List<String> options;
  final ValueChanged<String?> onChanged;

  const FilterDropdown({
    Key? key,
    required this.title,
    required this.selectedValue,
    required this.options,
    required this.onChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DropdownButton<String>(
      hint: Text(title),
      value: selectedValue,
      items: options.map((option) {
        return DropdownMenuItem<String>(
          value: option,
          child: Text(option),
        );
      }).toList(),
      onChanged: onChanged,
    );
  }
}
