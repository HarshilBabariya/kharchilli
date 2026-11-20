import 'package:flutter/material.dart';

import 'format.dart';
import 'l10n.dart';

typedef Json = Map<String, dynamic>;

abstract class Doc {
  int id = 0;
  String get kind;
  Json toJson();
}

T _enum<T extends Enum>(List<T> values, Object? name, T fallback) => values.firstWhere((v) => v.name == name, orElse: () => fallback);

enum PaymentMode {
  cash('pay_cash', Icons.payments_rounded, Color(0xFF43A047)),
  upi('pay_upi', Icons.qr_code_rounded, Color(0xFF7C4DFF)),
  card('pay_card', Icons.credit_card_rounded, Color(0xFFFB8C00)),
  bank('pay_bank', Icons.account_balance_rounded, Color(0xFF039BE5));

  const PaymentMode(this.labelKey, this.icon, this.color);
  final String labelKey;
  final IconData icon;
  final Color color;
  String get label => tr(labelKey);
}

/// How a shared expense was divided. Shares are always stored as amounts; the type only records how they were entered.
enum SplitType { none, equal, custom, percent, weights }

enum RepeatRule {
  once('repeat_once'),
  daily('repeat_daily'),
  weekly('repeat_weekly'),
  monthly('repeat_monthly'),
  yearly('repeat_yearly');

  const RepeatRule(this.labelKey);
  final String labelKey;
}

enum Mood {
  happy,
  love,
  excited,
  smart,
  neutral,
  confused,
  sleepy,
  sad,
  worried,
  angry;

  String get label => tr('mood_$name');
  String line(String greeting, int seed) => trPick('mood_lines_$name', [greeting], seed);
}

enum Gender { male, female }

enum FaceShape { oval, round, square, heart, long }

enum Beard {
  none('beard_none'),
  stubble('beard_stubble'),
  mustache('beard_mustache'),
  goatee('beard_goatee'),
  chinStrap('beard_chin_strap'),
  full('beard_full');

  const Beard(this.labelKey);
  final String labelKey;
}

enum AvatarAction {
  wave(1500),
  jump(1100),
  spin(1000),
  dance(2000),
  wink(1200),
  cheer(1600),
  laugh(1500);

  const AvatarAction(this.durationMs);
  final int durationMs;
  String get label => tr('act_$name');
}

class AvatarConfig {
  const AvatarConfig({
    this.skinTone = 0,
    this.hairId = 'hair_short',
    this.hairColor = 0,
    this.outfitId = 'outfit_tee',
    this.accessoryId = 'acc_none',
    this.gender = Gender.male,
    this.mood,
    this.faceShape = FaceShape.oval,
    this.beard = Beard.none,
  });

  final int skinTone;
  final String hairId;
  final int hairColor;
  final String outfitId;
  final String accessoryId;
  final Gender gender;
  final Mood? mood;
  final FaceShape faceShape;
  final Beard beard;

  AvatarConfig copyWith({
    int? skinTone,
    String? hairId,
    int? hairColor,
    String? outfitId,
    String? accessoryId,
    Gender? gender,
    Mood? mood,
    bool autoMood = false,
    FaceShape? faceShape,
    Beard? beard,
  }) =>
      AvatarConfig(
        skinTone: skinTone ?? this.skinTone,
        hairId: hairId ?? this.hairId,
        hairColor: hairColor ?? this.hairColor,
        outfitId: outfitId ?? this.outfitId,
        accessoryId: accessoryId ?? this.accessoryId,
        gender: gender ?? this.gender,
        mood: autoMood ? null : mood ?? this.mood,
        faceShape: faceShape ?? this.faceShape,
        beard: beard ?? this.beard,
      );

  Json toJson() => {
        'skinTone': skinTone,
        'hairId': hairId,
        'hairColor': hairColor,
        'outfitId': outfitId,
        'accessoryId': accessoryId,
        'gender': gender.name,
        'mood': mood?.name,
        'faceShape': faceShape.name,
        'beard': beard.name,
      };

  factory AvatarConfig.fromJson(Json j) => AvatarConfig(
        skinTone: j['skinTone'] as int? ?? 0,
        hairId: j['hairId'] as String? ?? 'hair_short',
        hairColor: j['hairColor'] as int? ?? 0,
        outfitId: j['outfitId'] as String? ?? 'outfit_tee',
        accessoryId: j['accessoryId'] as String? ?? 'acc_none',
        gender: _enum(Gender.values, j['gender'], Gender.male),
        mood: j['mood'] == null ? null : _enum(Mood.values, j['mood'], Mood.happy),
        faceShape: _enum(FaceShape.values, j['faceShape'], FaceShape.oval),
        beard: _enum(Beard.values, j['beard'], Beard.none),
      );
}

class Member extends Doc {
  Member({required this.name, this.relation = 'me', this.isOwner = false, this.pinHash = '', this.upiId = '', this.avatar = const AvatarConfig()});

  String name;
  String relation;
  bool isOwner;
  String pinHash;

  /// Where group settlements are paid to, e.g. name@bank. Empty when not given.
  String upiId;
  AvatarConfig avatar;

  bool get hasPin => pinHash.isNotEmpty;

  @override
  String get kind => 'member';

  @override
  Json toJson() => {'name': name, 'relation': relation, 'isOwner': isOwner, 'pinHash': pinHash, 'upiId': upiId, 'avatar': avatar.toJson()};

  factory Member.fromJson(Json j) => Member(
        name: j['name'] as String,
        relation: j['relation'] as String? ?? 'other',
        isOwner: j['isOwner'] as bool? ?? false,
        pinHash: j['pinHash'] as String? ?? '',
        upiId: j['upiId'] as String? ?? '',
        avatar: AvatarConfig.fromJson((j['avatar'] as Map).cast<String, dynamic>()),
      );
}

class Category extends Doc {
  Category({required this.key, this.customName = '', required this.iconKey, required this.color, this.builtIn = false, this.sortOrder = 0});

  /// Stable id stored on expenses: a built-in constant or `custom_<millis>`.
  final String key;
  String customName;
  String iconKey;
  int color;
  final bool builtIn;
  int sortOrder;

  String get name => builtIn ? tr(BuiltInCategories.labelKey(key)) : customName;
  IconData get icon => CategoryIcons.of(iconKey);
  Color get tint => Color(color);

  @override
  String get kind => 'category';

  @override
  Json toJson() => {'key': key, 'customName': customName, 'iconKey': iconKey, 'color': color, 'builtIn': builtIn, 'sortOrder': sortOrder};

  factory Category.fromJson(Json j) => Category(
        key: j['key'] as String,
        customName: j['customName'] as String? ?? '',
        iconKey: j['iconKey'] as String,
        color: j['color'] as int,
        builtIn: j['builtIn'] as bool? ?? false,
        sortOrder: j['sortOrder'] as int? ?? 0,
      );
}

class CategoryIcons {
  static const Map<String, IconData> byKey = {
    'cart': Icons.shopping_cart_rounded,
    'bulb': Icons.lightbulb_rounded,
    'home': Icons.home_rounded,
    'car': Icons.directions_car_rounded,
    'restaurant': Icons.restaurant_rounded,
    'medical': Icons.medical_services_rounded,
    'school': Icons.school_rounded,
    'movie': Icons.movie_rounded,
    'bag': Icons.shopping_bag_rounded,
    'box': Icons.inventory_2_rounded,
    'phone': Icons.phone_android_rounded,
    'gift': Icons.card_giftcard_rounded,
    'pets': Icons.pets_rounded,
    'flight': Icons.flight_rounded,
    'train': Icons.train_rounded,
    'fuel': Icons.local_gas_station_rounded,
    'fitness': Icons.fitness_center_rounded,
    'cafe': Icons.local_cafe_rounded,
    'baby': Icons.child_care_rounded,
    'wifi': Icons.wifi_rounded,
    'repair': Icons.build_rounded,
    'savings': Icons.savings_rounded,
    'clothes': Icons.checkroom_rounded,
    'party': Icons.celebration_rounded,
    'games': Icons.sports_esports_rounded,
    'spa': Icons.spa_rounded,
  };

  static IconData of(String key) => byKey[key] ?? Icons.inventory_2_rounded;
}

const categoryColors = <int>[
  0xFF43A047, 0xFFF9A825, 0xFF3949AB, 0xFF039BE5, 0xFFF4511E, 0xFFD81B60, 0xFF8E24AA, 0xFF00ACC1, 0xFFFB8C00, 0xFF757575,
  0xFF6D4C41, 0xFF00897B, 0xFFC0CA33, 0xFF5E35B1, 0xFFE53935, 0xFF1E88E5, 0xFF7CB342, 0xFFFFB300, 0xFFEC407A, 0xFF26A69A,
  0xFFAB47BC, 0xFF5C6BC0, 0xFFFF7043, 0xFF8D6E63, 0xFF78909C, 0xFF0D47A1, 0xFF1B5E20, 0xFFB71C1C, 0xFF4A148C, 0xFF006064,
  0xFFFF4081, 0xFF00E5FF, 0xFF76FF03, 0xFFFFD600, 0xFF455A64, 0xFFF48FB1, 0xFF80CBC4, 0xFFB39DDB, 0xFFFFCC80, 0xFF90CAF9,
];

class BuiltInCategories {
  static const groceries = 'GROCERIES';
  static const utilities = 'UTILITIES';
  static const rent = 'RENT';
  static const transport = 'TRANSPORT';
  static const dining = 'DINING';
  static const health = 'HEALTH';
  static const education = 'EDUCATION';
  static const entertainment = 'ENTERTAINMENT';
  static const shopping = 'SHOPPING';
  static const other = 'OTHER';

  static const _seeds = <(String, String, String)>[
    (groceries, 'cat_groceries', 'cart'),
    (utilities, 'cat_utilities', 'bulb'),
    (rent, 'cat_rent', 'home'),
    (transport, 'cat_transport', 'car'),
    (dining, 'cat_dining', 'restaurant'),
    (health, 'cat_health', 'medical'),
    (education, 'cat_education', 'school'),
    (entertainment, 'cat_fun', 'movie'),
    (shopping, 'cat_shopping', 'bag'),
    (other, 'cat_other', 'box'),
  ];

  static String labelKey(String key) => _seeds.firstWhere((s) => s.$1 == key, orElse: () => _seeds.last).$2;

  static List<Category> seed() => [
        for (var i = 0; i < _seeds.length; i++) Category(key: _seeds[i].$1, iconKey: _seeds[i].$3, color: categoryColors[i], builtIn: true, sortOrder: i),
      ];
}

class Expense extends Doc {
  Expense({
    required this.title,
    required this.amount,
    required this.category,
    this.mode = PaymentMode.cash,
    required this.day,
    required this.paidBy,
    this.groupId,
    this.splitType = SplitType.none,
    Map<int, double>? shares,
    this.note = '',
    this.photo = '',
    this.accountId,
    int? createdAt,
  })  : shares = shares ?? {},
        createdAt = createdAt ?? DateTime.now().millisecondsSinceEpoch;

  String title;

  /// Positive for a spend, negative for a credit (cashback, refund, money received).
  double amount;
  String category;
  PaymentMode mode;
  int day;
  int paidBy;
  int? groupId;
  SplitType splitType;
  Map<int, double> shares;
  String note;

  /// File name of the receipt photo inside the app's documents folder; empty when there is none.
  String photo;

  /// The [Account] the money moved through, when one was picked.
  int? accountId;
  final int createdAt;

  bool get isCredit => amount < 0;
  DateTime get date => Days.fromKey(day);

  @override
  String get kind => 'expense';

  @override
  Json toJson() => {
        'title': title,
        'amount': amount,
        'category': category,
        'mode': mode.name,
        'day': day,
        'paidBy': paidBy,
        'groupId': groupId,
        'splitType': splitType.name,
        'shares': shares.map((k, v) => MapEntry('$k', v)),
        'note': note,
        'photo': photo,
        'accountId': accountId,
        'createdAt': createdAt,
      };

  factory Expense.fromJson(Json j) => Expense(
        title: j['title'] as String,
        amount: (j['amount'] as num).toDouble(),
        category: j['category'] as String,
        mode: _enum(PaymentMode.values, j['mode'], PaymentMode.cash),
        day: j['day'] as int,
        paidBy: j['paidBy'] as int,
        groupId: j['groupId'] as int?,
        splitType: _enum(SplitType.values, j['splitType'], SplitType.none),
        shares: ((j['shares'] ?? const {}) as Map).map((k, v) => MapEntry(int.parse('$k'), (v as num).toDouble())),
        note: j['note'] as String? ?? '',
        photo: j['photo'] as String? ?? '',
        accountId: j['accountId'] as int?,
        createdAt: j['createdAt'] as int?,
      );
}

class Group extends Doc {
  Group({required this.name, this.icon = 'home', required this.memberIds, int? createdAt}) : createdAt = createdAt ?? DateTime.now().millisecondsSinceEpoch;

  String name;

  /// A key of `groupIcons`.
  String icon;
  List<int> memberIds;
  final int createdAt;

  @override
  String get kind => 'group';

  @override
  Json toJson() => {'name': name, 'icon': icon, 'memberIds': memberIds, 'createdAt': createdAt};

  factory Group.fromJson(Json j) =>
      Group(name: j['name'] as String, icon: j['icon'] as String? ?? 'home', memberIds: (j['memberIds'] as List).cast<int>().toList(), createdAt: j['createdAt'] as int?);
}

class Settlement extends Doc {
  Settlement({required this.groupId, required this.from, required this.to, required this.amount, int? at}) : at = at ?? DateTime.now().millisecondsSinceEpoch;

  final int groupId;
  final int from;
  final int to;
  final double amount;
  final int at;

  @override
  String get kind => 'settlement';

  @override
  Json toJson() => {'groupId': groupId, 'from': from, 'to': to, 'amount': amount, 'at': at};

  factory Settlement.fromJson(Json j) =>
      Settlement(groupId: j['groupId'] as int, from: j['from'] as int, to: j['to'] as int, amount: (j['amount'] as num).toDouble(), at: j['at'] as int?);
}

class Reminder extends Doc {
  Reminder({
    required this.title,
    required this.hour,
    required this.minute,
    this.repeat = RepeatRule.monthly,
    this.weekday = 1,
    this.dayOfMonth = 1,
    this.month = 1,
    this.onceDay,
    this.amount,
    this.category,
    this.enabled = true,
    this.autoLog = false,
    this.lastLoggedDay = 0,
    this.preset,
  });

  /// Ready-made reminder names, as translation keys.
  static const presets = ['preset_rent', 'preset_emi', 'preset_electricity', 'preset_insurance', 'preset_school_fees', 'preset_daily_nudge'];

  String title;

  /// One of [presets] while the reminder still carries that ready-made name, so the name follows the app language.
  String? preset;

  /// The name to show. A ready-made name is translated, including one saved in English before `preset` existed.
  String get label {
    final key = preset ?? presets.where((k) => L10n.english(k) == title).firstOrNull;
    return key == null ? title : tr(key);
  }
  int hour;
  int minute;
  RepeatRule repeat;

  /// 1 = Monday … 7 = Sunday.
  int weekday;
  int dayOfMonth;
  int month;
  int? onceDay;
  double? amount;
  String? category;
  bool enabled;
  bool autoLog;
  int lastLoggedDay;

  bool get isBill => amount != null && amount! > 0;

  DateTime? nextAfter(DateTime from) {
    DateTime at(DateTime d) => DateTime(d.year, d.month, d.day, hour, minute);
    switch (repeat) {
      case RepeatRule.once:
        final when = at(onceDay == null ? from : Days.fromKey(onceDay!));
        return when.isAfter(from) ? when : null;
      case RepeatRule.daily:
        final today = at(from);
        return today.isAfter(from) ? today : today.add(const Duration(days: 1));
      case RepeatRule.weekly:
        for (var i = 0; i < 8; i++) {
          final candidate = at(DateTime(from.year, from.month, from.day + i));
          if (candidate.weekday == weekday && candidate.isAfter(from)) return candidate;
        }
        return null;
      case RepeatRule.monthly:
        for (var i = 0; i < 3; i++) {
          final base = DateTime(from.year, from.month + i);
          final candidate = DateTime(base.year, base.month, dayOfMonth.clamp(1, Days.inMonth(base)).toInt(), hour, minute);
          if (candidate.isAfter(from)) return candidate;
        }
        return null;
      case RepeatRule.yearly:
        for (var i = 0; i < 2; i++) {
          final base = DateTime(from.year + i, month);
          final candidate = DateTime(base.year, month, dayOfMonth.clamp(1, Days.inMonth(base)).toInt(), hour, minute);
          if (candidate.isAfter(from)) return candidate;
        }
        return null;
    }
  }

  bool occursOn(DateTime d) {
    switch (repeat) {
      case RepeatRule.once:
        return onceDay == Days.key(d);
      case RepeatRule.daily:
        return true;
      case RepeatRule.weekly:
        return d.weekday == weekday;
      case RepeatRule.monthly:
        return d.day == dayOfMonth.clamp(1, Days.inMonth(d)).toInt();
      case RepeatRule.yearly:
        return d.month == month && d.day == dayOfMonth.clamp(1, Days.inMonth(d)).toInt();
    }
  }

  String get schedule {
    final time = Fmt.time(hour, minute);
    switch (repeat) {
      case RepeatRule.once:
        return tr('sched_once', [time]);
      case RepeatRule.daily:
        return tr('sched_daily', [time]);
      case RepeatRule.weekly:
        return tr('sched_weekly', [Fmt.weekday(DateTime(2024, 1, weekday)), time]);
      case RepeatRule.monthly:
        return tr('sched_monthly', [dayOfMonth, time]);
      case RepeatRule.yearly:
        return tr('sched_yearly', [dayOfMonth, Fmt.month(DateTime(2024, month)), time]);
    }
  }

  @override
  String get kind => 'reminder';

  @override
  Json toJson() => {
        'title': title,
        'hour': hour,
        'minute': minute,
        'repeat': repeat.name,
        'weekday': weekday,
        'dayOfMonth': dayOfMonth,
        'month': month,
        'onceDay': onceDay,
        'amount': amount,
        'category': category,
        'enabled': enabled,
        'autoLog': autoLog,
        'lastLoggedDay': lastLoggedDay,
        'preset': preset,
      };

  factory Reminder.fromJson(Json j) => Reminder(
        title: j['title'] as String,
        hour: j['hour'] as int,
        minute: j['minute'] as int,
        repeat: _enum(RepeatRule.values, j['repeat'], RepeatRule.monthly),
        weekday: j['weekday'] as int? ?? 1,
        dayOfMonth: j['dayOfMonth'] as int? ?? 1,
        month: j['month'] as int? ?? 1,
        onceDay: j['onceDay'] as int?,
        amount: (j['amount'] as num?)?.toDouble(),
        category: j['category'] as String?,
        enabled: j['enabled'] as bool? ?? true,
        autoLog: j['autoLog'] as bool? ?? false,
        lastLoggedDay: j['lastLoggedDay'] as int? ?? 0,
        preset: j['preset'] as String?,
      );
}

class PointEntry extends Doc {
  PointEntry({required this.delta, required this.reason, int? at}) : at = at ?? DateTime.now().millisecondsSinceEpoch;

  final int delta;

  /// `kind` or `kind:arg`, see [PointReasons].
  final String reason;
  final int at;

  @override
  String get kind => 'points';

  @override
  Json toJson() => {'delta': delta, 'reason': reason, 'at': at};

  factory PointEntry.fromJson(Json j) => PointEntry(delta: j['delta'] as int, reason: j['reason'] as String, at: j['at'] as int?);
}

class Shop extends Doc {
  Shop({required this.name});

  String name;

  @override
  String get kind => 'shop';

  @override
  Json toJson() => {'name': name};

  factory Shop.fromJson(Json j) => Shop(name: j['name'] as String);
}

class KhataEntry extends Doc {
  KhataEntry({required this.shopId, required this.amount, required this.payment, this.note = '', required this.day});

  final int shopId;
  final double amount;
  final bool payment;
  final String note;
  final int day;

  @override
  String get kind => 'khata';

  @override
  Json toJson() => {'shopId': shopId, 'amount': amount, 'payment': payment, 'note': note, 'day': day};

  factory KhataEntry.fromJson(Json j) => KhataEntry(
      shopId: j['shopId'] as int, amount: (j['amount'] as num).toDouble(), payment: j['payment'] as bool, note: j['note'] as String? ?? '', day: j['day'] as int);
}

enum ServiceBilling { perUnit, monthly }

class HomeService extends Doc {
  HomeService({
    required this.name,
    required this.icon,
    required this.billing,
    required this.rate,
    this.defaultQty = 1,
    this.leaveDeduction = 0,
    required this.category,
    required this.startDay,
    Map<int, double>? days,
    Map<int, double>? paidMonths,
    Map<int, double>? advances,
  })  : days = days ?? {},
        paidMonths = paidMonths ?? {},
        advances = advances ?? {};

  String name;

  /// A key of `serviceIcons`.
  String icon;
  ServiceBilling billing;
  double rate;
  double defaultQty;
  double leaveDeduction;
  String category;
  final int startDay;

  /// Day key → quantity that differs from the default (0 = leave for monthly services).
  final Map<int, double> days;

  /// Month key (yyyymm) → amount paid.
  final Map<int, double> paidMonths;

  /// Month key (yyyymm) → money already handed over as an advance against that month's bill.
  final Map<int, double> advances;

  double qtyOn(DateTime d) => days[Days.key(d)] ?? defaultQty;

  DateTime _from(DateTime month) {
    final start = Days.fromKey(startDay);
    final first = Days.monthStart(month);
    return Days.monthKey(start) == Days.monthKey(month) ? Days.monthStart(start) : first;
  }

  double unitsUntil(DateTime month, DateTime until) {
    var total = 0.0;
    for (var d = _from(month); !d.isAfter(until) && d.month == month.month; d = DateTime(d.year, d.month, d.day + 1)) {
      total += qtyOn(d);
    }
    return total;
  }

  int leavesIn(DateTime month) => days.entries.where((e) => e.key ~/ 100 == Days.monthKey(month) && e.value == 0).length;

  DateTime _lastCounted(DateTime month) {
    final end = DateTime(month.year, month.month, Days.inMonth(month));
    final today = Days.today();
    return Days.monthKey(today) == Days.monthKey(month) && today.isBefore(end) ? today : end;
  }

  double billSoFar(DateTime month) =>
      billing == ServiceBilling.perUnit ? unitsUntil(month, _lastCounted(month)) * rate : (rate - leavesIn(month) * leaveDeduction).clamp(0, double.infinity).toDouble();

  double billFullMonth(DateTime month) => billing == ServiceBilling.perUnit
      ? unitsUntil(month, DateTime(month.year, month.month, Days.inMonth(month))) * rate
      : billSoFar(month);

  @override
  String get kind => 'service';

  @override
  Json toJson() => {
        'name': name,
        'icon': icon,
        'billing': billing.name,
        'rate': rate,
        'defaultQty': defaultQty,
        'leaveDeduction': leaveDeduction,
        'category': category,
        'startDay': startDay,
        'days': days.map((k, v) => MapEntry('$k', v)),
        'paidMonths': paidMonths.map((k, v) => MapEntry('$k', v)),
        'advances': advances.map((k, v) => MapEntry('$k', v)),
      };

  factory HomeService.fromJson(Json j) => HomeService(
        name: j['name'] as String,
        icon: j['icon'] as String? ?? 'other',
        billing: _enum(ServiceBilling.values, j['billing'], ServiceBilling.perUnit),
        rate: (j['rate'] as num).toDouble(),
        defaultQty: (j['defaultQty'] as num? ?? 1).toDouble(),
        leaveDeduction: (j['leaveDeduction'] as num? ?? 0).toDouble(),
        category: j['category'] as String? ?? BuiltInCategories.other,
        startDay: j['startDay'] as int,
        days: ((j['days'] ?? const {}) as Map).map((k, v) => MapEntry(int.parse('$k'), (v as num).toDouble())),
        paidMonths: ((j['paidMonths'] ?? const {}) as Map).map((k, v) => MapEntry(int.parse('$k'), (v as num).toDouble())),
        advances: ((j['advances'] ?? const {}) as Map).map((k, v) => MapEntry(int.parse('$k'), (v as num).toDouble())),
      );
}

class GoldItem extends Doc {
  GoldItem({required this.label, required this.grams, this.karat = 22, this.pricePaid = 0});

  String label;
  double grams;
  int karat;
  double pricePaid;

  double valueAt(double rate24k) => grams * rate24k * karat / 24;

  @override
  String get kind => 'gold';

  @override
  Json toJson() => {'label': label, 'grams': grams, 'karat': karat, 'pricePaid': pricePaid};

  factory GoldItem.fromJson(Json j) =>
      GoldItem(label: j['label'] as String, grams: (j['grams'] as num).toDouble(), karat: j['karat'] as int? ?? 22, pricePaid: (j['pricePaid'] as num? ?? 0).toDouble());
}

/// A payment spotted in a notification, waiting for the user to add it as an expense or dismiss it.
class Capture extends Doc {
  Capture({required this.amount, required this.merchant, required this.source, required this.at});

  /// Negative for money received.
  final double amount;
  final String merchant;

  /// Who the message came from, as the notification named them.
  final String source;
  final int at;

  DateTime get date => DateTime.fromMillisecondsSinceEpoch(at);

  @override
  String get kind => 'capture';

  @override
  Json toJson() => {'amount': amount, 'merchant': merchant, 'source': source, 'at': at};

  factory Capture.fromJson(Json j) => Capture(amount: (j['amount'] as num).toDouble(), merchant: j['merchant'] as String, source: j['source'] as String? ?? '', at: j['at'] as int);
}

/// Something being saved up for.
class Goal extends Doc {
  Goal({required this.name, required this.target, this.saved = 0, this.dueMonth, List<(int, double)>? history}) : history = history ?? [];

  String name;
  double target;
  double saved;

  /// Month key (yyyymm) the money is wanted by, if a date was set.
  int? dueMonth;

  /// Each "Add money": the day key and the amount, oldest first.
  final List<(int, double)> history;

  double get left => (target - saved).clamp(0, target).toDouble();

  /// What to put aside each month from [today] to reach the target in time; null without a due month.
  double? monthly(DateTime today) {
    final due = dueMonth;
    if (due == null) return null;
    final months = (due ~/ 100 - today.year) * 12 + due % 100 - today.month + 1;
    return left / (months < 1 ? 1 : months);
  }

  @override
  String get kind => 'goal';

  @override
  Json toJson() => {
        'name': name,
        'target': target,
        'saved': saved,
        'dueMonth': dueMonth,
        'history': [for (final (day, amount) in history) [day, amount]],
      };

  factory Goal.fromJson(Json j) => Goal(name: j['name'] as String, target: (j['target'] as num).toDouble(), saved: (j['saved'] as num? ?? 0).toDouble(),
        dueMonth: j['dueMonth'] as int?,
        history: [for (final h in j['history'] as List? ?? const []) ((h as List)[0] as int, (h[1] as num).toDouble())],
      );
}

/// One line of the shopping list.
class ShopItem extends Doc {
  ShopItem({required this.name, this.done = false, this.count = 1});

  String name;
  bool done;

  /// How many of it to buy; adding a name that is already waiting raises this.
  int count;

  String get label => count > 1 ? '$name × $count' : name;

  @override
  String get kind => 'shopitem';

  @override
  Json toJson() => {'name': name, 'done': done, 'count': count};

  factory ShopItem.fromJson(Json j) => ShopItem(name: j['name'] as String, done: j['done'] as bool? ?? false, count: j['count'] as int? ?? 1);
}

/// Money lent to someone (positive [amount]) or borrowed from them (negative), outside any group.
class Loan extends Doc {
  Loan({required this.person, required this.amount, required this.day, this.dueDay, this.settled = false});

  String person;
  double amount;
  final int day;
  int? dueDay;
  bool settled;

  @override
  String get kind => 'loan';

  @override
  Json toJson() => {'person': person, 'amount': amount, 'day': day, 'dueDay': dueDay, 'settled': settled};

  factory Loan.fromJson(Json j) => Loan(person: j['person'] as String, amount: (j['amount'] as num).toDouble(), day: j['day'] as int, dueDay: j['dueDay'] as int?, settled: j['settled'] as bool? ?? false);
}

/// A warranty, policy or other paper with a date it runs out on.
class Paper extends Doc {
  Paper({required this.name, required this.expiryDay, this.photo = ''});

  String name;
  int expiryDay;

  /// File name inside the app's documents folder; empty when there is no picture.
  String photo;

  @override
  String get kind => 'paper';

  @override
  Json toJson() => {'name': name, 'expiryDay': expiryDay, 'photo': photo};

  factory Paper.fromJson(Json j) => Paper(name: j['name'] as String, expiryDay: j['expiryDay'] as int, photo: j['photo'] as String? ?? '');
}

/// Where money sits: cash, a bank account, a wallet.
class Account extends Doc {
  Account({required this.name, this.opening = 0});

  String name;
  double opening;

  @override
  String get kind => 'account';

  @override
  Json toJson() => {'name': name, 'opening': opening};

  factory Account.fromJson(Json j) => Account(name: j['name'] as String, opening: (j['opening'] as num? ?? 0).toDouble());
}

class Chit extends Doc {
  Chit({required this.name, required this.monthlyAmount, required this.months, required this.startMonth, this.paidMonths = 0, this.prizeAmount});

  String name;
  double monthlyAmount;
  int months;

  /// Month key (yyyymm).
  final int startMonth;
  int paidMonths;
  double? prizeAmount;

  bool get done => paidMonths >= months;
  double get paidIn => paidMonths * monthlyAmount;
  double get savingsValue => prizeAmount == null ? paidIn : 0;
  DateTime get nextDue => DateTime(startMonth ~/ 100, startMonth % 100 + paidMonths);

  @override
  String get kind => 'chit';

  @override
  Json toJson() => {'name': name, 'monthlyAmount': monthlyAmount, 'months': months, 'startMonth': startMonth, 'paidMonths': paidMonths, 'prizeAmount': prizeAmount};

  factory Chit.fromJson(Json j) => Chit(
        name: j['name'] as String,
        monthlyAmount: (j['monthlyAmount'] as num).toDouble(),
        months: j['months'] as int,
        startMonth: j['startMonth'] as int,
        paidMonths: j['paidMonths'] as int? ?? 0,
        prizeAmount: (j['prizeAmount'] as num?)?.toDouble(),
      );
}

enum ThemeModeSetting { system, light, dark }

/// How notifications are worded. [quiet] also drops the comeback, weekly and streak-in-danger nudges.
enum NotifTone { spicy, mild, quiet }

/// Everything that is one-per-household: preferences, the points profile and small keyed sets.
class Settings {
  bool onboarded = false;
  String language = 'en';
  String currencyCode = 'INR';
  double monthlyBudget = 0;
  double monthlyIncome = 0;
  Map<String, double> categoryBudgets = {};
  String themeId = 'theme_sunrise';
  ThemeModeSetting themeMode = ThemeModeSetting.system;
  bool appLock = false;

  /// The member whose PIN the phone's fingerprint or face check may stand in for; 0 when off.
  int biometricMemberId = 0;
  int activeMemberId = 0;
  bool budgetAlerts = true;
  bool reminderNotifs = true;
  bool rewardNotifs = true;
  NotifTone tone = NotifTone.spicy;

  /// Routes of the Home quick-access row, at most [quickAccessMax].
  List<String> quickAccess = ['reminders', 'shopping', 'goals', 'loans'];
  static const quickAccessMax = 4;

  /// The background last used for each kind of share card, keyed by the card's file name.
  Map<String, int> cardLooks = {};
  bool tourSeen = false;

  /// Home-screen widgets show dots in place of money.
  bool hideWidgetAmounts = false;
  bool soundEffects = true;
  bool festiveMode = true;
  double goldRate = 0;

  int points = 0;
  int lifetimePoints = 0;
  int streakDays = 0;
  int lastLogDay = 0;
  int voiceLogs = 0;
  bool languageChanged = false;
  Set<String> unlocked = {};
  Map<String, int> badges = {};
  Set<int> budgetMonthsWon = {};
  int lastBudgetCheckMonth = 0;
  Set<String> budgetAlertsSent = {};
  Set<String> festivalsSeen = {};
  Set<String> festivalsClaimed = {};
  String festivalThemeSkipped = '';

  Json toJson() => {
        'onboarded': onboarded,
        'language': language,
        'currencyCode': currencyCode,
        'monthlyBudget': monthlyBudget,
        'monthlyIncome': monthlyIncome,
        'categoryBudgets': categoryBudgets,
        'themeId': themeId,
        'themeMode': themeMode.name,
        'appLock': appLock,
        'biometricMemberId': biometricMemberId,
        'activeMemberId': activeMemberId,
        'budgetAlerts': budgetAlerts,
        'reminderNotifs': reminderNotifs,
        'rewardNotifs': rewardNotifs,
        'tone': tone.name,
        'quickAccess': quickAccess,
        'cardLooks': cardLooks,
        'tourSeen': tourSeen,
        'hideWidgetAmounts': hideWidgetAmounts,
        'soundEffects': soundEffects,
        'festiveMode': festiveMode,
        'goldRate': goldRate,
        'points': points,
        'lifetimePoints': lifetimePoints,
        'streakDays': streakDays,
        'lastLogDay': lastLogDay,
        'voiceLogs': voiceLogs,
        'languageChanged': languageChanged,
        'unlocked': unlocked.toList(),
        'badges': badges,
        'budgetMonthsWon': budgetMonthsWon.toList(),
        'lastBudgetCheckMonth': lastBudgetCheckMonth,
        'budgetAlertsSent': budgetAlertsSent.toList(),
        'festivalsSeen': festivalsSeen.toList(),
        'festivalsClaimed': festivalsClaimed.toList(),
        'festivalThemeSkipped': festivalThemeSkipped,
      };

  static Settings fromJson(Json j) {
    Set<T> set<T>(String key) => ((j[key] ?? const []) as List).cast<T>().toSet();
    return Settings()
      ..onboarded = j['onboarded'] as bool? ?? false
      ..language = j['language'] as String? ?? 'en'
      ..currencyCode = j['currencyCode'] as String? ?? 'INR'
      ..monthlyBudget = (j['monthlyBudget'] as num? ?? 0).toDouble()
      ..monthlyIncome = (j['monthlyIncome'] as num? ?? 0).toDouble()
      ..categoryBudgets = ((j['categoryBudgets'] ?? const {}) as Map).map((k, v) => MapEntry('$k', (v as num).toDouble()))
      ..themeId = j['themeId'] as String? ?? 'theme_sunrise'
      ..themeMode = _enum(ThemeModeSetting.values, j['themeMode'], ThemeModeSetting.system)
      ..appLock = j['appLock'] as bool? ?? false
      ..biometricMemberId = j['biometricMemberId'] as int? ?? 0
      ..activeMemberId = j['activeMemberId'] as int? ?? 0
      ..budgetAlerts = j['budgetAlerts'] as bool? ?? true
      ..reminderNotifs = j['reminderNotifs'] as bool? ?? true
      ..rewardNotifs = j['rewardNotifs'] as bool? ?? true
      ..tone = _enum(NotifTone.values, j['tone'], NotifTone.spicy)
      ..quickAccess = (j['quickAccess'] as List?)?.cast<String>().toList() ?? ['reminders', 'shopping', 'goals', 'loans']
      ..cardLooks = {...?(j['cardLooks'] as Map?)?.cast<String, int>()}
      ..tourSeen = j['tourSeen'] as bool? ?? false
      ..hideWidgetAmounts = j['hideWidgetAmounts'] as bool? ?? false
      ..soundEffects = j['soundEffects'] as bool? ?? true
      ..festiveMode = j['festiveMode'] as bool? ?? true
      ..goldRate = (j['goldRate'] as num? ?? 0).toDouble()
      ..points = j['points'] as int? ?? 0
      ..lifetimePoints = j['lifetimePoints'] as int? ?? 0
      ..streakDays = j['streakDays'] as int? ?? 0
      ..lastLogDay = j['lastLogDay'] as int? ?? 0
      ..voiceLogs = j['voiceLogs'] as int? ?? 0
      ..languageChanged = j['languageChanged'] as bool? ?? false
      ..unlocked = set<String>('unlocked')
      ..badges = ((j['badges'] ?? const {}) as Map).map((k, v) => MapEntry('$k', v as int))
      ..budgetMonthsWon = set<int>('budgetMonthsWon')
      ..lastBudgetCheckMonth = j['lastBudgetCheckMonth'] as int? ?? 0
      ..budgetAlertsSent = set<String>('budgetAlertsSent')
      ..festivalsSeen = set<String>('festivalsSeen')
      ..festivalsClaimed = set<String>('festivalsClaimed')
      ..festivalThemeSkipped = j['festivalThemeSkipped'] as String? ?? '';
  }
}

const currencies = <String, String>{'INR': '₹', 'USD': r'$', 'EUR': '€'};

const relations = <String>['me', 'partner', 'child', 'parent', 'sibling', 'roommate', 'friend', 'other'];

const skinTones = <int>[0xFFFFE0BD, 0xFFF1C27D, 0xFFD9A066, 0xFFB5753F, 0xFF8D5524, 0xFF5C3A21];

const hairColors = <int>[0xFF2A1B17, 0xFF5B3A29, 0xFFB4532A, 0xFFE0B678, 0xFF8E8E8E, 0xFF6D28D9, 0xFF0E9AA7];
