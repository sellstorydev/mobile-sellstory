import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:sellstory/features/login/widgets/branded_logo.dart';
import 'package:sellstory/core/i18n/app_translations.dart';

void main() {
  testWidgets('BrandedLogo widget test', (WidgetTester tester) async {
    // Build the widget with translations
    await tester.pumpWidget(
      GetMaterialApp(
        translations: AppTranslations(),
        locale: const Locale('en', 'US'),
        home: const Scaffold(
          body: BrandedLogo(),
        ),
      ),
    );

    // Verify that the logo text is displayed
    expect(find.text('SellStory'), findsOneWidget);
  });
}
