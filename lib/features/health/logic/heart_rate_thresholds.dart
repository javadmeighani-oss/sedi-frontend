class HeartRateThresholds {
  static const int low = 50;
  static const int high = 110;
}

enum HeartRateBand {
  low,
  normal,
  high,
}

HeartRateBand resolveHeartRateBand(int bpm) {
  if (bpm < HeartRateThresholds.low) return HeartRateBand.low;
  if (bpm > HeartRateThresholds.high) return HeartRateBand.high;
  return HeartRateBand.normal;
}
