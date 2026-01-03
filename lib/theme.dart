import 'package:flutter/material.dart';


final ThemeData navyTheme = ThemeData(
  primarySwatch: Colors.blue,
  primaryColor: const Color(0xFF000080), 
  scaffoldBackgroundColor: const Color(0xFF040331), 
  canvasColor: const Color(0xFF040331),
  brightness: Brightness.dark,
  textTheme: const TextTheme(
    bodyLarge: TextStyle(color: Colors.white),
    bodyMedium: TextStyle(color: Colors.white70),
  ),
);


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
