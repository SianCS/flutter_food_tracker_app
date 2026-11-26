import 'package:flutter/material.dart';
import 'package:flutter_food_tracker_app/views/show_all_food_tracker_ui.dart';

class SplashScreenUi
    extends
        StatefulWidget {
  const SplashScreenUi({super.key});

  @override
  State<
    SplashScreenUi
  >
  createState() => _SplashScreenUiState();
}

class _SplashScreenUiState
    extends
        State<
          SplashScreenUi
        > {
  @override
  void initState() {
    super.initState();
    // หน่วงเวลา 3 วินาที แล้วเปิดหน้า ShowAllFoodTrackerUi แทนหน้านี้ (กด back แล้วไม่กลับมาหน้า splash)
    Future.delayed(
      const Duration(
        seconds: 3,
      ),
      () {
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (
              context,
            ) => const ShowAllFoodTrackerUi(),
          ),
        );
      },
    );
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      backgroundColor: Colors.red,
      body: Stack(
        children: [
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  'assets/images/logo.png',
                  width:
                      MediaQuery.of(
                        context,
                      ).size.width *
                      0.5,
                  height:
                      MediaQuery.of(
                        context,
                      ).size.height *
                      0.3,
                ),
                Text(
                  'Food Tracker',
                  style: TextStyle(
                    fontSize:
                        MediaQuery.of(
                          context,
                        ).size.width *
                        0.07,
                    fontWeight: FontWeight.bold,
                    color: Colors.yellow,
                  ),
                ),
                Text(
                  '🍔🍕🌭🍿🍩🧁',
                  style: TextStyle(
                    fontSize:
                        MediaQuery.of(
                          context,
                        ).size.width *
                        0.06,
                  ),
                ),
                SizedBox(
                  height:
                      MediaQuery.of(
                        context,
                      ).size.height *
                      0.02,
                ),
                const CircularProgressIndicator(
                  color: Colors.yellow,
                ),
              ],
            ),
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  '@ 2026 Food Tracker',
                  style: TextStyle(
                    color: Colors.grey[200],
                    fontSize:
                        MediaQuery.of(
                          context,
                        ).size.width *
                        0.03,
                  ),
                ),

                SizedBox(
                  height:
                      MediaQuery.of(
                        context,
                      ).size.height *
                      0.03,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
