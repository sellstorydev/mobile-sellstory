import 'package:get/get.dart';

class ShellController extends GetxController {
  final RxInt currentIndex = 0.obs;
  // When true, show CompanyCenterPage on the Customers tab
  final RxBool showCompaniesInCustomersTab = false.obs;

  void onTabTapped(int index) {
    currentIndex.value = index;
  }

  void setCustomersTabMode({required bool companyMode}) {
    showCompaniesInCustomersTab.value = companyMode;
  }
}
