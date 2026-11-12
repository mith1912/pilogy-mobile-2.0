import '../../numerology/presentation/calculation_explanation.dart';
import '../../../core/text/display_text.dart';
import 'package:flutter/material.dart';
import '../../../core/design_system/app_colors.dart';
import '../../numerology/domain/api_models.dart';
import '../../numerology/presentation/calculation_widgets.dart';

const _strengthIcons = [
  Icons.visibility_outlined,
  Icons.local_library_outlined,
  Icons.self_improvement,
];

// Read-only article content uses Text rather than per-paragraph EditableText
// scroll/focus state, including while the formula expansion changes layout.
class InterpretationArticle extends StatelessWidget {
  const InterpretationArticle({
    super.key,
    required this.article,
    required this.index,
    required this.onRefresh,
  });
  final FullInterpretation article;
  final IndexResult index;
  final VoidCallback onRefresh;
  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final meaning = distinctDisplayParagraphs({
      'summary': article.summary,
      'essence': article.essence,
    });
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _DetailHero(article: article),
        const SizedBox(height: 16),
        _FormulaRecap(index: index),
        const SizedBox(height: 24),
        _ArticleCard(
          sectionKey: const ValueKey('detail-meaning'),
          title: 'Ý Nghĩa Cốt Lõi & Sứ Mệnh',
          eyebrow: 'Tần Số Rung Động Nội Sinh',
          icon: Icons.psychology_outlined,
          children: [
            for (final paragraph in meaning.values) ...[
              Text(paragraph, style: text.bodyMedium),
              const SizedBox(height: 12),
            ],
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                formatSentence(article.reflection),
                style: text.bodySmall?.copyWith(
                  fontStyle: FontStyle.italic,
                  color: AppColors.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _ArticleCard(
          sectionKey: const ValueKey('detail-strengths'),
          title: 'Điểm Mạnh Vượt Trội',
          eyebrow: 'Năng Khiếu Bẩm Sinh',
          icon: Icons.workspace_premium_outlined,
          children: [
            if (article.strengths.isEmpty)
              const Text('Nội dung điểm mạnh chưa có sẵn.'),
            for (var i = 0; i < article.strengths.length; i++)
              Padding(
                padding: EdgeInsets.only(
                  bottom: i == article.strengths.length - 1 ? 0 : 12,
                ),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.secondaryContainer,
                        ),
                        child: Icon(
                          _strengthIcons[i % _strengthIcons.length],
                          size: 16,
                          color: AppColors.onSecondaryContainer,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              formatUiTitle(article.strengths[i].title),
                              style: text.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              formatSentence(article.strengths[i].description),
                              style: text.bodySmall?.copyWith(
                                color: AppColors.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),
        _ArticleCard(
          sectionKey: const ValueKey('detail-challenges'),
          title: 'Thách Thức Cần Cân Bằng',
          eyebrow: 'Vùng Mù Nhận Thức',
          icon: Icons.warning_amber_outlined,
          children: [
            if (article.challenges.isEmpty)
              const Text('Nội dung thách thức chưa có sẵn.'),
            for (var i = 0; i < article.challenges.length; i++)
              Padding(
                padding: EdgeInsets.only(
                  bottom: i == article.challenges.length - 1 ? 0 : 10,
                ),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.do_not_disturb_on_outlined,
                            size: 16,
                            color: AppColors.secondary,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              formatUiTitle(article.challenges[i].title),
                              style: text.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w500,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        formatSentence(article.challenges[i].description),
                        style: text.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          key: const ValueKey('detail-advice'),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.primaryContainer,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.spa_outlined,
                    size: 20,
                    color: AppColors.secondaryContainer,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Lời Khuyên Pythagoras',
                      style: text.titleLarge?.copyWith(
                        color: AppColors.onPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'Chánh Niệm',
                      style: text.labelSmall?.copyWith(
                        color: AppColors.secondaryFixed,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                formatSentence(article.suggestedAction),
                style: text.bodyMedium?.copyWith(
                  fontStyle: FontStyle.italic,
                  color: AppColors.onPrimaryContainer,
                ),
              ),
              for (final entry
                  in distinctDisplayParagraphs(<String, String>{
                    'Các mối quan hệ': article.relationships,
                    'Sự nghiệp & Phát triển': article.careerAndGrowth,
                    'Bài học cuộc sống': article.lifeLesson,
                    'Lời khẳng định': article.affirmation,
                    if (article.periodFocus != null)
                      'Trọng tâm giai đoạn': article.periodFocus!,
                  }).entries)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.check_circle_outline,
                        size: 16,
                        color: AppColors.secondaryContainer,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              formatUiTitle(entry.key),
                              style: text.labelSmall?.copyWith(
                                color: AppColors.secondaryFixed,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              formatSentence(entry.value),
                              style: text.bodySmall?.copyWith(
                                color: AppColors.onPrimaryContainer,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: _whiteCard(),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.surfaceContainer,
                ),
                child: const Icon(Icons.edit_note, color: AppColors.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ghi Chép Cảm Ngộ Của Bạn',
                      style: text.titleLarge?.copyWith(fontSize: 15),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Chức năng ghi chép chưa có sẵn.',
                      style: text.bodySmall?.copyWith(color: AppColors.outline),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            key: const ValueKey('detail-refresh'),
            onPressed: onRefresh,
            icon: const Icon(Icons.sync, size: 18, color: AppColors.secondary),
            label: const Text('Tải Lại Luận Giải'),
          ),
        ),
      ],
    );
  }
}

BoxDecoration _whiteCard() => BoxDecoration(
  color: AppColors.surfaceContainerLowest,
  borderRadius: BorderRadius.circular(12),
  boxShadow: [
    BoxShadow(
      color: Colors.black.withOpacity(.05),
      blurRadius: 3,
      offset: const Offset(0, 1),
    ),
  ],
);

class _DetailHero extends StatelessWidget {
  const _DetailHero({required this.article});
  final FullInterpretation article;
  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Container(
      key: const ValueKey('detail-hero'),
      decoration: _whiteCard(),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          const Positioned(
            right: -48,
            top: -48,
            child: ExcludeSemantics(
              child: CustomPaint(
                size: Size(192, 192),
                painter: _RadiantPattern(),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainer,
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.auto_stories_outlined,
                          size: 13,
                          color: AppColors.secondary,
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            formatUiTitle(
                              article.index == IndexType.lifePath
                                  ? 'Chỉ số nền tảng cốt lõi'
                                  : indexTitles[article.index]!,
                            ),
                            textAlign: TextAlign.center,
                            style: text.labelSmall?.copyWith(
                              color: AppColors.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Center(
                  child: Container(
                    width: 96,
                    height: 96,
                    padding: const EdgeInsets.all(10),
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppColors.surfaceContainerHigh,
                          AppColors.surfaceContainerLowest,
                          AppColors.surfaceVariant,
                        ],
                      ),
                    ),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        formatIndexValue(article.value, article.baseValue),
                        key: const ValueKey('article-number'),
                        style: text.displayMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  formatUiTitle(article.title),
                  textAlign: TextAlign.center,
                  style: text.headlineSmall?.copyWith(color: AppColors.primary),
                ),
                const SizedBox(height: 4),
                Text(
                  formatSentence(article.subtitle),
                  textAlign: TextAlign.center,
                  style: text.bodyMedium?.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  formatSentence(article.tagline),
                  textAlign: TextAlign.center,
                  style: text.bodyMedium?.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 24),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final keyword in article.keywords)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceContainer,
                          borderRadius: BorderRadius.circular(99),
                        ),
                        child: Text(
                          formatUiTitle(keyword),
                          style: text.labelLarge?.copyWith(
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FormulaRecap extends StatelessWidget {
  const _FormulaRecap({required this.index});
  final IndexResult index;
  @override
  Widget build(BuildContext context) => Container(
    key: const ValueKey('detail-formula'),
    decoration: BoxDecoration(
      color: AppColors.surfaceContainerLow,
      borderRadius: BorderRadius.circular(12),
    ),
    child: ExpansionTile(
      key: ValueKey('steps-${index.type.name}'),
      tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: const Icon(
        Icons.calculate_outlined,
        size: 15,
        color: AppColors.secondary,
      ),
      title: Text(
        'Phương Thức Quy Nạp Pythagoras',
        style: Theme.of(
          context,
        ).textTheme.labelSmall?.copyWith(color: AppColors.outline),
      ),
      subtitle: const Text('Các Bước Do Máy Chủ Cung Cấp'),
      childrenPadding: const EdgeInsets.all(16),
      expandedCrossAxisAlignment: CrossAxisAlignment.start,
      children: [CalculationExplanation(index: index)],
    ),
  );
}

class _ArticleCard extends StatelessWidget {
  const _ArticleCard({
    required this.sectionKey,
    required this.title,
    required this.eyebrow,
    required this.icon,
    required this.children,
  });
  final Key sectionKey;
  final String title, eyebrow;
  final IconData icon;
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => Container(
    key: sectionKey,
    padding: const EdgeInsets.all(20),
    decoration: _whiteCard(),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 18, color: AppColors.primary),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    formatUiTitle(title),
                    style: Theme.of(
                      context,
                    ).textTheme.titleLarge?.copyWith(color: AppColors.primary),
                  ),
                  Text(
                    formatUiTitle(eyebrow),
                    style: Theme.of(
                      context,
                    ).textTheme.labelSmall?.copyWith(color: AppColors.outline),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ...children,
      ],
    ),
  );
}

class _RadiantPattern extends CustomPainter {
  const _RadiantPattern();
  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 100, size.height / 100);
    final paint =
        Paint()
          ..color = AppColors.primary.withOpacity(.1)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2;
    canvas.drawCircle(const Offset(50, 50), 45, paint);
    canvas.drawCircle(const Offset(50, 50), 30, paint);
    canvas.drawPath(
      Path()
        ..moveTo(50, 5)
        ..lineTo(93, 75)
        ..lineTo(7, 75)
        ..close(),
      paint,
    );
    canvas.drawPath(
      Path()
        ..moveTo(50, 95)
        ..lineTo(7, 25)
        ..lineTo(93, 25)
        ..close(),
      paint,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _RadiantPattern oldDelegate) => false;
}
