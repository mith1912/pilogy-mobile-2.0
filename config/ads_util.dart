import 'dart:io';

class AdsUtil {
  static const String _androidAppId = "ca-app-pub-1578425271408021~1229517112";
  static const String _androidBannerId =
      "ca-app-pub-1578425271408021/6573343131";
  static const String _androidInterstitialId =
      "ca-app-pub-1578425271408021/2634098121";
  static const String _androidAdOpen = "ca-app-pub-1578425271408021/4389220110";

  static const String _androidCustomAdId =
      "ca-app-pub-1578425271408021/1894918711";

  static const String _iosAppId = "ca-app-pub-1578425271408021~3755608109";
  static const String _iosBannerId = "ca-app-pub-1578425271408021/5987019770";
  static const String _iosInterstitialId =
      "ca-app-pub-1578425271408021/9163847454";
  static const String _iosAdOpenId =
      "ca-app-pub-1578425271408021/9409859923";
  static const String _iosCustomAdId =
      "ca-app-pub-1578425271408021/1351993236";

  static String get adsAppId => Platform.isIOS ? _iosAppId : _androidAppId;

  static String get bannerAdsId =>
      Platform.isIOS ? _iosBannerId : _androidBannerId;

  static String get interstitialAdsId =>
      Platform.isIOS ? _iosInterstitialId : _androidInterstitialId;
}
