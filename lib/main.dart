import 'package:flutter/material.dart';
import 'package:flutter_food_tracker_app/views/splash_screen_ui.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  // ต้องเรียกก่อน await อะไรก็ตามใน main
  WidgetsFlutterBinding.ensureInitialized();

  // Supabase settings
  await Supabase.initialize(
    url: 'https://obmwvrguqlokmftvwmlb.supabase.co',
    publishableKey: 'sb_publishable_xjxLPIewnd-Zdcr9xM0eeg_t_HJu8Cj',
  );

  runApp(const FlutterFoodTrackerApp());
}

class FlutterFoodTrackerApp extends StatefulWidget {
  const FlutterFoodTrackerApp({super.key});

  @override
  State<FlutterFoodTrackerApp> createState() => _FlutterFoodTrackerAppState();
}

class _FlutterFoodTrackerAppState extends State<FlutterFoodTrackerApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const SplashScreenUi(),
      theme: ThemeData(
        textTheme: Theme.of(context).textTheme.apply(
              fontFamily: GoogleFonts.kanit().fontFamily,
              fontFamilyFallback: GoogleFonts.kanit().fontFamilyFallback,
            ),
      ),
    );
  }
}
