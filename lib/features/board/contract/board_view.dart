import '../state/board_state.dart';

abstract class BoardView {
  void showLoading(bool isLoading);
  void showError(String message);
  void render(BoardState state);
}
