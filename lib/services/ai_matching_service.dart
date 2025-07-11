import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/collaboration_models.dart';

class AIMatchingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // AI-powered skill matching algorithm
  Future<List<String>> findSkillMatches(String userId, List<String> requiredSkills) async {
    try {
      final usersSnapshot = await _firestore.collection('user_skills').get();
      final matches = <Map<String, dynamic>>[];

      for (var doc in usersSnapshot.docs) {
        if (doc.id == userId) continue; // Don't match with self

        final userSkills = List<Map<String, dynamic>>.from(doc.data()['skills'] ?? []);
        final matchScore = _calculateSkillMatchScore(requiredSkills, userSkills);

        if (matchScore > 0.6) { // 60% match threshold
          matches.add({
            'userId': doc.id,
            'score': matchScore,
            'skills': userSkills,
          });
        }
      }

      // Sort by match score
      matches.sort((a, b) => b['score'].compareTo(a['score']));
      
      return matches.take(10).map((m) => m['userId'] as String).toList();
    } catch (e) {
      print('Error finding skill matches: $e');
      return [];
    }
  }

  double _calculateSkillMatchScore(List<String> required, List<Map<String, dynamic>> userSkills) {
    if (required.isEmpty) return 0.0;

    int matches = 0;
    double totalProficiency = 0.0;

    for (String requiredSkill in required) {
      for (var skill in userSkills) {
        if (_skillsMatch(requiredSkill, skill['name'])) {
          matches++;
          totalProficiency += (skill['proficiencyLevel'] ?? 1) / 5.0;
          break;
        }
      }
    }

    final coverageScore = matches / required.length;
    final proficiencyScore = matches > 0 ? totalProficiency / matches : 0.0;
    
    return (coverageScore * 0.7) + (proficiencyScore * 0.3);
  }

  bool _skillsMatch(String required, String available) {
    // Simple fuzzy matching - can be enhanced with ML
    final requiredLower = required.toLowerCase();
    final availableLower = available.toLowerCase();
    
    return availableLower.contains(requiredLower) || 
           requiredLower.contains(availableLower) ||
           _calculateLevenshteinDistance(requiredLower, availableLower) <= 2;
  }

  int _calculateLevenshteinDistance(String s1, String s2) {
    if (s1.isEmpty) return s2.length;
    if (s2.isEmpty) return s1.length;

    List<List<int>> matrix = List.generate(
      s1.length + 1,
      (i) => List.generate(s2.length + 1, (j) => 0),
    );

    for (int i = 0; i <= s1.length; i++) matrix[i][0] = i;
    for (int j = 0; j <= s2.length; j++) matrix[0][j] = j;

    for (int i = 1; i <= s1.length; i++) {
      for (int j = 1; j <= s2.length; j++) {
        int cost = s1[i - 1] == s2[j - 1] ? 0 : 1;
        matrix[i][j] = [
          matrix[i - 1][j] + 1,
          matrix[i][j - 1] + 1,
          matrix[i - 1][j - 1] + cost,
        ].reduce((a, b) => a < b ? a : b);
      }
    }

    return matrix[s1.length][s2.length];
  }

  // AI-powered service recommendations
  Future<List<ServiceOffering>> recommendServices(String userId, String category) async {
    try {
      final servicesSnapshot = await _firestore
          .collection('service_offerings')
          .where('category', isEqualTo: category)
          .where('isActive', isEqualTo: true)
          .get();

      final userPrefsSnapshot = await _firestore
          .collection('user_preferences')
          .doc(userId)
          .get();

      final userPrefs = userPrefsSnapshot.data() ?? {};
      final services = servicesSnapshot.docs
          .map((doc) => ServiceOffering.fromMap({...doc.data(), 'id': doc.id}))
          .toList();

      // AI scoring based on user preferences, ratings, and past interactions
      for (var service in services) {
        service = _scoreService(service, userPrefs);
      }

      services.sort((a, b) => b.rating.compareTo(a.rating));
      return services.take(20).toList();
    } catch (e) {
      print('Error recommending services: $e');
      return [];
    }
  }

  ServiceOffering _scoreService(ServiceOffering service, Map<String, dynamic> userPrefs) {
    // AI scoring logic - can be enhanced with ML models
    double score = service.rating;
    
    // Boost score based on user preferences
    final preferredPriceRange = userPrefs['preferredPriceRange'] as Map<String, dynamic>?;
    if (preferredPriceRange != null) {
      final minPrice = preferredPriceRange['min'] ?? 0.0;
      final maxPrice = preferredPriceRange['max'] ?? double.infinity;
      
      if (service.price >= minPrice && service.price <= maxPrice) {
        score += 0.5;
      }
    }

    // Boost for quick delivery
    if (service.deliveryDays <= 3) {
      score += 0.3;
    }

    // Boost for experienced sellers
    if (service.ordersCompleted > 50) {
      score += 0.4;
    }

    return service;
  }

  // Auto-reassignment logic for unresponsive collaborators
  Future<void> handleUnresponsiveCollaborator(String teamId, String unresponsiveUserId) async {
    try {
      final teamDoc = await _firestore.collection('collaboration_teams').doc(teamId).get();
      if (!teamDoc.exists) return;

      final team = CollaborationTeam.fromMap({...teamDoc.data()!, 'id': teamDoc.id});
      
      // Find replacement
      final replacementCandidates = await findSkillMatches(
        unresponsiveUserId, 
        team.requiredSkills
      );

      if (replacementCandidates.isNotEmpty) {
        final newMemberIds = team.memberIds.where((id) => id != unresponsiveUserId).toList();
        newMemberIds.add(replacementCandidates.first);

        await _firestore.collection('collaboration_teams').doc(teamId).update({
          'memberIds': newMemberIds,
          'aiMatchingData': {
            ...team.aiMatchingData,
            'lastReassignment': DateTime.now().toIso8601String(),
            'replacedMember': unresponsiveUserId,
            'newMember': replacementCandidates.first,
          }
        });

        // Notify team members
        await _notifyTeamReassignment(teamId, unresponsiveUserId, replacementCandidates.first);
      }
    } catch (e) {
      print('Error handling unresponsive collaborator: $e');
    }
  }

  Future<void> _notifyTeamReassignment(String teamId, String oldMember, String newMember) async {
    // Implementation for notifications
    await _firestore.collection('notifications').add({
      'type': 'team_reassignment',
      'teamId': teamId,
      'oldMember': oldMember,
      'newMember': newMember,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  // Quality checking AI
  Future<Map<String, dynamic>> performQualityCheck(String serviceOrderId) async {
    try {
      final orderDoc = await _firestore.collection('service_orders').doc(serviceOrderId).get();
      if (!orderDoc.exists) return {'passed': false, 'issues': ['Order not found']};

      final order = ServiceOrder.fromMap({...orderDoc.data()!, 'id': orderDoc.id});
      
      // AI quality checks
      final qualityScore = _calculateQualityScore(order);
      final issues = _identifyQualityIssues(order);

      return {
        'passed': qualityScore >= 0.7,
        'score': qualityScore,
        'issues': issues,
        'recommendations': _generateQualityRecommendations(issues),
      };
    } catch (e) {
      print('Error performing quality check: $e');
      return {'passed': false, 'issues': ['Quality check failed']};
    }
  }

  double _calculateQualityScore(ServiceOrder order) {
    double score = 0.5; // Base score

    // Check delivery time
    if (order.deliveryDate != null) {
      final expectedDelivery = order.orderDate.add(Duration(days: 7)); // Assume 7 days
      if (order.deliveryDate!.isBefore(expectedDelivery)) {
        score += 0.2;
      }
    }

    // Check deliverables count
    if (order.deliverables.isNotEmpty) {
      score += 0.2;
    }

    // Check if requirements were met (simplified)
    if (order.requirements.isNotEmpty && order.deliverables.isNotEmpty) {
      score += 0.1;
    }

    return score.clamp(0.0, 1.0);
  }

  List<String> _identifyQualityIssues(ServiceOrder order) {
    final issues = <String>[];

    if (order.deliverables.isEmpty) {
      issues.add('No deliverables provided');
    }

    if (order.deliveryDate == null) {
      issues.add('No delivery date recorded');
    }

    if (order.status == 'disputed') {
      issues.add('Order is under dispute');
    }

    return issues;
  }

  List<String> _generateQualityRecommendations(List<String> issues) {
    final recommendations = <String>[];

    for (String issue in issues) {
      switch (issue) {
        case 'No deliverables provided':
          recommendations.add('Request seller to upload deliverables');
          break;
        case 'No delivery date recorded':
          recommendations.add('Update delivery tracking system');
          break;
        case 'Order is under dispute':
          recommendations.add('Initiate mediation process');
          break;
      }
    }

    return recommendations;
  }
}