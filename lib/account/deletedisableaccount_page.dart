import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'signin_page.dart';

class DeleteDisableAccountPage extends StatefulWidget {
  final String userId;

  DeleteDisableAccountPage({required this.userId});

  @override
  _DeleteDisableAccountPageState createState() =>
      _DeleteDisableAccountPageState();
}

class _DeleteDisableAccountPageState extends State<DeleteDisableAccountPage> {
  bool _passwordVisible = false;
  String? _selectedOption;

  final TextEditingController _passwordController = TextEditingController();
  String? _passwordError;
  String? _generalErrorMessage;

  @override
  void initState() {
    super.initState();
    _passwordVisible = false;

    _passwordController.addListener(() {
      if (_passwordController.text.isNotEmpty && _passwordError != null) {
        setState(() {
          _passwordError = null;
        });
      }
    });
  }

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  bool _validateFields() {
    String password = _passwordController.text.trim();
    bool isValid = true;

    setState(() {
      _passwordError = null;
      _generalErrorMessage = null;
    });

    if (password.isEmpty) {
      setState(() {
        _passwordError = "Password is required";
      });
      isValid = false;
    }

    return isValid;
  }

  Future<void> _handleAccountAction() async {
    if (_validateFields()) {
      String actionMessage = "";
      FirebaseFirestore firestore = FirebaseFirestore.instance;

      try {
        DocumentSnapshot userDoc =
            await firestore.collection('Users').doc(widget.userId).get();

        if (!userDoc.exists) {
          setState(() {
            _generalErrorMessage = "Error: User does not exist.";
          });
          return;
        }

        if (_selectedOption == 'Disable Account') {
          await firestore.collection('Users').doc(widget.userId).update({
            'isDisabled': true,
          });
          actionMessage = 'Account has been successfully disabled!';
        } else if (_selectedOption == 'Delete Account') {
          DocumentReference userDocRef =
              firestore.collection('Users').doc(widget.userId);
          await userDocRef.delete();

          List<String> collectionsToCheck = ['FeedbackForms', 'SensorData'];
          for (String collection in collectionsToCheck) {
            QuerySnapshot querySnapshot = await firestore
                .collection(collection)
                .where('userID', isEqualTo: widget.userId)
                .get();

            for (QueryDocumentSnapshot doc in querySnapshot.docs) {
              await doc.reference.delete();
            }
          }
          actionMessage = 'Account has been successfully deleted!';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(actionMessage),
            backgroundColor: Colors.green,
          ),
        );

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => LoginPage()),
          (route) => false,
        );
      } catch (error) {
        setState(() {
          _generalErrorMessage = "Error: $error";
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: GestureDetector(
        onTap: () {
          FocusScope.of(context).unfocus();
        },
        child: SingleChildScrollView(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(height: 30),
                  Image.asset(
                    'assets/images/logo.jpg',
                    width: 300,
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Delete/Disable Account',
                    style: GoogleFonts.roboto(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF8B0000),
                    ),
                  ),
                  SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    value: _selectedOption,
                    hint: Text('Select Option'),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    items: ['Disable Account', 'Delete Account']
                        .map((option) => DropdownMenuItem<String>(
                              value: option,
                              child: Text(option),
                            ))
                        .toList(),
                    dropdownColor: Colors.white,
                    onChanged: (value) {
                      setState(() {
                        _selectedOption = value;
                      });
                    },
                  ),
                  SizedBox(height: 20),
                  TextField(
                    controller: _passwordController,
                    obscureText: !_passwordVisible,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      labelStyle: TextStyle(fontSize: 16),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _passwordVisible
                              ? Icons.visibility
                              : Icons.visibility_off,
                        ),
                        onPressed: () {
                          setState(() {
                            _passwordVisible = !_passwordVisible;
                          });
                        },
                      ),
                      errorText: _passwordError,
                    ),
                  ),
                  SizedBox(height: 10),
                  if (_generalErrorMessage != null)
                    Text(
                      _generalErrorMessage!,
                      style: TextStyle(
                        color: Colors.red,
                        fontSize: 14,
                      ),
                    ),
                  SizedBox(height: 30),
                  ElevatedButton(
                    onPressed: _handleAccountAction,
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(
                        vertical: 15,
                        horizontal: 100,
                      ),
                      backgroundColor: Color(0xFF8B0000),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      'Confirm',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
