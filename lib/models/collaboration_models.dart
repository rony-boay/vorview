// Models for the collaborative ecosystem
class UserSkill {
  final String id;
  final String name;
  final String category;
  final int proficiencyLevel; // 1-5
  final double rating;
  final int completedProjects;
  final List<String> tags;

  UserSkill({
    required this.id,
    required this.name,
    required this.category,
    required this.proficiencyLevel,
    required this.rating,
    required this.completedProjects,
    required this.tags,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'proficiencyLevel': proficiencyLevel,
      'rating': rating,
      'completedProjects': completedProjects,
      'tags': tags,
    };
  }

  factory UserSkill.fromMap(Map<String, dynamic> map) {
    return UserSkill(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      category: map['category'] ?? '',
      proficiencyLevel: map['proficiencyLevel'] ?? 1,
      rating: (map['rating'] ?? 0.0).toDouble(),
      completedProjects: map['completedProjects'] ?? 0,
      tags: List<String>.from(map['tags'] ?? []),
    );
  }
}

class ServiceOffering {
  final String id;
  final String sellerId;
  final String title;
  final String description;
  final String category;
  final double price;
  final String currency;
  final int deliveryDays;
  final List<String> skillsRequired;
  final List<String> portfolioImages;
  final double rating;
  final int ordersCompleted;
  final bool isActive;
  final DateTime createdAt;

  ServiceOffering({
    required this.id,
    required this.sellerId,
    required this.title,
    required this.description,
    required this.category,
    required this.price,
    required this.currency,
    required this.deliveryDays,
    required this.skillsRequired,
    required this.portfolioImages,
    required this.rating,
    required this.ordersCompleted,
    required this.isActive,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'sellerId': sellerId,
      'title': title,
      'description': description,
      'category': category,
      'price': price,
      'currency': currency,
      'deliveryDays': deliveryDays,
      'skillsRequired': skillsRequired,
      'portfolioImages': portfolioImages,
      'rating': rating,
      'ordersCompleted': ordersCompleted,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory ServiceOffering.fromMap(Map<String, dynamic> map) {
    return ServiceOffering(
      id: map['id'] ?? '',
      sellerId: map['sellerId'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      category: map['category'] ?? '',
      price: (map['price'] ?? 0.0).toDouble(),
      currency: map['currency'] ?? 'USD',
      deliveryDays: map['deliveryDays'] ?? 1,
      skillsRequired: List<String>.from(map['skillsRequired'] ?? []),
      portfolioImages: List<String>.from(map['portfolioImages'] ?? []),
      rating: (map['rating'] ?? 0.0).toDouble(),
      ordersCompleted: map['ordersCompleted'] ?? 0,
      isActive: map['isActive'] ?? true,
      createdAt: DateTime.parse(map['createdAt'] ?? DateTime.now().toIso8601String()),
    );
  }
}

class CollaborationTeam {
  final String id;
  final String name;
  final String description;
  final String leaderId;
  final List<String> memberIds;
  final List<String> requiredSkills;
  final String status; // forming, active, completed, disbanded
  final DateTime createdAt;
  final Map<String, dynamic> aiMatchingData;

  CollaborationTeam({
    required this.id,
    required this.name,
    required this.description,
    required this.leaderId,
    required this.memberIds,
    required this.requiredSkills,
    required this.status,
    required this.createdAt,
    required this.aiMatchingData,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'leaderId': leaderId,
      'memberIds': memberIds,
      'requiredSkills': requiredSkills,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
      'aiMatchingData': aiMatchingData,
    };
  }

  factory CollaborationTeam.fromMap(Map<String, dynamic> map) {
    return CollaborationTeam(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      leaderId: map['leaderId'] ?? '',
      memberIds: List<String>.from(map['memberIds'] ?? []),
      requiredSkills: List<String>.from(map['requiredSkills'] ?? []),
      status: map['status'] ?? 'forming',
      createdAt: DateTime.parse(map['createdAt'] ?? DateTime.now().toIso8601String()),
      aiMatchingData: Map<String, dynamic>.from(map['aiMatchingData'] ?? {}),
    );
  }
}

class ServiceOrder {
  final String id;
  final String buyerId;
  final String sellerId;
  final String serviceId;
  final double amount;
  final String status; // pending, in_progress, completed, cancelled, disputed
  final String requirements;
  final List<String> deliverables;
  final DateTime orderDate;
  final DateTime? deliveryDate;
  final double? rating;
  final String? feedback;

  ServiceOrder({
    required this.id,
    required this.buyerId,
    required this.sellerId,
    required this.serviceId,
    required this.amount,
    required this.status,
    required this.requirements,
    required this.deliverables,
    required this.orderDate,
    this.deliveryDate,
    this.rating,
    this.feedback,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'buyerId': buyerId,
      'sellerId': sellerId,
      'serviceId': serviceId,
      'amount': amount,
      'status': status,
      'requirements': requirements,
      'deliverables': deliverables,
      'orderDate': orderDate.toIso8601String(),
      'deliveryDate': deliveryDate?.toIso8601String(),
      'rating': rating,
      'feedback': feedback,
    };
  }

  factory ServiceOrder.fromMap(Map<String, dynamic> map) {
    return ServiceOrder(
      id: map['id'] ?? '',
      buyerId: map['buyerId'] ?? '',
      sellerId: map['sellerId'] ?? '',
      serviceId: map['serviceId'] ?? '',
      amount: (map['amount'] ?? 0.0).toDouble(),
      status: map['status'] ?? 'pending',
      requirements: map['requirements'] ?? '',
      deliverables: List<String>.from(map['deliverables'] ?? []),
      orderDate: DateTime.parse(map['orderDate'] ?? DateTime.now().toIso8601String()),
      deliveryDate: map['deliveryDate'] != null ? DateTime.parse(map['deliveryDate']) : null,
      rating: map['rating']?.toDouble(),
      feedback: map['feedback'],
    );
  }
}