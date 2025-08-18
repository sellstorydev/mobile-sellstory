import 'package:flutter/material.dart';
import 'package:get/get.dart';

class BrandedLogo extends StatelessWidget {
  const BrandedLogo({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Placeholder orange mark
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(
            Icons.shopping_cart,
            color: Theme.of(context).colorScheme.onPrimary,
            size: 40,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'app_name'.tr,
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).primaryColor,
          ),
        ),
      ],
    );
  }
}
