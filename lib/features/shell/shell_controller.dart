import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../data/services/firestore_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ShellController extends GetxController {
  final RxInt currentIndex = 0.obs;
  // When true, show CompanyCenterPage on the Customers tab
  final RxBool showCompaniesInCustomersTab = false.obs;

  // Prevent multiple prompts
  bool _emailPromptChecked = false;

  @override
  void onReady() {
    super.onReady();
    _maybePromptAppleEmail();
  }

  void onTabTapped(int index) {
    currentIndex.value = index;
  }

  void setCustomersTabMode({required bool companyMode}) {
    showCompaniesInCustomersTab.value = companyMode;
  }

  Future<void> _maybePromptAppleEmail() async {
    if (_emailPromptChecked) return;
    _emailPromptChecked = true;
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // Check if signed in with Apple
      final isApple = user.providerData.any((p) => p.providerId == 'apple.com');
      if (!isApple) return;

      final fs = FirestoreService.to.firestore;
      final userDocRef = fs.collection('users').doc(user.uid);
      final userSnap = await userDocRef.get();
      final data = userSnap.data() ?? <String, dynamic>{};
      final storedEmail = (data['email'] as String?)?.trim() ?? '';
      final emailCollected = data['emailCollected'] == true;

      // Show once until collected, regardless of auth profile email
      final needsPrompt = !emailCollected || storedEmail.isEmpty;
      if (!needsPrompt) return;

      // Ensure user doc exists
      if (!userSnap.exists) {
        await userDocRef.set({
          'createdAt': FieldValue.serverTimestamp(),
          'provider': 'apple',
        }, SetOptions(merge: true));
      }

      await _showEmailBottomSheet(userDocRef, prefill: (user.email ?? storedEmail));
    } catch (e) {
      // Fail silently; not critical for app usage
    }
  }

  Future<void> _showEmailBottomSheet(DocumentReference<Map<String, dynamic>> userDocRef, {String prefill = ''}) async {
    final context = Get.context;
    if (context == null) return;

    final formKey = GlobalKey<FormState>();
    final emailController = TextEditingController(text: prefill);

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
            left: 16,
            right: 16,
            top: 16,
          ),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'enter_email_contact'.tr,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                Text(
                  'apple_id_email_prompt'.tr,
                  style: const TextStyle(fontSize: 14, color: Colors.black54),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    hintText: 'email_placeholder'.tr,
                    filled: true,
                    fillColor: const Color(0xFFF5F5F5),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                  validator: (value) {
                    final v = (value ?? '').trim();
                    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
                    if (v.isEmpty) return 'please_enter_email'.tr;
                    if (!emailRegex.hasMatch(v)) return 'invalid_email'.tr;
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (!formKey.currentState!.validate()) return;
                      final rawEmail = emailController.text.trim();
                      final emailLower = rawEmail.toLowerCase();
                      try {
                        final current = FirebaseAuth.instance.currentUser;

                        // Check Firestore users collection for duplicate (other user)
                        final fs = FirestoreService.to.firestore;
                        // Exact case
                        final dupExact = await fs
                            .collection('users')
                            .where('email', isEqualTo: rawEmail)
                            .limit(1)
                            .get();
                        if (dupExact.docs.isNotEmpty && dupExact.docs.first.id != (current?.uid ?? '')) {
                          Get.snackbar(
                            'failed'.tr,
                            'email_already_exists'.tr,
                            snackPosition: SnackPosition.BOTTOM,
                            backgroundColor: Colors.red.withValues(alpha: 0.08),
                            colorText: Colors.red,
                          );
                          if (Get.isOverlaysOpen) Get.back();
                          return;
                        }
                        // Case-insensitive via emailLower
                        final dupLower = await fs
                            .collection('users')
                            .where('emailLower', isEqualTo: emailLower)
                            .limit(1)
                            .get();
                        if (dupLower.docs.isNotEmpty && dupLower.docs.first.id != (current?.uid ?? '')) {
                          Get.snackbar(
                            'failed'.tr,
                            'email_already_exists'.tr,
                            snackPosition: SnackPosition.BOTTOM,
                            backgroundColor: Colors.red.withValues(alpha: 0.08),
                            colorText: Colors.red,
                          );
                          if (Get.isOverlaysOpen) Get.back();
                          return;
                        }
                        // Save
                        await userDocRef.set({
                          'email': rawEmail,
                          'emailLower': emailLower,
                          'emailCollected': true,
                          'updatedAt': FieldValue.serverTimestamp(),
                        }, SetOptions(merge: true));
                        Get.back();
                        Get.snackbar(
                          'success'.tr,
                          'save_email_success'.tr,
                          snackPosition: SnackPosition.BOTTOM,
                          backgroundColor: Colors.green.withValues(alpha: 0.08),
                          colorText: Colors.green,
                        );
                        // if (Get.isOverlaysOpen) Get.back();
                      } catch (e) {

                        Get.snackbar(
                          'failed'.tr,
                          'save_email_failed'.tr,
                          snackPosition: SnackPosition.BOTTOM,
                          backgroundColor: Colors.red.withValues(alpha: 0.08),
                          colorText: Colors.red,
                        );
                        if (Get.isOverlaysOpen) Get.back();
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF6F3D),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: Text('save_email'.tr),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () => Get.back(),
                    child: Text('later'.tr),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }
}
