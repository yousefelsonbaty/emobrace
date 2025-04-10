import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'notifications_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:emobrace_app/account/updateaccount_page.dart';
import 'package:emobrace_app/account/deletedisableaccount_page.dart';
import 'package:emobrace_app/account/signin_page.dart';

class EmoBraceApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: AccountPage(userId: FirebaseAuth.instance.currentUser?.uid ?? ''),
    );
  }
}

class AccountPage extends StatelessWidget {
  final String userId;

  const AccountPage({Key? key, required this.userId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (userId.isEmpty) {
      return Center(child: Text('No user logged in.'));
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Row(
          children: [
            Image.asset(
              'assets/images/logo.jpg',
              width: 120,
              fit: BoxFit.contain,
            ),
            Spacer(),
            IconButton(
              icon: Icon(Icons.notifications, color: Color(0xFF8B0000)),
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                      builder: (context) => NotificationsPage(userId: userId)),
                );
              },
            ),
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: GestureDetector(
                onTap: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                        builder: (context) => AccountPage(userId: userId)),
                  );
                },
                child: CircleAvatar(
                  backgroundColor: Color(0xFF8B0000),
                  child: Icon(Icons.person, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future:
            FirebaseFirestore.instance.collection('Users').doc(userId).get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error fetching user data.'));
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return Center(
              child: Text(
                'No user data found.',
                style: TextStyle(fontSize: 18, color: Colors.red),
              ),
            );
          }

          var userData = snapshot.data!.data() as Map<String, dynamic>? ?? {};

          return Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
            child: Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Color(0xFF8B0000),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  buildProfileDetailRow(
                      "Name: ",
                      '${userData['firstName'] ?? 'N/A'} ${userData['lastName'] ?? ''}',
                      24,
                      FontWeight.bold),
                  buildProfileDetailRow("Gender: ", userData['gender'] ?? 'N/A',
                      20, FontWeight.w600),
                  buildProfileDetailRow("DOB: ", _formatDOB(userData['DOB']),
                      20, FontWeight.w600),
                  buildProfileDetailRow("Email Address: ",
                      userData['emailAddress'] ?? 'N/A', 20, FontWeight.w600),
                  buildProfileDetailRow("Phone Number: ",
                      userData['phoneNumber'] ?? 'N/A', 20, FontWeight.w600),
                  buildProfileDetailRow("Address: ",
                      userData['address'] ?? 'N/A', 20, FontWeight.w600),
                  SizedBox(height: 32),
                  Spacer(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      buildActionButton(
                        icon: Icons.edit,
                        label: "Edit",
                        onPressed: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                                builder: (context) =>
                                    UpdateAccountPage(userId: userId)),
                          );
                        },
                        isOutlined: true,
                      ),
                      buildActionButton(
                        icon: Icons.settings,
                        label: "Manage",
                        onPressed: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                                builder: (context) => DeleteDisableAccountPage(
                                    userId:
                                        userId)), // Make sure this is correct
                          );
                        },
                        isOutlined: true,
                      ),
                      buildActionButton(
                        icon: Icons.logout,
                        label: "Sign Out",
                        onPressed: () {
                          FirebaseAuth.instance.signOut();
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                                builder: (context) => LoginPage()),
                          );
                        },
                        isOutlined: true,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  String _formatDOB(dynamic dob) {
    if (dob == null) {
      return 'N/A';
    } else if (dob is Timestamp) {
      return dob.toDate().toLocal().toString().split(' ')[0];
    } else if (dob is String) {
      // Assuming the string is in a valid date format (e.g., 'yyyy-MM-dd')
      return dob;
    } else {
      return 'Invalid Date Format';
    }
  }

  Widget buildProfileDetailRow(
      String label, String value, double fontSize, FontWeight fontWeight) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: fontSize,
              color: Colors.white,
              fontWeight: fontWeight,
            ),
          ),
        ),
        Expanded(
          flex: 3,
          child: Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: fontSize,
              color: Colors.white,
              fontWeight: fontWeight,
            ),
          ),
        ),
      ],
    );
  }

  Widget buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    bool isOutlined = false,
  }) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        backgroundColor: isOutlined ? Colors.white : Color(0xFF8B0000),
        foregroundColor: isOutlined ? Color(0xFF8B0000) : Colors.white,
        side: BorderSide(color: Color(0xFF8B0000), width: 2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        padding: EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
      ),
      icon:
          Icon(icon, size: 18, color: Colors.black), // Set icon color to black
      label: Text(
        label,
        style: TextStyle(fontSize: 16),
      ),
    );
  }
}
