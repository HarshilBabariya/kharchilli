import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';

import 'format.dart';
import 'models.dart';

class Pin {
  static const length = 4;

  static String hash(String pin, [String? salt]) {
    final s = salt ?? List.generate(8, (_) => Random.secure().nextInt(256).toRadixString(16).padLeft(2, '0')).join();
    return '$s:${sha256.convert(utf8.encode('$s:$pin'))}';
  }

  static bool matches(String pin, String stored) => stored.isNotEmpty && hash(pin, stored.split(':').first) == stored;

  static bool isWeak(String pin) => pin.split('').toSet().length == 1 || const ['1234', '4321', '0123', '9876'].contains(pin);
}

class VoiceResult {
  const VoiceResult(this.amount, this.title, this.categoryKey, this.mode, this.note, this.credit);
  final double? amount;
  final String title;
  final String? categoryKey;
  final PaymentMode? mode;
  final String? note;
  final bool credit;
}

class VoiceParser {
  static final _noteMarker = RegExp(r'(\S+)\s+(note|नोट|નોંધ|નોટ)[:,]?\s+\S');
  static const _currencyNoteWords = {'ka', 'ke', 'ki', 'का', 'के', 'की', 'no', 'ni', 'na', 'નો', 'ની', 'ના'};
  static const _creditWords = ['cashback', 'refund', 'refunded', 'credited', 'mila', 'मिला', 'मिले', 'कैशबैक', 'रिफंड', 'કેશબેક', 'રિફંડ', 'મળ્યા'];
  static final _amount = RegExp(r'(\d+(?:[.,]\d{1,2})?)');
  static const _fillers = {
    'for', 'on', 'spent', 'paid', 'pay', 'by', 'via', 'using', 'with', 'through', 'rupees', 'rupee', 'rs', 'inr', 'dollars', 'dollar', 'euros', 'euro', 'bucks', 'the', 'a', 'an',
    'of', 'today', 'yesterday', 'add', 'expense', 'ka', 'ke', 'ki', 'ko', 'me', 'mein', 'se', 'diya', 'diye', 'kharch', 'kharcha', 'rupiya', 'rupaye', 'rupaya', 'no', 'na', 'ma',
    'mate', 'aapya', 'chukavya',
  };
  static const _categoryWords = <String, List<String>>{
    BuiltInCategories.groceries: ['grocery', 'groceries', 'vegetables', 'vegetable', 'sabzi', 'shak', 'fruits', 'fruit', 'milk', 'doodh', 'dudh', 'bread', 'kirana', 'supermarket', 'dmart', 'ration'],
    BuiltInCategories.utilities: ['electricity', 'bijli', 'light bill', 'water bill', 'gas', 'recharge', 'wifi', 'internet', 'broadband', 'phone bill', 'mobile bill'],
    BuiltInCategories.rent: ['rent', 'kiraya', 'bhada', 'maintenance', 'society', 'emi', 'loan'],
    BuiltInCategories.transport: ['auto', 'rickshaw', 'cab', 'uber', 'ola', 'taxi', 'petrol', 'diesel', 'fuel', 'bus', 'train', 'metro', 'parking', 'toll'],
    BuiltInCategories.dining: ['restaurant', 'dinner', 'lunch', 'breakfast', 'coffee', 'chai', 'tea', 'snacks', 'nashta', 'zomato', 'swiggy', 'pizza', 'burger', 'hotel', 'food', 'pani puri', 'dosa', 'biryani', 'thali', 'ice cream'],
    BuiltInCategories.health: ['medicine', 'medicines', 'dawa', 'doctor', 'hospital', 'pharmacy', 'chemist', 'clinic', 'gym', 'test'],
    BuiltInCategories.education: ['school', 'fees', 'fee', 'books', 'book', 'course', 'tuition', 'class', 'college', 'stationery'],
    BuiltInCategories.entertainment: ['movie', 'film', 'netflix', 'cinema', 'game', 'games', 'party', 'concert', 'subscription', 'spotify'],
    BuiltInCategories.shopping: ['shopping', 'clothes', 'kapde', 'shoes', 'amazon', 'flipkart', 'myntra', 'gift', 'dress', 'saree', 'kurta'],
  };
  static const _paymentWords = <PaymentMode, List<String>>{
    PaymentMode.upi: ['upi', 'gpay', 'google pay', 'phonepe', 'phone pe', 'paytm', 'bhim', 'online'],
    PaymentMode.card: ['card', 'credit', 'debit', 'visa', 'mastercard'],
    PaymentMode.bank: ['bank', 'netbanking', 'net banking', 'neft', 'imps', 'transfer', 'cheque', 'check'],
    PaymentMode.cash: ['cash', 'nakad', 'rokda', 'rokad'],
  };

  static bool _hasWord(String text, String word) => RegExp('(^|\\s)${RegExp.escape(word)}(\\s|\$)').hasMatch(text);
  static String _dropWord(String text, String word) => text.replaceAll(RegExp('(^|\\s)${RegExp.escape(word)}(?=\\s|\$)'), ' ');
  static String _titleCase(String text) => text.split(' ').where((w) => w.isNotEmpty).map((w) => w.capitalised).join(' ');

  /// [customCategories] maps a category key to its display name.
  static VoiceResult parse(String text, Map<String, String> customCategories) {
    final lower = text.toLowerCase();
    final marker = _noteMarker.allMatches(lower).where((m) => !_currencyNoteWords.contains(m.group(1))).firstOrNull;
    String? note;
    var working = lower;
    if (marker != null) {
      final markerStart = lower.indexOf(marker.group(2)!, marker.start);
      final markerEnd = markerStart + marker.group(2)!.length;
      note = lower.substring(markerEnd).replaceFirst(RegExp(r'^[\s:,]+'), '').trim().capitalised;
      working = lower.substring(0, markerStart);
    }
    working = working.replaceAll('₹', ' ').replaceAll(r'$', ' ').replaceAll('€', ' ');
    double? amount;
    final amountMatch = _amount.firstMatch(working);
    if (amountMatch != null) {
      working = working.replaceFirst(amountMatch.group(0)!, ' ');
      amount = double.tryParse(amountMatch.group(0)!.replaceAll(',', '.'));
    }
    final credit = _creditWords.any((w) => _hasWord(working, w));
    for (final w in _creditWords) {
      working = _dropWord(working, w);
    }
    final mode = _paymentWords.entries.where((e) => e.value.any((w) => _hasWord(working, w))).firstOrNull?.key;
    if (mode != null) {
      for (final w in _paymentWords[mode]!) {
        working = _dropWord(working, w);
      }
    }
    final custom = customCategories.entries.where((e) => e.value.trim().isNotEmpty && _hasWord(working, e.value.toLowerCase())).firstOrNull;
    final categoryKey = custom?.key ?? _categoryWords.entries.where((e) => e.value.any((w) => _hasWord(working, w))).firstOrNull?.key;
    var title = _titleCase(working.split(RegExp(r'\s+')).where((w) => w.isNotEmpty && !_fillers.contains(w)).join(' '));
    if (title.isEmpty) title = custom?.value ?? '';
    return VoiceResult(amount, title, categoryKey, mode, note, credit);
  }
}

/// Reads a pasted payment message (bank SMS, UPI app text) into the same fields voice entry fills.
class MessageParser {
  static final _amount = RegExp(r'(?:rs\.?|inr|₹)\s*([0-9][0-9,]*(?:\.[0-9]{1,2})?)', caseSensitive: false);
  static final _credit = RegExp(r'\b(credited|received|refund(ed)?|cashback|deposited)\b', caseSensitive: false);
  static final _party = RegExp(r"\b(?:to|at|from)\s+([A-Za-z0-9][A-Za-z0-9 .&'-]{1,28}?)(?=\s+(?:on|via|ref|upi|using|for|thru|through|a/c|ac|account)\b|[.,;:]|\s*$)", caseSensitive: false);

  /// Null when the text carries no currency amount, so the caller can fall back to [VoiceParser].
  static VoiceResult? parse(String text, Map<String, String> customCategories) {
    final amount = _amount.firstMatch(text);
    if (amount == null) return null;
    final lower = text.toLowerCase();
    final mode = lower.contains('upi')
        ? PaymentMode.upi
        : lower.contains('card')
            ? PaymentMode.card
            : RegExp(r'\b(neft|imps|rtgs|a/c|acct|account)\b').hasMatch(lower)
                ? PaymentMode.bank
                : null;
    final party = _party.allMatches(text).map((m) => m.group(1)!.trim()).where((p) => !RegExp(r'^(a/c|ac|account|your|bank)\b', caseSensitive: false).hasMatch(p)).firstOrNull ?? '';
    final title = party.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).map((w) => w.toLowerCase().capitalised).join(' ');
    return VoiceResult(double.tryParse(amount.group(1)!.replaceAll(',', '')), title, VoiceParser.parse(party, customCategories).categoryKey, mode, null, _credit.hasMatch(text));
  }
}

class Csv {
  static const header = ['date', 'title', 'category', 'payment_mode', 'amount', 'paid_by', 'group_id', 'note'];

  static String cell(String value) => value.contains(RegExp('[,"\n\r]')) ? '"${value.replaceAll('"', '""')}"' : value;

  static String encode(List<List<String>> rows) => rows.map((r) => r.map(cell).join(',')).join('\n');

  static List<List<String>> parse(String text) {
    final rows = <List<String>>[];
    var row = <String>[];
    final cell = StringBuffer();
    var quoted = false;
    final source = text.startsWith('\uFEFF') ? text.substring(1) : text;
    void endRow() {
      row.add(cell.toString());
      cell.clear();
      if (row.any((c) => c.trim().isNotEmpty)) rows.add(row);
      row = <String>[];
    }

    for (var i = 0; i < source.length; i++) {
      final c = source[i];
      final next = i + 1 < source.length ? source[i + 1] : '';
      if (quoted && c == '"' && next == '"') {
        cell.write('"');
        i++;
      } else if (quoted && c == '"') {
        quoted = false;
      } else if (quoted) {
        cell.write(c);
      } else if (c == '"' && cell.isEmpty) {
        quoted = true;
      } else if (c == ',') {
        row.add(cell.toString());
        cell.clear();
      } else if (c == '\n' || c == '\r') {
        if (c == '\r' && next == '\n') i++;
        endRow();
      } else {
        cell.write(c);
      }
    }
    endRow();
    return rows;
  }

  static DateTime? parseDate(String value) {
    final v = value.trim();
    final iso = RegExp(r'^(\d{4})-(\d{1,2})-(\d{1,2})').firstMatch(v);
    if (iso != null) return DateTime(int.parse(iso.group(1)!), int.parse(iso.group(2)!), int.parse(iso.group(3)!));
    final dmy = RegExp(r'^(\d{1,2})[/.-](\d{1,2})[/.-](\d{4})').firstMatch(v);
    if (dmy != null) return DateTime(int.parse(dmy.group(3)!), int.parse(dmy.group(2)!), int.parse(dmy.group(1)!));
    return null;
  }

  static String isoDate(DateTime d) => '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}
