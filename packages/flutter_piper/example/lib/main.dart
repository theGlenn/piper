import 'package:flutter/material.dart';
import 'package:example/features/search_race/search_race_page.dart';

void main() {
  runApp(const PiperSearchRaceApp());
}

class PiperSearchRaceApp extends StatelessWidget {
  const PiperSearchRaceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Piper Search Race',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2457F5)),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF5F7FB),
      ),
      home: const SearchRacePage(),
    );
  }
}
