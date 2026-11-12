import 'package:flutter_test/flutter_test.dart';
import 'package:pilogy_app/core/text/display_text.dart';

void main() {
  test('Vietnamese labels, brands, acronyms and master strings', () {
    expect(formatUiTitle('chỉ số đường đời'), 'Chỉ Số Đường Đời');
    expect(formatUiLabel('xem chi tiết'), 'Xem Chi Tiết');
    expect(
      formatUiTitle('pilogy API NASA Firebase AdMob'),
      'PILOGY API NASA Firebase AdMob',
    );
    expect(formatUiTitle('11/2 22/4 33/6'), '11/2 22/4 33/6');
    expect(formatUiTitle(''), '');
    expect(formatUiTitle('  '), '  ');
    expect(formatUiTitle('🌸 khám phá bản thân'), '🌸 Khám Phá Bản Thân');
    expect(formatUiTitle('a\u0301nh sáng'), 'A\u0301nh Sáng');
  });
  test('sentences remain sentences; identifiers and names are preserved', () {
    expect(
      formatSentence('bạn có thể học hỏi. hãy lắng nghe.'),
      'Bạn có thể học hỏi. Hãy lắng nghe.',
    );
    expect(
      formatUiTitle('https://pilogy.vercel.app lifePath user_id a@b.vn'),
      'https://pilogy.vercel.app lifePath user_id a@b.vn',
    );
    expect(
      formatUiTitle('hồ sơ nguyễn văn an', protectedTerms: ['nguyễn văn an']),
      'Hồ Sơ nguyễn văn an',
    );
    final long = List.filled(100, 'khám phá').join(' ');
    expect(formatUiTitle(long), List.filled(100, 'Khám Phá').join(' '));
  });
  test('deduplication is a display projection without source mutations', () {
    final source = {
      'summary': 'bạn học hỏi.',
      'essence': 'Bạn học hỏi.',
      'other': 'đi tiếp.',
    };
    expect(distinctDisplayParagraphs(source), {
      'summary': 'Bạn học hỏi.',
      'other': 'Đi tiếp.',
    });
    expect(source['summary'], 'bạn học hỏi.');
    expect(source.length, 3);
  });
}
