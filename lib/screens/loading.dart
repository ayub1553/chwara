// ignore_for_file: unnecessary_underscores

import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'dart:async';
import 'menu_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    
    Timer(const Duration(seconds: 4), () {
      if (mounted) {
        Navigator.pushReplacement(
          context, 
          PageRouteBuilder(
            pageBuilder: (_, __, ___) => const MenuScreen(),
            transitionsBuilder: (_, a, __, c) => FadeTransition(opacity: a, child: c),
            transitionDuration: const Duration(milliseconds: 1000),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/images/logo_CHWARA.png', width: 320),
            
            const SizedBox(height: 60),

            SpinKitCubeGrid(
              itemBuilder: (context, index) {
                return DecoratedBox(
                  decoration: BoxDecoration(
                    color: index % 2 == 0 ? const Color.fromARGB(255, 105, 158, 249) : const Color.fromARGB(255, 249, 122, 122),
                  ),
                );
              },
              size: 50.0,
            ),

            const SizedBox(height: 60),

            const Text(
              "CHWARA", 
              style: TextStyle(
                letterSpacing: 10, 
                fontSize: 12, 
                fontWeight: FontWeight.w300, 
                color: const Color.fromARGB(255, 100, 100, 100),
                fontFamily: 'ChwaraFont',
              ),
            ),
          ],
        ),
      ),
    );
  }
}