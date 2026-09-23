import 'package:flutter/material.dart';

import 'spike/spike_screen.dart';

void main() {
  runApp(const IrenefyApp());
}

class IrenefyApp extends StatelessWidget {
  const IrenefyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Irenefy',
      theme: ThemeData(colorSchemeSeed: const Color(0xFFB5562B)),
      home: const SpikeScreen(),
    );
  }
}
