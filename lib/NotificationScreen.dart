import 'dart:convert';
import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vorviewadmin/product_detail_screen.dart';
import 'package:vorviewadmin/serviceNotifi.dart';

class NotificationScreen extends StatefulWidget {
  @override
  _NotificationScreenState createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  bool _notificationsEnabled = true;
  List<Map<String, dynamic>> _productServiceTiles = [];
  Timer? _notificationTimer;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadNotificationPreference();
    _loadProductServiceTiles();
  }

  Future<void> _loadNotificationPreference() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _notificationsEnabled = prefs.getBool('notificationsEnabled') ?? true;
    });
  }

  Future<void> _saveNotificationPreference(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notificationsEnabled', value);

    setState(() {
      _notificationsEnabled = value;

      if (_notificationsEnabled) {
        _startNotificationLoop();
      } else {
        _stopNotificationLoop();
        NotificationService.cancelAllNotifications();
      }
    });
  }

  Future<void> _loadProductServiceTiles() async {
    final productsSnapshot =
        await FirebaseFirestore.instance.collection('products').get();

    final products = productsSnapshot.docs.map((doc) {
      return {
        'name': doc['name'],
        'description': 'Price: ${doc['price']}, Address: ${doc['address']}',
        'productId': doc.id,
      };
    }).toList();

    setState(() {
      _productServiceTiles = products;
      _currentIndex = 0;
    });

    if (_notificationsEnabled) {
      _startNotificationLoop();
    }
  }

  void _startNotificationLoop() {
    _notificationTimer?.cancel(); // Cancel any existing timer
    _notificationTimer = Timer.periodic(Duration(seconds: 5), (timer) {
      if (_productServiceTiles.isNotEmpty) {
        final product = _productServiceTiles[_currentIndex];
        NotificationService.showInstantNotification(
          product['name'],
          product['description'],
          product['productId'],
        );

        _currentIndex++;
        if (_currentIndex >= _productServiceTiles.length) {
          _currentIndex = 0; // Reset to the first product
        }
      }
    });
  }

  void _stopNotificationLoop() {
    _notificationTimer?.cancel();
  }

  @override
  void dispose() {
    _notificationTimer?.cancel(); // Cancel the timer when the widget is disposed
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: Text('Notifications'),
        centerTitle: true,
        backgroundColor: Color(0xFF191970),
        foregroundColor: Colors.white,
      ),
      backgroundColor: Colors.white,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Text(
                  'Notifications: ',
                  style: TextStyle(color: Color(0xFF191970)),
                ),
                Radio(
                  value: true,
                  groupValue: _notificationsEnabled,
                  onChanged: (value) {
                    _saveNotificationPreference(value!);
                  },
                  activeColor: Color(0xFF191970),
                ),
                Text('On', style: TextStyle(color: Color(0xFF191970))),
                Radio(
                  value: false,
                  groupValue: _notificationsEnabled,
                  onChanged: (value) {
                    _saveNotificationPreference(value!);
                  },
                  activeColor: Color(0xFF191970),
                ),
                Text('Off', style: TextStyle(color: Color(0xFF191970))),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(user?.uid)
                  .collection('notifications')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Center(
                      child: CircularProgressIndicator(
                          color: Color(0xFF191970)));
                }
                final notifications = snapshot.data!.docs;
                if (notifications.isEmpty) {
                  return Center(
                      child: Text('No notifications yet.',
                          style: TextStyle(color: Color(0xFF191970))));
                }

                return ListView.builder(
                  itemCount: notifications.length,
                  itemBuilder: (context, index) {
                    final notification = notifications[index];
                    final notificationData =
                        notification.data() as Map<String, dynamic>;

                    final timestamp = notificationData['timestamp'] != null
                        ? (notificationData['timestamp'] as Timestamp).toDate()
                        : DateTime.now();

                    final productServiceTile = {
                      'name': notificationData['title'] ?? 'Unknown Title',
                      'description': notificationData['body'] ??
                          'No description available',
                      'productId': notificationData['productId'] ?? '',
                    };

                    return Card(
                      color: Color(0xFF191970),
                      margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                      child: ListTile(
                        title: Text(
                          productServiceTile['name'],
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.white),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(productServiceTile['description'],
                                style: TextStyle(color: Colors.white)),
                            Text(
                              timestamp.toString(),
                              style: TextStyle(
                                  color: Colors.white, fontSize: 12),
                            ),
                          ],
                        ),
                        onTap: () {
                          _navigateToProductDetail(
                              context, productServiceTile['productId']);
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

  void _navigateToProductDetail(BuildContext context, String? productId) {
    if (productId != null && productId.isNotEmpty) {
      Navigator.pushNamed(
        context,
        '/productDetail',
        arguments: productId,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Product details are not available.')),
      );
    }
  }
}
