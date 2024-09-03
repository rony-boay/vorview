import 'package:flutter/material.dart';
import 'dart:async';

import 'package:vorviewadmin/main.dart';

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  AnimationController? _controller;
  Animation<double>? _animation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: Duration(seconds: 2),
      vsync: this,
    );
    _animation = CurvedAnimation(parent: _controller!, curve: Curves.easeInOut);
    _controller?.forward();

    Timer(Duration(seconds: 2), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
            builder: (context) =>
                AuthWrapper()), // Navigate to AuthWrapper after splash
      );
    });
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF191970),
      body: Center(
        child: FadeTransition(
          opacity: _animation!,
          child: Image.asset(
            'assets/vorvie.jpg', // Replace with your logo asset
            width: 150,
            height: 150,
          ),
        ),
      ),
    );
  }
}
