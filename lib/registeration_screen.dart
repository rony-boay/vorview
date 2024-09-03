import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:vorviewadmin/SelectionScreen.dart';

class RegisterScreen extends StatefulWidget {
  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameController = TextEditingController();
  final _genderController = TextEditingController();
  final _addressController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController(); // New controller
  final _phoneNumberController = TextEditingController(); // New controller
  bool _isObscured = true;
  File? _image;
  bool _isLoading = false;
  bool _rememberMe = false;

  @override
  void initState() {
    super.initState();
    _loadCredentials();
  }

  Future<void> _loadCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    _emailController.text = prefs.getString('email') ?? '';
    _passwordController.text = prefs.getString('password') ?? '';
    setState(() {
      _rememberMe = prefs.getBool('rememberMe') ?? false;
    });
  }

  Future<void> _saveCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    if (_rememberMe) {
      prefs.setString('email', _emailController.text);
      prefs.setString('password', _passwordController.text);
      prefs.setBool('rememberMe', true);
    } else {
      prefs.remove('email');
      prefs.remove('password');
      prefs.setBool('rememberMe', false);
    }
  }

  Future<void> _pickImage() async {
    final pickedFile =
        await ImagePicker().pickImage(source: ImageSource.gallery);
    setState(() {
      _image = File(pickedFile!.path);
    });
  }

  Future<void> _register() async {
    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Passwords do not match')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Check if email already exists
      final signInMethods = await FirebaseAuth.instance
          .fetchSignInMethodsForEmail(_emailController.text);
      if (signInMethods.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Account already exists with this email')),
        );
        return;
      }

      // Register the new user
      final UserCredential userCredential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text,
        password: _passwordController.text,
      );

      User? user = userCredential.user;
      final userId = user!.uid;

      String imageUrl = '';
      if (_image != null) {
        final storageRef = FirebaseStorage.instance
            .ref()
            .child('user_images')
            .child('$userId.jpg');
        await storageRef.putFile(_image!);
        imageUrl = await storageRef.getDownloadURL();
      }

      // Save user data to Firestore
      await FirebaseFirestore.instance.collection('users').doc(userId).set({
        'name': _nameController.text,
        'gender': _genderController.text,
        'address': _addressController.text,
        'phoneNumber': _phoneNumberController.text,
        'email': _emailController.text,
        'imageUrl': imageUrl,
        'isAdmin': false,
        'blocked': false,
      });

      await _saveCredentials();
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => SelectionScreen()),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Registration failed: ${e.toString()}')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _registerWithGoogle() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final GoogleSignIn googleSignIn = GoogleSignIn(
        scopes: ['email'],
        signInOption: SignInOption.standard,
        forceCodeForRefreshToken: true,
      );

      // Clear any previous sign-in account to force the user to select an account
      await googleSignIn.signOut();

      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        setState(() {
          _isLoading = false;
        });
        return; // User canceled the sign-in process
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential =
          await FirebaseAuth.instance.signInWithCredential(credential);

      User? user = userCredential.user;
      final userId = user!.uid;

      final DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      if (!userDoc.exists) {
        // Save user data to Firestore
        await FirebaseFirestore.instance.collection('users').doc(userId).set({
          'name': user.displayName ?? '',
          'gender': '',
          'address': '',
          'phoneNumber': user.phoneNumber ?? '',
          'email': user.email ?? '',
          'imageUrl': user.photoURL ?? '',
          'isAdmin': false,
          'blocked': false,
        });
      }

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => SelectionScreen()),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Google Sign-In failed: ${e.toString()}')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // White background
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset('assets/vorvie.jpg',
                    height: 100), // Logo at the top
                SizedBox(height: 40),
                TextField(
                  controller: _nameController,
                  style:
                      TextStyle(color: Color(0xFF191970)), // Midnight blue text
                  decoration: InputDecoration(
                    labelText: 'Full Name',
                    labelStyle: TextStyle(
                        color: Color(0xFF191970)), // Midnight blue label
                    filled: true,
                    fillColor: Colors.white24,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.0),
                      borderSide: BorderSide(
                          color: Color(0xFF191970)), // Midnight blue border
                    ),
                    prefixIcon: Icon(Icons.person,
                        color: Color(0xFF191970)), // Midnight blue icon
                  ),
                ),
                SizedBox(height: 20),
                TextField(
                  controller: _genderController,
                  style:
                      TextStyle(color: Color(0xFF191970)), // Midnight blue text
                  decoration: InputDecoration(
                    labelText: 'Gender',
                    labelStyle: TextStyle(
                        color: Color(0xFF191970)), // Midnight blue label
                    filled: true,
                    fillColor: Colors.white24,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.0),
                      borderSide: BorderSide(
                          color: Color(0xFF191970)), // Midnight blue border
                    ),
                    prefixIcon: Icon(Icons.male,
                        color: Color(0xFF191970)), // Midnight blue icon
                  ),
                ),
                SizedBox(height: 20),
                TextField(
                  controller: _addressController,
                  style:
                      TextStyle(color: Color(0xFF191970)), // Midnight blue text
                  decoration: InputDecoration(
                    labelText: 'Address',
                    labelStyle: TextStyle(
                        color: Color(0xFF191970)), // Midnight blue label
                    filled: true,
                    fillColor: Colors.white24,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.0),
                      borderSide: BorderSide(
                          color: Color(0xFF191970)), // Midnight blue border
                    ),
                    prefixIcon: Icon(Icons.location_on,
                        color: Color(0xFF191970)), // Midnight blue icon
                  ),
                ),
                SizedBox(height: 20),
                TextField(
                  controller: _phoneNumberController, // Phone number field
                  style:
                      TextStyle(color: Color(0xFF191970)), // Midnight blue text
                  decoration: InputDecoration(
                    labelText: 'Phone Number',
                    labelStyle: TextStyle(
                        color: Color(0xFF191970)), // Midnight blue label
                    filled: true,
                    fillColor: Colors.white24,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.0),
                      borderSide: BorderSide(
                          color: Color(0xFF191970)), // Midnight blue border
                    ),
                    prefixIcon: Icon(Icons.phone,
                        color: Color(0xFF191970)), // Midnight blue icon
                  ),
                ),
                SizedBox(height: 20),
                TextField(
                  controller: _emailController,
                  style:
                      TextStyle(color: Color(0xFF191970)), // Midnight blue text
                  decoration: InputDecoration(
                    labelText: 'Email',
                    labelStyle: TextStyle(
                        color: Color(0xFF191970)), // Midnight blue label
                    filled: true,
                    fillColor: Colors.white24,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.0),
                      borderSide: BorderSide(
                          color: Color(0xFF191970)), // Midnight blue border
                    ),
                    prefixIcon: Icon(Icons.email,
                        color: Color(0xFF191970)), // Midnight blue icon
                  ),
                ),
                SizedBox(height: 20),
                TextField(
                  controller: _passwordController,
                  obscureText: _isObscured,
                  style:
                      TextStyle(color: Color(0xFF191970)), // Midnight blue text
                  decoration: InputDecoration(
                    labelText: 'Password',
                    labelStyle: TextStyle(
                        color: Color(0xFF191970)), // Midnight blue label
                    filled: true,
                    fillColor: Colors.white24,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.0),
                      borderSide: BorderSide(
                          color: Color(0xFF191970)), // Midnight blue border
                    ),
                    prefixIcon: Icon(Icons.lock,
                        color: Color(0xFF191970)), // Midnight blue icon
                    suffixIcon: IconButton(
                      icon: Icon(
                        _isObscured ? Icons.visibility_off : Icons.visibility,
                        color: Color(0xFF191970),
                      ),
                      onPressed: () {
                        setState(() {
                          _isObscured = !_isObscured;
                        });
                      },
                    ),
                  ),
                ),
                SizedBox(height: 20),
                TextField(
                  controller: _confirmPasswordController,
                  obscureText: _isObscured,
                  style:
                      TextStyle(color: Color(0xFF191970)), // Midnight blue text
                  decoration: InputDecoration(
                    labelText: 'Confirm Password',
                    labelStyle: TextStyle(
                        color: Color(0xFF191970)), // Midnight blue label
                    filled: true,
                    fillColor: Colors.white24,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.0),
                      borderSide: BorderSide(
                          color: Color(0xFF191970)), // Midnight blue border
                    ),
                    prefixIcon: Icon(Icons.lock,
                        color: Color(0xFF191970)), // Midnight blue icon
                    suffixIcon: IconButton(
                      icon: Icon(
                        _isObscured ? Icons.visibility_off : Icons.visibility,
                        color: Color(0xFF191970),
                      ),
                      onPressed: () {
                        setState(() {
                          _isObscured = !_isObscured;
                        });
                      },
                    ),
                  ),
                ),
                SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Checkbox(
                      value: _rememberMe,
                      onChanged: (value) {
                        setState(() {
                          _rememberMe = value!;
                        });
                      },
                    ),
                    ElevatedButton.icon(
                      onPressed: _registerWithGoogle,
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: Color(0xFF191970),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                        padding: EdgeInsets.symmetric(
                          horizontal: 60,
                          vertical: 15,
                        ),
                      ),
                      icon: Icon(Icons.login, color: Colors.white),
                      label: Text('Sign in with Google'),
                    ),

                    Text('Remember me',
                        style: TextStyle(
                            color: Color(0xFF191970))), // Midnight blue text
                  ],
                ),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _register,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF191970), // Midnight blue button
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                  ),
                  child: _isLoading
                      ? CircularProgressIndicator(
                          color: Colors.white,
                        )
                      : Text('Register'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
