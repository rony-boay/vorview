import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';

class SmartDashboardScreen extends StatefulWidget {
  @override
  _SmartDashboardScreenState createState() => _SmartDashboardScreenState();
}

class _SmartDashboardScreenState extends State<SmartDashboardScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final User? _currentUser = FirebaseAuth.instance.currentUser;

  Map<String, dynamic> _dashboardData = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    if (_currentUser == null) return;

    setState(() => _isLoading = true);

    try {
      // Load various metrics
      final teamsSnapshot = await _firestore
          .collection('collaboration_teams')
          .where('memberIds', arrayContains: _currentUser!.uid)
          .get();

      final servicesSnapshot = await _firestore
          .collection('service_offerings')
          .where('sellerId', isEqualTo: _currentUser!.uid)
          .get();

      final ordersSnapshot = await _firestore
          .collection('service_orders')
          .where('sellerId', isEqualTo: _currentUser!.uid)
          .get();

      final reviewsSnapshot = await _firestore
          .collection('reviews')
          .where('userId', isEqualTo: _currentUser!.uid)
          .get();

      // Calculate metrics
      final totalTeams = teamsSnapshot.docs.length;
      final totalServices = servicesSnapshot.docs.length;
      final totalOrders = ordersSnapshot.docs.length;
      final completedOrders = ordersSnapshot.docs
          .where((doc) => doc.data()['status'] == 'completed')
          .length;

      double averageRating = 0.0;
      if (reviewsSnapshot.docs.isNotEmpty) {
        final totalRating = reviewsSnapshot.docs
            .map((doc) => (doc.data()['rating'] ?? 0.0) as double)
            .reduce((a, b) => a + b);
        averageRating = totalRating / reviewsSnapshot.docs.length;
      }

      // Calculate earnings
      double totalEarnings = 0.0;
      for (var order in ordersSnapshot.docs) {
        if (order.data()['status'] == 'completed') {
          totalEarnings += (order.data()['amount'] ?? 0.0) as double;
        }
      }

      setState(() {
        _dashboardData = {
          'totalTeams': totalTeams,
          'totalServices': totalServices,
          'totalOrders': totalOrders,
          'completedOrders': completedOrders,
          'averageRating': averageRating,
          'totalEarnings': totalEarnings,
          'completionRate': totalOrders > 0 ? (completedOrders / totalOrders) * 100 : 0.0,
        };
      });
    } catch (e) {
      print('Error loading dashboard data: $e');
    }

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'Smart Dashboard',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Color(0xFF191970),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadDashboardData,
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: Color(0xFF191970)))
          : RefreshIndicator(
              onRefresh: _loadDashboardData,
              child: SingleChildScrollView(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildWelcomeCard(),
                    SizedBox(height: 20),
                    _buildMetricsGrid(),
                    SizedBox(height: 20),
                    _buildPerformanceChart(),
                    SizedBox(height: 20),
                    _buildRecentActivity(),
                    SizedBox(height: 20),
                    _buildAIInsights(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildWelcomeCard() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF191970), Color(0xFF4169E1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Welcome back!',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Here\'s your collaboration performance overview',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 16,
            ),
          ),
          SizedBox(height: 16),
          Row(
            children: [
              Icon(Icons.trending_up, color: Colors.white, size: 20),
              SizedBox(width: 8),
              Text(
                '${_dashboardData['completionRate']?.toStringAsFixed(1) ?? '0'}% completion rate',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricsGrid() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.2,
      children: [
        _buildMetricCard(
          'Teams',
          '${_dashboardData['totalTeams'] ?? 0}',
          Icons.group,
          Colors.blue,
        ),
        _buildMetricCard(
          'Services',
          '${_dashboardData['totalServices'] ?? 0}',
          Icons.store,
          Colors.green,
        ),
        _buildMetricCard(
          'Orders',
          '${_dashboardData['totalOrders'] ?? 0}',
          Icons.shopping_cart,
          Colors.orange,
        ),
        _buildMetricCard(
          'Rating',
          '${_dashboardData['averageRating']?.toStringAsFixed(1) ?? '0.0'}',
          Icons.star,
          Colors.amber,
        ),
      ],
    );
  }

  Widget _buildMetricCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF191970),
            ),
          ),
          SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceChart() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Performance Overview',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF191970),
            ),
          ),
          SizedBox(height: 16),
          Container(
            height: 200,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(show: false),
                titlesData: FlTitlesData(show: false),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: [
                      FlSpot(0, 3),
                      FlSpot(1, 4),
                      FlSpot(2, 3.5),
                      FlSpot(3, 5),
                      FlSpot(4, 4.5),
                      FlSpot(5, 6),
                    ],
                    isCurved: true,
                    color: Color(0xFF191970),
                    barWidth: 3,
                    dotData: FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: Color(0xFF191970).withOpacity(0.1),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivity() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Recent Activity',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF191970),
            ),
          ),
          SizedBox(height: 16),
          ...List.generate(3, (index) {
            return Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Color(0xFF191970).withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.notifications,
                      color: Color(0xFF191970),
                      size: 20,
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'New collaboration request',
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF191970),
                          ),
                        ),
                        Text(
                          '2 hours ago',
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildAIInsights() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.psychology, color: Color(0xFF191970)),
              SizedBox(width: 8),
              Text(
                'AI Insights',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF191970),
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          _buildInsightItem(
            'Your photography skills are in high demand',
            'Consider offering more photo editing services',
            Icons.camera_alt,
          ),
          SizedBox(height: 12),
          _buildInsightItem(
            'Team collaboration score: 92%',
            'You work well with others - great for team projects',
            Icons.group,
          ),
          SizedBox(height: 12),
          _buildInsightItem(
            'Optimal pricing detected',
            'Your service prices are competitive in the market',
            Icons.trending_up,
          ),
        ],
      ),
    );
  }

  Widget _buildInsightItem(String title, String subtitle, IconData icon) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.amber.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: Colors.amber[700], size: 16),
        ),
        SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF191970),
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}