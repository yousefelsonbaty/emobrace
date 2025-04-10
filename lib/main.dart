import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_api_availability/google_api_availability.dart';
import 'package:emobrace_app/account/signin_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Initialize Firebase with error handling
    await Firebase.initializeApp();
    print("Firebase initialized successfully");
  } catch (e) {
    print("Error initializing Firebase: $e");
  }

  // Check Google Play Services availability
  await _checkGooglePlayServices();

  runApp(EmoBraceApp());
}

Future<void> _checkGooglePlayServices() async {
  GooglePlayServicesAvailability availability = await GoogleApiAvailability
      .instance
      .checkGooglePlayServicesAvailability();

  if (availability != GooglePlayServicesAvailability.success) {
    print("Google Play Services are unavailable: $availability");
  } else {
    print("Google Play Services are available");
  }
}

class EmoBraceApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: LandingPage(),
    );
  }
}

class LandingPage extends StatefulWidget {
  @override
  _LandingPageState createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _logoScaleAnimation;
  late Animation<double> _fadeInAnimation;
  late Animation<Offset> _slideInAnimation;

  @override
  void initState() {
    super.initState();

    // Initialize AnimationController
    _controller = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );

    // Logo scale animation
    _logoScaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );

    // Text fade-in animation
    _fadeInAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Interval(0.5, 1.0)),
    );

    // Text slide-in animation
    _slideInAnimation =
        Tween<Offset>(begin: Offset(0, 1), end: Offset.zero).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    // Start the animation after a short delay
    Future.delayed(Duration(seconds: 1), () {
      _controller.forward();
    });

    // Navigate to the Sign In page after 5 seconds
    Future.delayed(Duration(seconds: 5), () {
      Navigator.of(context).pushReplacement(_createRoute());
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Animated logo
            AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Transform.scale(
                  scale: _logoScaleAnimation.value,
                  child: child,
                );
              },
              child: Image.asset(
                'assets/images/logo.jpg',
                width: 300, // Adjust the width to fit your needs
              ),
            ),
            SizedBox(height: 30),
            // Animated slide-in text with fade effect
            SlideTransition(
              position: _slideInAnimation,
              child: FadeTransition(
                opacity: _fadeInAnimation,
                child: Text(
                  'Welcome to EmoBrace!',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ),
            ),
            SizedBox(height: 20),
            FadeTransition(
              opacity: _fadeInAnimation,
              child: Text(
                'Your Emotional Partner',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w400,
                  color: Colors.grey[700],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Route _createRoute() {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) =>
          LoginPage(), // Navigate to SignInPage
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        // Define the animation effects for transition
        var fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(
            parent: animation,
            curve: Curves.easeInOut,
          ),
        );

        var scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
          CurvedAnimation(
            parent: animation,
            curve: Curves.easeInOut,
          ),
        );

        return FadeTransition(
          opacity: fadeAnimation,
          child: ScaleTransition(
            scale: scaleAnimation,
            child: child,
          ),
        );
      },
      transitionDuration:
          Duration(seconds: 3), // Animation duration for transition
    );
  }
}
