import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: Colors.white, // Set background to white
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildSettingsCard(
              context,
              title: 'Role',
              icon: Icons.switch_account,
              onTap: () {
                Navigator.pushNamed(context, '/Selection');
              },
            ),
            _buildSettingsCard(
              context,
              title: 'Profile',
              icon: Icons.person,
              onTap: () {
                Navigator.pushNamed(context, '/profile');
              },
            ),
            SizedBox(height: 20),
            if (user != null)
              FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection('users')
                    .doc(user.uid)
                    .get(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return CircularProgressIndicator(color: Color(0xFF191970));
                  }
                  if (snapshot.hasError ||
                      !snapshot.hasData ||
                      !snapshot.data!.exists) {
                    return Container();
                  }
                  final userData =
                      snapshot.data!.data() as Map<String, dynamic>;
                  if (userData['isAdmin'] == true) {
                    return Column(
                      children: [
                        _buildSettingsCard(
                          context,
                          title: 'Admin Panel',
                          icon: Icons.admin_panel_settings,
                          onTap: () {
                            Navigator.pushNamed(context, '/adminPanel');
                          },
                        ),
                      ],
                    );
                  }
                  return Container();
                },
              ),
            Text('Contact Admin: admin@gmail.com'),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Card(
      color: Color(0xFF191970), // Set card color to midnight blue
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15.0),
      ),
      elevation: 8,
      child: InkWell(
        borderRadius: BorderRadius.circular(15.0),
        onTap: onTap,
        child: Container(
          width: 250,
          padding: EdgeInsets.symmetric(vertical: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white), // Set icon color to white
              SizedBox(width: 10),
              Text(
                title,
                style: TextStyle(
                  color: Colors.white, // Set text color to white
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ProfileScreen extends StatefulWidget {
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _nameController = TextEditingController();
  final _genderController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneNumberController = TextEditingController();
  final _emailController = TextEditingController();
  String? _imageUrl;
  File? _newImage;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (userDoc.exists) {
        final userData = userDoc.data()!;
        _nameController.text = userData['name'];
        _genderController.text = userData['gender'];
        _addressController.text = userData['address'];
        _phoneNumberController.text = userData['phoneNumber'];
        _emailController.text = userData['email'];
        setState(() {
          _imageUrl = userData['imageUrl'];
        });
      }
    }
  }

  Future<void> _saveUserProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      String? imageUrl = _imageUrl;

      if (_newImage != null) {
        // Upload the new image to Firebase Storage
        final storageRef = FirebaseStorage.instance
            .ref()
            .child('user_images')
            .child('${user.uid}.jpg');
        await storageRef.putFile(_newImage!);
        imageUrl = await storageRef.getDownloadURL();
      }

      // Update the user profile in Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({
        'name': _nameController.text,
        'gender': _genderController.text,
        'address': _addressController.text,
        'phoneNumber': _phoneNumberController.text,
        'email': _emailController.text,
        'imageUrl': imageUrl,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Profile updated successfully')),
      );
    }
  }

  Future<void> _pickImage() async {
    final pickedFile =
        await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _newImage = File(pickedFile.path);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Profile',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Color(0xFF191970),
        actions: [
          IconButton(
            icon: Icon(
              Icons.logout,
              color: Colors.white,
            ),
            onPressed: () async {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: Text('Confirm Logout'),
                    content: Text('Are you sure you want to logout?'),
                    actions: [
                      TextButton(
                        child: Text(
                          'Cancel',
                          style: TextStyle(color: Colors.blue),
                        ),
                        onPressed: () {
                          Navigator.of(context).pop(); // Close the dialog
                        },
                      ),
                      ElevatedButton(
                        child: Text('Confirm'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              Colors.red, // Red button for confirmation
                        ),
                        onPressed: () async {
                          await FirebaseAuth.instance.signOut();
                          Navigator.pushReplacementNamed(context, '/login');
                        },
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ],
      ),
      backgroundColor: Colors.white, // Set background to white
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              GestureDetector(
                onTap: _pickImage,
                child: CircleAvatar(
                  backgroundImage: _newImage != null
                      ? FileImage(_newImage!)
                      : _imageUrl != null
                          ? NetworkImage(_imageUrl!) as ImageProvider
                          : AssetImage('assets/placeholder.png'),
                  radius: 50,
                ),
              ),
              SizedBox(height: 20),
              _buildProfileTextField(_nameController, 'Name'),
              SizedBox(height: 10),
              _buildProfileTextField(_genderController, 'Gender'),
              SizedBox(height: 10),
              _buildProfileTextField(_addressController, 'Address'),
              SizedBox(height: 10),
              _buildProfileTextField(_phoneNumberController, 'Phone Number'),
              SizedBox(height: 10),
              _buildProfileTextField(_emailController, 'Email', enabled: false),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _saveUserProfile,
                style: ElevatedButton.styleFrom(
                  foregroundColor:
                      Color(0xFF191970), // Set text color to midnight blue
                  backgroundColor: Colors.white, // Set button color to white
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  'Save',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileTextField(TextEditingController controller, String label,
      {bool enabled = true}) {
    return TextField(
      controller: controller,
      enabled: enabled,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
            color: Color(0xFF191970)), // Set label color to midnight blue
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide:
              BorderSide(color: Color(0xFF191970)), // Midnight blue border
        ),
      ),
      style: TextStyle(
          color: Color(0xFF191970)), // Set text color to midnight blue
    );
  }
}
