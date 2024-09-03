import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:vorviewadmin/main.dart';

class ExploreProductScreen extends StatefulWidget {
  @override
  _ExploreProductScreenState createState() => _ExploreProductScreenState();
}

class _ExploreProductScreenState extends State<ExploreProductScreen> {
  TextEditingController _searchController = TextEditingController();
  ScrollController _scrollController = ScrollController();
  List<QueryDocumentSnapshot> _products = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Updated to white background
      appBar: AppBar(
        backgroundColor: Color(0xFF191970), // Midnight blue AppBar
        title: Text(
          'Explore Products',
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                SizedBox(height: 30),
                // Logo
                Image.asset(
                  'assets/vorvie.jpg', // Replace with your logo asset path
                  height: 100, // Adjust the height as needed
                ),
                SizedBox(height: 20),
                // Search Bar
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white, // White background for the search bar
                    borderRadius: BorderRadius.circular(5),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.5),
                        spreadRadius: 2,
                        blurRadius: 5,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      prefixIcon: Icon(
                        Icons.search,
                        color: Color(0xFF191970), // Midnight blue icon
                      ),
                      hintText: 'Search...',
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.all(15),
                    ),
                    onSubmitted: (query) {
                      // Navigate to ViewProductScreen with the search query
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              BottomMenuScreen(searchQuery: query),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream:
                  FirebaseFirestore.instance.collection('products').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF191970), // Midnight blue loading indicator
                    ),
                  );
                }
                _products = snapshot.data!.docs;

                return ListView.builder(
                  controller: _scrollController,
                  itemCount: _products.length,
                  itemBuilder: (context, index) {
                    final product = _products[index];
                    return Card(
                      margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                      color: Colors.white,
                      child: ListTile(
                        leading: Image.network(
                          product['imageUrl'],
                          width: 50,
                          height: 50,
                          fit: BoxFit.cover,
                        ),
                        title: Text(
                          product['name'],
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF191970), // Midnight blue text
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              product['address'],
                              style: TextStyle(
                                color: Colors.grey[600], // Grey text
                              ),
                            ),
                          ],
                        ),
                        trailing: StreamBuilder<DocumentSnapshot>(
                          stream: FirebaseFirestore.instance
                              .collection('favorites')
                              .doc(FirebaseAuth.instance.currentUser?.uid)
                              .collection('products')
                              .doc(product.id)
                              .snapshots(),
                          builder: (context, snapshot) {
                            if (!snapshot.hasData) {
                              return IconButton(
                                icon: Icon(
                                  Icons.favorite_border,
                                  color: Color(0xFF191970), // Midnight blue icon
                                ),
                                onPressed: () {
                                  _toggleFavorite(product.id);
                                },
                              );
                            }
                            bool isFavorite = snapshot.data!.exists;
                            return IconButton(
                              icon: Icon(
                                isFavorite
                                    ? Icons.favorite
                                    : Icons.favorite_border,
                                color: isFavorite
                                    ? Colors.red
                                    : Color(
                                        0xFF191970)), // Red if favorite, otherwise midnight blue
                              onPressed: () {
                                _toggleFavorite(product.id);
                              },
                            );
                          },
                        ),
                        onTap: () {
                          _showReviewsDialog(context, product.id);
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _toggleFavorite(String productId) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    FirebaseFirestore.instance
        .collection('favorites')
        .doc(user.uid)
        .collection('products')
        .doc(productId)
        .get()
        .then((doc) {
      if (doc.exists) {
        doc.reference.delete();
      } else {
        doc.reference.set({});
      }
    });
  }

  void _showReviewsDialog(BuildContext context, String productId) async {
    // Get the current user
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) return;

    // Fetch the user data from Firestore
    DocumentSnapshot<Map<String, dynamic>> userSnapshot =
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

    // Check if the user is blocked
    if (userSnapshot.exists && userSnapshot.data()!['blocked'] == true) {
      // Show a Snackbar to notify the user that they are blocked
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Color(0xFF191970), // Midnight blue background
          content: Text(
            'You are blocked and cannot leave reviews.',
            style: TextStyle(color: Colors.white), // White text
          ),
        ),
      );
    } else {
      // If not blocked, show the review dialog
      showDialog(
        context: context,
        builder: (context) => ReviewsDialog(productId: productId),
      );
    }
  }
}
