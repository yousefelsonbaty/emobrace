import 'package:flutter/material.dart';
import 'signup_page.dart';
import 'resetpassword_page.dart';
import 'package:emobrace_app/app/home_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EmoBraceApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: LoginPage(),
    );
  }
}

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool _passwordVisible = false;

  final FocusNode _emailFocusNode = FocusNode();
  final FocusNode _passwordFocusNode = FocusNode();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  String? _emailError;
  String? _passwordError;
  String? _generalErrorMessage;

  @override
  void initState() {
    super.initState();
    _passwordVisible = false;

    _emailController.addListener(() {
      if (_emailController.text.isNotEmpty && _emailError != null) {
        setState(() {
          _emailError = null;
        });
      }
    });

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
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _unfocus() {
    _emailFocusNode.unfocus();
    _passwordFocusNode.unfocus();
  }

  bool _validateFields() {
    String email = _emailController.text.trim();
    String password = _passwordController.text.trim();
    bool isValid = true;

    setState(() {
      _emailError = null;
      _passwordError = null;
      _generalErrorMessage = null;
    });

    if (email.isEmpty) {
      setState(() {
        _emailError = "Email is required";
      });
      isValid = false;
    } else if (!email.contains('@')) {
      setState(() {
        _emailError = "Invalid email address";
      });
      isValid = false;
    }

    if (password.isEmpty) {
      setState(() {
        _passwordError = "Password is required";
      });
      isValid = false;
    }

    return isValid;
  }

  // Updated authenticate function with user ID retrieval and isDisabled update
  Future<void> _authenticate(String email, String password) async {
    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('Users')
          .where('emailAddress', isEqualTo: email)
          .get();

      if (snapshot.docs.isNotEmpty) {
        var userDoc = snapshot.docs.first.data() as Map<String, dynamic>;

        if (userDoc['password'] == password) {
          // Retrieve the user ID
          String userId = snapshot.docs.first.id;

          // Update the isDisabled field to false
          await FirebaseFirestore.instance
              .collection('Users')
              .doc(userId)
              .update({'isDisabled': false});

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Successfully logged in!',
                  style: TextStyle(color: Colors.white)),
              backgroundColor: Colors.green,
            ),
          );

          // Inside _authenticate function after successful login
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => HomePage(userId: userId),
            ),
          );
        } else {
          setState(() {
            _generalErrorMessage = "Invalid email or password";
          });
        }
      } else {
        setState(() {
          _generalErrorMessage = "No account found with this email";
        });
      }
    } catch (e) {
      setState(() {
        _generalErrorMessage = "An error occurred. Please try again.";
      });
      print('Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: Colors.white,
      body: GestureDetector(
        onTap: _unfocus,
        child: SingleChildScrollView(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(height: 30),
                  Image.asset('assets/images/logo.jpg', width: 300),
                  SizedBox(height: 10),
                  TextField(
                    controller: _emailController,
                    focusNode: _emailFocusNode,
                    decoration: InputDecoration(
                      labelText: 'Email Address',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      errorText: _emailError,
                    ),
                  ),
                  SizedBox(height: 20),
                  TextField(
                    controller: _passwordController,
                    focusNode: _passwordFocusNode,
                    obscureText: !_passwordVisible,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(_passwordVisible
                            ? Icons.visibility
                            : Icons.visibility_off),
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
                      style: TextStyle(color: Colors.red, fontSize: 14),
                    ),
                  SizedBox(height: 30),
                  ElevatedButton(
                    onPressed: () {
                      if (_validateFields()) {
                        _authenticate(
                          _emailController.text.trim(),
                          _passwordController.text.trim(),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      padding:
                          EdgeInsets.symmetric(vertical: 15, horizontal: 100),
                      backgroundColor: Color(0xFF8B0000),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text('Sign In',
                        style: TextStyle(fontSize: 18, color: Colors.white)),
                  ),
                  SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      InkWell(
                        onTap: () {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => SignUpPage()));
                        },
                        child: Text(
                          'Sign Up Instead',
                          style: TextStyle(
                            color: Color(0xFF8B0000),
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            decoration: TextDecoration.underline,
                            decorationColor: Color(0xFF8B0000),
                          ),
                        ),
                      ),
                      SizedBox(width: 10),
                      Text('|', style: TextStyle(fontSize: 14)),
                      SizedBox(width: 10),
                      InkWell(
                        onTap: () {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => ResetPasswordPage()));
                        },
                        child: Text(
                          'Forgot Your Password?',
                          style: TextStyle(
                            color: Color(0xFF8B0000),
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            decoration: TextDecoration.underline,
                            decorationColor: Color(0xFF8B0000),
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
      ),
    );
  }
}
