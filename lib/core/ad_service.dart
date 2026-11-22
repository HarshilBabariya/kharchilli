import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// Manages Google AdMob initialization, banner unit IDs, and rewarded video preloading.
/// Uses Google's official test ad unit IDs in debug mode or when production IDs are not supplied via --dart-define.
class AdService {
  AdService._();
  static final AdService instance = AdService._();

  static const _envBannerId = String.fromEnvironment('ADMOB_BANNER_ID');
  static const _envRewardedId = String.fromEnvironment('ADMOB_REWARDED_ID');

  bool _initialized = false;
  bool _isLoadingRewarded = false;
  RewardedAd? _rewardedAd;

  bool get isSupported => !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  String get bannerUnitId {
    if (!kDebugMode && _envBannerId.isNotEmpty) return _envBannerId;
    return Platform.isIOS
        ? 'ca-app-pub-3940256099942544/2435281174'
        : 'ca-app-pub-3940256099942544/9214589741';
  }

  String get rewardedUnitId {
    if (!kDebugMode && _envRewardedId.isNotEmpty) return _envRewardedId;
    return Platform.isIOS
        ? 'ca-app-pub-3940256099942544/1712485313'
        : 'ca-app-pub-3940256099942544/5224354917';
  }

  bool get isRewardedReady => _rewardedAd != null;

  Future<void> init() async {
    if (!isSupported || _initialized) return;
    try {
      await MobileAds.instance.initialize();
      _initialized = true;
      preloadRewardedAd();
    } catch (e) {
      debugPrint('AdService.init failed: $e');
    }
  }

  void preloadRewardedAd() {
    if (!isSupported || !_initialized || _isLoadingRewarded || _rewardedAd != null) return;
    _isLoadingRewarded = true;
    RewardedAd.load(
      adUnitId: rewardedUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
          _isLoadingRewarded = false;
        },
        onAdFailedToLoad: (err) {
          debugPrint('RewardedAd failed to load: ${err.message}');
          _rewardedAd = null;
          _isLoadingRewarded = false;
        },
      ),
    );
  }

  void showRewardedAd({
    required VoidCallback onRewardEarned,
    required VoidCallback onUnavailable,
  }) {
    if (!isSupported) {
      onUnavailable();
      return;
    }
    final ad = _rewardedAd;
    if (ad == null) {
      preloadRewardedAd();
      onUnavailable();
      return;
    }
    _rewardedAd = null;
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        preloadRewardedAd();
      },
      onAdFailedToShowFullScreenContent: (ad, err) {
        debugPrint('RewardedAd failed to show: ${err.message}');
        ad.dispose();
        preloadRewardedAd();
      },
    );
    ad.show(
      onUserEarnedReward: (_, __) => onRewardEarned(),
    );
  }
}
