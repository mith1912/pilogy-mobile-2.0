import 'package:diacritic/diacritic.dart';

import '../../../core/storage/local_data_exception.dart';

abstract final class ProfileValidation {
  static String? fullNameError(String? value) {
    final name = (value ?? '').trim();
    if (name.isEmpty) return 'Vui lòng nhập họ và tên khai sinh.';
    if (name.length > 200) return 'Họ tên không được vượt quá 200 ký tự.';
    if (!RegExp('[A-Za-z]').hasMatch(removeDiacritics(name))) {
      return 'Họ tên cần có ít nhất một chữ cái.';
    }
    return null;
  }

  static String? birthDateError(String? value) =>
      isCalendarDate(value ?? '')
          ? null
          : 'Nhập ngày dương lịch hợp lệ theo định dạng YYYY-MM-DD.';

  static bool isCalendarDate(String value) {
    if (value.length != 10 || !RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(value))
      return false;
    final year = int.parse(value.substring(0, 4));
    final month = int.parse(value.substring(5, 7));
    final day = int.parse(value.substring(8, 10));
    if (year < 1 || year > 9999 || month < 1 || month > 12 || day < 1) {
      return false;
    }
    final date = DateTime.utc(year, month, day);
    return date.year == year && date.month == month && date.day == day;
  }

  static void validate(String fullName, String birthDate) {
    if (fullNameError(fullName) != null) {
      throw const LocalDataException(
        LocalDataFailure.invalidInput,
        field: 'fullName',
      );
    }
    if (birthDateError(birthDate) != null) {
      throw const LocalDataException(
        LocalDataFailure.invalidInput,
        field: 'birthDate',
      );
    }
  }
}
