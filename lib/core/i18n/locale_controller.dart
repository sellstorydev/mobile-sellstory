import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

class LocaleController extends GetxController {
  final box = GetStorage();
  final locale = const Locale('th', 'TH').obs;
  static const _k = 'locale';

  @override
  void onInit() {
    final s = box.read<String>(_k);
    if (s == 'en_US') locale.value = const Locale('en', 'US');
    super.onInit();
  }

  void setLocale(Locale l) {
    locale.value = l;
    box.write(_k, '${l.languageCode}_${l.countryCode}');
    Get.updateLocale(l);
  }

  void toggle() {
    setLocale(locale.value.languageCode == 'th' 
        ? const Locale('en', 'US') 
        : const Locale('th', 'TH'));
  }
}
