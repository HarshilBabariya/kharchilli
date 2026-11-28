import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../core/ad_service.dart';
import '../core/app_state.dart';
import 'theme.dart';
import 'widgets.dart';

/// Anchored adaptive banner (optional standalone bar).
/// Automatically hides while the user has an active Ad-Free or All-Access boost.
class AdBannerBar extends StatefulWidget {
  const AdBannerBar({super.key});

  @override
  State<AdBannerBar> createState() => _AdBannerBarState();
}

class _AdBannerBarState extends State<AdBannerBar> {
  BannerAd? _banner;
  bool _loaded = false;
  int _lastWidth = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadIfNeeded();
  }

  Future<void> _loadIfNeeded() async {
    if (!AdService.instance.isSupported) return;
    final width = MediaQuery.sizeOf(context).width.truncate();
    if (width <= 0 || width == _lastWidth) return;
    _lastWidth = width;
    final size = await AdSize.getCurrentOrientationAnchoredAdaptiveBannerAdSize(width);
    if (size == null || !mounted) return;

    _banner?.dispose();
    final ad = BannerAd(
      adUnitId: AdService.instance.bannerUnitId,
      size: size,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          if (mounted) setState(() => _loaded = true);
        },
        onAdFailedToLoad: (ad, _) {
          ad.dispose();
          if (mounted) setState(() => _loaded = false);
        },
      ),
    );
    _banner = ad;
    await ad.load();
  }

  @override
  void dispose() {
    _banner?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    if (app.isAdFree || !_loaded || _banner == null) return const SizedBox.shrink();
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: context.cs.surface,
        border: Border(top: BorderSide(color: context.cs.outlineVariant)),
      ),
      alignment: Alignment.center,
      height: _banner!.size.height.toDouble(),
      child: AdWidget(ad: _banner!),
    );
  }
}

/// Inline banner card placed between expense groups every 25 records.
class InlineAdBanner extends StatefulWidget {
  const InlineAdBanner({super.key});

  @override
  State<InlineAdBanner> createState() => _InlineAdBannerState();
}

class _InlineAdBannerState extends State<InlineAdBanner> with AutomaticKeepAliveClientMixin {
  BannerAd? _banner;
  bool _loaded = false;
  int _lastWidth = 0;

  @override
  bool get wantKeepAlive => true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadIfNeeded();
  }

  Future<void> _loadIfNeeded() async {
    if (!AdService.instance.isSupported) return;
    final width = (MediaQuery.sizeOf(context).width - 40).truncate();
    if (width <= 0 || width == _lastWidth) return;
    _lastWidth = width;
    final size = await AdSize.getCurrentOrientationAnchoredAdaptiveBannerAdSize(width);
    if (size == null || !mounted) return;

    _banner?.dispose();
    final ad = BannerAd(
      adUnitId: AdService.instance.bannerUnitId,
      size: size,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          if (mounted) setState(() => _loaded = true);
        },
        onAdFailedToLoad: (ad, _) {
          ad.dispose();
          if (mounted) setState(() => _loaded = false);
        },
      ),
    );
    _banner = ad;
    await ad.load();
  }

  @override
  void dispose() {
    _banner?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final app = AppScope.of(context);
    if (app.isAdFree || !_loaded || _banner == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: KCard(
        padding: const EdgeInsets.symmetric(vertical: 8),
        radius: 22,
        child: SizedBox(
          width: double.infinity,
          height: _banner!.size.height.toDouble(),
          child: Center(child: AdWidget(ad: _banner!)),
        ),
      ),
    );
  }
}
