class JobCard {
  final String id;
  final String title;
  final String assignee;
  final DateTime? dueDate;
  final List<String> badges;
  final double amount;
  final String laneId;
  final int order;

  JobCard({
    required this.id,
    required this.title,
    required this.assignee,
    this.dueDate,
    required this.badges,
    required this.amount,
    required this.laneId,
    required this.order,
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
        other.order == order;
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
        order.hashCode;
  }

  @override
  String toString() {
    return 'JobCard(id: $id, title: $title, assignee: $assignee, dueDate: $dueDate, badges: $badges, amount: $amount, laneId: $laneId, order: $order)';
  }
}
