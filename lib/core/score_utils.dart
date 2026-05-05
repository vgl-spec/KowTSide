const double kFivePointScoreMax = 5.0;
const double kLegacyTenPointScoreMax = 10.0;
const double kFivePointPassThreshold = 3.5;
const double kFivePointSupportThreshold = 2.5;
const double kFivePointOnTrackThreshold = 3.5;
const double kFivePointExcellingThreshold = 4.5;

double normalizeScoreValue(
  double value, {
  double? sourceMax,
  double targetMax = kFivePointScoreMax,
}) {
  if (value <= 0) {
    return 0.0;
  }

  final resolvedSourceMax = sourceMax ?? _guessScoreMax(value);
  if (resolvedSourceMax <= 0) {
    return value.clamp(0.0, targetMax);
  }

  final normalized = (value / resolvedSourceMax) * targetMax;
  return normalized.clamp(0.0, targetMax);
}

double normalizeAverageScore(double value) {
  return normalizeScoreValue(value);
}

int normalizeScoreTotalItems(int totalItems) {
  if (totalItems <= 0) {
    return kFivePointScoreMax.toInt();
  }
  if (totalItems == kLegacyTenPointScoreMax.toInt()) {
    return kFivePointScoreMax.toInt();
  }
  return totalItems;
}

double averageScoreFromValues(Iterable<double> values) {
  final list = values.toList(growable: false);
  if (list.isEmpty) {
    return 0.0;
  }
  return list.reduce((a, b) => a + b) / list.length;
}

bool isPassingFivePointScore(double score) {
  return score >= kFivePointPassThreshold;
}

String proficiencyForAverage(double avgScore) {
  if (avgScore >= kFivePointExcellingThreshold) {
    return 'Excelling';
  }
  if (avgScore >= kFivePointOnTrackThreshold) {
    return 'On track';
  }
  if (avgScore >= kFivePointSupportThreshold) {
    return 'Needs support';
  }
  return 'Needs significant support';
}

String resolveProficiencyLabel(String? rawLabel, double avgScore) {
  final normalized = rawLabel?.trim().toLowerCase() ?? '';
  if (normalized.isEmpty) {
    return proficiencyForAverage(avgScore);
  }

  if (normalized == 'excelling' ||
      normalized == 'on track' ||
      normalized == 'needs support' ||
      normalized == 'needs significant support') {
    return proficiencyForAverage(avgScore);
  }

  if (normalized.contains('needs') && normalized.contains('support')) {
    return proficiencyForAverage(avgScore);
  }

  return proficiencyForAverage(avgScore);
}

double _guessScoreMax(double value) {
  if (value > kFivePointScoreMax) {
    return kLegacyTenPointScoreMax;
  }
  return kFivePointScoreMax;
}
