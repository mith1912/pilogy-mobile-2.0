import '../../services/ads/ad_banner.dart';
import '../text/display_text.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../design_system/app_colors.dart';

void contextualBack(BuildContext context, {String fallback = '/profiles'}) {
  if (context.canPop()) {
    context.pop();
  } else {
    context.go(fallback);
  }
}

class PilogyScaffold extends StatelessWidget {
  const PilogyScaffold({
    super.key,
    required this.screenId,
    required this.title,
    required this.children,
    this.tab,
    this.showHeader = true,
    this.back = false,
    this.backFallback = '/profiles',
    this.actions = const [],
    this.bottomActions,
    this.headerTitle,
    this.showDefaultProfileAction = true,
    this.titleSpacing,
    this.flatHeader = false,
    this.onRefresh,
    this.sectionSpacing = 24,
  });
  final String screenId, title;
  final List<Widget> children, actions;
  final int? tab;
  final bool back, showHeader;
  final String backFallback;
  final Widget? bottomActions, headerTitle;
  final bool showDefaultProfileAction;
  final double? titleSpacing;
  final bool flatHeader;
  final RefreshCallback? onRefresh;
  final double sectionSpacing;
  @override
  Widget build(BuildContext context) => Scaffold(
    key: ValueKey('screen-$screenId'),
    appBar:
        !showHeader
            ? null
            : AppBar(
              toolbarHeight:
                  64 *
                  MediaQuery.textScaleFactorOf(
                    context,
                  ).clamp(1.0, 2.0).toDouble(),
              automaticallyImplyLeading: false,
              leading:
                  back
                      ? IconButton(
                        tooltip: 'Quay Lại',
                        icon: const Icon(Icons.arrow_back),
                        onPressed:
                            () =>
                                contextualBack(context, fallback: backFallback),
                      )
                      : null,
              scrolledUnderElevation: flatHeader ? 0 : null,
              surfaceTintColor: flatHeader ? Colors.transparent : null,
              titleSpacing: titleSpacing,
              title:
                  headerTitle ??
                  Text(
                    formatUiTitle(title),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              actions: [
                ...actions,
                if (!back && showDefaultProfileAction)
                  IconButton(
                    tooltip: 'Hồ Sơ Đã Lưu',
                    onPressed: () => context.go('/profiles'),
                    icon: const Icon(Icons.account_circle_outlined),
                  ),
                const SizedBox(width: 8),
              ],
            ),
    body: SafeArea(
      top: !showHeader,
      child: Column(
        children: [
          Expanded(
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: _scrollBody(
                  ListView(
                    key: PageStorageKey(screenId),
                    keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                    physics:
                        onRefresh == null
                            ? null
                            : const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 36),
                    children: [
                      for (final child in children)
                        Padding(
                          padding: EdgeInsets.only(bottom: sectionSpacing),
                          child: child,
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const StickyAdBanner(),
        ],
      ),
    ),
    bottomNavigationBar:
        bottomActions ??
        (tab == null
            ? null
            : NavigationBar(
              height:
                  64 *
                  MediaQuery.textScaleFactorOf(
                    context,
                  ).clamp(1.0, 1.8).toDouble(),
              selectedIndex: tab!,
              backgroundColor: AppColors.surface,
              onDestinationSelected: (index) {
                if (index != tab)
                  context.go(
                    const ['/discover', '/analysis', '/profiles'][index],
                  );
              },
              destinations: const [
                NavigationDestination(
                  key: ValueKey('tab-discover'),
                  icon: Icon(Icons.explore_outlined),
                  selectedIcon: Icon(Icons.explore),
                  label: 'Khám Phá',
                ),
                NavigationDestination(
                  key: ValueKey('tab-analysis'),
                  icon: Icon(Icons.grid_view_outlined),
                  selectedIcon: Icon(Icons.grid_view),
                  label: 'Phân Tích',
                ),
                NavigationDestination(
                  key: ValueKey('tab-profiles'),
                  icon: Icon(Icons.person_outline),
                  selectedIcon: Icon(Icons.person),
                  label: 'Hồ Sơ',
                ),
              ],
            )),
  );
  Widget _scrollBody(Widget list) =>
      onRefresh == null
          ? list
          : RefreshIndicator(
            onRefresh: onRefresh!,
            color: AppColors.secondary,
            child: list,
          );
}

class EditorialPanel extends StatelessWidget {
  const EditorialPanel({
    super.key,
    required this.child,
    this.dark = false,
    this.gold = false,
  });
  final Widget child;
  final bool dark, gold;
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color:
          dark
              ? AppColors.primary
              : gold
              ? AppColors.secondaryContainer
              : AppColors.surfaceContainerLow,
      borderRadius: BorderRadius.circular(12),
    ),
    child: DefaultTextStyle.merge(
      style: TextStyle(color: dark ? AppColors.onPrimary : AppColors.onSurface),
      child: child,
    ),
  );
}

class InfoPanel extends StatelessWidget {
  const InfoPanel({
    super.key,
    required this.title,
    required this.message,
    this.icon = Icons.verified_user_outlined,
  });
  final String title, message;
  final IconData icon;
  @override
  Widget build(BuildContext context) => EditorialPanel(
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppColors.secondary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                formatUiTitle(title),
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(formatSentence(message)),
            ],
          ),
        ),
      ],
    ),
  );
}

class ActionRow extends StatelessWidget {
  const ActionRow({
    super.key,
    required this.title,
    required this.icon,
    this.subtitle,
    this.onTap,
  });
  final String title;
  final String? subtitle;
  final IconData icon;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => Card(
    child: ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: Icon(icon, color: AppColors.secondary),
      title: Text(title),
      subtitle: subtitle == null ? null : Text(formatSentence(subtitle!)),
      trailing: onTap == null ? null : const Icon(Icons.chevron_right),
      onTap: onTap,
    ),
  );
}

/// Native rendering of the reference's decorative inline SVG, not an image download.
class PilogyEmblem extends StatelessWidget {
  const PilogyEmblem({super.key});
  @override
  Widget build(BuildContext context) => const ExcludeSemantics(
    child: CustomPaint(size: Size(96, 96), painter: _EmblemPainter()),
  );
}

class _EmblemPainter extends CustomPainter {
  const _EmblemPainter();
  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 100, size.height / 100);
    final paint =
        Paint()
          ..color = AppColors.secondary
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2;
    canvas.drawCircle(const Offset(50, 50), 44, paint);
    canvas.drawCircle(const Offset(50, 50), 36, paint);
    canvas.drawCircle(const Offset(50, 50), 14, paint);
    final star =
        Path()
          ..moveTo(50, 6)
          ..lineTo(59, 38)
          ..lineTo(91, 41)
          ..lineTo(65, 60)
          ..lineTo(74, 92)
          ..lineTo(50, 72)
          ..lineTo(26, 92)
          ..lineTo(35, 60)
          ..lineTo(9, 41)
          ..lineTo(41, 38)
          ..close();
    paint.color = AppColors.primaryContainer;
    canvas.drawPath(star, paint);
    paint
      ..color = AppColors.secondary
      ..style = PaintingStyle.fill;
    canvas.drawCircle(const Offset(50, 50), 3, paint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _EmblemPainter oldDelegate) => false;
}
