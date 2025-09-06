import '../../../domain/entities/job_card.dart';

class LaneTotalCalculator {
  static double _r2(num v) => (v * 100).round() / 100.0;

  static LaneTotals calculateTotals(List<JobCard> cards) {
    double totalBeforeDiscount = 0;
    double totalAfterDiscount = 0;
    double grandTotal = 0;
    double netTotal = 0;

    for (final card in cards) {
      final cardTotals = _calculateCardTotals(card);
      totalBeforeDiscount += cardTotals.totalBeforeDiscount;
      totalAfterDiscount += cardTotals.totalAfterDiscount;
      grandTotal += cardTotals.grandTotal;
      netTotal += cardTotals.netTotal;
    }

    return LaneTotals(
      totalBeforeDiscount: _r2(totalBeforeDiscount),
      totalAfterDiscount: _r2(totalAfterDiscount),
      grandTotal: _r2(grandTotal),
      netTotal: _r2(netTotal),
    );
  }

  static CardTotals _calculateCardTotals(JobCard card) {
    double totalBeforeDiscount = 0;

    // Calculate from expenses if available, otherwise use card amount
    if (card.expenses.isNotEmpty) {
      for (final expense in card.expenses) {
        final quantity = (expense['quantity'] ?? 0).toDouble();
        final pricePerUnit = (expense['pricePerUnit'] ?? 0).toDouble();
        final base = quantity * pricePerUnit;
        totalBeforeDiscount += base;
      }
    } else {
      // Fallback to card amount if no expenses
      totalBeforeDiscount = card.amount;
    }

    // Apply additional discount
    double totalAfterDiscount = totalBeforeDiscount; // Use totalBeforeDiscount as base
    if (card.additionalDiscount != null && (card.additionalDiscount!['value'] ?? 0) != 0) {
      final value = (card.additionalDiscount!['value'] ?? 0).toDouble();
      final type = (card.additionalDiscount!['type'] ?? 'amount') as String;
      if (type == 'percentage') {
        totalAfterDiscount = totalBeforeDiscount * (1 - (value / 100.0));
      } else {
        totalAfterDiscount = totalBeforeDiscount - value;
      }
    }
    totalAfterDiscount = _r2(totalAfterDiscount.clamp(0, double.infinity));

    // Calculate VAT
    final vatAmount = card.isVatEnabled ? _r2(totalAfterDiscount * 0.07) : 0.0;
    final grandTotal = _r2(totalAfterDiscount + vatAmount);

    // Calculate withholding tax
    final wht = _r2(totalAfterDiscount * (card.withholdingTaxPercentage / 100.0));
    final netTotal = _r2(grandTotal - wht);

    return CardTotals(
      totalBeforeDiscount: _r2(totalBeforeDiscount),
      totalAfterDiscount: totalAfterDiscount,
      grandTotal: grandTotal,
      netTotal: netTotal,
    );
  }
}

class LaneTotals {
  final double totalBeforeDiscount;
  final double totalAfterDiscount;
  final double grandTotal;
  final double netTotal;

  LaneTotals({
    required this.totalBeforeDiscount,
    required this.totalAfterDiscount,
    required this.grandTotal,
    required this.netTotal,
  });
}

class CardTotals {
  final double totalBeforeDiscount;
  final double totalAfterDiscount;
  final double grandTotal;
  final double netTotal;

  CardTotals({
    required this.totalBeforeDiscount,
    required this.totalAfterDiscount,
    required this.grandTotal,
    required this.netTotal,
  });
}
