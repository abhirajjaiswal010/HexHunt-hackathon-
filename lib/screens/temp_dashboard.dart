// Temporary file to help fix duplicate method in dashboard_screen.dart

// Temporary copy of the _getRiskLabel method
String _getRiskLabel(int score) {
  if (score < 30) return 'Low';
  if (score < 60) return 'Medium';
  if (score < 80) return 'High';
  return 'Critical';
}

// Temporary copy of the _calculateRiskScore method
int _calculateRiskScore(int threats) {
  if (threats == 0) return 0;
  if (threats < 3) return 30 + threats * 10;
  if (threats < 6) return 50 + (threats - 3) * 7;
  if (threats < 10) return 70 + (threats - 6) * 5;
  return 90 + math.min(9, threats - 10);
} 