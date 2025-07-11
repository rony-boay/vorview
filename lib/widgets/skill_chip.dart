import 'package:flutter/material.dart';
import '../models/collaboration_models.dart';

class SkillChip extends StatelessWidget {
  final UserSkill skill;
  final VoidCallback onTap;

  const SkillChip({
    Key? key,
    required this.skill,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: _getProficiencyColor(skill.proficiencyLevel),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: _getProficiencyColor(skill.proficiencyLevel).withOpacity(0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              skill.name,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w500,
                fontSize: 12,
              ),
            ),
            SizedBox(width: 6),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.star,
                    color: Colors.white,
                    size: 10,
                  ),
                  SizedBox(width: 2),
                  Text(
                    skill.proficiencyLevel.toString(),
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            if (skill.rating > 0) ...[
              SizedBox(width: 6),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  skill.rating.toStringAsFixed(1),
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _getProficiencyColor(int level) {
    switch (level) {
      case 1:
        return Colors.red[400]!;
      case 2:
        return Colors.orange[400]!;
      case 3:
        return Colors.yellow[600]!;
      case 4:
        return Colors.lightGreen[400]!;
      case 5:
        return Colors.green[600]!;
      default:
        return Colors.grey[400]!;
    }
  }
}