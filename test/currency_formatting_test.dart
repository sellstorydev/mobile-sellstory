import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Currency Formatting Tests', () {
    String formatCurrency(double amount) {
      // Format with commas and 2 decimal places
      String formatted = amount.toStringAsFixed(2);
      
      // Split into integer and decimal parts
      List<String> parts = formatted.split('.');
      String integerPart = parts[0];
      String decimalPart = parts[1];
      
      // Add commas to integer part
      String withCommas = '';
      for (int i = 0; i < integerPart.length; i++) {
        if (i > 0 && (integerPart.length - i) % 3 == 0) {
          withCommas += ',';
        }
        withCommas += integerPart[i];
      }
      
      // Return single line format since total is now below title
      String result = '฿$withCommas.$decimalPart';
      
      return result;
      
      return result;
    }

    test('should format small amounts correctly', () {
      expect(formatCurrency(100.50), '฿100.50');
      expect(formatCurrency(1234.75), '฿1,234.75');
    });

    test('should format large amounts with commas', () {
      expect(formatCurrency(12345.67), '฿12,345.67');
      expect(formatCurrency(99999.89), '฿99,999.89');
    });

    test('should format large amounts with commas (single line)', () {
      expect(formatCurrency(12345.67), '฿12,345.67');
      expect(formatCurrency(99999.89), '฿99,999.89');
      expect(formatCurrency(123456.89), '฿123,456.89');
      expect(formatCurrency(987654.32), '฿987,654.32');
    });

    test('should handle millions with single line format', () {
      expect(formatCurrency(1234567.89), '฿1,234,567.89');
      expect(formatCurrency(1000000.00), '฿1,000,000.00');
    });
  });
}
