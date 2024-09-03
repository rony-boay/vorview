import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:vorviewadmin/add_product_screen.dart';
import 'package:vorviewadmin/explore_product_screen.dart';

class SelectionScreen extends StatelessWidget {
  const SelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Set background to white
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Card(
              color: const Color(0xFF191970), // Set card color to midnight blue
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15.0),
              ),
              elevation: 8,
              child: InkWell(
                borderRadius: BorderRadius.circular(15.0),
                onTap: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                        builder: (context) => ExploreProductScreen()),
                  );
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(vertical: 20, horizontal: 40),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(
                        Icons
                            .supervised_user_circle, // Choose the icon you prefer
                        color: Colors.white, // Set icon color to white
                        size: 24, // Set the icon size
                      ),
                      SizedBox(width: 10), // Add spacing between icon and text
                      Text(
                        'User',
                        style: TextStyle(
                          color: Colors.white, // Set text color to white
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 30),
            Card(
              color: const Color(0xFF191970), // Set card color to midnight blue
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15.0),
              ),
              elevation: 8,
              child: InkWell(
                borderRadius: BorderRadius.circular(15.0),
                onTap: () async {
                  // Check if the user is blocked before navigating
                  bool isBlocked = await _checkIfUserIsBlocked();
                  if (isBlocked) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Blocked! Please contact admin.'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  } else {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const AddProductScreen()),
                    );
                  }
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(vertical: 20, horizontal: 40),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(
                        Icons.business, // Choose the icon you prefer
                        color: Colors.white, // Set icon color to white
                        size: 24, // Set the icon size
                      ),
                      SizedBox(width: 10), // Add spacing between icon and text
                      Text(
                        'Business Owner',
                        style: TextStyle(
                          color: Colors.white, // Set text color to white
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Function to check if the current user is blocked
  Future<bool> _checkIfUserIsBlocked() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;

    // Fetch user document from Firestore
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
}
