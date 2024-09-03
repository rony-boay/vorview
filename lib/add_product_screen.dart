import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AddProductScreen extends StatefulWidget {
  const AddProductScreen({super.key});

  @override
  _AddProductScreenState createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _productNameController = TextEditingController();
  final _addressController = TextEditingController();
  final _priceController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressFormController = TextEditingController();
  final _genderController = TextEditingController();
  final _businessNameController = TextEditingController();
  final _businessDescriptionController = TextEditingController();

  XFile? _image;
  XFile? _approvalImage;
  bool _isSubmitting = false;
  bool _isPickingImage = false;
  bool _isPickingApprovalImage = false;
  bool _isApproved = false;

  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _checkApprovalStatus();
  }

  void _onTabTapped(int index) {
    setState(() {
      _selectedIndex = index;
      switch (index) {
        case 1:
          Navigator.of(context)
              .push(MaterialPageRoute(builder: (context) => ServicesScreen()));
          break;
        case 2:
          Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => BusinessProfileScreen()));
          break;
      }
    });
  }

  Future<void> _checkApprovalStatus() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance
          .collection('business_owners')
          .doc(user.uid)
          .get();
      setState(() {
        _isApproved = doc.exists && doc.data()?['approved'] == true;
      });
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    setState(() {
      _isPickingImage = true;
    });
    final pickedImage = await picker.pickImage(source: ImageSource.gallery);
    setState(() {
      _image = pickedImage;
      _isPickingImage = false;
    });
  }

  Future<void> _pickApprovalImage() async {
    final picker = ImagePicker();
    setState(() {
      _isPickingApprovalImage = true;
    });
    final pickedImage = await picker.pickImage(source: ImageSource.gallery);
    setState(() {
      _approvalImage = pickedImage;
      _isPickingApprovalImage = false;
    });
  }

  Future<void> _submitApprovalRequest() async {
    if (_firstNameController.text.isEmpty ||
        _lastNameController.text.isEmpty ||
        _emailController.text.isEmpty ||
        _addressFormController.text.isEmpty ||
        _genderController.text.isEmpty ||
        _businessNameController.text.isEmpty ||
        _businessDescriptionController.text.isEmpty ||
        _approvalImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please fill all fields and upload an image')),
      );
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return;
    }

    final storageRef = FirebaseStorage.instance
        .ref()
        .child('approval_images/${DateTime.now().toString()}');
    final uploadTask = storageRef.putFile(File(_approvalImage!.path));
    final imageUrl = await (await uploadTask).ref.getDownloadURL();

    await FirebaseFirestore.instance
        .collection('business_owner_requests')
        .doc(user.uid)
        .set({
      'firstName': _firstNameController.text,
      'lastName': _lastNameController.text,
      'email': _emailController.text,
      'address': _addressFormController.text,
      'gender': _genderController.text,
      'businessName': _businessNameController.text,
      'businessDescription': _businessDescriptionController.text,
      'imageUrl': imageUrl,
      'timestamp': FieldValue.serverTimestamp(),
    });

    _notifyAdmins();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Request sent, waiting for admin approval')),
    );
  }

  Future<void> _notifyAdmins() async {
    final adminSnapshot =
        await FirebaseFirestore.instance.collection('admins').get();
    for (var doc in adminSnapshot.docs) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(doc.id)
          .collection('notifications')
          .add({
        'title': 'New Business Owner Request',
        'body': 'A new business owner request needs your attention.',
        'timestamp': FieldValue.serverTimestamp(),
      });
    }
  }

  Future<void> _submitProduct() async {
    if (_productNameController.text.isEmpty ||
        _addressController.text.isEmpty ||
        _priceController.text.isEmpty ||
        _image == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please fill all fields and pick an image')),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() {
        _isSubmitting = false;
      });
      return;
    }

    final storageRef = FirebaseStorage.instance
        .ref()
        .child('product_images/${DateTime.now().toString()}');
    final uploadTask = storageRef.putFile(File(_image!.path));
    final imageUrl = await (await uploadTask).ref.getDownloadURL();

    await FirebaseFirestore.instance.collection('products').add({
      'name': _productNameController.text,
      'address': _addressController.text,
      'price': _priceController.text,
      'imageUrl': imageUrl,
      'userId': user.uid,
    });

    setState(() {
      _isSubmitting = false;
    });

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => AddProductScreen()),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label,
      {bool isNumber = false}) {
    return TextField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      style: TextStyle(color: Color(0xFF191970)), // Midnight blue for text
      decoration: InputDecoration(
        labelText: label,
        labelStyle:
            TextStyle(color: Color(0xFF191970)), // Midnight blue for label
        filled: true,
        fillColor: Colors.white24,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide:
              BorderSide(color: Color(0xFF191970)), // Midnight blue border
        ),
      ),
    );
  }

  Widget _buildImagePicker() {
    return _isPickingImage
        ? CircularProgressIndicator(
            color: Color(0xFF191970)) // Midnight blue for progress indicator
        : _image != null
            ? Image.file(File(_image!.path), height: 200)
            : TextButton(
                onPressed: _pickImage,
                child:
                    Text('Pick Image', style: TextStyle(color: Colors.white)),
                style: TextButton.styleFrom(
                    backgroundColor:
                        Color(0xFF191970)), // Midnight blue for button
              );
  }

  Widget _buildSubmitButton() {
    return _isSubmitting
        ? CircularProgressIndicator(
            color: Color(0xFF191970)) // Midnight blue for progress indicator
        : ElevatedButton(
            onPressed: _submitProduct,
            child: Text('Submit'),
            style: ElevatedButton.styleFrom(
              foregroundColor: Colors.white, // White for text
              backgroundColor:
                  Color(0xFF191970), // Midnight blue for button background
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              padding: EdgeInsets.symmetric(horizontal: 50, vertical: 15),
              textStyle: TextStyle(fontSize: 16),
            ),
          );
  }

  Widget _buildApprovalForm() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTextField(_firstNameController, 'First Name'),
            SizedBox(height: 16),
            _buildTextField(_lastNameController, 'Last Name'),
            SizedBox(height: 16),
            _buildTextField(_emailController, 'Email'),
            SizedBox(height: 16),
            _buildTextField(_addressFormController, 'Address'),
            SizedBox(height: 16),
            _buildTextField(_genderController, 'Gender'),
            SizedBox(height: 16),
            _buildTextField(_businessNameController, 'Business Name'),
            SizedBox(height: 16),
            _buildTextField(
                _businessDescriptionController, 'Business Description'),
            SizedBox(height: 20),
            _isPickingApprovalImage
                ? CircularProgressIndicator(
                    color: Color(
                        0xFF191970)) // Midnight blue for progress indicator
                : _approvalImage != null
                    ? Image.file(File(_approvalImage!.path), height: 200)
                    : TextButton(
                        onPressed: _pickApprovalImage,
                        child: Text('Legal Document Image',
                            style: TextStyle(color: Colors.white)),
                        style: TextButton.styleFrom(
                            backgroundColor: Color(
                                0xFF191970)), // Midnight blue for button background
                      ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _submitApprovalRequest,
              child: Text('Submit for Approval'),
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white, // White for text
                backgroundColor:
                    Color(0xFF191970), // Midnight blue for button background
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                padding: EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                textStyle: TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // White background
      appBar: AppBar(
        backgroundColor: Color(0xFF191970), // Midnight blue for AppBar
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title:
            Text('Add Product/Service', style: TextStyle(color: Colors.white)),
      ),
      body: _isApproved
          ? SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTextField(
                        _productNameController, 'Product/Service Name'),
                    SizedBox(height: 16),
                    _buildTextField(_addressController, 'Address'),
                    SizedBox(height: 16),
                    _buildTextField(_priceController, 'Price', isNumber: true),
                    SizedBox(height: 20),
                    _buildImagePicker(),
                    SizedBox(height: 20),
                    _buildSubmitButton(),
                  ],
                ),
              ),
            )
          : _buildApprovalForm(),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor:
            Color(0xFF191970), // Midnight blue for bottom navigation
        currentIndex: _selectedIndex,
        onTap: _onTabTapped,
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.home, color: Colors.white),
            label: 'Products',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.business, color: Colors.white),
            label: 'Services',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_circle, color: Colors.white),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

class ServicesScreen extends StatefulWidget {
  @override
  _ServicesScreenState createState() => _ServicesScreenState();
}

class _ServicesScreenState extends State<ServicesScreen> {
  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser!.uid;
    Future<bool> _checkIfUserIsBlocked() async {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return false;

      DocumentSnapshot<Map<String, dynamic>> snapshot = await FirebaseFirestore
          .instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (snapshot.exists) {
        return snapshot.data()?['blocked'] ?? false;
      }

      return false;
    }

    return Scaffold(
      backgroundColor: Colors.white, // Set background color to white
      appBar: AppBar(
        backgroundColor: Colors.white, // Set AppBar background color to white
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: Color(0xFF191970), // Set icon color to midnight blue
          ),
          onPressed: () {
            Navigator.pop(context); // Navigate back to the previous screen
          },
        ),
        title: Column(
          children: [
            SizedBox(
              height: 30,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset('assets/vorvie.jpg', height: 200),
                SizedBox(
                  width: 65,
                )
              ],
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('products')
            .where('userId', isEqualTo: userId)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(
                child: CircularProgressIndicator(
                    color: Color(
                        0xFF191970))); // Set spinner color to midnight blue
          }
          final products = snapshot.data!.docs;
          return ListView.builder(
            itemCount: products.length,
            itemBuilder: (context, index) {
              final product = products[index];
              return Card(
                color: Color(
                    0xFF191970), // Set card background color to midnight blue
                margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                child: ListTile(
                  leading: Image.network(product['imageUrl'],
                      width: 50, height: 50, fit: BoxFit.cover),
                  title: Text(product['name'],
                      style: TextStyle(
                          fontWeight: FontWeight.bold, color: Colors.white)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(product['address'],
                          style: TextStyle(color: Colors.white)),
                      Text('\RS${product['price']}',
                          style: TextStyle(color: Colors.white)),
                    ],
                  ),
                  trailing: IconButton(
                    icon: Icon(Icons.delete, color: Colors.white),
                    onPressed: () async {
                      await FirebaseFirestore.instance
                          .collection('products')
                          .doc(product.id)
                          .delete();

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Product deleted successfully'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    },
                  ),
                  onTap: () async {
                    bool isBlocked = await _checkIfUserIsBlocked();
                    if (isBlocked) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content:
                              Text('You are blocked and cannot leave reviews.'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    } else {
                      showDialog(
                        context: context,
                        builder: (context) =>
                            ReviewsDialog(productId: product.id),
                      );
                    }
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class BusinessProfileScreen extends StatelessWidget {
  const BusinessProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: Colors.white, // Set background color to white
      appBar: AppBar(
        title: Text('Business Profile'),
        backgroundColor: Colors.white, // Set AppBar background color to white
        titleTextStyle: TextStyle(
            color: Color(0xFF191970),
            fontSize: 20), // Set title text color to midnight blue
        actions: [
          IconButton(
            icon: Icon(Icons.logout,
                color: Color(0xFF191970)), // Set icon color to midnight blue
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
                          style: TextStyle(
                              color: Color(
                                  0xFF191970)), // Set button text color to midnight blue
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
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('business_owners')
            .doc(user?.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }
          final data = snapshot.data!.data() as Map<String, dynamic>?;
          if (data == null) {
            return Center(child: Text('No profile data found.'));
          }
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                ListTile(
                  title: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Color(0xFF191970)),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    padding: EdgeInsets.all(8),
                    child: Text(
                      '${data['firstName']} ${data['lastName']}',
                      style: TextStyle(color: Color(0xFF191970)),
                    ),
                  ),
                  subtitle: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Color(0xFF191970)),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    padding: EdgeInsets.all(8),
                    child: Text(
                      data['businessName'],
                      style: TextStyle(color: Color(0xFF191970)),
                    ),
                  ),
                ),
                ListTile(
                  title: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Color(0xFF191970)),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    padding: EdgeInsets.all(8),
                    child: Text(
                      'Email',
                      style: TextStyle(color: Color(0xFF191970)),
                    ),
                  ),
                  subtitle: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Color(0xFF191970)),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    padding: EdgeInsets.all(8),
                    child: Text(
                      data['email'],
                      style: TextStyle(color: Color(0xFF191970)),
                    ),
                  ),
                ),
                ListTile(
                  title: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Color(0xFF191970)),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    padding: EdgeInsets.all(8),
                    child: Text(
                      'Address',
                      style: TextStyle(color: Color(0xFF191970)),
                    ),
                  ),
                  subtitle: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Color(0xFF191970)),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    padding: EdgeInsets.all(8),
                    child: Text(
                      data['address'],
                      style: TextStyle(color: Color(0xFF191970)),
                    ),
                  ),
                ),
                ListTile(
                  title: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Color(0xFF191970)),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    padding: EdgeInsets.all(8),
                    child: Text(
                      'Gender',
                      style: TextStyle(color: Color(0xFF191970)),
                    ),
                  ),
                  subtitle: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Color(0xFF191970)),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    padding: EdgeInsets.all(8),
                    child: Text(
                      data['gender'],
                      style: TextStyle(color: Color(0xFF191970)),
                    ),
                  ),
                ),
                ListTile(
                  title: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Color(0xFF191970)),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    padding: EdgeInsets.all(8),
                    child: Text(
                      'Business Description',
                      style: TextStyle(color: Color(0xFF191970)),
                    ),
                  ),
                  subtitle: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Color(0xFF191970)),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    padding: EdgeInsets.all(8),
                    child: Text(
                      data['businessDescription'],
                      style: TextStyle(color: Color(0xFF191970)),
                    ),
                  ),
                ),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => EditProfileScreen(
                          profileData: data,
                        ),
                      ),
                    );
                  },
                  child: Text('Edit Profile',
                      style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(
                        0xFF191970), // Set button background color to midnight blue
                    padding: EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                    textStyle: TextStyle(fontSize: 16),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class EditProfileScreen extends StatefulWidget {
  final Map<String, dynamic> profileData;

  EditProfileScreen({required this.profileData});

  @override
  _EditProfileScreenState createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();
  final _genderController = TextEditingController();
  final _businessNameController = TextEditingController();
  final _businessDescriptionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _firstNameController.text = widget.profileData['firstName'] ?? '';
    _lastNameController.text = widget.profileData['lastName'] ?? '';
    _emailController.text = widget.profileData['email'] ?? '';
    _addressController.text = widget.profileData['address'] ?? '';
    _genderController.text = widget.profileData['gender'] ?? '';
    _businessNameController.text = widget.profileData['businessName'] ?? '';
    _businessDescriptionController.text =
        widget.profileData['businessDescription'] ?? '';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Set background color to white
      appBar: AppBar(
        title: Text('Edit Profile'),
        backgroundColor: Colors.white, // Set AppBar background color to white
        titleTextStyle: TextStyle(
            color: Color(0xFF191970),
            fontSize: 20), // Set title text color to midnight blue
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: Color(0xFF191970), // Set icon color to midnight blue
          ),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: _firstNameController,
                decoration: InputDecoration(
                  labelText: 'First Name',
                  labelStyle: TextStyle(
                      color: Color(
                          0xFF191970)), // Set label text color to midnight blue
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                    borderSide: BorderSide(
                        color: Color(0xFF191970)), // Midnight blue border
                  ),
                ),
              ),
              SizedBox(height: 16),
              TextField(
                controller: _lastNameController,
                decoration: InputDecoration(
                  labelText: 'Last Name',
                  labelStyle: TextStyle(color: Color(0xFF191970)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                    borderSide: BorderSide(
                        color: Color(0xFF191970)), // Midnight blue border
                  ), // Set label text color to midnight blue
                ),
              ),
              SizedBox(height: 16),
              TextField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: 'Email',
                  labelStyle: TextStyle(color: Color(0xFF191970)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                    borderSide: BorderSide(
                        color: Color(0xFF191970)), // Midnight blue border
                  ), // Set label text color to midnight blue
                ),
              ),
              SizedBox(height: 16),
              TextField(
                controller: _addressController,
                decoration: InputDecoration(
                  labelText: 'Address',
                  labelStyle: TextStyle(color: Color(0xFF191970)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                    borderSide: BorderSide(
                        color: Color(0xFF191970)), // Midnight blue border
                  ), // Set label text color to midnight blue
                ),
              ),
              SizedBox(height: 16),
              TextField(
                controller: _genderController,
                decoration: InputDecoration(
                  labelText: 'Gender',
                  labelStyle: TextStyle(color: Color(0xFF191970)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                    borderSide: BorderSide(
                        color: Color(0xFF191970)), // Midnight blue border
                  ), // Set label text color to midnight blue
                ),
              ),
              SizedBox(height: 16),
              TextField(
                controller: _businessNameController,
                decoration: InputDecoration(
                  labelText: 'Business Name',
                  labelStyle: TextStyle(color: Color(0xFF191970)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                    borderSide: BorderSide(
                        color: Color(0xFF191970)), // Midnight blue border
                  ), // Set label text color to midnight blue
                ),
              ),
              SizedBox(height: 16),
              TextField(
                controller: _businessDescriptionController,
                decoration: InputDecoration(
                  labelText: 'Business Description',
                  labelStyle: TextStyle(color: Color(0xFF191970)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                    borderSide: BorderSide(
                        color: Color(0xFF191970)), // Midnight blue border
                  ), // Set label text color to midnight blue
                ),
              ),
              SizedBox(height: 32),
              ElevatedButton(
                onPressed: () async {
                  final updatedProfileData = {
                    'firstName': _firstNameController.text,
                    'lastName': _lastNameController.text,
                    'email': _emailController.text,
                    'address': _addressController.text,
                    'gender': _genderController.text,
                    'businessName': _businessNameController.text,
                    'businessDescription': _businessDescriptionController.text,
                  };

                  final user = FirebaseAuth.instance.currentUser;

                  if (user != null) {
                    await FirebaseFirestore.instance
                        .collection('business_owners')
                        .doc(user.uid)
                        .update(updatedProfileData);

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Profile updated successfully'),
                        backgroundColor: Color(
                            0xFF191970), // Set snackbar background color to midnight blue
                      ),
                    );
                    Navigator.pop(context);
                  }
                },
                child: Text('Save', style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(
                      0xFF191970), // Set button background color to midnight blue
                  padding: EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                  textStyle: TextStyle(fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ReviewsDialog extends StatefulWidget {
  final String productId;

  ReviewsDialog({required this.productId});

  @override
  _ReviewsDialogState createState() => _ReviewsDialogState();
}

class _ReviewsDialogState extends State<ReviewsDialog> {
  TextEditingController _reviewController = TextEditingController();
  TextEditingController _replyController = TextEditingController();
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();
  double _rating = 0.0;
  bool _hasSubmittedReview = false; // Track if the user has submitted a review

  @override
  void initState() {
    super.initState();
    _checkIfReviewed();
  }

  Future<void> _checkIfReviewed() async {
    final reviewSnapshot = await FirebaseFirestore.instance
        .collection('reviews')
        .where('productId', isEqualTo: widget.productId)
        .where('userId', isEqualTo: FirebaseAuth.instance.currentUser!.uid)
        .get();

    setState(() {
      _hasSubmittedReview = reviewSnapshot.docs.isNotEmpty;
    });
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    setState(() {
      _imageFile = pickedFile != null ? File(pickedFile.path) : null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white, // Background color
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('reviews')
                    .where('productId', isEqualTo: widget.productId)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return Center(child: CircularProgressIndicator());
                  }
                  final reviews = snapshot.data!.docs;
                  return ListView.builder(
                    itemCount: reviews.length,
                    itemBuilder: (context, index) {
                      final review = reviews[index];
                      final isClaimed =
                          review['isClaimed'] ?? false; // Handle missing field

                      return Card(
                        key: ValueKey(review.id),
                        margin: EdgeInsets.symmetric(vertical: 8),
                        color: Colors.white, // White background for cards
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    review['userName'] ?? 'Anonymous',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Color(
                                          0xFF191970), // Midnight blue text color
                                    ),
                                  ),
                                  if (!isClaimed)
                                    // IconButton(
                                    //   icon: Icon(Icons.claim,
                                    //       color: Color(0xFF191970)),
                                    //   onPressed: () {
                                    //     _claimReview(review.id);
                                    //   },
                                    // ),
                                    ElevatedButton(
                                      onPressed: () {
                                        _claimReview(review.id);
                                      },
                                      style: ElevatedButton.styleFrom(
                                        foregroundColor:
                                            Colors.white, // White text
                                        backgroundColor: Color(
                                            0xFF191970), // Midnight blue button
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(12.0),
                                        ),
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 80,
                                          vertical: 15,
                                        ),
                                      ),
                                      child: Text('Claim'),
                                    ),
                                ],
                              ),
                              SizedBox(height: 4),
                              if (review['imageUrl'] != null)
                                GestureDetector(
                                  onTap: () {
                                    showDialog(
                                      context: context,
                                      builder: (context) => Dialog(
                                        child:
                                            Image.network(review['imageUrl']),
                                      ),
                                    );
                                  },
                                  child: Image.network(
                                    review['imageUrl'],
                                    height: 150,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              RatingBarIndicator(
                                rating: (review['rating'] ?? 0.0).toDouble(),
                                itemBuilder: (context, index) => Icon(
                                  Icons.star,
                                  color: Colors.amber,
                                ),
                                itemCount: 5,
                                itemSize: 20.0,
                                direction: Axis.horizontal,
                              ),
                              Text(
                                review['reviewText'] ?? 'No review text',
                                style: TextStyle(
                                    color: Color(
                                        0xFF191970)), // Midnight blue text color
                              ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  IconButton(
                                    icon: Icon(
                                      Icons.thumb_up,
                                      color: review['likedBy'].contains(
                                              FirebaseAuth
                                                  .instance.currentUser!.uid)
                                          ? Color(0xFF191970)
                                          : null,
                                    ),
                                    onPressed: () {
                                      _toggleLike(review.id, true);
                                    },
                                  ),
                                  IconButton(
                                    icon: Icon(
                                      Icons.thumb_down,
                                      color: review['dislikedBy'].contains(
                                              FirebaseAuth
                                                  .instance.currentUser!.uid)
                                          ? Colors.red
                                          : null,
                                    ),
                                    onPressed: () {
                                      _toggleLike(review.id, false);
                                    },
                                  ),
                                ],
                              ),
                              _buildRepliesSection(review.id),
                              if (!_hasSubmittedReview)
                                TextField(
                                  controller: _replyController,
                                  decoration: InputDecoration(
                                    labelText: 'Write a reply...',
                                    labelStyle: TextStyle(
                                        color: Color(
                                            0xFF191970)), // Midnight blue hint color
                                    enabledBorder: OutlineInputBorder(
                                      borderSide: BorderSide(
                                          color: Color(
                                              0xFF191970)), // Midnight blue border
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderSide: BorderSide(
                                          color: Color(
                                              0xFF191970)), // Midnight blue border
                                    ),
                                  ),
                                  style: TextStyle(
                                      color: Color(
                                          0xFF191970)), // Midnight blue text color
                                  cursorColor: Color(
                                      0xFF191970), // Midnight blue cursor color
                                ),
                              if (!_hasSubmittedReview)
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    TextButton(
                                      onPressed: () {
                                        _submitReply(review.id);
                                      },
                                      child: Text(
                                        'Submit',
                                        style: TextStyle(
                                            color: Color(
                                                0xFF191970)), // Midnight blue text color
                                      ),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            if (!_hasSubmittedReview)
              Column(
                children: [
                  TextField(
                    controller: _reviewController,
                    decoration: InputDecoration(
                      labelText: 'Write a review...',
                      labelStyle: TextStyle(
                          color: Color(0xFF191970)), // Midnight blue hint color
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                            color: Color(0xFF191970)), // Midnight blue border
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                            color: Color(0xFF191970)), // Midnight blue border
                      ),
                    ),
                    style: TextStyle(
                        color: Color(0xFF191970)), // Midnight blue text color
                    cursorColor:
                        Color(0xFF191970), // Midnight blue cursor color
                  ),
                  RatingBar.builder(
                    initialRating: _rating,
                    minRating: 1,
                    direction: Axis.horizontal,
                    allowHalfRating: true,
                    itemCount: 5,
                    itemPadding: EdgeInsets.symmetric(horizontal: 4.0),
                    itemBuilder: (context, _) => Icon(
                      Icons.star,
                      color: Colors.amber,
                    ),
                    onRatingUpdate: (rating) {
                      setState(() {
                        _rating = rating;
                      });
                    },
                  ),
                  Row(
                    children: [
                      TextButton(
                        onPressed: _pickImage,
                        child: Text('Upload Image',
                            style: TextStyle(
                                color: Color(
                                    0xFF191970))), // Midnight blue text color
                      ),
                      TextButton(
                        onPressed: _submitReview,
                        child: Text('Submit Review',
                            style: TextStyle(
                                color: Color(
                                    0xFF191970))), // Midnight blue text color
                      ),
                    ],
                  ),
                  if (_imageFile != null)
                    Image.file(_imageFile!, height: 100, fit: BoxFit.cover),
                ],
              ),
            if (_hasSubmittedReview)
              Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: Text(
                  'You have already submitted a review for this product.',
                  style: TextStyle(
                      color: Color(0xFF191970)), // Midnight blue text color
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildRepliesSection(String reviewId) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('replies')
          .where('reviewId', isEqualTo: reviewId)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(child: CircularProgressIndicator());
        }
        final replies = snapshot.data!.docs;
        return ListView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          itemCount: replies.length,
          itemBuilder: (context, index) {
            final reply = replies[index];
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Divider(
                    color: Color(0xFF191970)), // Midnight blue divider color
                Text(
                  reply['userName'] ?? 'Anonymous',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF191970)), // Midnight blue text color
                ),
                Text(reply['replyText'] ?? 'No reply text',
                    style: TextStyle(
                        color: Color(0xFF191970))), // Midnight blue text color
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _submitReview() async {
    if (_reviewController.text.isEmpty || _rating == 0.0) {
      // Show error if the review or rating is missing
      return;
    }

    final reviewData = {
      'productId': widget.productId,
      'userId': FirebaseAuth.instance.currentUser!.uid,
      'userName': FirebaseAuth.instance.currentUser!.displayName ?? 'Anonymous',
      'reviewText': _reviewController.text,
      'rating': _rating,
      'timestamp': Timestamp.now(),
      'imageUrl': _imageFile != null ? await _uploadImage(_imageFile!) : null,
      'likedBy': [],
      'dislikedBy': [],
    };

    await FirebaseFirestore.instance.collection('reviews').add(reviewData);

    setState(() {
      _hasSubmittedReview = true;
    });

    _reviewController.clear();
    _rating = 0.0;
    _imageFile = null;
  }

  Future<void> _submitReply(String reviewId) async {
    if (_replyController.text.isEmpty) {
      // Show error if the reply text is empty
      return;
    }

    final replyData = {
      'reviewId': reviewId,
      'userId': FirebaseAuth.instance.currentUser!.uid,
      'userName': FirebaseAuth.instance.currentUser!.displayName ?? 'Anonymous',
      'replyText': _replyController.text,
      'timestamp': Timestamp.now(),
    };

    await FirebaseFirestore.instance.collection('replies').add(replyData);

    _replyController.clear();
  }

  Future<void> _claimReview(String reviewId) async {
    await FirebaseFirestore.instance
        .collection('reviews')
        .doc(reviewId)
        .update({
      'isClaimed': true,
    });
  }

  Future<String?> _uploadImage(File image) async {
    final storageRef = FirebaseStorage.instance
        .ref()
        .child('review_images')
        .child('${DateTime.now().millisecondsSinceEpoch}.jpg');

    final uploadTask = storageRef.putFile(image);

    final snapshot = await uploadTask.whenComplete(() => {});
    final downloadUrl = await snapshot.ref.getDownloadURL();

    return downloadUrl;
  }

  Future<void> _toggleLike(String reviewId, bool isLike) async {
    final userId = FirebaseAuth.instance.currentUser!.uid;
    final reviewDoc =
        FirebaseFirestore.instance.collection('reviews').doc(reviewId);

    final reviewSnapshot = await reviewDoc.get();
    final reviewData = reviewSnapshot.data()!;
    final likedBy = List<String>.from(reviewData['likedBy'] ?? []);
    final dislikedBy = List<String>.from(reviewData['dislikedBy'] ?? []);

    if (isLike) {
      if (likedBy.contains(userId)) {
        likedBy.remove(userId);
      } else {
        likedBy.add(userId);
        dislikedBy.remove(userId);
      }
    } else {
      if (dislikedBy.contains(userId)) {
        dislikedBy.remove(userId);
      } else {
        dislikedBy.add(userId);
        likedBy.remove(userId);
      }
    }

    await reviewDoc.update({
      'likedBy': likedBy,
      'dislikedBy': dislikedBy,
    });
  }
}
