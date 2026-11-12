import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'ad_providers.dart';
import 'ad_diagnostics.dart';
import 'banner_ad_controller.dart';

/// Shared fixed footer; never overlays content, navigation or the keyboard.
class StickyAdBanner extends ConsumerStatefulWidget {
  const StickyAdBanner({super.key});
  @override
  ConsumerState<StickyAdBanner> createState() => _StickyAdBannerState();
}

class _StickyAdBannerState extends ConsumerState<StickyAdBanner> {
  late final BannerAdController _controller;
  @override
  void initState() {
    super.initState();
    AdDiagnostics.stage('banner_footer_mounted');
    _controller = BannerAdController(ref.read(adMobServiceProvider));
    _controller.addListener(_changed);
  }

  void _changed() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final visible = ModalRoute.of(context)?.isCurrent != false &&
          MediaQuery.viewInsetsOf(context).bottom == 0;
      final width = constraints.maxWidth.floor();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _controller.setVisible(visible);
        if (visible) _controller.load(width);
      });
      final ad = visible ? _controller.ad : null;
      return AnimatedSize(
        duration: const Duration(milliseconds: 200),
        alignment: Alignment.topCenter,
        child:
            ad == null
                ? const SizedBox.shrink()
                : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 8),
                    const Divider(height: 1),
                    Text(
                      'Quảng Cáo',
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: ad.width.toDouble(),
                      height: ad.height.toDouble(),
                      child: ad.view(),
                    ),
                  ],
                ),
      );
    },
  );
  @override
  void dispose() {
    _controller.removeListener(_changed);
    _controller.dispose();
    super.dispose();
  }
}
