import 'package:flutter/widgets.dart';
import 'ad_mob_service.dart';

/// Counts only a completed, loaded interpretation visit returned by a real pop.
/// Modal dialogs/sheets block ads; route names contain no profile inputs.
class AdNavigationObserver extends NavigatorObserver {
  AdNavigationObserver(this.service);
  final AdMobService service;
  final List<Route<dynamic>> _routes = [];
  void _context() {
    final pages = _routes.where((route) => route is PageRoute).toList();
    service.context(
      screen: pages.isEmpty ? 'startup' : pages.last.settings.name ?? 'unknown',
      calculationBusy: service.calculationBusy,
      dialogOpen: _routes.any((route) => route is PopupRoute),
    );
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _routes.add(route);
    _context();
    if (route.settings.name == 'numberDetail') service.beginInterpretation();
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _routes.remove(route);
    _context();
    if (route.settings.name == 'numberDetail') {
      final visit = service.endInterpretation();
      // Wait until the route transition has completed before presenting.
      final animation = route is TransitionRoute ? route.animation : null;
      if (route is TransitionRoute &&
          animation != null &&
          animation.status != AnimationStatus.dismissed) {
        void finished(AnimationStatus status) {
          if (status != AnimationStatus.dismissed) return;
          animation.removeStatusListener(finished);
          service.finishInterpretation(visit);
        }

        animation.addStatusListener(finished);
      } else {
        service.finishInterpretation(visit);
      }
    }
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _routes.remove(route);
    _context();
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    final index = oldRoute == null ? -1 : _routes.indexOf(oldRoute);
    if (index >= 0) {
      if (newRoute == null) {
        _routes.removeAt(index);
      } else {
        _routes[index] = newRoute;
      }
    } else if (newRoute != null) {
      _routes.add(newRoute);
    }
    _context();
  }
}
