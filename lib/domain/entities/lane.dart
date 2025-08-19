import 'job_card.dart';

class Lane {
  final String id;
  final String title;
  final int order;
  final List<JobCard> cards;

  Lane({
    required this.id,
    required this.title,
    required this.order,
    required this.cards,
  });

  Lane copyWith({
    String? id,
    String? title,
    int? order,
    List<JobCard>? cards,
  }) {
    return Lane(
      id: id ?? this.id,
      title: title ?? this.title,
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

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Lane &&
        other.id == id &&
        other.title == title &&
        other.order == order &&
        other.cards == cards;
  }

  @override
  int get hashCode {
    return id.hashCode ^ title.hashCode ^ order.hashCode ^ cards.hashCode;
  }

  @override
  String toString() {
    return 'Lane(id: $id, title: $title, order: $order, cards: $cards)';
  }
}
