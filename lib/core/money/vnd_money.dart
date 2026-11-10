import '../contracts/json_parsers.dart';

class VndMoney implements Comparable<VndMoney> {
  const VndMoney(this.amount) : assert(amount >= 0);

  static const zero = VndMoney(0);

  final int amount;

  factory VndMoney.fromJson(Object? value, {String? field}) =>
      VndMoney(intFromJson(value ?? 0, field: field));

  VndMoney operator +(VndMoney other) => VndMoney(amount + other.amount);

  VndMoney operator -(VndMoney other) => VndMoney(amount - other.amount);

  VndMoney multiply(int quantity) => VndMoney(amount * quantity);

  String format() {
    final digits = amount.toString();
    final buffer = StringBuffer();
    for (var index = 0; index < digits.length; index++) {
      final remaining = digits.length - index;
      buffer.write(digits[index]);
      if (remaining > 1 && remaining % 3 == 1) buffer.write('.');
    }
    return '$bufferđ';
  }

  @override
  int compareTo(VndMoney other) => amount.compareTo(other.amount);

  @override
  bool operator ==(Object other) => other is VndMoney && other.amount == amount;

  @override
  int get hashCode => amount.hashCode;

  @override
  String toString() => format();
}
