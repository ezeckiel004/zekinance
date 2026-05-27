import 'package:intl/intl.dart';

extension DoubleExt on double {
  /// Formats the number as FCFA currency (e.g. 15000.0 -> "15 000 FCFA")
  String toFCFA() {
    final formatter = NumberFormat.currency(
      locale: 'fr_FR',
      symbol: 'FCFA',
      decimalDigits: 0,
      customPattern: '#,##0 \u00A4', // Space as thousands separator and symbol at the end
    );
    return formatter.format(this).replaceAll('\u00A0', ' ').trim();
  }

  /// Formats double with decimals if needed (e.g. 15.5 -> "15,5")
  String toFormattedString({int decimalDigits = 2}) {
    final formatter = NumberFormat.decimalPattern('fr_FR');
    formatter.maximumFractionDigits = decimalDigits;
    return formatter.format(this).replaceAll('\u00A0', ' ');
  }
}
