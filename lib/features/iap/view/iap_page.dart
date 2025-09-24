import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/services/in_app_purchase_service.dart';

class IapPage extends StatefulWidget {
  const IapPage({super.key});
  @override
  State<IapPage> createState() => _IapPageState();
}

class _IapPageState extends State<IapPage> {
  late final InAppPurchaseService service;

  @override
  void initState() {
    super.initState();
    // Register (or find) the service. Keep permanent for app lifetime.
    service = Get.put(InAppPurchaseService(), permanent: true);
    if (Platform.isIOS) {
      service.init();
    } else {
      service.isLoading.value = false; // fast fail for non‑iOS UI
    }
  }

  @override
  Widget build(BuildContext context) {
   
    return Scaffold(
      backgroundColor: AppTheme.backgroundGrey,
      appBar: AppBar(
        title: Text('iap_title'.tr),
        backgroundColor: AppTheme.backgroundWhite,
        foregroundColor: AppTheme.textPrimary,
        elevation: 0,
        
      ),
      body: Obx(() {
        if (service.isLoading.value) {
          return const Center(
            child: CircularProgressIndicator(color: AppTheme.primaryOrange),
          );
        }
        if (!service.isAvailable.value) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                service.errorMessage.isNotEmpty
                    ? service.errorMessage.value
                    : 'iap_not_available'.tr,
                textAlign: TextAlign.center,
              ),
            ),
          );
        }
        if (service.forceMock.value) {
          return _ForceMockBody(service: service);
        }
        if (service.products.isEmpty) {
          if (service.isSimulator) {
            return _SimulatorMockBody(service: service);
          }
          return _EmptyState(service: service);
        }
        return _ProductsList(service: service);
      }),
    );
  }
}

/// List of real store products
class _ProductsList extends StatelessWidget {
  final InAppPurchaseService service;
  const _ProductsList({required this.service});
  @override
  Widget build(BuildContext context) {
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
              Text(
                p.title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                p.description,
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text(
                    p.price,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primaryOrange,
                    ),
                  ),
                  const Spacer(),
                  if (owned)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'iap_owned'.tr,
                        style: const TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    )
                  else
                    ElevatedButton(
                      onPressed: processing ? null : () => service.buy(p),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryOrange,
                      ),
                      child: processing
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text('iap_buy'.tr),
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Simulator fallback body (since real store often returns empty on simulator)
class _SimulatorMockBody extends StatelessWidget {
  final InAppPurchaseService service;
  const _SimulatorMockBody({required this.service});
  @override
  Widget build(BuildContext context) {
    const mockId = '365day';
    final owned = service.hasActivePurchase(mockId);
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text(
          'iap_simulator_mode'.tr,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Text(
          'iap_simulator_notice'.tr,
          style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
        ),
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
              Text(
                'iap_simulator_mock_product'.trParams({'id': mockId}),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'iap_no_products'.tr,
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Text(
                    '—',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primaryOrange,
                    ),
                  ),
                  const Spacer(),
                  owned
                      ? Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'iap_owned'.tr,
                            style: const TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        )
                      : ElevatedButton(
                          onPressed: () => service.simulatePurchase(mockId),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryOrange,
                          ),
                          child: Text('iap_buy'.tr),
                        ),
                ],
              ),
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
          label: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text('iap_refresh'.tr),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryOrange,
          ),
        ),
      ],
    );
  }
}

class _ForceMockBody extends StatelessWidget {
  final InAppPurchaseService service;
  const _ForceMockBody({required this.service});
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'iap_force_mock_title'.tr,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text('iap_force_mock_desc'.tr, textAlign: TextAlign.center),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: service.toggleForceMock,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryOrange,
              ),
              child: Text('iap_exit_force_mock'.tr),
            ),
          ],
        ),
      ),
    );
  }
}

/// Empty state when store returns zero products but we are on device (not simulator)
class _EmptyState extends StatelessWidget {
  final InAppPurchaseService service;
  const _EmptyState({required this.service});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'iap_no_products'.tr,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'iap_products_empty_hint'.tr,
            style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 24),
          _DebugPanel(service: service),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              try {
                service.refreshProducts();
              } catch (_) {
                service.reloadProducts();
              }
            },
            label: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text('iap_refresh'.tr),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryOrange,
            ),
          ),
        ],
      ),
    );
  }
}

class _DebugPanel extends StatelessWidget {
  final InAppPurchaseService service;
  const _DebugPanel({required this.service});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.backgroundWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: DefaultTextStyle(
        style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'iap_debug_title'.tr,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
            const SizedBox(height: 8),
            Text('IDs: ${service.productIds.join(', ')}'),
            if (service.notFoundIds.isNotEmpty)
              Text('NotFound: ${service.notFoundIds.join(', ')}'),
            if (service.errorMessage.isNotEmpty)
              Text('Error: ${service.errorMessage.value}'),
            Text('Simulator: ${service.isSimulator}'),
            Text('ForceMock: ${service.forceMock.value}'),
          ],
        ),
      ),
    );
  }
}
