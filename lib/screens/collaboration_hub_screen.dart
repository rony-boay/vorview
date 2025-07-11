import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/collaboration_models.dart';
import '../services/ai_matching_service.dart';
import '../widgets/team_card.dart';
import '../widgets/service_card.dart';
import '../widgets/skill_chip.dart';

class CollaborationHubScreen extends StatefulWidget {
  @override
  _CollaborationHubScreenState createState() => _CollaborationHubScreenState();
}

class _CollaborationHubScreenState extends State<CollaborationHubScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final AIMatchingService _aiService = AIMatchingService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final User? _currentUser = FirebaseAuth.instance.currentUser;

  List<CollaborationTeam> _myTeams = [];
  List<ServiceOffering> _recommendedServices = [];
  List<UserSkill> _mySkills = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    if (_currentUser == null) return;

    setState(() => _isLoading = true);

    try {
      // Load user's teams
      final teamsSnapshot = await _firestore
          .collection('collaboration_teams')
          .where('memberIds', arrayContains: _currentUser!.uid)
          .get();

      _myTeams = teamsSnapshot.docs
          .map((doc) => CollaborationTeam.fromMap({...doc.data(), 'id': doc.id}))
          .toList();

      // Load user's skills
      final skillsDoc = await _firestore
          .collection('user_skills')
          .doc(_currentUser!.uid)
          .get();

      if (skillsDoc.exists) {
        final skillsData = skillsDoc.data()!['skills'] as List<dynamic>? ?? [];
        _mySkills = skillsData
            .map((skill) => UserSkill.fromMap(Map<String, dynamic>.from(skill)))
            .toList();
      }

      // Get AI recommendations
      _recommendedServices = await _aiService.recommendServices(
        _currentUser!.uid,
        'photography', // Default category
      );
    } catch (e) {
      print('Error loading collaboration data: $e');
    }

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'Collaboration Hub',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Color(0xFF191970),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: [
            Tab(icon: Icon(Icons.group), text: 'Teams'),
            Tab(icon: Icon(Icons.store), text: 'Services'),
            Tab(icon: Icon(Icons.psychology), text: 'AI Match'),
            Tab(icon: Icon(Icons.dashboard), text: 'Dashboard'),
          ],
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: Color(0xFF191970)))
          : TabBarView(
              controller: _tabController,
              children: [
                _buildTeamsTab(),
                _buildServicesTab(),
                _buildAIMatchTab(),
                _buildDashboardTab(),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateOptions,
        backgroundColor: Color(0xFF191970),
        icon: Icon(Icons.add, color: Colors.white),
        label: Text('Create', style: TextStyle(color: Colors.white)),
      ),
    );
  }

  Widget _buildTeamsTab() {
    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView(
        padding: EdgeInsets.all(16),
        children: [
          _buildSectionHeader('My Teams', Icons.group),
          SizedBox(height: 16),
          if (_myTeams.isEmpty)
            _buildEmptyState(
              'No teams yet',
              'Join or create a team to start collaborating',
              Icons.group_add,
            )
          else
            ...(_myTeams.map((team) => TeamCard(
                  team: team,
                  onTap: () => _navigateToTeamDetails(team),
                ))),
          SizedBox(height: 24),
          _buildSectionHeader('Recommended Teams', Icons.auto_awesome),
          SizedBox(height: 16),
          _buildRecommendedTeams(),
        ],
      ),
    );
  }

  Widget _buildServicesTab() {
    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView(
        padding: EdgeInsets.all(16),
        children: [
          _buildSectionHeader('Recommended Services', Icons.recommend),
          SizedBox(height: 16),
          if (_recommendedServices.isEmpty)
            _buildEmptyState(
              'No services found',
              'Check back later for AI-recommended services',
              Icons.store,
            )
          else
            ...(_recommendedServices.map((service) => ServiceCard(
                  service: service,
                  onTap: () => _navigateToServiceDetails(service),
                ))),
        ],
      ),
    );
  }

  Widget _buildAIMatchTab() {
    return ListView(
      padding: EdgeInsets.all(16),
      children: [
        _buildSectionHeader('AI-Powered Matching', Icons.psychology),
        SizedBox(height: 16),
        Card(
          color: Colors.blue.shade50,
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.auto_awesome, color: Color(0xFF191970)),
                    SizedBox(width: 8),
                    Text(
                      'Smart Recommendations',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF191970),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12),
                Text(
                  'Our AI analyzes your skills, preferences, and collaboration history to find the perfect matches.',
                  style: TextStyle(color: Colors.grey[700]),
                ),
                SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _findAIMatches,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF191970),
                    foregroundColor: Colors.white,
                  ),
                  icon: Icon(Icons.search),
                  label: Text('Find Matches'),
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: 24),
        _buildSectionHeader('Your Skills', Icons.star),
        SizedBox(height: 16),
        if (_mySkills.isEmpty)
          _buildEmptyState(
            'No skills added',
            'Add your skills to get better AI matches',
            Icons.add_circle,
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _mySkills
                .map((skill) => SkillChip(
                      skill: skill,
                      onTap: () => _editSkill(skill),
                    ))
                .toList(),
          ),
        SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: _addSkill,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: Color(0xFF191970),
            side: BorderSide(color: Color(0xFF191970)),
          ),
          icon: Icon(Icons.add),
          label: Text('Add Skill'),
        ),
      ],
    );
  }

  Widget _buildDashboardTab() {
    return ListView(
      padding: EdgeInsets.all(16),
      children: [
        _buildSectionHeader('Performance Dashboard', Icons.dashboard),
        SizedBox(height: 16),
        _buildStatsCards(),
        SizedBox(height: 24),
        _buildSectionHeader('Recent Activity', Icons.history),
        SizedBox(height: 16),
        _buildRecentActivity(),
      ],
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: Color(0xFF191970), size: 24),
        SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF191970),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(String title, String subtitle, IconData icon) {
    return Container(
      padding: EdgeInsets.all(32),
      child: Column(
        children: [
          Icon(icon, size: 64, color: Colors.grey[400]),
          SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 8),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendedTeams() {
    // Placeholder for recommended teams
    return Container(
      height: 200,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: 3,
        itemBuilder: (context, index) {
          return Container(
            width: 300,
            margin: EdgeInsets.only(right: 16),
            child: Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Photography Team ${index + 1}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF191970),
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Looking for product photographers and editors',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    Spacer(),
                    Row(
                      children: [
                        Icon(Icons.people, size: 16, color: Colors.grey[500]),
                        SizedBox(width: 4),
                        Text('3/5 members', style: TextStyle(fontSize: 12)),
                        Spacer(),
                        TextButton(
                          onPressed: () {},
                          child: Text('Join'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatsCards() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard('Teams', '${_myTeams.length}', Icons.group),
        ),
        SizedBox(width: 16),
        Expanded(
          child: _buildStatCard('Skills', '${_mySkills.length}', Icons.star),
        ),
        SizedBox(width: 16),
        Expanded(
          child: _buildStatCard('Rating', '4.8', Icons.thumb_up),
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon) {
    return Card(
      color: Color(0xFF191970),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: Colors.white, size: 32),
            SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            Text(
              title,
              style: TextStyle(color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivity() {
    return Column(
      children: List.generate(3, (index) {
        return ListTile(
          leading: CircleAvatar(
            backgroundColor: Color(0xFF191970),
            child: Icon(Icons.history, color: Colors.white),
          ),
          title: Text('Activity ${index + 1}'),
          subtitle: Text('Recent collaboration activity'),
          trailing: Text('2h ago'),
        );
      }),
    );
  }

  void _showCreateOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.group_add, color: Color(0xFF191970)),
              title: Text('Create Team'),
              onTap: () {
                Navigator.pop(context);
                _createTeam();
              },
            ),
            ListTile(
              leading: Icon(Icons.store, color: Color(0xFF191970)),
              title: Text('Offer Service'),
              onTap: () {
                Navigator.pop(context);
                _createService();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _findAIMatches() async {
    if (_mySkills.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Add skills first to get AI matches')),
      );
      return;
    }

    final skillNames = _mySkills.map((s) => s.name).toList();
    final matches = await _aiService.findSkillMatches(_currentUser!.uid, skillNames);
    
    // Show matches dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('AI Matches Found'),
        content: Text('Found ${matches.length} potential collaborators'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  void _addSkill() {
    // Navigate to add skill screen
  }

  void _editSkill(UserSkill skill) {
    // Navigate to edit skill screen
  }

  void _createTeam() {
    // Navigate to create team screen
  }

  void _createService() {
    // Navigate to create service screen
  }

  void _navigateToTeamDetails(CollaborationTeam team) {
    // Navigate to team details screen
  }

  void _navigateToServiceDetails(ServiceOffering service) {
    // Navigate to service details screen
  }
}