import 'package:intl/intl.dart';

import 'l10n.dart';

class Fmt {
  static String symbol = '₹';
  static String currencyCode = 'INR';

  static String _group(int whole) {
    final digits = whole.toString();
    if (currencyCode != 'INR') return NumberFormat('#,##0', 'en_US').format(whole);
    if (digits.length <= 3) return digits;
    final head = digits.substring(0, digits.length - 3);
    final tail = digits.substring(digits.length - 3);
    final buffer = StringBuffer();
    for (var i = 0; i < head.length; i++) {
      if (i > 0 && (head.length - i) % 2 == 0) buffer.write(',');
      buffer.write(head[i]);
    }
    return '$buffer,$tail';
  }

  static String number(num value) {
    final abs = value.abs();
    final cents = (abs * 100).round();
    final whole = cents ~/ 100;
    final frac = cents % 100;
    return frac == 0 ? _group(whole) : '${_group(whole)}.${frac.toString().padLeft(2, '0')}';
  }

  static String money(num value) => '$symbol${number(value)}';

  /// Ledger amounts: spends are positive, credits negative and shown as +₹50.
  static String ledger(num amount) => amount < 0 ? '+${money(-amount)}' : money(amount);

  static String compact(num value) {
    final abs = value.abs();
    String cut(double v, String unit) => '${v >= 10 ? v.round() : (v * 10).round() / 10}$unit'.replaceAll('.0', '');
    final text = abs >= 10000000
        ? cut(abs / 10000000, 'Cr')
        : abs >= 100000
            ? cut(abs / 100000, 'L')
            : abs >= 1000
                ? cut(abs / 1000, 'k')
                : abs.round().toString();
    return value < 0 ? '+$text' : text;
  }

  static String date(DateTime d, [String pattern = 'd MMM']) => DateFormat(pattern, L10n.lang).format(d);
  static String monthYear(DateTime d) => DateFormat('MMMM yyyy', L10n.lang).format(d);
  static String month(DateTime d) => DateFormat('MMMM', L10n.lang).format(d);
  static String weekday(DateTime d) => DateFormat('EEEE', L10n.lang).format(d);
  static String time(int hour, int minute) => DateFormat('h:mm a', L10n.lang).format(DateTime(2000, 1, 1, hour, minute));

  static String relativeDay(DateTime d) {
    final diff = Days.of(d).difference(Days.today()).inDays;
    final label = date(d, 'EEE, d MMM');
    if (diff == 0) return tr('today_with_date', [label]);
    if (diff == -1) return tr('yesterday_with_date', [label]);
    if (diff == 1) return tr('tomorrow_with_date', [label]);
    return label;
  }
}

class Days {
  static DateTime of(DateTime d) => DateTime(d.year, d.month, d.day);
  static DateTime today() => of(DateTime.now());
  static int key(DateTime d) => d.year * 10000 + d.month * 100 + d.day;
  static DateTime fromKey(int key) => DateTime(key ~/ 10000, key ~/ 100 % 100, key % 100);
  static int monthKey(DateTime d) => d.year * 100 + d.month;
  static DateTime monthStart(DateTime d) => DateTime(d.year, d.month);
  static int inMonth(DateTime d) => DateTime(d.year, d.month + 1, 0).day;
  static DateTime addMonths(DateTime d, int months) => DateTime(d.year, d.month + months);
  static int between(DateTime from, DateTime to) => (of(to).difference(of(from)).inHours / 24).round();
}

extension TitleCase on String {
  String get capitalised => isEmpty ? this : this[0].toUpperCase() + substring(1);
}
