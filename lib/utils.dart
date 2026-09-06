String formatCurrency(String symbol, num n) {
  final fixed = n.toStringAsFixed(2);
  final parts = fixed.split('.');
  var intPart = parts[0];
  final negative = intPart.startsWith('-');
  if (negative) intPart = intPart.substring(1);
  final buffer = StringBuffer();
  for (int i = 0; i < intPart.length; i++) {
    if (i > 0 && (intPart.length - i) % 3 == 0) buffer.write(',');
    buffer.write(intPart[i]);
  }
  return '$symbol${negative ? '-' : ''}${buffer.toString()}.${parts[1]}';
}

String todayIso() => DateTime.now().toIso8601String().substring(0, 10);
