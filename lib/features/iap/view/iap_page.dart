import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/in_app_purchase_service.dart';

class IapPage extends StatelessWidget {
  const IapPage({super.key});

  @override
  Widget build(BuildContext context) {
    if (!Platform.isIOS) {
      return Scaffold(
        appBar: AppBar(title: Text('iap_title'.tr)),
        body: Center(child: Text('iap_ios_only'.tr)),
      );
    }

    final svc = Get.put(InAppPurchaseService()).init();

    return FutureBuilder(
      future: svc,
      builder: (context, snapshot) {
        return Scaffold(
          backgroundColor: AppTheme.backgroundGrey,
          appBar: AppBar(
            title: Text('iap_title'.tr),
            backgroundColor: AppTheme.backgroundWhite,
            foregroundColor: AppTheme.textPrimary,
            elevation: 0,
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh),
                tooltip: 'refresh'.tr,
                onPressed: () {
                  final s = Get.find<InAppPurchaseService>();
                  try {
                    s.refreshProducts();
                  } catch (_) {
                    // fallback if hot reload symbol mismatch
                    s.reloadProducts();
                  }
                },
              ),
              IconButton(
                icon: const Icon(Icons.restore),
                tooltip: 'iap_restore'.tr,
                onPressed: () {
                  final s = Get.find<InAppPurchaseService>();
                  s.restore();
                },
              )
            ],
          ),
          body: GetX<InAppPurchaseService>(builder: (service) {
            if (service.isLoading.value) {
              return const Center(child: CircularProgressIndicator(color: AppTheme.primaryOrange));
            }
            if (!service.isAvailable.value) {
              return Center(child: Text(service.errorMessage.isNotEmpty ? service.errorMessage.value : 'iap_not_available'.tr));
            }
            if (service.products.isEmpty) {
              // Simulator fallback UI: show a mock product to let QA flow proceed
              if (service.isSimulator) {
                final mockId = '365day';
                final owned = service.hasActivePurchase(mockId);
                return ListView(
                  padding: const EdgeInsets.all(24),
                  children: [
                    Text('iap_simulator_mode'.tr, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    Text('iap_simulator_notice'.tr, style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.backgroundWhite,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('iap_simulator_mock_product'.trParams({'id': mockId}), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 4),
                          Text('iap_no_products'.tr, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Text('—', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppTheme.primaryOrange)),
                              const Spacer(),
                              owned
                                  ? Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.green.shade50,
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text('iap_owned'.tr, style: const TextStyle(color: Colors.green, fontWeight: FontWeight.w600)),
                                    )
                                  : ElevatedButton(
                                      onPressed: () => service.simulatePurchase(mockId),
                                      style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryOrange),
                                      child: Text('iap_buy'.tr),
                                    )
                            ],
                          )
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton.icon(
                      onPressed: () {
                        try {
                          service.refreshProducts();
                        } catch (_) {
                          service.reloadProducts();
                        }
                      },
                      icon: const Icon(Icons.refresh),
                      label: Text('refresh'.tr),
                      style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryOrange),
                    )
                  ],
                );
              }
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('iap_no_products'.tr, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                     
                
                      // Debug info (always shown for now – remove later or gate with kDebugMode)
                      const SizedBox(height: 12),
                      const Text(
                        'IDs (configured): 365day',
                        style: TextStyle(fontSize: 11, color: Colors.grey),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Not Found: ' + (service.notFoundIds.isEmpty ? '—' : service.notFoundIds.join(', ')),
                        style: const TextStyle(fontSize: 11, color: Colors.grey),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () {
                          try {
                            service.refreshProducts();
                          } catch (_) {
                            service.reloadProducts();
                          }
                        },

                        icon: const Icon(Icons.refresh),
                        label: Text('refresh'.tr, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                        style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryOrange),
                      )
                    ],
                  ),
                ),
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: service.products.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final p = service.products[index];
                final processing = service.processingPurchaseIds.contains(p.id);
                final owned = service.hasActivePurchase(p.id);
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.backgroundWhite,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(p.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 4),
                      Text(p.description, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Text(p.price, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppTheme.primaryOrange)),
                          const Spacer(),
                          if (owned)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.green.shade50,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text('iap_owned'.tr, style: const TextStyle(color: Colors.green, fontWeight: FontWeight.w600)),
                            )
                          else
                            ElevatedButton(
                              onPressed: processing ? null : () => service.buy(p),
                              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryOrange),
                              child: processing
                                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                  : Text('iap_buy'.tr),
                            )
                        ],
                      )
                    ],
                  ),
                );
              },
            );
          }),
        );
      },
    );
  }
}
