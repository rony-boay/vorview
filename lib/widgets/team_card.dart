import 'package:flutter/material.dart';
import '../models/collaboration_models.dart';

class TeamCard extends StatelessWidget {
  final CollaborationTeam team;
  final VoidCallback onTap;

  const TeamCard({
    Key? key,
    required this.team,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.only(bottom: 16),
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getStatusColor(team.status),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      team.status.toUpperCase(),
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Spacer(),
                  Icon(Icons.people, color: Colors.grey[600], size: 16),
                  SizedBox(width: 4),
                  Text(
                    '${team.memberIds.length} members',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                ],
              ),
              SizedBox(height: 12),
              Text(
                team.name,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF191970),
                ),
              ),
              SizedBox(height: 8),
              Text(
                team.description,
                style: TextStyle(color: Colors.grey[700]),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: 12),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: team.requiredSkills.take(3).map((skill) {
                  return Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Color(0xFF191970).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      skill,
                      style: TextStyle(
                        color: Color(0xFF191970),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  );
                }).toList(),
              ),
              if (team.requiredSkills.length > 3)
                Padding(
                  padding: EdgeInsets.only(top: 6),
                  child: Text(
                    '+${team.requiredSkills.length - 3} more skills',
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 12,
                    ),
                  ),
                ),
              SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.access_time, color: Colors.grey[500], size: 14),
                  SizedBox(width: 4),
                  Text(
                    'Created ${_formatDate(team.createdAt)}',
                    style: TextStyle(color: Colors.grey[500], fontSize: 12),
                  ),
                  Spacer(),
                  if (team.aiMatchingData.isNotEmpty)
                    Row(
                      children: [
                        Icon(Icons.auto_awesome, color: Colors.amber, size: 14),
                        SizedBox(width: 4),
                        Text(
                          'AI Matched',
                          style: TextStyle(color: Colors.amber[700], fontSize: 12),
                        ),
                      ],
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'forming':
        return Colors.orange;
      case 'active':
        return Colors.green;
      case 'completed':
        return Colors.blue;
      case 'disbanded':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inMinutes}m ago';
    }
  }
}