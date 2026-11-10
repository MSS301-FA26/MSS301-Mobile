/// Registration-only rules verified against RegisterRequest and Web Register.
/// Other Auth stages deliberately keep their existing validation.
abstract final class RegistrationValidation {
  static String? name(String? value) {
    final name = value?.trim() ?? '';
    if (name.isEmpty) return 'Vui lòng nhập họ tên';
    if (name.length > 100) return 'Tên không được vượt quá 100 ký tự.';
    return null;
  }

  static String? phone(String? value) =>
      RegExp(r'^(03|05|08|09)\d{8}$').hasMatch(value?.trim() ?? '')
      ? null
      : 'Số điện thoại phải gồm 10 chữ số và bắt đầu bằng 03, 05, 08 hoặc 09.';

  static String? username(String? value) {
    final username = value?.trim() ?? '';
    if (username.isEmpty) return 'Vui lòng nhập tên đăng nhập';
    if (RegExp(r'\s').hasMatch(username)) {
      return 'Tên đăng nhập không được chứa khoảng trắng';
    }
    if (username.length > 255) {
      return 'Tên đăng nhập không được vượt quá 255 ký tự';
    }
    return null;
  }

  static String? identity(String? value) =>
      RegExp(r'^(?:\d{9}|\d{12})$').hasMatch(value?.trim() ?? '')
      ? null
      : 'CCCD/CMND phải gồm 9 hoặc 12 chữ số';

  static String? email(String? value) =>
      RegExp(r'^[^\s@]+@[^\s@]+$').hasMatch(value?.trim() ?? '')
      ? null
      : 'Email không hợp lệ';

  static String? password(String? value) =>
      RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[^A-Za-z0-9]).{8,}$')
          .hasMatch(value ?? '')
      ? null
      : 'Mật khẩu phải có tối thiểu 8 ký tự, gồm chữ hoa, chữ thường, số và ký tự đặc biệt.';

  static String? confirm(String? value, String password) =>
      value != null && value.isNotEmpty && value == password
      ? null
      : 'Xác thực mật khẩu chưa khớp.';
}
