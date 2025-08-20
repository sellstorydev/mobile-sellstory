import 'package:cloud_firestore/cloud_firestore.dart';

class JobCard {
  final String id;
  final String title;
  final String assignee;
  final DateTime? dueDate;
  final List<String> badges;
  final double amount;
  final String laneId;
  final int order;
  final DateTime createdAt;
  final DateTime updatedAt;

  JobCard({
    required this.id,
    required this.title,
    required this.assignee,
    this.dueDate,
    required this.badges,
    required this.amount,
    required this.laneId,
    required this.order,
    required this.createdAt,
    required this.updatedAt,
  });

  JobCard copyWith({
    String? id,
    String? title,
    String? assignee,
    DateTime? dueDate,
    List<String>? badges,
    double? amount,
    String? laneId,
    int? order,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return JobCard(
      id: id ?? this.id,
      title: title ?? this.title,
      assignee: assignee ?? this.assignee,
      dueDate: dueDate ?? this.dueDate,
      badges: badges ?? this.badges,
      amount: amount ?? this.amount,
      laneId: laneId ?? this.laneId,
      order: order ?? this.order,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'assignee': assignee,
      'dueDate': dueDate != null ? Timestamp.fromDate(dueDate!) : null,
      'badges': badges,
      'amount': amount,
      'laneId': laneId,
      'order': order,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  // Create from Map from Firestore
  factory JobCard.fromMap(Map<String, dynamic> map, String id) {
    return JobCard(
      id: id,
      title: map['title'] ?? '',
      assignee: map['assignee'] ?? '',
      dueDate: (map['dueDate'] as Timestamp?)?.toDate(),
      badges: List<String>.from(map['badges'] ?? []),
      amount: (map['amount'] ?? 0.0).toDouble(),
      laneId: map['laneId'] ?? '',
      order: map['order'] ?? 0,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is JobCard &&
        other.id == id &&
        other.title == title &&
        other.assignee == assignee &&
        other.dueDate == dueDate &&
        other.badges == badges &&
        other.amount == amount &&
        other.laneId == laneId &&
        other.order == order &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        title.hashCode ^
        assignee.hashCode ^
        dueDate.hashCode ^
        badges.hashCode ^
        amount.hashCode ^
        laneId.hashCode ^
        order.hashCode ^
        createdAt.hashCode ^
        updatedAt.hashCode;
  }

  @override
  String toString() {
    return 'JobCard(id: $id, title: $title, assignee: $assignee, dueDate: $dueDate, badges: $badges, amount: $amount, laneId: $laneId, order: $order, createdAt: $createdAt, updatedAt: $updatedAt)';
  }
}
