import 'package:flutter_test/flutter_test.dart';
import 'package:finsmart/core/utils/financial_health_calculator.dart';

void main() {
  group('FinancialHealthCalculator', () {
    test('score excellent quand épargne > 20% et pas de dettes', () {
      final score = FinancialHealthCalculator.calculate(
        revenuMensuel: 300000,
        depensesTotales: 180000,
        epargneMensuelle: 70000,
        dettesTotal: 0,
        objectifsAtteints: 2,
        objectifsTotal: 3,
      );
      expect(score, greaterThanOrEqualTo(75));
    });

    test('score critique quand dépenses > revenu', () {
      final score = FinancialHealthCalculator.calculate(
        revenuMensuel: 200000,
        depensesTotales: 210000,
        epargneMensuelle: 0,
        dettesTotal: 500000,
        objectifsAtteints: 0,
        objectifsTotal: 2,
      );
      expect(score, lessThan(40));
    });
  });
}
