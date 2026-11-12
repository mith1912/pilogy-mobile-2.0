import 'ad_configuration.dart';

/// Session-only, non-sensitive policy. Tokens are ephemeral navigation visits.
class AdFrequencyPolicy {
  AdFrequencyPolicy(this.config, {DateTime Function()? now})
    : now = now ?? DateTime.now {
    launchedAt = this.now();
  }
  final AdConfiguration config;
  final DateTime Function() now;
  late final DateTime launchedAt;
  DateTime? lastShown, lastEnded, lastAppOpen;
  bool presenting = false, foreground = true;
  int actions = 0, fullscreenShown = 0;
  final Set<int> _visits = {};
  bool completeInterpretation(int visit) {
    if (!_visits.add(visit)) return false;
    if (_visits.length > 100) _visits.remove(_visits.first);
    final threshold = config.actionThreshold.clamp(1, 100);
    actions = (actions + 1).clamp(0, threshold).toInt();
    return true;
  }

  Duration get cooldown =>
      config.fullscreenCooldown < const Duration(seconds: 120)
          ? const Duration(seconds: 120)
          : config.fullscreenCooldown;
  bool get fullscreenLimitReached =>
      fullscreenShown >= config.fullscreenSessionCap.clamp(0, 100);
  bool get canPresent =>
      foreground &&
      !fullscreenLimitReached &&
      !presenting &&
      now().difference(launchedAt) >= cooldown &&
      (lastShown == null || now().difference(lastShown!) >= cooldown) &&
      (lastEnded == null || now().difference(lastEnded!) >= cooldown);
  bool get interstitialDue =>
      actions >= config.actionThreshold.clamp(1, 100) && canPresent;
  bool appOpenDue(Duration background) =>
      background >= config.backgroundMinimum &&
      canPresent &&
      (lastAppOpen == null ||
          now().difference(lastAppOpen!) >= config.appOpenCooldown);
  bool acquire() {
    if (!canPresent) return false;
    presenting = true;
    return true;
  }

  void shown(AdFormat format) {
    fullscreenShown++;
    lastShown = now();
    if (format == AdFormat.interstitial) actions = 0;
    if (format == AdFormat.appOpen) lastAppOpen = now();
  }

  void ended() {
    presenting = false;
    lastEnded = now();
  }
}
