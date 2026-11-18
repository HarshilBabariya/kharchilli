import 'dart:math';

import 'format.dart';
import 'l10n.dart';
import 'models.dart';

class PointsRules {
  static const logExpense = 10;
  static const firstLogOfDay = 5;
  static const streakPerDay = 2;
  static const streakCap = 20;
  static const createGroup = 30;
  static const settleUp = 15;
  static const addMember = 20;
  static const monthUnderBudget = 100;
  static const festivalGift = 50;

  static int streakBonus(int streakDays) => min(streakDays * streakPerDay, streakCap);
}

class PointReasons {
  static const logExpense = 'log_expense';
  static const group = 'group';
  static const settle = 'settle';
  static const member = 'member';
  static const budget = 'budget';
  static const badge = 'badge';
  static const unlock = 'unlock';
  static const festival = 'festival';

  static String encode(String kind, [String arg = '']) => arg.isEmpty ? kind : '$kind:$arg';
  static String kindOf(String reason) => reason.split(':').first;
  static String argOf(String reason) => reason.contains(':') ? reason.substring(reason.indexOf(':') + 1) : '';

  static String describe(String reason) {
    final arg = argOf(reason);
    switch (kindOf(reason)) {
      case logExpense:
        return tr('reason_log_expense');
      case group:
        return tr('reason_group');
      case settle:
        return tr('reason_settle');
      case member:
        return tr('reason_member');
      case budget:
        return tr('reason_budget', [arg]);
      case badge:
        return tr('reason_badge', [BadgeCatalog.find(arg)?.name ?? arg]);
      case unlock:
        return tr('reason_unlock', [RewardCatalog.find(arg)?.name ?? arg]);
      case festival:
        return tr('reason_festival', [FestivalPack.values.where((p) => p.name == arg).map((p) => p.label).firstOrNull ?? arg]);
      default:
        return reason;
    }
  }
}

class StreakMilestones {
  static const days = [3, 7, 14, 21, 30, 50, 75, 100, 150, 200, 365];
  static bool reached(int streak) => days.contains(streak) || (streak > days.last && streak % 100 == 0);
  static int next(int streak) => days.where((d) => d > streak).firstOrNull ?? (streak ~/ 100 + 1) * 100;
}

class LevelInfo {
  const LevelInfo(this.level, this.title, this.start, this.nextAt);
  final int level;
  final String title;
  final int start;
  final int nextAt;

  double progress(int lifetime) => ((lifetime - start) / max(nextAt - start, 1)).clamp(0.0, 1.0).toDouble();
}

class Levels {
  static const _base = 100;
  static const titles = ['lvl_rookie', 'lvl_saver', 'lvl_planner', 'lvl_tracker', 'lvl_strategist', 'lvl_accountant', 'lvl_treasurer', 'lvl_guardian', 'lvl_master', 'lvl_legend'];

  static LevelInfo of(int lifetime) {
    final level = sqrt(lifetime / _base).floor() + 1;
    return LevelInfo(level, tr(titles[min(level - 1, titles.length - 1)]), (level - 1) * (level - 1) * _base, level * level * _base);
  }
}

class MemberBalance {
  const MemberBalance(this.memberId, this.name, this.net);
  final int memberId;
  final String name;
  final double net;
}

class Transfer {
  const Transfer(this.fromId, this.fromName, this.toId, this.toName, this.amount);
  final int fromId;
  final String fromName;
  final int toId;
  final String toName;
  final double amount;
}

class SplitCalculator {
  static Map<int, double> equalShares(double amount, List<int> memberIds) {
    if (memberIds.isEmpty) return {};
    final cents = (amount * 100).round();
    final base = cents ~/ memberIds.length;
    final remainder = cents % memberIds.length;
    return {for (var i = 0; i < memberIds.length; i++) memberIds[i]: (base + (i < remainder ? 1 : 0)) / 100};
  }

  static List<Transfer> settlements(List<MemberBalance> balances) {
    final creditors = balances.where((b) => b.net > 0.005).toList()..sort((a, b) => b.net.compareTo(a.net));
    final debtors = balances.where((b) => b.net < -0.005).toList()..sort((a, b) => a.net.compareTo(b.net));
    final result = <Transfer>[];
    var ci = 0, di = 0;
    var creditLeft = creditors.isEmpty ? 0.0 : creditors.first.net;
    var debtLeft = debtors.isEmpty ? 0.0 : -debtors.first.net;
    while (ci < creditors.length && di < debtors.length) {
      final pay = min(creditLeft, debtLeft);
      result.add(Transfer(debtors[di].memberId, debtors[di].name, creditors[ci].memberId, creditors[ci].name, (pay * 100).round() / 100));
      creditLeft -= pay;
      debtLeft -= pay;
      if (creditLeft < 0.005) {
        ci++;
        creditLeft = ci < creditors.length ? creditors[ci].net : 0.0;
      }
      if (debtLeft < 0.005) {
        di++;
        debtLeft = di < debtors.length ? -debtors[di].net : 0.0;
      }
    }
    return result;
  }
}

enum RewardKind {
  theme('kind_themes'),
  outfit('kind_outfits'),
  hair('kind_hair'),
  accessory('kind_accessories'),
  feature('kind_features');

  const RewardKind(this.labelKey);
  final String labelKey;
}

enum FestivalPack {
  uttarayan('fest_uttarayan', '🪁', 'theme_kites', 'uttarayan'),
  tiranga('pack_tiranga', '🇮🇳', 'theme_tiranga', 'tiranga'),
  holi('fest_holi', '🎨', 'theme_holi', 'holi'),
  rakhi('fest_rakhi', '🎀', 'theme_rakhi', 'rakhi'),
  ganesh('fest_ganesh', '🌺', 'theme_bappa', 'ganesh'),
  navratri('fest_navratri', '💃', 'theme_garba', 'navratri'),
  diwali('fest_diwali', '🪔', 'theme_diwali', 'diwali'),
  christmas('fest_christmas', '🎄', 'theme_christmas', 'christmas'),
  newYear('fest_new_year', '🎆', 'theme_new_year', 'new_year');

  const FestivalPack(this.labelKey, this.emoji, this.themeId, this.sound);
  final String labelKey;
  final String emoji;
  final String themeId;
  final String sound;
  String get label => tr(labelKey);
}

class RewardItem {
  const RewardItem(this.id, this.kind, this.key, this.cost, this.emoji, [this.pack]);
  final String id;
  final RewardKind kind;
  final String key;
  final int cost;
  final String emoji;
  final FestivalPack? pack;

  bool get isFree => cost == 0;
  String get name => tr(key);
  String get description => tr('${key}_d');
}

class RewardCatalog {
  static const _t = RewardKind.theme, _o = RewardKind.outfit, _h = RewardKind.hair, _a = RewardKind.accessory, _f = RewardKind.feature;

  static const items = <RewardItem>[
    RewardItem('theme_sunrise', _t, 'rw_sunrise', 0, '🌅'),
    RewardItem('theme_ocean', _t, 'rw_ocean', 200, '🌊'),
    RewardItem('theme_forest', _t, 'rw_forest', 250, '🌲'),
    RewardItem('theme_midnight', _t, 'rw_midnight', 300, '🌙'),
    RewardItem('theme_candy', _t, 'rw_candy', 350, '🍬'),
    RewardItem('theme_royal', _t, 'rw_royal', 500, '👑'),
    RewardItem('theme_glass', _t, 'rw_glass', 600, '🫧'),
    RewardItem('outfit_tee', _o, 'rw_tee', 0, '👕'),
    RewardItem('outfit_shirt', _o, 'rw_shirt', 0, '👔'),
    RewardItem('outfit_polo', _o, 'rw_polo', 0, '🎽'),
    RewardItem('outfit_hoodie', _o, 'rw_hoodie', 150, '🧥'),
    RewardItem('outfit_sweater', _o, 'rw_sweater', 150, '🧶'),
    RewardItem('outfit_jersey', _o, 'rw_jersey', 180, '🏏'),
    RewardItem('outfit_denim', _o, 'rw_denim', 200, '🧢'),
    RewardItem('outfit_lab_coat', _o, 'rw_lab_coat', 220, '🥼'),
    RewardItem('outfit_kurta', _o, 'rw_kurta', 250, '🪔'),
    RewardItem('outfit_dress', _o, 'rw_dress', 250, '👗'),
    RewardItem('outfit_blazer', _o, 'rw_blazer', 250, '🤵'),
    RewardItem('outfit_nehru', _o, 'rw_nehru', 260, '🧥'),
    RewardItem('outfit_leather', _o, 'rw_leather', 280, '🏍️'),
    RewardItem('outfit_saree', _o, 'rw_saree', 300, '🥻'),
    RewardItem('outfit_sherwani', _o, 'rw_sherwani', 300, '👘'),
    RewardItem('outfit_lehenga', _o, 'rw_lehenga', 320, '💃'),
    RewardItem('outfit_spacesuit', _o, 'rw_spacesuit', 400, '🚀'),
    RewardItem('outfit_hero', _o, 'rw_hero', 500, '🦸'),
    RewardItem('hair_short', _h, 'rw_short', 0, '💇'),
    RewardItem('hair_buzz', _h, 'rw_buzz', 0, '✂️'),
    RewardItem('hair_long', _h, 'rw_long', 0, '💁'),
    RewardItem('hair_curly', _h, 'rw_curly', 0, '🌀'),
    RewardItem('hair_side_part', _h, 'rw_side_part', 0, '💼'),
    RewardItem('hair_pixie', _h, 'rw_pixie', 0, '🧚'),
    RewardItem('hair_wavy', _h, 'rw_wavy', 100, '🌊'),
    RewardItem('hair_bob', _h, 'rw_bob', 100, '💈'),
    RewardItem('hair_spiky', _h, 'rw_spiky', 100, '⚡'),
    RewardItem('hair_ponytail', _h, 'rw_ponytail', 120, '🎀'),
    RewardItem('hair_bun', _h, 'rw_bun', 120, '🍡'),
    RewardItem('hair_quiff', _h, 'rw_quiff', 140, '🕺'),
    RewardItem('hair_man_bun', _h, 'rw_man_bun', 140, '🧘'),
    RewardItem('hair_braids', _h, 'rw_braids', 150, '🪢'),
    RewardItem('hair_afro', _h, 'rw_afro', 160, '🌳'),
    RewardItem('hair_mohawk', _h, 'rw_mohawk', 180, '🎸'),
    RewardItem('acc_none', _a, 'rw_none', 0, '✨'),
    RewardItem('acc_bindi', _a, 'rw_bindi', 50, '🔴'),
    RewardItem('acc_flower', _a, 'rw_flower', 60, '🌸'),
    RewardItem('acc_earrings', _a, 'rw_earrings', 80, '💛'),
    RewardItem('acc_nose_ring', _a, 'rw_nose_ring', 90, '💍'),
    RewardItem('acc_bow_tie', _a, 'rw_bow_tie', 90, '🎀'),
    RewardItem('acc_glasses', _a, 'rw_glasses', 100, '👓'),
    RewardItem('acc_beanie', _a, 'rw_beanie', 120, '🧶'),
    RewardItem('acc_cap', _a, 'rw_cap', 150, '🧢'),
    RewardItem('acc_sunglasses', _a, 'rw_sunglasses', 150, '🕶️'),
    RewardItem('acc_headphones', _a, 'rw_headphones', 200, '🎧'),
    RewardItem('acc_chain', _a, 'rw_chain', 220, '⛓️'),
    RewardItem('acc_turban', _a, 'rw_turban', 250, '👳'),
    RewardItem('acc_crown', _a, 'rw_crown', 400, '👑'),
    RewardItem('theme_diwali', _t, 'rw_theme_diwali', 0, '🪔', FestivalPack.diwali),
    RewardItem('theme_holi', _t, 'rw_theme_holi', 0, '🎨', FestivalPack.holi),
    RewardItem('theme_garba', _t, 'rw_theme_garba', 0, '💃', FestivalPack.navratri),
    RewardItem('theme_kites', _t, 'rw_theme_kites', 0, '🪁', FestivalPack.uttarayan),
    RewardItem('theme_rakhi', _t, 'rw_theme_rakhi', 0, '🎀', FestivalPack.rakhi),
    RewardItem('theme_bappa', _t, 'rw_theme_bappa', 0, '🌺', FestivalPack.ganesh),
    RewardItem('theme_tiranga', _t, 'rw_theme_tiranga', 0, '🇮🇳', FestivalPack.tiranga),
    RewardItem('theme_christmas', _t, 'rw_theme_christmas', 0, '🎄', FestivalPack.christmas),
    RewardItem('theme_new_year', _t, 'rw_theme_new_year', 0, '🎆', FestivalPack.newYear),
    RewardItem('outfit_diwali_silk', _o, 'rw_diwali_silk', 0, '🪔', FestivalPack.diwali),
    RewardItem('outfit_holi', _o, 'rw_holi', 0, '🎨', FestivalPack.holi),
    RewardItem('outfit_garba', _o, 'rw_garba', 0, '💃', FestivalPack.navratri),
    RewardItem('outfit_kite', _o, 'rw_kite', 0, '🪁', FestivalPack.uttarayan),
    RewardItem('outfit_rakhi', _o, 'rw_rakhi', 0, '🎀', FestivalPack.rakhi),
    RewardItem('outfit_bappa', _o, 'rw_bappa', 0, '🌺', FestivalPack.ganesh),
    RewardItem('outfit_tiranga', _o, 'rw_tiranga', 0, '🇮🇳', FestivalPack.tiranga),
    RewardItem('outfit_santa', _o, 'rw_santa', 0, '🎅', FestivalPack.christmas),
    RewardItem('outfit_sequin', _o, 'rw_sequin', 0, '🪩', FestivalPack.newYear),
    RewardItem('acc_gulal', _a, 'rw_gulal', 0, '🌈', FestivalPack.holi),
    RewardItem('acc_santa_hat', _a, 'rw_santa_hat', 0, '🎅', FestivalPack.christmas),
    RewardItem('acc_party_hat', _a, 'rw_party_hat', 0, '🥳', FestivalPack.newYear),
    RewardItem('feature_insights', _f, 'rw_insights', 300, '📈'),
    RewardItem('feature_export_csv', _f, 'rw_export', 250, '📤'),
  ];

  static const insights = 'feature_insights';
  static const export = 'feature_export_csv';

  static Set<String> defaults() => items.where((i) => i.isFree && i.pack == null).map((i) => i.id).toSet();
  static List<RewardItem> ofKind(RewardKind kind) => items.where((i) => i.kind == kind).toList();
  static List<RewardItem> ofPack(FestivalPack pack) => items.where((i) => i.pack == pack).toList();
  static RewardItem? find(String id) => items.where((i) => i.id == id).firstOrNull;

  static AvatarConfig dressFor(FestivalPack pack, AvatarConfig config) {
    final festive = ofPack(pack);
    return config.copyWith(
      outfitId: festive.where((i) => i.kind == RewardKind.outfit).firstOrNull?.id,
      accessoryId: festive.where((i) => i.kind == RewardKind.accessory).firstOrNull?.id,
    );
  }
}

class BadgeDef {
  const BadgeDef(this.id, this.emoji, this.bonus, this.target, this.unitKey, this.hard);
  final String id;
  final String emoji;
  final int bonus;
  final int target;
  final String unitKey;
  final bool hard;

  String get _key => id.replaceFirst('badge_', 'b_');
  String get name => tr(_key);
  String get description => tr('${_key}_d');
  List<String> get howTo => [for (var i = 1; i <= 3; i++) tr('${_key}_$i')];
}

class BadgeSnapshot {
  int expenses = 0;
  int distinctCategories = 0;
  int paymentModes = 0;
  double maxExpense = 0;
  int smallExpenses = 0;
  int notedExpenses = 0;
  int earlyLogs = 0;
  int lateLogs = 0;
  int voiceLogs = 0;
  int streak = 0;
  int groups = 0;
  int settlements = 0;
  int membersBesidesYou = 0;
  int reminders = 0;
  int customCategories = 0;
  int paidUnlocks = 0;
  int outfitUnlocks = 0;
  int accessoryUnlocks = 0;
  int themeUnlocks = 0;
  int monthsUnderBudget = 0;
  int level = 1;
  bool languageChanged = false;
}

class BadgeCatalog {
  static const badges = <BadgeDef>[
    BadgeDef('badge_first_step', '🥇', 20, 1, 'unit_expense', false),
    BadgeDef('badge_ten_logged', '🔟', 40, 10, 'unit_expenses', false),
    BadgeDef('badge_century', '💯', 150, 100, 'unit_expenses', true),
    BadgeDef('badge_half_k', '🚀', 500, 500, 'unit_expenses', true),
    BadgeDef('badge_week_warrior', '🔥', 60, 7, 'unit_days', false),
    BadgeDef('badge_month_master', '🏆', 250, 30, 'unit_days', true),
    BadgeDef('badge_streak_60', '⚡', 400, 60, 'unit_days', true),
    BadgeDef('badge_streak_100', '🐉', 1000, 100, 'unit_days', true),
    BadgeDef('badge_early_bird', '🌅', 30, 1, 'unit_expense', false),
    BadgeDef('badge_night_owl', '🦉', 30, 1, 'unit_expense', false),
    BadgeDef('badge_voice', '🎙️', 40, 1, 'unit_expense', false),
    BadgeDef('badge_notes', '📝', 60, 10, 'unit_expenses', false),
    BadgeDef('badge_explorer', '🧭', 60, 5, 'unit_categories', false),
    BadgeDef('badge_custom_cat', '🏷️', 50, 1, 'unit_category', false),
    BadgeDef('badge_payment_pro', '💳', 80, 4, 'unit_modes', false),
    BadgeDef('badge_big_spender', '💎', 100, 1, 'unit_expense', false),
    BadgeDef('badge_penny', '🪙', 80, 20, 'unit_expenses', false),
    BadgeDef('badge_team_player', '🤝', 30, 1, 'unit_group', false),
    BadgeDef('badge_group_guru', '🧑‍🤝‍🧑', 100, 3, 'unit_groups', true),
    BadgeDef('badge_fair_share', '⚖️', 40, 1, 'unit_settlement', false),
    BadgeDef('badge_settler', '🏦', 300, 10, 'unit_settlements', true),
    BadgeDef('badge_family_first', '👨‍👩‍👧', 50, 3, 'unit_members', false),
    BadgeDef('badge_full_house', '🏠', 150, 5, 'unit_members', true),
    BadgeDef('badge_bill_planner', '📅', 100, 5, 'unit_reminders', false),
    BadgeDef('badge_budget_boss', '🎯', 200, 1, 'unit_month', true),
    BadgeDef('badge_budget_hattrick', '🥉', 600, 3, 'unit_months', true),
    BadgeDef('badge_stylist', '🧵', 30, 1, 'unit_outfit', false),
    BadgeDef('badge_accessorized', '💍', 120, 3, 'unit_accessories', true),
    BadgeDef('badge_new_look', '🎨', 50, 1, 'unit_theme', false),
    BadgeDef('badge_collector', '🗂️', 80, 5, 'unit_rewards', true),
    BadgeDef('badge_polyglot', '🗣️', 30, 1, 'unit_language', false),
    BadgeDef('badge_level_5', '🎖️', 300, 5, 'unit_level', true),
    BadgeDef('badge_level_10', '👑', 1000, 10, 'unit_level', true),
  ];

  static BadgeDef? find(String id) => badges.where((b) => b.id == id).firstOrNull;

  static int progress(String id, BadgeSnapshot s) {
    switch (id) {
      case 'badge_first_step' || 'badge_ten_logged' || 'badge_century' || 'badge_half_k':
        return s.expenses;
      case 'badge_week_warrior' || 'badge_month_master' || 'badge_streak_60' || 'badge_streak_100':
        return s.streak;
      case 'badge_early_bird':
        return s.earlyLogs;
      case 'badge_night_owl':
        return s.lateLogs;
      case 'badge_voice':
        return s.voiceLogs;
      case 'badge_notes':
        return s.notedExpenses;
      case 'badge_explorer':
        return s.distinctCategories;
      case 'badge_custom_cat':
        return s.customCategories;
      case 'badge_payment_pro':
        return s.paymentModes;
      case 'badge_big_spender':
        return s.maxExpense >= 10000 ? 1 : 0;
      case 'badge_penny':
        return s.smallExpenses;
      case 'badge_team_player' || 'badge_group_guru':
        return s.groups;
      case 'badge_fair_share' || 'badge_settler':
        return s.settlements;
      case 'badge_family_first' || 'badge_full_house':
        return s.membersBesidesYou;
      case 'badge_bill_planner':
        return s.reminders;
      case 'badge_budget_boss' || 'badge_budget_hattrick':
        return s.monthsUnderBudget;
      case 'badge_stylist':
        return s.outfitUnlocks;
      case 'badge_accessorized':
        return s.accessoryUnlocks;
      case 'badge_new_look':
        return s.themeUnlocks;
      case 'badge_collector':
        return s.paidUnlocks;
      case 'badge_polyglot':
        return s.languageChanged ? 1 : 0;
      case 'badge_level_5' || 'badge_level_10':
        return s.level;
      default:
        return 0;
    }
  }
}

enum Festival {
  uttarayan('uttarayan', FestivalPack.uttarayan),
  republicDay('republic', FestivalPack.tiranga),
  holi('holi', FestivalPack.holi),
  rakshaBandhan('rakhi', FestivalPack.rakhi),
  independenceDay('independence', FestivalPack.tiranga),
  ganeshChaturthi('ganesh', FestivalPack.ganesh),
  navratri('navratri', FestivalPack.navratri),
  diwali('diwali', FestivalPack.diwali),
  christmas('christmas', FestivalPack.christmas),
  newYear('new_year', FestivalPack.newYear);

  const Festival(this.slug, this.pack);
  final String slug;
  final FestivalPack pack;

  String get label => tr('fest_$slug');
  String title(String name) => tr('fest_${slug}_title', [name]);
  String get line => tr('fest_${slug}_line');
  int get greetHour => this == Festival.newYear ? 0 : 9;
}

class FestivalDay {
  const FestivalDay(this.festival, this.start, this.main, this.end);
  final Festival festival;
  final DateTime start;
  final DateTime main;
  final DateTime end;

  String get key => '${festival.name}:${Days.key(main)}';
  DateTime get packFrom => DateTime(start.year, start.month, start.day - FestivalCalendar.packWindowDays);
  DateTime get packUntil => DateTime(end.year, end.month, end.day + FestivalCalendar.packWindowDays);
  bool contains(DateTime date) => !date.isBefore(packFrom) && !date.isAfter(packUntil);

  int daysOutside(DateTime date) {
    if (date.isBefore(start)) return Days.between(date, start);
    if (date.isAfter(end)) return Days.between(end, date);
    return 0;
  }
}

class FestivalCalendar {
  static const packWindowDays = 3;

  /// Lunar festivals as (festival, start, main, end) in MMdd, New Delhi panchang.
  static const _lunar = <int, List<(Festival, int, int, int)>>{
    2026: [(Festival.holi, 303, 304, 304), (Festival.rakshaBandhan, 828, 828, 828), (Festival.ganeshChaturthi, 914, 914, 924), (Festival.navratri, 1011, 1011, 1020), (Festival.diwali, 1106, 1108, 1111)],
    2027: [(Festival.holi, 321, 322, 323), (Festival.rakshaBandhan, 817, 817, 817), (Festival.ganeshChaturthi, 904, 904, 914), (Festival.navratri, 930, 930, 1009), (Festival.diwali, 1027, 1029, 1031)],
    2028: [(Festival.holi, 310, 311, 311), (Festival.rakshaBandhan, 805, 805, 805), (Festival.ganeshChaturthi, 823, 823, 902), (Festival.navratri, 919, 919, 927), (Festival.diwali, 1015, 1017, 1019)],
    2029: [(Festival.holi, 228, 301, 301), (Festival.rakshaBandhan, 823, 823, 823), (Festival.ganeshChaturthi, 911, 911, 921), (Festival.navratri, 1008, 1008, 1016), (Festival.diwali, 1104, 1105, 1107)],
    2030: [(Festival.holi, 319, 320, 320), (Festival.rakshaBandhan, 813, 813, 813), (Festival.ganeshChaturthi, 901, 901, 911), (Festival.navratri, 928, 928, 1006), (Festival.diwali, 1024, 1026, 1028)],
  };

  static DateTime _date(int year, int monthDay) => DateTime(year, monthDay ~/ 100, monthDay % 100);

  static List<FestivalDay> _occurrences(int year) {
    FestivalDay fixed(Festival f, int start, int main, int end) => FestivalDay(f, _date(year, start), _date(year, main), _date(year, end));
    return [
      FestivalDay(Festival.newYear, _date(year - 1, 1231), _date(year, 101), _date(year, 101)),
      fixed(Festival.uttarayan, 113, 114, 115),
      fixed(Festival.republicDay, 126, 126, 126),
      fixed(Festival.independenceDay, 815, 815, 815),
      fixed(Festival.christmas, 1224, 1225, 1226),
      for (final l in _lunar[year] ?? const <(Festival, int, int, int)>[]) fixed(l.$1, l.$2, l.$3, l.$4),
    ]..sort((a, b) => a.start.compareTo(b.start));
  }

  static List<FestivalDay> _around(int year) => [..._occurrences(year), ..._occurrences(year + 1)];

  static FestivalDay? active(DateTime date) {
    final live = _around(date.year).where((f) => f.contains(date)).toList()..sort((a, b) => a.daysOutside(date).compareTo(b.daysOutside(date)));
    return live.firstOrNull;
  }

  static FestivalDay? upcoming(DateTime date, [int withinDays = 7]) {
    final limit = DateTime(date.year, date.month, date.day + withinDays);
    final soon = _around(date.year).where((f) => f.packFrom.isAfter(date) && !f.main.isAfter(limit)).toList()..sort((a, b) => a.start.compareTo(b.start));
    return soon.firstOrNull;
  }

  static (FestivalDay, DateTime)? nextGreeting(DateTime now) {
    final next = _around(now.year)
        .map((f) => (f, DateTime(f.main.year, f.main.month, f.main.day, f.festival.greetHour)))
        .where((e) => e.$2.isAfter(now))
        .toList()
      ..sort((a, b) => a.$2.compareTo(b.$2));
    return next.firstOrNull;
  }
}
