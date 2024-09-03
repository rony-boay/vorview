import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProductDetailScreen extends StatelessWidget {
  final String productId;

  const ProductDetailScreen({Key? key, required this.productId})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Product/Service Details'),
        backgroundColor: Colors.white,
        foregroundColor: Color(0xFF191970), // Midnight Blue
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance
            .collection('products')
            .doc(productId)
            .get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(
                  color: Color(0xFF191970)), // Midnight Blue
            );
          } else if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error: ${snapshot.error}',
                style: TextStyle(color: Color(0xFF191970)), // Midnight Blue
              ),
            );
          } else if (!snapshot.hasData || !snapshot.data!.exists) {
            return Center(
              child: Text(
                'Product not found.',
                style: TextStyle(color: Color(0xFF191970)), // Midnight Blue
              ),
            );
          } else {
            final productData = snapshot.data!.data() as Map<String, dynamic>;

            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Product Name
                    Text(
                      productData['name'] ?? 'Product Name',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF191970), // Midnight Blue
                      ),
                    ),
                    SizedBox(height: 16),

                    // Product Price
                    Text(
                      'Price: ${productData['price'] ?? 'N/A'}',
                      style: TextStyle(
                        fontSize: 18,
                        color: Color(0xFF191970), // Midnight Blue
                      ),
                    ),
                    SizedBox(height: 8),

                    // Product Address
                    Text(
                      'Address: ${productData['address'] ?? 'N/A'}',
                      style: TextStyle(
                        fontSize: 18,
                        color: Color(0xFF191970), // Midnight Blue
                      ),
                    ),
                    SizedBox(height: 16),

                    // Product Image (if available)
                    if (productData['imageUrl'] != null)
                      Image.network(
                        productData['imageUrl'],
                        height: 200,
                        fit: BoxFit.cover,
                      ),
                    SizedBox(height: 16),

                    // Product Description
                    // Text(
                    //   productData['description'] ?? 'No description available.',
                    //   style: TextStyle(
                    //     fontSize: 16,
                    //     color: Colors.black,
                    //   ),
                    // ),
                    SizedBox(height: 16),

                    // Ratings and Reviews
                    Text(
                      'Ratings and Reviews',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF191970), // Midnight Blue
                      ),
                    ),
                    SizedBox(height: 8),

                    // Fetch Reviews and Calculate Average Rating
                    FutureBuilder<QuerySnapshot>(
                      future: FirebaseFirestore.instance
                          .collection('reviews')
                          .where('productId', isEqualTo: productId)
                          .get(),
                      builder: (context, reviewsSnapshot) {
                        if (reviewsSnapshot.connectionState ==
                            ConnectionState.waiting) {
                          return Center(
                            child: CircularProgressIndicator(
                                color: Color(0xFF191970)), // Midnight Blue
                          );
                        } else if (reviewsSnapshot.hasError) {
                          return Center(
                            child: Text(
                              'Error: ${reviewsSnapshot.error}',
                              style: TextStyle(
                                  color: Color(0xFF191970)), // Midnight Blue
                            ),
                          );
                        } else if (!reviewsSnapshot.hasData ||
                            reviewsSnapshot.data!.docs.isEmpty) {
                          return Center(
                            child: Text(
                              'No reviews available.',
                              style: TextStyle(
                                  color: Color(0xFF191970)), // Midnight Blue
                            ),
                          );
                        } else {
                          // Calculate average rating
                          final reviewDocs = reviewsSnapshot.data!.docs;
                          double totalRating = 0.0;

                          for (var doc in reviewDocs) {
                            totalRating += (doc['rating'] ?? 0).toDouble();
                          }

                          final avgRating = totalRating / reviewDocs.length;

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Display Average Rating
                              Row(
                                children: List.generate(5, (index) {
                                  return Icon(
                                    index < avgRating
                                        ? Icons.star
                                        : Icons.star_border,
                                    color: Colors.yellow,
                                  );
                                }),
                              ),
                              SizedBox(height: 16),

                              // Display List of Reviews
                              ListView.builder(
                                shrinkWrap: true,
                                physics: NeverScrollableScrollPhysics(),
                                itemCount: reviewDocs.length,
                                itemBuilder: (context, index) {
                                  final reviewData = reviewDocs[index].data()
                                      as Map<String, dynamic>;
                                  return ListTile(
                                    leading: reviewData['imageUrl'] != null
                                        ? Image.network(
                                            reviewData['imageUrl'],
                                            width: 50,
                                            height: 50,
                                            fit: BoxFit.cover,
                                          )
                                        : null,
                                    title: Text(
                                      reviewData['userName'] ?? 'Anonymous',
                                      style: TextStyle(
                                          color: Color(
                                              0xFF191970)), // Midnight Blue
                                    ),
                                    subtitle: Text(
                                      reviewData['reviewText'] ?? '',
                                      style: TextStyle(
                                          color: Color(
                                              0xFF191970)), // Midnight Blue
                                    ),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: List.generate(5, (index) {
                                        return Icon(
                                          index < (reviewData['rating'] ?? 0)
                                              ? Icons.star
                                              : Icons.star_border,
                                          color: Colors.yellow,
                                        );
                                      }),
                                    ),
                                  );
                                },
                              ),
                            ],
                          );
                        }
                      },
                    ),
                  ],
                ),
              ),
            );
          }
        },
      ),
      backgroundColor: Colors.white, // White background
    );
  }
}
