import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/numerology/presentation/backend_providers.dart';
import 'ad_mob_service.dart';
import 'ad_providers.dart';

/// Mounted only after local startup. Ad work is never awaited by core startup.
class AdRuntime extends ConsumerStatefulWidget {
  const AdRuntime({
    super.key,
    required this.returningUser,
    required this.child,
  });
  final bool returningUser;
  final Widget child;
  @override
  ConsumerState<AdRuntime> createState() => _AdRuntimeState();
}

class _AdRuntimeState extends ConsumerState<AdRuntime>
    with WidgetsBindingObserver {
  late final AdMobService _service;
  @override
  void initState() {
    super.initState();
    _service = ref.read(adMobServiceProvider);
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(_service.start(returning: widget.returningUser));
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        _service.resumed();
      case AppLifecycleState.paused:
        _service.paused();
      case AppLifecycleState.inactive:
        _service.inactive();
      case AppLifecycleState.detached:
        _service.inactive();
      case AppLifecycleState.hidden:
        _service.inactive();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.returningUser) {
      final calculation = ref.watch(selectedProfileCalculationProvider);
      final busy =
          calculation.isLoading ||
          calculation.hasError ||
          calculation.valueOrNull?.refreshing == true ||
          calculation.valueOrNull?.data == null;
      if (_service.calculationBusy != busy)
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted)
            _service.context(
              screen: _service.screen,
              calculationBusy: busy,
              dialogOpen: _service.dialogOpen,
            );
        });
    }
    return widget.child;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}
