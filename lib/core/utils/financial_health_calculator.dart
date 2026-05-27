import 'package:flutter/material.dart';

class FinancialHealthCalculator {
  /// Score sur 100 basé sur la situation financière
  static int calculate({
    required double revenuMensuel,
    required double depensesTotales,
    required double epargneMensuelle,
    required double dettesTotal,
    required int objectifsAtteints,
    required int objectifsTotal,
  }) {
    int score = 0;

    // Taux d'épargne (max 30 pts)
    final tauxEpargne = revenuMensuel > 0 ? epargneMensuelle / revenuMensuel : 0;
    score += (tauxEpargne * 150).clamp(0, 30).toInt();

    // Taux de dépenses (max 30 pts)
    final tauxDepenses = revenuMensuel > 0 ? depensesTotales / revenuMensuel : 1;
    if (tauxDepenses <= 0.50) {
      score += 30;
    } else if (tauxDepenses <= 0.70) {
      score += 20;
    } else if (tauxDepenses <= 0.90) {
      score += 10;
    }

    // Gestion des dettes (max 20 pts)
    final ratioEndettement = revenuMensuel > 0 ? dettesTotal / (revenuMensuel * 12) : 1;
    if (ratioEndettement == 0) {
      score += 20;
    } else if (ratioEndettement < 0.3) {
      score += 15;
    } else if (ratioEndettement < 0.6) {
      score += 8;
    }

    // Atteinte des objectifs (max 20 pts)
    if (objectifsTotal > 0) {
      score += ((objectifsAtteints / objectifsTotal) * 20).toInt();
    }

    return score.clamp(0, 100);
  }

  static String getLabel(int score) {
    if (score >= 80) return 'Excellent';
    if (score >= 60) return 'Bien';
    if (score >= 40) return 'Moyen';
    return 'Critique';
  }

  static Color getColor(int score) {
    if (score >= 80) return const Color(0xFF22C55E);
    if (score >= 60) return const Color(0xFF84CC16);
    if (score >= 40) return const Color(0xFFF59E0B);
    return const Color(0xFFEF4444);
  }
}
