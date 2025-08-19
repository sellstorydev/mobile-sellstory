import '../../../domain/entities/lane.dart';

class BoardState {
  final List<Lane> lanes;
  final bool isLoading;
  final String? error;

  const BoardState({
    required this.lanes,
    this.isLoading = false,
    this.error,
  });

  BoardState copyWith({
    List<Lane>? lanes,
    bool? isLoading,
    String? error,
  }) {
    return BoardState(
      lanes: lanes ?? this.lanes,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BoardState &&
        other.lanes == lanes &&
        other.isLoading == isLoading &&
        other.error == error;
  }

  @override
  int get hashCode {
    return lanes.hashCode ^ isLoading.hashCode ^ error.hashCode;
  }

  @override
  String toString() {
    return 'BoardState(lanes: $lanes, isLoading: $isLoading, error: $error)';
  }
}
