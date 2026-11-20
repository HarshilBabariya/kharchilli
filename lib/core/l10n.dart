import 'dart:convert';
import 'dart:math';

import 'package:flutter/services.dart';

class L10n {
  static const languages = {'en': 'English', 'hi': 'हिन्दी', 'gu': 'ગુજરાતી'};
  static String lang = 'en';
  static Map<String, dynamic> _strings = {};
  static Map<String, dynamic> _arrays = {};
  static Map<String, dynamic> _plurals = {};
  static Map<String, dynamic> _fallback = {};

  static Future<void> load(String code) async {
    lang = languages.containsKey(code) ? code : 'en';
    final data = jsonDecode(await rootBundle.loadString('assets/l10n/$lang.json')) as Map<String, dynamic>;
    _strings = data['strings'] as Map<String, dynamic>;
    _arrays = data['arrays'] as Map<String, dynamic>;
    _plurals = data['plurals'] as Map<String, dynamic>;
    if (_fallback.isEmpty) {
      final en = jsonDecode(await rootBundle.loadString('assets/l10n/en.json')) as Map<String, dynamic>;
      _fallback = en['strings'] as Map<String, dynamic>;
    }
  }

  static final _arg = RegExp(r'%(?:(\d)\$)?[sd]');

  static String format(String pattern, List<Object?> args) {
    var next = 0;
    return pattern.replaceAllMapped(_arg, (m) {
      final index = m.group(1) == null ? next++ : int.parse(m.group(1)!) - 1;
      return index < args.length ? '${args[index]}' : '';
    }).replaceAll('%%', '%');
  }

  /// The English text of [key], whatever language is showing.
  static String english(String key) => (_fallback[key] ?? key) as String;

  static String string(String key) => (_strings[key] ?? _fallback[key] ?? key) as String;
  static List<String> array(String key) => ((_arrays[key] ?? const []) as List).cast<String>();
  static String plural(String key, int n) {
    final forms = (_plurals[key] ?? const {}) as Map;
    return (forms[n == 1 ? 'one' : 'other'] ?? forms['other'] ?? key) as String;
  }
}

String tr(String key, [List<Object?> args = const []]) => L10n.format(L10n.string(key), args);

String trPlural(String key, int n, [List<Object?>? args]) => L10n.format(L10n.plural(key, n), args ?? [n]);

final _random = Random();

String trPick(String arrayKey, [List<Object?> args = const [], int? seed]) {
  final lines = L10n.array(arrayKey);
  if (lines.isEmpty) return arrayKey;
  return L10n.format(lines[(seed ?? _random.nextInt(1 << 20)) % lines.length], args);
}
