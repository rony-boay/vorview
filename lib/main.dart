import 'dart:async';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:image_picker/image_picker.dart';
import 'package:vorviewadmin/NotificationScreen.dart';
import 'package:vorviewadmin/SelectionScreen.dart';
import 'package:vorviewadmin/SplashScreen.dart';
import 'package:vorviewadmin/admin_pane.dart';
import 'package:vorviewadmin/favorite_products_screen.dart';
import 'package:vorviewadmin/login_screen.dart';
import 'package:vorviewadmin/registeration_screen.dart';
import 'package:vorviewadmin/serviceNotifi.dart';
import 'package:vorviewadmin/settings_screen.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:vorviewadmin/product_detail_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await NotificationService.init();

  runApp(MyApp());
}

// Top-level function for handling notification taps in the background
@pragma('vm:entry-point')
void notificationTapBackgroundHandler(NotificationResponse response) {
  if (response.payload != null) {
    print('Notification payload in background: ${response.payload}');
    // You can add navigation logic here if needed
  }
}

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
final GlobalKey<_BottomMenuScreenState> bottomMenuKey =
    GlobalKey<_BottomMenuScreenState>();

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Vorview',
      theme: ThemeData(primarySwatch: Colors.blue),
      navigatorKey: navigatorKey,
      home: SplashScreen(),
      onGenerateRoute: (RouteSettings settings) {
        switch (settings.name) {
          case '/login':
            return MaterialPageRoute(builder: (_) => LoginScreen());
          case '/register':
            return MaterialPageRoute(builder: (_) => RegisterScreen());
          case '/profile':
            return MaterialPageRoute(builder: (_) => ProfileScreen());
          case '/adminPanel':
            return MaterialPageRoute(builder: (_) => AdminPanelScreen());
          case '/notifications':
            return MaterialPageRoute(builder: (_) => NotificationScreen());
          case '/Selection':
            return MaterialPageRoute(builder: (_) => const SelectionScreen());
          case '/productDetail':
            final productId = settings.arguments as String;
            return MaterialPageRoute(
              builder: (_) => ProductDetailScreen(productId: productId),
            );
          default:
            return MaterialPageRoute(builder: (_) => SplashScreen());
        }
      },
    );
  }
}

// Top-level function for handling notification taps in the background
// void notificationTapBackgroundHandler(NotificationResponse response) {
//   if (response.payload != null) {
//     // Handle the background notification tap (e.g., navigate to a screen)
//     print('Notification payload: ${response.payload}');
//   }
// }

class AuthWrapper extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        } else if (snapshot.hasData) {
          return LoginScreen(); // Navigate to SelectionScreen if authenticated
        } else {
          return LoginScreen(); // Navigate to LoginScreen if not authenticated
        }
      },
    );
  }
}

class BottomMenuScreen extends StatefulWidget {
  final String searchQuery;

  BottomMenuScreen({Key? key, required this.searchQuery}) : super(key: key);

  @override
  _BottomMenuScreenState createState() => _BottomMenuScreenState();
}

class _BottomMenuScreenState extends State<BottomMenuScreen> {
  int _currentIndex = 0;
  int _notificationCount = 0;

  final List<Widget> _children = [
    ViewProductScreen(searchQuery: ''),
    FavoriteProductsScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // White background
      appBar: AppBar(
        backgroundColor: Colors.white, // White background for AppBar
        title: Column(
          children: [
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Image.asset('assets/vorvie.jpg',
                    height: 210), // Logo at the top
              ],
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          Stack(
            children: [
              IconButton(
                icon: Icon(Icons.notifications,
                    color: Color(0xFF191970)), // Midnight blue for icons
                onPressed: () {
                  setState(() {
                    _notificationCount = 0;
                  });
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => NotificationScreen()),
                  );
                },
              ),
              if (_notificationCount > 0)
                Positioned(
                  right: 11,
                  top: 11,
                  child: Container(
                    padding: EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    constraints: BoxConstraints(
                      minWidth: 8,
                      minHeight: 8,
                    ),
                    child: Text(
                      '$_notificationCount',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 6,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: _children[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        backgroundColor: Colors.white, // White background for bottom nav
        selectedItemColor: Color(0xFF191970), // Midnight blue for selected item
        unselectedItemColor: Colors.grey,
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.view_list,
                color: _currentIndex == 0 ? Color(0xFF191970) : Colors.grey),
            label: 'View',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite,
                color: _currentIndex == 1 ? Color(0xFF191970) : Colors.grey),
            label: 'Favorites',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings,
                color: _currentIndex == 2 ? Color(0xFF191970) : Colors.grey),
            label: 'Settings',
          ),
        ],
      ),
    );
  }

  void incrementNotificationCount() {
    setState(() {
      _notificationCount++;
    });
  }
}

class ViewProductScreen extends StatefulWidget {
  final String? productId;
  final String searchQuery;

  ViewProductScreen({this.productId, required this.searchQuery});

  @override
  _ViewProductScreenState createState() => _ViewProductScreenState();
}

class _ViewProductScreenState extends State<ViewProductScreen> {
  TextEditingController _searchController = TextEditingController();
  RangeValues _priceRange = RangeValues(0, 1000);
  String _searchQuery = '';
  ScrollController _scrollController = ScrollController();
  String? _highlightProductId;
  List<QueryDocumentSnapshot> _products = [];

  @override
  void initState() {
    super.initState();
    _searchQuery = widget.searchQuery;
    if (widget.productId != null) {
      _highlightProductId = widget.productId;
    }
    _searchController.text = _searchQuery;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Set the background color to white
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
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
                  prefixIcon: Icon(Icons.search,
                      color: Color(0xFF191970)), // Midnight blue color
                  hintText: 'Search...',
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.all(15),
                ),
                onChanged: (query) {
                  setState(() {
                    _searchQuery = query;
                  });
                },
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Row(
              children: [
                Text('Price Range:',
                    style: TextStyle(
                        color: Color(0xFF191970))), // Midnight blue text
                Expanded(
                  child: RangeSlider(
                    values: _priceRange,
                    min: 0,
                    max: 1000,
                    divisions: 20,
                    activeColor:
                        Color(0xFF191970), // Midnight blue active color
                    inactiveColor: Colors.grey,
                    labels: RangeLabels(
                      '\Rs${_priceRange.start.round()}',
                      '\Rs${_priceRange.end.round()}',
                    ),
                    onChanged: (RangeValues values) {
                      setState(() {
                        _priceRange = values;
                      });
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
                      color: Color(0xFF191970), // Midnight blue indicator
                    ),
                  );
                }
                _products = snapshot.data!.docs;

                final filteredProducts = _filterProducts(_products);

                // Check if there are no matching products
                if (filteredProducts.isEmpty) {
                  return Center(
                    child: Text(
                      'No items found',
                      style: TextStyle(
                        color: Color(0xFF191970), // Midnight blue text color
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  );
                }

                if (_highlightProductId != null) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    _scrollToProduct(_highlightProductId!);
                  });
                }

                return ListView.builder(
                  controller: _scrollController,
                  itemCount: filteredProducts.length,
                  itemBuilder: (context, index) {
                    final product = filteredProducts[index];
                    final isHighlighted = product.id == _highlightProductId;
                    return Card(
                      margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                      color: isHighlighted ? Colors.yellow[100] : Colors.white,
                      child: ListTile(
                        leading: Image.network(
                          product['imageUrl'],
                          width: 50,
                          height: 50,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Icon(
                            Icons.image_not_supported,
                            color: Color(0xFF191970), // Midnight blue icon
                          ),
                        ),
                        title: Text(
                          product['name'] ?? 'Unnamed Product',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF191970), // Midnight blue text
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              product['address'] ?? 'No Address',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                            Text(
                              '\Rs: ${product['price'] ?? 'N/A'}',
                              style: TextStyle(color: Colors.black),
                            ),
                            _buildAverageRating(
                                product.id), // Display the average rating
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _buildFavoriteIcon(product.id),
                            IconButton(
                              icon: Icon(Icons.account_circle,
                                  color:
                                      Color(0xFF191970)), // Midnight blue icon
                              onPressed: () {
                                _showBusinessProfileDialog(product['userId']);
                              },
                            ),
                          ],
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

  List<QueryDocumentSnapshot> _filterProducts(
      List<QueryDocumentSnapshot> products) {
    return products.where((product) {
      final name = product['name'].toString().toLowerCase();
      final address = product['address'].toString().toLowerCase();
      final price = double.tryParse(product['price'].toString()) ?? 0.0;
      final matchesQuery = _searchQuery.isEmpty ||
          name.contains(_searchQuery.toLowerCase()) ||
          address.contains(_searchQuery.toLowerCase());
      final matchesPriceRange =
          price >= _priceRange.start && price <= _priceRange.end;
      return matchesQuery && matchesPriceRange;
    }).toList();
  }

  void _scrollToProduct(String productId) {
    final index = _getProductIndex(productId);
    if (index != -1) {
      _scrollController.animateTo(
        index * 100.0,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  int _getProductIndex(String productId) {
    for (int i = 0; i < _products.length; i++) {
      if (_products[i].id == productId) {
        return i;
      }
    }
    return -1;
  }

  Widget _buildFavoriteIcon(String productId) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return Container();

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('favorites')
          .doc(user.uid)
          .collection('products')
          .doc(productId)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return IconButton(
            icon: Icon(Icons.favorite_border, color: Color(0xFF191970)),
            onPressed: () {
              _toggleFavorite(productId);
            },
          );
        }
        bool isFavorite = snapshot.data!.exists;
        return IconButton(
          icon: Icon(
            isFavorite ? Icons.favorite : Icons.favorite_border,
            color: isFavorite ? Colors.red : Color(0xFF191970),
          ),
          onPressed: () {
            _toggleFavorite(productId);
          },
        );
      },
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
          content: Text('blocked! contact admin please'),
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

  Widget _buildAverageRating(String productId) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('reviews')
          .where('productId', isEqualTo: productId)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          // No reviews, show empty stars and indicate no rating
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: List.generate(
                  5,
                  (index) => Icon(
                    Icons.star_border,
                    color: Colors.grey,
                    size: 20,
                  ),
                ),
              ),
              Text(
                'Avg Rating: N/A (0 reviews)',
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
            ],
          );
        }

        // Calculate total rating
        double totalRating = 0;
        int reviewCount = snapshot.data!.docs.length;
        for (var doc in snapshot.data!.docs) {
          totalRating += (doc['rating'] ?? 0).toDouble();
        }

        // Calculate the average rating
        double averageRating = totalRating / reviewCount;

        // Determine the number of filled stars based on the average rating
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: List.generate(5, (index) {
                return Icon(
                  index < averageRating ? Icons.star : Icons.star_border,
                  color: index < averageRating ? Colors.amber : Colors.grey,
                  size: 20,
                );
              }),
            ),
            Text(
              'Avg Rating: ${averageRating.toStringAsFixed(1)} ($reviewCount reviews)',
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
          ],
        );
      },
    );
  }

  void _showBusinessProfileDialog(String userId) async {
    DocumentSnapshot<Map<String, dynamic>> snapshot =
        await FirebaseFirestore.instance.collection('users').doc(userId).get();

    if (snapshot.exists) {
      final userData = snapshot.data()!;
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            backgroundColor: Colors.white, // Set background color to white
            title: Text(
              'Business Profile',
              style: TextStyle(
                color: Color(0xFF191970), // Set text color to midnight blue
                fontWeight: FontWeight.bold,
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Name: ${userData['name'] ?? 'N/A'}',
                  style: TextStyle(color: Color(0xFF191970)), // Text color
                ),
                Text(
                  'Email: ${userData['email'] ?? 'N/A'}',
                  style: TextStyle(color: Color(0xFF191970)), // Text color
                ),
                Text(
                  'Contact: ${userData['contact'] ?? 'N/A'}',
                  style: TextStyle(color: Color(0xFF191970)), // Text color
                ),
                Text(
                  'Address: ${userData['address'] ?? 'N/A'}',
                  style: TextStyle(color: Color(0xFF191970)), // Text color
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text(
                  'Close',
                  style: TextStyle(
                    color: Color(0xFF191970), // Button text color
                  ),
                ),
              ),
            ],
          );
        },
      );
    } else {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            backgroundColor: Colors.white, // Set background color to white
            title: Text(
              'Error',
              style: TextStyle(
                color: Color(0xFF191970), // Set text color to midnight blue
                fontWeight: FontWeight.bold,
              ),
            ),
            content: Text(
              'Business profile not found.',
              style: TextStyle(color: Color(0xFF191970)), // Text color
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text(
                  'Close',
                  style: TextStyle(
                    color: Color(0xFF191970), // Button text color
                  ),
                ),
              ),
            ],
          );
        },
      );
    }
  }
}

// ReviewsDialog.dart

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

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    setState(() {
      _imageFile = pickedFile != null ? File(pickedFile.path) : null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white, // White background
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Product Reviews',
              style: TextStyle(
                color: Color(0xFF191970), // Midnight blue text color
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            SizedBox(height: 16),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('reviews')
                    .where('productId', isEqualTo: widget.productId)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return Center(
                        child: CircularProgressIndicator(
                            color: Color(0xFF191970))); // Midnight blue loader
                  }
                  final reviews = snapshot.data!.docs;
                  return ListView.builder(
                    itemCount: reviews.length,
                    itemBuilder: (context, index) {
                      final review = reviews[index];
                      final userName = review['userName'] ?? 'Anonymous';
                      final reviewText = review['reviewText'] ?? '';
                      final imageUrl = review['imageUrl'];
                      final rating = (review['rating'] ?? 0.0).toDouble();
                      final repliesStream = FirebaseFirestore.instance
                          .collection('replies')
                          .where('reviewId', isEqualTo: review.id)
                          .snapshots();

                      return Card(
                        key: ValueKey(review.id),
                        color: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        margin: EdgeInsets.symmetric(vertical: 8),
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                userName,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF191970), // Midnight blue
                                ),
                              ),
                              SizedBox(height: 4),
                              if (imageUrl != null)
                                GestureDetector(
                                  onTap: () {
                                    showDialog(
                                      context: context,
                                      builder: (context) => Dialog(
                                        backgroundColor: Colors.transparent,
                                        child: Image.network(imageUrl),
                                      ),
                                    );
                                  },
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.network(
                                      imageUrl,
                                      height: 150,
                                      width: double.infinity,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                              SizedBox(height: 8),
                              RatingBarIndicator(
                                rating: rating,
                                itemBuilder: (context, index) => Icon(
                                  Icons.star,
                                  color: Colors.amber,
                                ),
                                itemCount: 5,
                                itemSize: 20.0,
                                direction: Axis.horizontal,
                              ),
                              SizedBox(height: 8),
                              Text(
                                reviewText,
                                style: TextStyle(color: Colors.black87),
                              ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  IconButton(
                                    icon: Icon(
                                      Icons.thumb_up,
                                      color: (review['likedBy']?.contains(
                                                  FirebaseAuth.instance
                                                      .currentUser?.uid) ??
                                              false)
                                          ? Colors.blue
                                          : Colors.grey,
                                    ),
                                    onPressed: () {
                                      _toggleLike(review.id, true);
                                    },
                                  ),
                                  IconButton(
                                    icon: Icon(
                                      Icons.thumb_down,
                                      color: (review['dislikedBy']?.contains(
                                                  FirebaseAuth.instance
                                                      .currentUser?.uid) ??
                                              false)
                                          ? Colors.red
                                          : Colors.grey,
                                    ),
                                    onPressed: () {
                                      _toggleLike(review.id, false);
                                    },
                                  ),
                                ],
                              ),
                              _buildRepliesSection(repliesStream),
                              TextField(
                                controller: _replyController,
                                decoration: InputDecoration(
                                  labelText: 'Write a reply...',
                                  labelStyle: TextStyle(
                                      color:
                                          Color(0xFF191970)), // Midnight blue
                                  filled: true,
                                  fillColor: Colors.white,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                style: TextStyle(
                                    color: Color(0xFF191970)), // Midnight blue
                              ),
                              SizedBox(height: 8),
                              Align(
                                alignment: Alignment.centerRight,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor:
                                        Color(0xFF191970), // Midnight blue
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  onPressed: () {
                                    _submitReply(review.id);
                                  },
                                  child: Text('Submit',
                                      style: TextStyle(color: Colors.white)),
                                ),
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
            SizedBox(height: 16),
            TextField(
              controller: _reviewController,
              decoration: InputDecoration(
                labelText: 'Write a review...',
                labelStyle:
                    TextStyle(color: Color(0xFF191970)), // Midnight blue
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              style: TextStyle(color: Color(0xFF191970)), // Midnight blue
            ),
            SizedBox(height: 8),
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
            SizedBox(height: 16),
            Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: _pickImage,
                  icon: Icon(Icons.upload, color: Colors.white),
                  label: Text('Upload Image',
                      style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF191970), // Midnight blue
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: _submitReview,
                  child: Text('Submit Review',
                      style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF191970), // Midnight blue
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
            if (_imageFile != null)
              Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child:
                      Image.file(_imageFile!, height: 100, fit: BoxFit.cover),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildRepliesSection(Stream<QuerySnapshot> repliesStream) {
    return StreamBuilder<QuerySnapshot>(
      stream: repliesStream,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(
              child: CircularProgressIndicator(
                  color: Color(0xFF191970))); // Midnight blue loader
        }
        final replies = snapshot.data!.docs;
        return ListView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          itemCount: replies.length,
          itemBuilder: (context, index) {
            final reply = replies[index];
            final replyUserName = reply['userName'] ?? 'Anonymous';
            final replyText = reply['replyText'] ?? '';

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Divider(color: Colors.grey),
                Text(
                  replyUserName,
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF191970)), // Midnight blue
                ),
                SizedBox(height: 4),
                Text(replyText, style: TextStyle(color: Colors.black87)),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _submitReview() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final reviewText = _reviewController.text.trim();
    if (reviewText.isEmpty || _rating <= 0.0) return;

    // Check if the user has already submitted a review for this product
    final existingReview = await FirebaseFirestore.instance
        .collection('reviews')
        .where('productId', isEqualTo: widget.productId)
        .where('userId', isEqualTo: user.uid)
        .get();

    if (existingReview.docs.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('You can only submit one review per product.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Upload the image if available
    String? imageUrl;
    if (_imageFile != null) {
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('review_images/${DateTime.now().toIso8601String()}');
      final uploadTask = storageRef.putFile(_imageFile!);
      final snapshot = await uploadTask.whenComplete(() {});
      imageUrl = await snapshot.ref.getDownloadURL();
    }

    // Save the review
    await FirebaseFirestore.instance.collection('reviews').add({
      'productId': widget.productId,
      'userId': user.uid,
      'userName': user.displayName ?? 'Anonymous',
      'reviewText': reviewText,
      'rating': _rating,
      'imageUrl': imageUrl,
      'likedBy': [],
      'dislikedBy': [],
      'createdAt': DateTime.now(),
      'isClaimed': false,
    });

    _reviewController.clear();
    setState(() {
      _rating = 0.0;
      _imageFile = null;
    });

    Navigator.of(context).pop(); // Close the dialog after submitting
  }

  Future<void> _submitReply(String reviewId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final replyText = _replyController.text.trim();
    if (replyText.isEmpty) return;

    await FirebaseFirestore.instance.collection('replies').add({
      'reviewId': reviewId,
      'userId': user.uid,
      'userName': user.displayName ?? 'Anonymous',
      'replyText': replyText,
      'createdAt': DateTime.now(),
    });

    _replyController.clear();
  }

  void _toggleLike(String reviewId, bool isLike) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final reviewRef =
        FirebaseFirestore.instance.collection('reviews').doc(reviewId);

    final review = await reviewRef.get();
    final likedBy = List<String>.from(review['likedBy'] ?? []);
    final dislikedBy = List<String>.from(review['dislikedBy'] ?? []);

    if (isLike) {
      if (likedBy.contains(user.uid)) {
        likedBy.remove(user.uid);
      } else {
        likedBy.add(user.uid);
        dislikedBy.remove(user.uid);
      }
    } else {
      if (dislikedBy.contains(user.uid)) {
        dislikedBy.remove(user.uid);
      } else {
        dislikedBy.add(user.uid);
        likedBy.remove(user.uid);
      }
    }

    await reviewRef.update({
      'likedBy': likedBy,
      'dislikedBy': dislikedBy,
    });
  }
}
