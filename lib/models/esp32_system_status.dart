class Esp32SystemStatus {
  const Esp32SystemStatus({
    required this.reportedOnline,
    required this.lastSeen,
    required this.observedAt,
  });

  static const Duration heartbeatTimeout = Duration(seconds: 25);

  final bool? reportedOnline;
  final DateTime? lastSeen;
  final DateTime observedAt;

  Duration? get age {
    final heartbeat = lastSeen;
    if (heartbeat == null) return null;

    final difference = observedAt.difference(heartbeat);
    return difference.isNegative ? Duration.zero : difference;
  }

  bool? get isOnline {
    if (reportedOnline == false) return false;
    final heartbeatAge = age;
    if (heartbeatAge == null) return reportedOnline;
    return heartbeatAge <= heartbeatTimeout;
  }

  Esp32SystemStatus observedAtTime(DateTime value) {
    return Esp32SystemStatus(
      reportedOnline: reportedOnline,
      lastSeen: lastSeen,
      observedAt: value,
    );
  }
}
