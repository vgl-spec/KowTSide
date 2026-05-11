const double kFivePointScoreMax = 5.0;
const double kLegacyTenPointScoreMax = 10.0;
const double kPassingRatio = 0.5;
const double kNeedsSupportRatio = 0.5;
const double kOnTrackRatio = 0.7;
const double kExcellingRatio = 0.9;
const double kFivePointPassThreshold = kFivePointScoreMax * kPassingRatio;
const double kFivePointSupportThreshold =
    kFivePointScoreMax * kNeedsSupportRatio;
const double kFivePointOnTrackThreshold = kFivePointScoreMax * kOnTrackRatio;
const double kFivePointExcellingThreshold =
    kFivePointScoreMax * kExcellingRatio;

int questionCountForDifficulty(String difficulty, {String? subject}) {
  final normalizedSubject = subject?.trim().toLowerCase() ?? '';
  if (normalizedSubject == 'writing' || normalizedSubject == 'handwriting') {
    return 1;
  }

  switch (difficulty.trim().toLowerCase()) {
    case 'easy':
      return 5;
    case 'average':
      return 8;
    case 'hard':
      return 10;
    default:
      return 0;
  }
}

int passingScoreForTotalItems(int totalItems) {
  if (totalItems <= 0) return 0;
  return ((totalItems * kPassingRatio).ceil()).clamp(1, totalItems);
}

bool didPassByTotalItems({required double score, required int totalItems}) {
  if (totalItems <= 0) {
    return score > 0;
  }
  return score >= passingScoreForTotalItems(totalItems);
}

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

double normalizeAverageScore(
  double value, {
  double? sourceMax,
  int? totalItems,
  String? difficulty,
  String? subject,
}) {
  final inferredSourceMax =
      sourceMax ??
      (totalItems != null && totalItems > 0 ? totalItems.toDouble() : null) ??
      () {
        final byDifficulty = questionCountForDifficulty(
          difficulty ?? '',
          subject: subject,
        );
        if (byDifficulty > 0) {
          return byDifficulty.toDouble();
        }
        return null;
      }();
  return normalizeScoreValue(value, sourceMax: inferredSourceMax);
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

double normalizedScoreToPercent(double normalizedScore) {
  if (kFivePointScoreMax <= 0) return 0;
  return ((normalizedScore / kFivePointScoreMax) * 100).clamp(0.0, 100.0);
}

bool isPassingFivePointScore(double score) {
  return score >= kFivePointPassThreshold;
}

String proficiencyForAverage(double avgScore) {
  final ratio = (avgScore / kFivePointScoreMax).clamp(0.0, 1.0);
  if (ratio >= kExcellingRatio) {
    return 'Excelling';
  }
  if (ratio >= kOnTrackRatio) {
    return 'On track';
  }
  if (ratio >= kNeedsSupportRatio) {
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
