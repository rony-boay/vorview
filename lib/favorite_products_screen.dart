import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class FavoriteProductsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Center(child: Text('Please log in to view your favorites.'));
    }

    return Scaffold(
      backgroundColor: Colors.white, // White background color
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('favorites')
            .doc(user.uid)
            .collection('products')
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(
                child: CircularProgressIndicator(
              color: Color(0xFF191970), // Midnight blue progress indicator
            ));
          }
          final favoriteProductIds =
              snapshot.data!.docs.map((doc) => doc.id).toList();
          if (favoriteProductIds.isEmpty) {
            return Center(
                child: Text('No favorite products/services found.',
                    style: TextStyle(
                        color: Color(0xFF191970), // Midnight blue text
                        fontWeight: FontWeight.bold)));
          }

          return StreamBuilder<QuerySnapshot>(
            stream:
                FirebaseFirestore.instance.collection('products').snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return Center(
                    child: CircularProgressIndicator(
                  color: Color(0xFF191970), // Midnight blue progress indicator
                ));
              }
              final products = snapshot.data!.docs.where((product) {
                return favoriteProductIds.contains(product.id);
              }).toList();

              return ListView.builder(
                itemCount: products.length,
                itemBuilder: (context, index) {
                  final product = products[index];
                  return Card(
                    margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                    color: Color(0xFF191970), // Midnight blue card color
                    child: ListTile(
                      leading: Image.network(product['imageUrl'],
                          width: 50, height: 50, fit: BoxFit.cover),
                      title: Text(product['name'],
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.white)), // White text
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(product['address'],
                              style: TextStyle(
                                  color: Colors.white70)), // Lighter white text
                          Text('\$${product['price']}',
                              style: TextStyle(
                                  color: Colors.white70)), // Lighter white text
                        ],
                      ),
                      trailing: IconButton(
                        icon: Icon(Icons.favorite, color: Colors.red),
                        onPressed: () {
                          _removeFromFavorites(user.uid, product.id);
                        },
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  void _removeFromFavorites(String userId, String productId) {
    FirebaseFirestore.instance
        .collection('favorites')
        .doc(userId)
        .collection('products')
        .doc(productId)
        .delete();
  }
}
