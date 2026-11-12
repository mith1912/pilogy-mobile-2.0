import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'ad_configuration.dart';
import 'ad_providers.dart';
import 'inline_ad_controller.dart';

/// One disclosed small native template at a content section boundary.
/// SDK templates own attribution, assets, AdChoices and click handling.
class NativeContentAd extends ConsumerStatefulWidget {
  const NativeContentAd({super.key});
  @override
  ConsumerState<NativeContentAd> createState() => _NativeContentAdState();
}

class _NativeContentAdState extends ConsumerState<NativeContentAd> {
  late final InlineAdController _controller;

  @override
  void initState() {
    super.initState();
    _controller = InlineAdController(
      ref.read(adMobServiceProvider), format: AdFormat.nativeAdvanced,
    );
    _controller.addListener(_changed);
  }

  void _changed() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      // Small templates need at least 320dp; never clip a creative to fit.
      final width = constraints.maxWidth.clamp(0, 400).floor();
      final visible = width >= 320 &&
          ModalRoute.of(context)?.isCurrent != false &&
          MediaQuery.viewInsetsOf(context).bottom == 0;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _controller.setVisible(visible);
        if (visible) _controller.load(width);
      });
      final ad = visible ? _controller.ad : null;
      if (ad == null) return const SizedBox.shrink();
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Divider(height: 1),
            const SizedBox(height: 8),
            Text('Quảng Cáo', style: Theme.of(context).textTheme.labelSmall),
            const SizedBox(height: 8),
            SizedBox(
              width: ad.width.toDouble(),
              height: ad.height.toDouble(),
              child: ad.view(),
            ),
            const SizedBox(height: 8),
            const Divider(height: 1),
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
