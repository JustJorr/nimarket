import 'package:flutter/material.dart';

// Navy theme (default)
final ThemeData navyTheme = ThemeData(
  primarySwatch: Colors.blue,
  primaryColor: const Color(0xFF000080), // Navy blue
  scaffoldBackgroundColor: const Color(0xFF040331), // Dark navy background
  canvasColor: const Color(0xFF040331),
  brightness: Brightness.dark,
  textTheme: const TextTheme(
    bodyLarge: TextStyle(color: Colors.white),
    bodyMedium: TextStyle(color: Colors.white70),
  ),
);

// Bright theme (mostly white)
final ThemeData brightTheme = ThemeData(
  primarySwatch: Colors.blue,
  primaryColor: Colors.white,
  scaffoldBackgroundColor: Colors.white,
  canvasColor: Colors.white,
  brightness: Brightness.light,
  textTheme: const TextTheme(
    bodyLarge: TextStyle(color: Colors.black),
    bodyMedium: TextStyle(color: Colors.black87),
  ),
);
