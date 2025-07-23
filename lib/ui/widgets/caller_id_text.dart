import 'package:flutter/material.dart';

class CallerIdText extends StatelessWidget {
  final String callerId;
  const CallerIdText({super.key, required this.callerId});

  @override
  Widget build(BuildContext context) {
    return Text(callerId, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18));
  }
} 