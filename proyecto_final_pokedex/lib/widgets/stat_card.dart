import 'package:flutter/material.dart';

class StatCard extends StatelessWidget {
  final String statName;
  final int statValue;

  const StatCard({Key? key, required this.statName, required this.statValue})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(statName),
        subtitle: Text(statValue.toString()),
      ),
    );
  }
}
