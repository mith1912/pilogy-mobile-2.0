import 'package:flutter/material.dart';
import '../../../core/design_system/app_colors.dart';
import '../../../core/text/display_text.dart';
import '../domain/api_models.dart';

const _subjects = <String, String>{
  'birthMonth': 'Tháng Sinh',
  'birthDay': 'Ngày Sinh',
  'birthYear': 'Năm Sinh',
  'referenceYear': 'Năm Tham Chiếu',
  'lifePath': 'Đường Đời',
  'expression': 'Sứ Mệnh',
  'soulUrge': 'Linh Hồn',
  'personality': 'Nhân Cách',
  'birthday': 'Ngày Sinh',
  'attitude': 'Thái Độ',
  'maturity': 'Trưởng Thành',
  'personalYear': 'Năm Cá Nhân',
  'personalMonth': 'Tháng Cá Nhân',
};
String calculationStepTitle(CalculationStep step) {
  final parts = step.label.split('.');
  final subject = _subjects[parts.first];
  if (subject == null)
    return step.operation == 'digitSum'
        ? 'Cộng Các Chữ Số'
        : step.operation == 'sum'
        ? 'Cộng Các Thành Phần'
        : 'Bước Do Máy Chủ Cung Cấp';
  if (parts.last == 'base') return 'Giá Trị Cơ Sở · $subject';
  return '${step.operation == 'digitSum' ? 'Cộng Các Chữ Số' : 'Cộng Các Thành Phần'} · $subject';
}

String calculationStepExpression(CalculationStep step) =>
    step.inputs.isEmpty
        ? 'Kết Quả: ${step.result}'
        : '${step.inputs.join(' + ')} = ${step.result}';

/// Renders the returned sequence verbatim: no sums, reductions or hidden steps.
class CalculationExplanation extends StatelessWidget {
  const CalculationExplanation({super.key, required this.index});
  final IndexResult index;
  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (index.steps.isEmpty)
          Text('Chưa có các bước tính cho chỉ số này.', style: text.bodySmall)
        else
          for (var i = 0; i < index.steps.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Bước ${i + 1} · ${calculationStepTitle(index.steps[i])}',
                    style: text.labelLarge,
                  ),
                  const SizedBox(height: 4),
                  // Formula rows are read-only. Avoid mounting EditableText selection
                  // state while the enclosing ExpansionTile animates or is replaced.
                  Text(
                    calculationStepExpression(index.steps[i]),
                    key: ValueKey('step-expression-$i'),
                    softWrap: true,
                    style: text.bodyMedium,
                  ),
                  if (index.steps[i].inputLabels != null)
                    Text(
                      formatSentence(index.steps[i].inputLabels!.join(' · ')),
                      style: text.bodySmall,
                    ),
                ],
              ),
            ),
        const SizedBox(height: 4),
        Text(
          'Kết Quả: ${formatIndexValue(index.value, index.baseValue)}',
          key: const ValueKey('calculation-final-value'),
          style: text.titleLarge?.copyWith(color: AppColors.primary),
        ),
        if (const {11, 22, 33}.contains(index.value)) ...[
          const SizedBox(height: 8),
          Text(
            'Giá trị ${index.value} và giá trị cơ sở ${index.baseValue} do máy chủ trả về. Luận giải dùng số ${index.value}.',
            style: text.bodySmall,
          ),
        ],
      ],
    );
  }
}
