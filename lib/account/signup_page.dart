import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:emobrace_app/app/home_page.dart';

class SignUpApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: SignUpPage(),
    );
  }
}

class SignUpPage extends StatefulWidget {
  @override
  _SignUpPageState createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  // Controllers for the text fields
  TextEditingController _firstNameController = TextEditingController();
  TextEditingController _middleNameController = TextEditingController();
  TextEditingController _lastNameController = TextEditingController();
  TextEditingController _dobController = TextEditingController();
  TextEditingController _countryCodeController = TextEditingController();
  TextEditingController _phoneNumberController = TextEditingController();
  TextEditingController _addressController = TextEditingController();
  TextEditingController _emailController = TextEditingController();
  TextEditingController _passwordController = TextEditingController();
  TextEditingController _confirmPasswordController = TextEditingController();

  // Dropdown value for gender
  String? _selectedGender;

  // Validation flags for each field
  bool _isFirstNameValid = true;
  bool _isMiddleNameValid = true;
  bool _isLastNameValid = true;
  bool _isDobValid = true;
  bool _isGenderValid = true;
  bool _isCodeValid = true;
  bool _isPhoneValid = true;
  bool _isAddressValid = true;
  bool _isEmailValid = true;
  bool _isPasswordValid = true;
  bool _isConfirmPasswordValid = true;

  // Password strength indicator
  Color _passwordStrengthColor = Colors.grey;
  double _passwordStrengthValue = 0.0;

  // Validation message
  String? _validationMessage;

  // Toggle visibility of password fields
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void initState() {
    super.initState();
    _dobController.text = 'Select DOB';

    // Listen to password input to check strength
    _passwordController.addListener(_checkPasswordStrength);
  }

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  // Function to handle date picker selection
  Future<void> _selectDate(BuildContext context) async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: ColorScheme.light(
              primary: Color(0xFF8B0000), // Header color
              onPrimary: Colors.white, // Header text color
              onSurface: Colors.black, // Body text color
            ),
            dialogBackgroundColor: Colors.white, // Background color
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _dobController.text = DateFormat('yyyy-MM-dd').format(picked);
        _isDobValid = true;
      });
    }
  }

  // Function to validate fields
  bool _validateFields() {
    // Reset validation flags
    setState(() {
      _isFirstNameValid = _firstNameController.text.isNotEmpty;
      _isMiddleNameValid = _middleNameController.text.isNotEmpty;
      _isLastNameValid = _lastNameController.text.isNotEmpty;
      _isDobValid = _dobController.text != 'Select DOB';
      _isGenderValid = _selectedGender != null;
      _isCodeValid = _countryCodeController.text.isNotEmpty;
      _isPhoneValid = _phoneNumberController.text.isNotEmpty;
      _isAddressValid = _addressController.text.isNotEmpty;
      _isEmailValid = _emailController.text.contains('@');
      _isPasswordValid = _passwordController.text.isNotEmpty;
      _isConfirmPasswordValid =
          _confirmPasswordController.text == _passwordController.text;
    });

    // Check if any field is invalid
    if (!_isFirstNameValid ||
        !_isMiddleNameValid ||
        !_isLastNameValid ||
        !_isDobValid ||
        !_isGenderValid ||
        !_isCodeValid ||
        !_isPhoneValid ||
        !_isAddressValid ||
        !_isEmailValid ||
        !_isPasswordValid ||
        !_isConfirmPasswordValid) {
      return false;
    }

    return true;
  }

  // Password strength label
  String _passwordStrengthText = 'Password Strength';

  // Function to check password strength
  void _checkPasswordStrength() {
    String password = _passwordController.text;

    if (password.isEmpty) {
      _passwordStrengthColor = Colors.red;
      _passwordStrengthValue = 0.0;
      _passwordStrengthText = 'Weak Password'; // Default when empty
    } else if (password.length < 6) {
      _passwordStrengthColor = Colors.red;
      _passwordStrengthValue = 0.33;
      _passwordStrengthText = 'Weak Password';
    } else if (password.length < 10 || !RegExp(r'[\W]').hasMatch(password)) {
      _passwordStrengthColor = Colors.orange;
      _passwordStrengthValue = 0.66;
      _passwordStrengthText = 'Medium Password';
    } else {
      _passwordStrengthColor = Colors.green;
      _passwordStrengthValue = 1.0;
      _passwordStrengthText = 'Strong Password';
    }

    setState(() {});
  }

  Future<void> _signUp() async {
    if (_validateFields()) {
      try {
        // Create a new user with Firebase Authentication
        UserCredential userCredential = await FirebaseAuth.instance
            .createUserWithEmailAndPassword(
                email: _emailController.text,
                password: _passwordController.text);

        // Use the user ID (UID) from Firebase Authentication
        String userId = userCredential.user!.uid;

        // Add user details to Firestore with the user ID as document ID
        await FirebaseFirestore.instance.collection('Users').doc(userId).set({
          'gender': _selectedGender,
          'firstName': _firstNameController.text,
          'middleName': _middleNameController.text,
          'lastName': _lastNameController.text,
          'phoneNumber':
              '${_countryCodeController.text}-${_phoneNumberController.text}',
          'emailAddress': _emailController.text,
          'password':
              _passwordController.text, // In practice, hash this password
          'address': _addressController.text,
          'DOB': _dobController.text, // Date of birth
          'userID': userId,
          'isDisabled': false, // Set isDisabled to false
        });

        // Navigate to the home page with the userId
        Future.delayed(Duration(seconds: 1), () {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => HomePage(userId: userId),
            ),
          );
        });
      } on FirebaseAuthException catch (e) {
        setState(() {
          _validationMessage = e.message;
        });
      }
    } else {
      setState(() {
        _validationMessage = "Please fill in all the fields correctly.";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus(); // Dismiss the keyboard
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: PreferredSize(
          preferredSize: Size.fromHeight(50.0),
          child: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: Icon(Icons.arrow_back, color: Colors.black),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
            systemOverlayStyle: SystemUiOverlayStyle.dark,
          ),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Column(
                    children: [
                      Image.asset(
                        'assets/images/logo.jpg',
                        width: 300,
                        fit: BoxFit.contain,
                      ),
                      SizedBox(height: 10),
                      Text(
                        'Create Your Account',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF8B0000),
                        ),
                      ),
                      SizedBox(height: 40),
                    ],
                  ),
                ),
                // First Name Text Field
                buildTextField(
                    'First Name', _firstNameController, _isFirstNameValid,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z]'))
                    ]),
                SizedBox(height: 16),
                // Middle Name Text Field
                buildTextField(
                    'Middle Name', _middleNameController, _isMiddleNameValid,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z]'))
                    ]),
                SizedBox(height: 16),
                // Last Name Text Field
                buildTextField(
                    'Last Name', _lastNameController, _isLastNameValid,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z]'))
                    ]),
                SizedBox(height: 16),
                // Date of Birth Text Field
                buildDateOfBirthField(context),
                SizedBox(height: 16),
                // Gender Dropdown
                buildGenderDropdown(),
                SizedBox(height: 16),
                // Phone Number Fields
                buildPhoneNumberFields(),
                SizedBox(height: 16),
                // Address
                buildTextField('Address', _addressController, _isAddressValid),
                SizedBox(height: 16),
                // Email Address
                buildTextField(
                    'Email Address', _emailController, _isEmailValid),
                SizedBox(height: 16),
                // Password Field with Strength Indicator
                buildPasswordFieldWithStrength(),
                SizedBox(height: 16),
                buildPasswordField(
                    'Confirm Password',
                    _confirmPasswordController,
                    _obscureConfirmPassword, (value) {
                  setState(() {
                    _obscureConfirmPassword = value;
                  });
                }, _isConfirmPasswordValid),
                SizedBox(height: 30),
                // Display validation message
                if (_validationMessage != null)
                  Text(
                    _validationMessage!,
                    style: TextStyle(color: Colors.red, fontSize: 14),
                  ),
                SizedBox(height: 16),
                // Sign Up Button
                Center(
                  child: SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF8B0000),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                      ),
                      onPressed: () {
                        _signUp(); // Call the sign up function
                      },
                      child: Text(
                        'Sign Up',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget buildTextField(
      String label, TextEditingController controller, bool isValid,
      {List<TextInputFormatter>? inputFormatters}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 8),
        TextField(
          controller: controller,
          inputFormatters: inputFormatters,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.grey[200],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
            contentPadding:
                EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
            errorText: isValid ? null : 'This field is required',
          ),
        ),
      ],
    );
  }

  Widget buildDateOfBirthField(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Date of Birth',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 8),
        GestureDetector(
          onTap: () => _selectDate(context),
          child: AbsorbPointer(
            child: TextField(
              controller: _dobController,
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.grey[200],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                contentPadding:
                    EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
                errorText: _isDobValid ? null : 'This field is required',
                suffixIcon: Icon(
                  Icons.calendar_today, // Calendar icon
                  color: Colors.grey, // Icon color
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget buildGenderDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Gender',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _selectedGender,
          items: ['Male', 'Female']
              .map((gender) => DropdownMenuItem<String>(
                    value: gender,
                    child: Text(gender),
                  ))
              .toList(),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.grey[200],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
            contentPadding:
                EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
            errorText: _isGenderValid ? null : 'This field is required',
          ),
          dropdownColor: Colors.white, // Sets dropdown menu background color
          onChanged: (value) {
            setState(() {
              _selectedGender = value;
              _isGenderValid = true;
            });
          },
        ),
      ],
    );
  }

  Widget buildPhoneNumberFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Phone Number',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              flex: 1,
              child: TextField(
                controller: _countryCodeController,
                decoration: InputDecoration(
                  hintText: '+1',
                  filled: true,
                  fillColor: Colors.grey[200],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding:
                      EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
                  errorText: _isCodeValid ? null : 'This field is required',
                ),
                keyboardType: TextInputType.phone,
              ),
            ),
            SizedBox(width: 8),
            Expanded(
              flex: 2,
              child: TextField(
                controller: _phoneNumberController,
                decoration: InputDecoration(
                  hintText: 'Phone Number',
                  filled: true,
                  fillColor: Colors.grey[200],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding:
                      EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
                  errorText: _isPhoneValid ? null : 'This field is required',
                ),
                keyboardType: TextInputType.phone,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget buildPasswordFieldWithStrength() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        buildPasswordField(
          'Password',
          _passwordController,
          _obscurePassword,
          (value) {
            setState(() {
              _obscurePassword = value;
            });
          },
          _isPasswordValid,
        ),
        SizedBox(height: 8),
        LinearProgressIndicator(
          value: _passwordStrengthValue,
          backgroundColor: Colors.grey[300],
          color: _passwordStrengthColor,
        ),
        SizedBox(height: 4),
        Text(
          _passwordStrengthText,
          style: TextStyle(
            color: _passwordStrengthColor,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget buildPasswordField(String label, TextEditingController controller,
      bool obscureText, Function(bool) toggleObscureText, bool isValid) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: obscureText,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.grey[200],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
            contentPadding:
                EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
            errorText: isValid ? null : 'Passwords do not match',
            suffixIcon: IconButton(
              icon: Icon(
                obscureText ? Icons.visibility_off : Icons.visibility,
              ),
              onPressed: () {
                toggleObscureText(!obscureText);
              },
            ),
          ),
        ),
      ],
    );
  }
}
