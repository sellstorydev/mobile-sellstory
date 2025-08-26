import 'package:cloud_firestore/cloud_firestore.dart';

class Board {
  final String id;
  final String name;
  final String workspaceId;
  final String createdBy;
  final List<Map<String, dynamic>> members;
  final List<String> memberUids;
  final List<String> lanes;
  final DateTime createdAt;
  final DateTime updatedAt;

  Board({
    required this.id,
    required this.name,
    required this.workspaceId,
    required this.createdBy,
    required this.members,
    required this.memberUids,
    required this.lanes,
    required this.createdAt,
    required this.updatedAt,
  });

  Board copyWith({
    String? id,
    String? name,
    String? workspaceId,
    String? createdBy,
    List<Map<String, dynamic>>? members,
    List<String>? memberUids,
    List<String>? lanes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Board(
      id: id ?? this.id,
      name: name ?? this.name,
      workspaceId: workspaceId ?? this.workspaceId,
      createdBy: createdBy ?? this.createdBy,
      members: members ?? this.members,
      memberUids: memberUids ?? this.memberUids,
      lanes: lanes ?? this.lanes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'workspaceId': workspaceId,
      'createdBy': createdBy,
      'members': members,
      'memberUids': memberUids,
      'lanes': lanes,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  factory Board.fromMap(Map<String, dynamic> map, String id) {
    return Board(
      id: id,
      name: map['name'] ?? '',
      workspaceId: map['workspaceId'] ?? '',
      createdBy: map['createdBy'] ?? '',
      members: List<Map<String, dynamic>>.from(map['members'] ?? []),
      memberUids: List<String>.from(map['memberUids'] ?? []),
      lanes: List<String>.from(map['lanes'] ?? []),
      createdAt: (map['createdAt'] is Timestamp) 
                 ? (map['createdAt'] as Timestamp).toDate()
                 : DateTime.fromMillisecondsSinceEpoch(map['createdAt'] ?? 0),
      updatedAt: (map['updatedAt'] is Timestamp)
                 ? (map['updatedAt'] as Timestamp).toDate()
                 : DateTime.fromMillisecondsSinceEpoch(map['updatedAt'] ?? 0),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Board &&
        other.id == id &&
        other.name == name &&
        other.workspaceId == workspaceId &&
        other.createdBy == createdBy &&
        other.members == members &&
        other.memberUids == memberUids &&
        other.lanes == lanes &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        name.hashCode ^
        workspaceId.hashCode ^
        createdBy.hashCode ^
        members.hashCode ^
        memberUids.hashCode ^
        lanes.hashCode ^
        createdAt.hashCode ^
        updatedAt.hashCode;
  }

  @override
  String toString() {
    return 'Board(id: $id, name: $name, workspaceId: $workspaceId, createdBy: $createdBy, members: $members, memberUids: $memberUids, lanes: $lanes, createdAt: $createdAt, updatedAt: $updatedAt)';
  }
}
