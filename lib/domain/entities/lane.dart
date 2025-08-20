import 'job_card.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Lane {
  final String id;
  final String title;
  final String boardId;
  final int order;
  final List<JobCard> cards;

  Lane({
    required this.id,
    required this.title,
    required this.boardId,
    required this.order,
    required this.cards,
  });

  Lane copyWith({
    String? id,
    String? title,
    String? boardId,
    int? order,
    List<JobCard>? cards,
  }) {
    return Lane(
      id: id ?? this.id,
      title: title ?? this.title,
      boardId: boardId ?? this.boardId,
      order: order ?? this.order,
      cards: cards ?? this.cards,
    );
  }

  double get totalAmount {
    return cards.fold(0.0, (sum, card) => sum + card.amount);
  }

  int get cardCount {
    return cards.length;
  }

  // Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'boardId': boardId,
      'order': order,
    };
  }

  // Create from Map from Firestore
  factory Lane.fromMap(Map<String, dynamic> map, String id) {
    return Lane(
      id: id,
      title: map['title'] ?? '',
      boardId: map['boardId'] ?? '',
      order: map['order'] ?? 0,
      cards: [], // Cards will be loaded separately
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Lane &&
        other.id == id &&
        other.title == title &&
        other.boardId == boardId &&
        other.order == order &&
        other.cards == cards;
  }

  @override
  int get hashCode {
    return id.hashCode ^ title.hashCode ^ boardId.hashCode ^ order.hashCode ^ cards.hashCode;
  }

  @override
  String toString() {
    return 'Lane(id: $id, title: $title, boardId: $boardId, order: $order, cards: $cards)';
  }
}
