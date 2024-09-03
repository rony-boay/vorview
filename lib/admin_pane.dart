import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';

class AdminPanelScreen extends StatefulWidget {
  @override
  _AdminPanelScreenState createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Background set to white
      body: IndexedStack(
        index: _currentIndex,
        children: [
          AdminManagementScreen(),
          BusinessOwnerRequestScreen(),
          ClaimReviewScreen(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        backgroundColor: Colors.white, // Background set to white
        selectedItemColor:
            Color(0xFF191970), // Foreground elements in midnight blue
        unselectedItemColor:
            Colors.black54, // Unselected items in a softer shade
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.admin_panel_settings),
            label: 'Role',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.business),
            label: 'Business Owner Requests',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.rate_review),
            label: 'Review Claims',
          ),
        ],
      ),
    );
  }
}

class BusinessOwnerRequestScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Background set to white
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('business_owner_requests')
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(
              child: CircularProgressIndicator(color: Color(0xFF191970)),
            );
          }
          final requests = snapshot.data!.docs;
          if (requests.isEmpty) {
            return Center(
              child: Text(
                'No requests available.',
                style: TextStyle(color: Color(0xFF191970), fontSize: 18),
              ),
            );
          }
          return ListView.builder(
            itemCount: requests.length,
            itemBuilder: (context, index) {
              final request = requests[index];
              return Card(
                color: Colors.white,
                margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                child: ListTile(
                  title: Text(
                    '${request['firstName']} ${request['lastName']}',
                    style: TextStyle(color: Color(0xFF191970)),
                  ),
                  subtitle: Text(
                    request['businessName'],
                    style: TextStyle(color: Color(0xFF191970)),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(Icons.check, color: Color(0xFF191970)),
                        onPressed: () => _handleRequest(request, true),
                      ),
                      IconButton(
                        icon: Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _handleRequest(request, false),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _handleRequest(DocumentSnapshot request, bool isAccepted) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      if (isAccepted) {
        await FirebaseFirestore.instance
            .collection('business_owners')
            .doc(request.id)
            .set({
          'approved': true,
          'firstName': request['firstName'],
          'lastName': request['lastName'],
          'email': request['email'],
          'address': request['address'],
          'gender': request['gender'],
          'businessName': request['businessName'],
          'businessDescription': request['businessDescription'],
          'timestamp': FieldValue.serverTimestamp(),
        });
      }
      await FirebaseFirestore.instance
          .collection('business_owner_requests')
          .doc(request.id)
          .delete();
      await FirebaseFirestore.instance
          .collection('users')
          .doc(request.id)
          .collection('notifications')
          .add({
        'title':
            'Business Owner Request ${isAccepted ? 'Accepted' : 'Rejected'}',
        'body':
            'Your business owner request has been ${isAccepted ? 'accepted' : 'rejected'}.',
        'timestamp': FieldValue.serverTimestamp(),
      });
    }
  }
}

class ClaimReviewScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Background set to white
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('reviews')
              .where('isClaimed', isEqualTo: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return Center(
                child: CircularProgressIndicator(color: Color(0xFF191970)),
              );
            }

            final reviews = snapshot.data!.docs;
            if (reviews.isEmpty) {
              return Center(
                child: Text(
                  'No claimed reviews available.',
                  style: TextStyle(color: Color(0xFF191970), fontSize: 18),
                ),
              );
            }

            return ListView.builder(
              itemCount: reviews.length,
              itemBuilder: (context, index) {
                final review = reviews[index];
                return Card(
                  color: Colors.white,
                  margin: EdgeInsets.symmetric(vertical: 8),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              review['userName'],
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF191970),
                              ),
                            ),
                            Row(
                              children: [
                                IconButton(
                                  icon: Icon(Icons.delete, color: Colors.red),
                                  onPressed: () {
                                    _deleteReview(review.id);
                                  },
                                ),
                                IconButton(
                                  icon: Icon(Icons.undo,
                                      color: Color(0xFF191970)),
                                  onPressed: () {
                                    _unclaimReview(review.id);
                                  },
                                ),
                              ],
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
                                  child: Image.network(review['imageUrl']),
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
                          rating: review['rating'] ?? 0.0,
                          itemBuilder: (context, index) => Icon(
                            Icons.star,
                            color: Colors.amber,
                          ),
                          itemCount: 5,
                          itemSize: 20.0,
                          direction: Axis.horizontal,
                        ),
                        SizedBox(height: 4),
                        Text(review['reviewText'],
                            style: TextStyle(color: Color(0xFF191970))),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            IconButton(
                              icon: Icon(
                                Icons.thumb_up,
                                color: review['likedBy'].contains(
                                        FirebaseAuth.instance.currentUser!.uid)
                                    ? Color(0xFF191970)
                                    : null,
                              ),
                              onPressed: () {
                                // Handle like action if needed
                              },
                            ),
                            IconButton(
                              icon: Icon(
                                Icons.thumb_down,
                                color: review['dislikedBy'].contains(
                                        FirebaseAuth.instance.currentUser!.uid)
                                    ? Colors.red
                                    : null,
                              ),
                              onPressed: () {
                                // Handle dislike action if needed
                              },
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
    );
  }

  void _deleteReview(String reviewId) {
    FirebaseFirestore.instance
        .collection('reviews')
        .doc(reviewId)
        .delete()
        .then((_) {
      print('Review deleted successfully');
    }).catchError((error) {
      print('Failed to delete review: $error');
    });
  }

  void _unclaimReview(String reviewId) {
    FirebaseFirestore.instance.collection('reviews').doc(reviewId).update({
      'isClaimed': false,
    }).then((_) {
      print('Review unclaimed successfully');
    }).catchError((error) {
      print('Failed to unclaim review: $error');
    });
  }
}

class AdminManagementScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Background set to white
      appBar: AppBar(
        title: Text(
          'Admin Management',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Color(0xFF191970), // Midnight blue AppBar
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('users').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(
              child: CircularProgressIndicator(color: Color(0xFF191970)),
            );
          }
          final users = snapshot.data!.docs;
          if (users.isEmpty) {
            return Center(
              child: Text(
                'No users available.',
                style: TextStyle(color: Color(0xFF191970), fontSize: 18),
              ),
            );
          }
          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index];
              return Card(
                color: Colors.white,
                child: ListTile(
                  title: Text(
                    user['name'] ?? '',
                    style: TextStyle(color: Color(0xFF191970)),
                  ),
                  subtitle: Text(
                    user['email'] ?? '',
                    style: TextStyle(color: Color(0xFF191970)),
                  ),
                  trailing: Switch(
                    value: user['isAdmin'] ?? false,
                    activeColor: Color(0xFF191970),
                    onChanged: (value) {
                      FirebaseFirestore.instance
                          .collection('users')
                          .doc(user.id)
                          .update({'isAdmin': value});
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
