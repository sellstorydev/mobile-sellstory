import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../domain/entities/job_card.dart';
import '../../../../app/routes.dart';

// NOTE: This widget now relies on an injected (via constructor) fieldConfig map coming
// from Firestore per-board (users/{uid}.viewSettings.kanbanCardDisplayFieldsConfig_{boardId})
// It no longer uses CardViewSettingsService for ordering/visibility.

// ===== Helpers for money/date & totals (spec-compliant) =====
final _currencyFmt = NumberFormat.currency(locale: 'th_TH', symbol: '฿');
String _fmtDate(int? ms) {
  if (ms == null) return '-';
  final d = DateTime.fromMillisecondsSinceEpoch(ms);
  return DateFormat('dd/MM/yyyy').format(d);
}
String _fmtDateRange(int? startMs, int? endMs) {
  if (startMs == null || endMs == null) return '-';
  final start = DateTime.fromMillisecondsSinceEpoch(startMs);
  final end = DateTime.fromMillisecondsSinceEpoch(endMs);
  
  // Format: "Sep 4 - Sep 6"
  final startStr = DateFormat('MMM d').format(start);
  final endStr = DateFormat('MMM d').format(end);
  
  return '$startStr - $endStr';
}

class _MoneyTotals {
  final double totalBeforeDiscount;
  final double totalAfterDiscount;
  final double totalBeforeVat;
  final double vatAmount;
  final double grandTotal;
  final double netTotal;
  const _MoneyTotals({
    required this.totalBeforeDiscount,
    required this.totalAfterDiscount,
    required this.totalBeforeVat,
    required this.vatAmount,
    required this.grandTotal,
    required this.netTotal,
  });
}

double _r2(num v) => (v * 100).round() / 100.0;
_MoneyTotals _computeTotals({
  required List<Map<String, dynamic>> expenses,
  required bool isVatEnabled,
  required Map<String, dynamic>? additionalDiscount,
  required num withholdingTaxPercentage,
  bool usePerItemDiscountsInTotals = false, // keep false matching provided image
}) {
  double totalBeforeDiscount = 0;
  double afterItemDiscount = 0;
  for (final e in expenses) {
    final q = (e['quantity'] ?? 0).toDouble();
    final p = (e['pricePerUnit'] ?? 0).toDouble();
    final base = q * p;
    totalBeforeDiscount += base;
    // Per-item discount (optional future toggle)
    final disc = (e['discount'] ?? 0).toDouble();
    final discType = (e['discountType'] ?? 'amount') as String;
    double line = base;
    if (disc > 0) {
      if (discType == 'percentage') {
        line -= base * (disc / 100.0);
      } else {
        line -= disc;
      }
    }
    afterItemDiscount += line.clamp(0, double.infinity);
  }
  double baseForAdditional = usePerItemDiscountsInTotals ? afterItemDiscount : totalBeforeDiscount;
  double totalAfterDiscount = baseForAdditional;
  if (additionalDiscount != null && (additionalDiscount['value'] ?? 0) != 0) {
    final v = (additionalDiscount['value'] ?? 0).toDouble();
    final t = (additionalDiscount['type'] ?? 'amount') as String?;
    if (t == 'percentage') {
      totalAfterDiscount = baseForAdditional * (1 - (v / 100.0));
    } else {
      totalAfterDiscount = baseForAdditional - v;
    }
  }
  totalAfterDiscount = _r2(totalAfterDiscount.clamp(0, double.infinity));
  final totalBeforeVat = totalAfterDiscount; // as per spec
  final vatAmount = isVatEnabled ? _r2(totalBeforeVat * 0.07) : 0.0;
  final grandTotal = _r2(totalBeforeVat + vatAmount);
  final wht = _r2(totalBeforeVat * ((withholdingTaxPercentage) / 100.0));
  final netTotal = _r2(grandTotal - wht);
  return _MoneyTotals(
    totalBeforeDiscount: _r2(totalBeforeDiscount),
    totalAfterDiscount: totalAfterDiscount,
    totalBeforeVat: totalBeforeVat,
    vatAmount: vatAmount,
    grandTotal: grandTotal,
    netTotal: netTotal,
  );
}

class JobCardTile extends StatelessWidget {
  final JobCard card;
  final Map<String, dynamic> fieldConfig; // per-board config map
  final Map<String, String> userNameCache; // uid -> displayName
  final VoidCallback? onTap;
  final Map<String, dynamic>? rawCardData; // Add raw data from Firestore

  const JobCardTile({
    super.key,
    required this.card,
    required this.fieldConfig,
    required this.userNameCache,
    this.onTap,
    this.rawCardData,
  });

  @override
  Widget build(BuildContext context) {
    // Compute totals once - use proper data structure based on the example provided
    final cardData = rawCardData ?? card.toMap();
    
    // Based on the example data structure:
    // isVatEnabled: true, additionalDiscount: {value: 97, type: "percentage"}, withholdingTaxPercentage: 3
    final isVatEnabled = cardData['isVatEnabled'] == true;
    final additionalDiscount = cardData['additionalDiscount'] as Map<String, dynamic>?;
    final withholdingTaxPercentage = (cardData['withholdingTaxPercentage'] ?? 0) as num;
    
    print('💰 Financial calculation inputs:');
    print('  - isVatEnabled: $isVatEnabled');
    print('  - additionalDiscount: $additionalDiscount');
    print('  - withholdingTaxPercentage: $withholdingTaxPercentage');
    print('  - expenses count: ${card.expenses.length}');
    
    final totals = _computeTotals(
      expenses: card.expenses,
      isVatEnabled: isVatEnabled,
      additionalDiscount: additionalDiscount,
      withholdingTaxPercentage: withholdingTaxPercentage,
    );

    return GestureDetector(
      onTap: onTap ?? () {
        // Navigate to edit card page directly
        Get.toNamed(AppRoutes.editCard, arguments: card);
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.grey.withValues(alpha: 0.2),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with title only
              Text(
                card.title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: AppTheme.textPrimary,
                ),
              ),
              
              const SizedBox(height: 12),
              
              _buildDynamicFields(totals),
            ],
          ),
        ),
      ),
    );
  }


  Widget _buildDynamicFields(_MoneyTotals totals) {
    // Build list of keys from config
    final entries = <_FieldEntry>[];
    print('🔧 Field config: $fieldConfig');
    fieldConfig.forEach((key, cfg) {
      if (cfg is Map<String, dynamic>) {
        final isVisible = cfg['isVisible'] ?? true;
        print('  - Field $key: visible=$isVisible, order=${cfg['order']}');
        if (isVisible == true) {
          entries.add(_FieldEntry(key, cfg['order'] ?? 999));
        }
      }
    });
    entries.sort((a, b) => a.order.compareTo(b.order));
    print('🔧 Final field order: ${entries.map((e) => e.key).toList()}');

    // Build widgets for each supported key
    final children = <Widget>[];
    for (final e in entries) {
      switch (e.key) {
        case 'customId':
          children.add(_kv('Job ID', card.customId.isNotEmpty ? card.customId : card.id));
          break;
        case 'status':
          children.add(_kv('Status', card.status));
          break;
        case 'dateRange':
          children.add(_kv('Date Range', _fmtDateRange(card.startDate?.millisecondsSinceEpoch, card.endDate?.millisecondsSinceEpoch)));
          break;
        case 'createdAt':
          children.add(_kv('Created Date', _fmtDate(card.createdAt.millisecondsSinceEpoch)));
          break;
        case 'assignee':
          children.add(_kv('Assignee', userNameCache[card.assignedTo] ?? card.assignedTo));
          break;
        case 'customerInterest':
          if (card.customerInterest?.isNotEmpty == true) {
            children.add(_kv('Customer Interest', card.customerInterest!));
          }
          break;
        case 'collaborators':
          if (card.collaborators.isNotEmpty) {
            final names = card.collaborators.map((id) => userNameCache[id] ?? id).join(', ');
            children.add(_kv('Collaborators', names));
          }
          break;
        case 'customer':
          if (card.customer.isNotEmpty) {
            children.add(_kv('Customer', card.customer));
          }
          break;
        case 'company':
          if (card.company != null) {
            final value = card.company?['value'] ?? '';
            if (value.toString().isNotEmpty) {
              children.add(_kv('Company', value.toString()));
            }
          }
          break;
        case 'hashtags':
          print('🏷️ Hashtags check: ${card.hashtags.length} hashtags found: ${card.hashtags}');
          if (card.hashtags.isNotEmpty) {
            children.add(_buildHashtags(card.hashtags));
          }
          break;
        case 'grandTotal':
          children.add(_kv('Grand Total', _currencyFmt.format(totals.grandTotal)));
          break;
        case 'netTotal':
          children.add(_kv('Net Total', _currencyFmt.format(totals.netTotal)));
          break;
        case 'totalAmountBeforeDiscount':
          children.add(_kv('Total (before discount)', _currencyFmt.format(totals.totalBeforeDiscount)));
          break;
        case 'totalAmountAfterDiscount':
          children.add(_kv('Total (after discount)', _currencyFmt.format(totals.totalAfterDiscount)));
          break;
        case 'totalAmountBeforeVat':
          children.add(_kv('Total (before VAT)', _currencyFmt.format(totals.totalBeforeVat)));
          break;
        case 'description':
          if (card.description.isNotEmpty) {
            // Simple strip tags fallback (avoid new deps)
            final plain = card.description.replaceAll(RegExp(r'<[^>]+>'), '').trim();
            children.add(_kv('Description', plain.isEmpty ? '(HTML content)' : plain));
          }
          break;
        case 'todos':
          final total = card.todos.length;
          final completed = card.todos.where((t) => (t['completed'] ?? false) == true).length;
          children.add(_kv('To-Do', '$completed/$total'));
          break;
        default:
          // Ignore unknown keys to remain forward compatible
          break;
      }
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    );
  }


  Widget _buildHashtags(List<dynamic> tags) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: tags.map<Widget>((t) {
        final text = t['text'] ?? t['id'] ?? '';
        final color = t['color'] ?? '#eeeeee';
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: _hexToColor(color).withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: _hexToColor(color)),
          ),
          child: Text('$text', style: const TextStyle(fontSize: 12)),
        );
      }).toList(),
    );
  }

  Color _hexToColor(String hex) {
    final buffer = StringBuffer();
    var cleaned = hex.replaceFirst('#', '');
    if (cleaned.length == 6) buffer.write('ff');
    buffer.write(cleaned);
    return Color(int.parse(buffer.toString(), radix: 16));
  }

  Widget _kv(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textSecondary)),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Text(value, style: const TextStyle(fontSize: 12, color: AppTheme.textPrimary)),
          ),
        ],
      ),
    );
  }
}

class _FieldEntry {
  final String key;
  final int order;
  _FieldEntry(this.key, this.order);
}
