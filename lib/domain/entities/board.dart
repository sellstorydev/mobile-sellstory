import 'lane.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Board {
  final String id;
  final String title;
  final String userId;
  final List<Lane> lanes;
  final DateTime createdAt;
  final DateTime updatedAt;

  Board({
    required this.id,
    required this.title,
    required this.userId,
    required this.lanes,
    required this.createdAt,
    required this.updatedAt,
  });

  Board copyWith({
    String? id,
    String? title,
    String? userId,
    List<Lane>? lanes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Board(
      id: id ?? this.id,
      title: title ?? this.title,
      userId: userId ?? this.userId,
      lanes: lanes ?? this.lanes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'userId': userId,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  // Create from Map from Firestore
  factory Board.fromMap(Map<String, dynamic> map, String id) {
    return Board(
      id: id,
      title: map['title'] ?? '',
      userId: map['userId'] ?? '',
      lanes: [], // Lanes will be loaded separately
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Board &&
        other.id == id &&
        other.title == title &&
        other.userId == userId &&
        other.lanes == lanes &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        title.hashCode ^
        userId.hashCode ^
        lanes.hashCode ^
        createdAt.hashCode ^
        updatedAt.hashCode;
  }

  @override
  String toString() {
    return 'Board(id: $id, title: $title, userId: $userId, lanes: $lanes, createdAt: $createdAt, updatedAt: $updatedAt)';
  }
}
