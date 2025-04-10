import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'bracelets_page.dart';
import 'data_page.dart';
import 'notifications_page.dart';
import 'account_page.dart';

class EmoBraceApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: HomePage(userId: 'dummyUserId'), // Replace with actual userId
    );
  }
}

class HomePage extends StatefulWidget {
  final String userId;

  const HomePage({Key? key, required this.userId}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  String _currentEmotion = "Loading...";
  String _currentSuggestion = "Loading suggestion...";

  @override
  void initState() {
    super.initState();
    _fetchLatestEmotionData();
  }

  Future<void> _fetchLatestEmotionData() async {
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('SensorData')
          .where('userID', isEqualTo: widget.userId)
          .orderBy('Timestamp', descending: true)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final doc = querySnapshot.docs.first;
        final output = doc.data()['Output'] as Map<String, dynamic>? ?? {};
        setState(() {
          _currentEmotion = output['Emotion']?.toString() ?? "Unknown";
          _currentSuggestion =
              output['Suggestion']?.toString() ?? "No suggestion available";
        });
      } else {
        setState(() {
          _currentEmotion = "No data";
          _currentSuggestion = "No recent data available";
        });
      }
    } catch (e) {
      setState(() {
        _currentEmotion = "Error";
        _currentSuggestion = "Failed to load data";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _getPage(_selectedIndex),
      bottomNavigationBar: BottomNavigationBar(
        selectedItemColor: Color(0xFF8B0000),
        unselectedItemColor: Colors.black54,
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.watch),
            label: 'Bracelet',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.data_usage),
            label: 'Data',
          ),
        ],
      ),
    );
  }

  Widget _getPage(int index) {
    switch (index) {
      case 0:
        return _buildHomePageContent();
      case 1:
        return BraceletsPage(userId: widget.userId);
      case 2:
        return DataPage(userId: widget.userId);
      default:
        return _buildHomePageContent();
    }
  }

  Widget _buildHomePageContent() {
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          pinned: false,
          floating: false,
          backgroundColor: Colors.white,
          elevation: 0,
          expandedHeight: 100.0,
          flexibleSpace: FlexibleSpaceBar(
            background: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Hero(
                    tag: 'logoHero',
                    child: Image.asset(
                      'assets/images/logo.jpg',
                      width: 120,
                      fit: BoxFit.contain,
                    ),
                  ),
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) =>
                                    NotificationsPage(userId: widget.userId)),
                          );
                        },
                        child: Icon(
                          Icons.notifications,
                          color: Color(0xFF8B0000),
                        ),
                      ),
                      SizedBox(width: 15),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) =>
                                    AccountPage(userId: widget.userId)),
                          );
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: Color(0xFF8B0000),
                            shape: BoxShape.circle,
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Icon(
                              Icons.person,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                // Big red box with emotion information
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Color(0xFF8B0000), // Dark red color
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        "Your Current Emotion:",
                        style: GoogleFonts.poppins(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 15),
                      Text(
                        _currentEmotion,
                        style: GoogleFonts.poppins(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 20),
                      Text(
                        "Suggestion:",
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 10),
                      Text(
                        _currentSuggestion,
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 30),
                // Refresh button
                ElevatedButton(
                  onPressed: _fetchLatestEmotionData,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF8B0000),
                    padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.refresh, color: Colors.white),
                      SizedBox(width: 8),
                      Text(
                        "Refresh Data",
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
