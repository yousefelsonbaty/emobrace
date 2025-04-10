import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'resetpassword_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:emobrace_app/app/home_page.dart';

class UpdateAccountApp extends StatelessWidget {
  final String userId; // Accept userId here

  // Constructor to accept userId
  const UpdateAccountApp({Key? key, required this.userId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: UpdateAccountPage(userId: userId), // Pass the userId dynamically
    );
  }
}

class UpdateAccountPage extends StatefulWidget {
  final String userId; // Named parameter for userId

  const UpdateAccountPage({Key? key, required this.userId}) : super(key: key);

  @override
  _UpdateAccountPageState createState() => _UpdateAccountPageState();
}

class _UpdateAccountPageState extends State<UpdateAccountPage> {
  // Controllers for the text fields
  TextEditingController _firstNameController = TextEditingController();
  TextEditingController _middleNameController = TextEditingController();
  TextEditingController _lastNameController = TextEditingController();
  TextEditingController _dobController = TextEditingController();
  TextEditingController _countryCodeController = TextEditingController();
  TextEditingController _phoneNumberController = TextEditingController();
  TextEditingController _addressController = TextEditingController();
  TextEditingController _emailController = TextEditingController();

  // Dropdown value for gender
  String? _selectedGender;

  // Firestore instance
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

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

  // Validation message
  String? _validationMessage;

  @override
  void initState() {
    super.initState();
    _dobController.text = 'Select DOB';
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
        !_isEmailValid) {
      return false;
    }

    return true;
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
                        'Update Your Account',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF8B0000),
                        ),
                      ),
                      SizedBox(height: 10),
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
                // Email Address Text Field
                buildTextField(
                    'Email Address', _emailController, _isEmailValid),
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
                SizedBox(height: 30),
                // Display validation message
                if (_validationMessage != null)
                  Text(
                    _validationMessage!,
                    style: TextStyle(color: Colors.red, fontSize: 14),
                  ),
                SizedBox(height: 16),
                // Update Account Details Button
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
                      onPressed: () async {
                        if (_validateFields()) {
                          try {
                            String uid = widget.userId;

                            // Update the 'Users' collection in Firestore
                            await _firestore
                                .collection('Users')
                                .doc(uid)
                                .update({
                              'firstName': _firstNameController.text,
                              'middleName': _middleNameController.text,
                              'lastName': _lastNameController.text,
                              'DOB': _dobController.text,
                              'gender': _selectedGender,
                              'phoneNumber':
                                  '${_countryCodeController.text}-${_phoneNumberController.text}',
                              'address': _addressController.text,
                              'emailAddress': _emailController.text,
                            });

                            // Show success message after successful update
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                    'Account has been successfully updated!'),
                                duration: Duration(seconds: 2),
                              ),
                            );

                            // Navigate to Home Page with the updated userId
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    HomePage(userId: widget.userId),
                              ),
                            );
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Failed to update account: $e'),
                              ),
                            );
                          }
                        }
                      },
                      child: Text(
                        'Update Account Details',
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
                // Reset Password (Clickable, Red Text)
                Center(
                  child: InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ResetPasswordPage(),
                        ),
                      );
                    },
                    child: Text(
                      'Reset Password',
                      style: TextStyle(
                        color: Color(0xFF8B0000),
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        decoration: TextDecoration.underline,
                        decorationColor: Color(0xFF8B0000),
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
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        errorText: isValid ? null : 'This field cannot be empty',
        border: OutlineInputBorder(),
      ),
      inputFormatters: inputFormatters,
    );
  }

  Widget buildDateOfBirthField(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _dobController,
          readOnly: true,
          decoration: InputDecoration(
            hintText: 'Select your date of birth',
            errorText: _isDobValid ? null : 'Please select a date',
            border: OutlineInputBorder(),
            filled: true,
            fillColor: Colors.white,
            suffixIcon: IconButton(
              icon: Icon(Icons.calendar_today),
              onPressed: () =>
                  _selectDate(context), // Opens date picker when tapped
            ),
          ),
          onTap: () =>
              _selectDate(context), // Also triggers the date picker when tapped
        ),
      ],
    );
  }

  Widget buildGenderDropdown() {
    return DropdownButtonFormField<String>(
      decoration: InputDecoration(
        labelText: 'Gender',
        errorText: _isGenderValid ? null : 'Please select a gender',
        border: OutlineInputBorder(),
        filled: true, // Enables the filled color
        fillColor: Colors
            .white, // Sets the background color to white for the input field
      ),
      value: _selectedGender,
      onChanged: (value) {
        setState(() {
          _selectedGender = value;
          _isGenderValid = true;
        });
      },
      items: ['Male', 'Female']
          .map((gender) => DropdownMenuItem(
                value: gender,
                child: Container(
                  color:
                      Colors.white, // Sets the background color for the options
                  child: Text(gender),
                ),
              ))
          .toList(),
      dropdownColor: Colors.white,
    );
  }

  Widget buildPhoneNumberFields() {
    return Row(
      children: [
        SizedBox(
          width: 70,
          child: TextField(
            controller: _countryCodeController,
            decoration: InputDecoration(
              labelText: 'Code',
              errorText: _isCodeValid ? null : 'Enter country code',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.phone,
          ),
        ),
        SizedBox(width: 10),
        Expanded(
          child: TextField(
            controller: _phoneNumberController,
            decoration: InputDecoration(
              labelText: 'Phone Number',
              errorText: _isPhoneValid ? null : 'Enter phone number',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.phone,
          ),
        ),
      ],
    );
  }
}
