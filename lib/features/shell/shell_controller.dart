import 'package:get/get.dart';

class ShellController extends GetxController {
  final RxInt currentIndex = 0.obs;

  void onTabTapped(int index) {
    currentIndex.value = index;
  }
}
