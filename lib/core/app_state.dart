import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:android_intent_plus/android_intent.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart' show DateTimeComponents;
import 'package:path_provider/path_provider.dart';

import 'capture.dart';
import 'catalogs.dart';
import 'format.dart';
import 'l10n.dart';
import 'models.dart';
import 'notifier.dart';
import 'parsers.dart';
import 'store.dart';

enum CelebrationKind { level, badge, streak, festival }

class Celebration {
  const Celebration(this.kind, {this.badgeId, required this.title, required this.body, required this.sound, this.festival});
  final CelebrationKind kind;
  final String? badgeId;
  final String title;
  final String body;
  final String sound;
  final FestivalDay? festival;
}

class BadgeStatus {
  const BadgeStatus(this.badge, this.earnedAt, this.progress);
  final BadgeDef badge;
  final int? earnedAt;
  final int progress;
  bool get earned => earnedAt != null;
  double get fraction => earned ? 1 : (progress / badge.target).clamp(0.0, 1.0).toDouble();
}

class ImportResult {
  const ImportResult(this.added, this.duplicates, this.invalid);
  final int added;
  final int duplicates;
  final int invalid;
}

class AppState extends ChangeNotifier {
  AppState(this._store);

  final Store _store;
  final _random = Random();

  Settings settings = Settings();
  List<Member> members = [];
  List<Category> categories = [];
  List<Expense> expenses = [];
  List<Group> groups = [];
  List<Settlement> settlements = [];
  List<Reminder> reminders = [];
  List<PointEntry> ledger = [];
  List<Shop> shops = [];
  List<KhataEntry> khata = [];
  List<HomeService> services = [];
  List<GoldItem> gold = [];
  List<Capture> captures = [];
  List<Goal> goals = [];
  List<ShopItem> shopping = [];
  List<Loan> loans = [];
  List<Paper> papers = [];
  List<Account> accounts = [];

  /// Whether Android notification access is granted, so payments can be captured.
  bool captureOn = false;
  List<Chit> chits = [];

  bool locked = true;
  final celebrations = <Celebration>[];
  final pointsToast = ValueNotifier<int>(0);
  final festiveMoment = ValueNotifier<int>(0);

  /// Where receipt photos are kept.
  String photosDir = '';

  Future<void> load() async {
    photosDir = (await getApplicationDocumentsDirectory()).path;
    settings = _store.loadSettings();
    members = await _store.load('member', Member.fromJson);
    categories = await _store.load('category', Category.fromJson);
    expenses = await _store.load('expense', Expense.fromJson);
    groups = await _store.load('group', Group.fromJson);
    settlements = await _store.load('settlement', Settlement.fromJson);
    reminders = await _store.load('reminder', Reminder.fromJson);
    ledger = await _store.load('points', PointEntry.fromJson);
    shops = await _store.load('shop', Shop.fromJson);
    khata = await _store.load('khata', KhataEntry.fromJson);
    services = await _store.load('service', HomeService.fromJson);
    gold = await _store.load('gold', GoldItem.fromJson);
    chits = await _store.load('chit', Chit.fromJson);
    captures = await _store.load('capture', Capture.fromJson);
    goals = await _store.load('goal', Goal.fromJson);
    shopping = await _store.load('shopitem', ShopItem.fromJson);
    loans = await _store.load('loan', Loan.fromJson);
    papers = await _store.load('paper', Paper.fromJson);
    accounts = await _store.load('account', Account.fromJson);
    if (categories.isEmpty) {
      categories = BuiltInCategories.seed();
      for (final c in categories) {
        await _store.save(c);
      }
    }
    _applyGlobals();
    await L10n.load(settings.language);
    locked = settings.onboarded && (settings.appLock || me == null);
    if (settings.onboarded) await _dailyChecks();
    await syncCaptures();
    await _syncNative();
  }

  void _applyGlobals() {
    Fmt.currencyCode = settings.currencyCode;
    Fmt.symbol = currencies[settings.currencyCode] ?? '₹';
    Sfx.enabled = settings.soundEffects;
  }

  Future<void> _persist() async {
    await _store.saveSettings(settings);
    notifyListeners();
  }

  // ---- Lookups

  Member? get me => members.where((m) => m.id == settings.activeMemberId).firstOrNull;
  Member? member(int id) => members.where((m) => m.id == id).firstOrNull;
  String memberName(int id) => member(id)?.name ?? '—';
  Category category(String key) => categories.where((c) => c.key == key).firstOrNull ?? categories.firstWhere((c) => c.key == BuiltInCategories.other);
  List<Category> get sortedCategories => [...categories]..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
  LevelInfo get level => Levels.of(settings.lifetimePoints);
  bool isUnlocked(String id) => settings.unlocked.contains(id) || (RewardCatalog.find(id)?.isFree ?? false) && RewardCatalog.find(id)?.pack == null;

  int get streak {
    if (settings.lastLogDay == 0) return 0;
    return Days.between(Days.fromKey(settings.lastLogDay), Days.today()) <= 1 ? settings.streakDays : 0;
  }

  bool get loggedToday => settings.lastLogDay == Days.key(Days.today());

  static double net(Iterable<Expense> list) => list.fold(0.0, (sum, e) => sum + e.amount);

  List<Expense> inMonth(DateTime month) => expenses.where((e) => e.day ~/ 100 == Days.monthKey(month)).toList();
  List<Expense> onDay(DateTime day) => expenses.where((e) => e.day == Days.key(day)).toList();
  List<Expense> between(DateTime from, DateTime to) => expenses.where((e) => e.day >= Days.key(from) && e.day <= Days.key(to)).toList();
  double spentIn(DateTime month) => max(net(inMonth(month)), 0.0);

  /// Net totals per category for [list], only categories above zero, largest first.
  List<MapEntry<Category, double>> byCategory(Iterable<Expense> list) {
    final totals = <String, double>{};
    for (final e in list) {
      totals[e.category] = (totals[e.category] ?? 0.0) + e.amount;
    }
    return totals.entries.where((e) => e.value > 0).map((e) => MapEntry(category(e.key), e.value)).toList()..sort((a, b) => b.value.compareTo(a.value));
  }

  List<MapEntry<Member, double>> byPayer(Iterable<Expense> list) {
    final totals = <int, double>{};
    for (final e in list) {
      totals[e.paidBy] = (totals[e.paidBy] ?? 0.0) + e.amount;
    }
    return [
      for (final e in totals.entries)
        if (e.value > 0 && member(e.key) != null) MapEntry(member(e.key)!, e.value),
    ]..sort((a, b) => b.value.compareTo(a.value));
  }

  /// What can still be spent today without breaking the monthly budget: the money left at the start of today spread
  /// over the days remaining, less what today has already cost. Null without a budget.
  double? get safeToday {
    if (settings.monthlyBudget <= 0) return null;
    final today = Days.today();
    final spentToday = max(net(onDay(today)), 0.0);
    final leftThisMorning = settings.monthlyBudget - (spentIn(today) - spentToday);
    return leftThisMorning / (Days.inMonth(today) - today.day + 1) - spentToday;
  }

  /// One-tap templates for the add screen: the latest expense for each distinct title, most used first. With a
  /// [query] only titles containing it are offered.
  List<Expense> quickPicks(String query, {int limit = 6}) {
    final q = query.trim().toLowerCase();
    final uses = <String, int>{};
    final latest = <String, Expense>{};
    for (final e in expenses) {
      final key = e.title.trim().toLowerCase();
      if (key.isEmpty || e.isCredit || (q.isNotEmpty && (!key.contains(q) || key == q))) continue;
      uses[key] = (uses[key] ?? 0) + 1;
      if (e.createdAt >= (latest[key]?.createdAt ?? 0)) latest[key] = e;
    }
    final keys = latest.keys.where((k) => q.isNotEmpty || uses[k]! >= 2).toList()..sort((a, b) => uses[b]!.compareTo(uses[a]!));
    return [for (final k in keys.take(limit)) latest[k]!];
  }

  /// The category last used for an expense with this title, so a shop is filed the same way every time.
  String? categoryFor(String title) {
    final key = title.trim().toLowerCase();
    if (key.isEmpty) return null;
    Expense? match;
    for (final e in expenses) {
      if (e.title.trim().toLowerCase() == key && e.createdAt >= (match?.createdAt ?? 0)) match = e;
    }
    return match?.category;
  }

  double balanceOf(Account a) => a.opening - net(expenses.where((e) => e.accountId == a.id));

  /// Saves [doc] and keeps it in [list]; a doc removed by [drop] comes back as a new record.
  Future<void> put<T extends Doc>(List<T> list, T doc) async {
    await _store.save(doc);
    if (!list.contains(doc)) list.add(doc);
    notifyListeners();
    _syncLater();
  }

  Future<void> drop<T extends Doc>(List<T> list, T doc) async {
    list.remove(doc);
    await _store.remove(doc);
    doc.id = 0;
    notifyListeners();
    _syncLater();
  }

  double get budgetProgress => settings.monthlyBudget <= 0 ? 0 : spentIn(Days.today()) / settings.monthlyBudget;

  Mood get mood {
    final own = me?.avatar.mood;
    if (own != null) return own;
    final now = DateTime.now();
    final hasBudget = settings.monthlyBudget > 0;
    final progress = budgetProgress;
    final sinceLog = settings.lastLogDay == 0 ? 0 : Days.between(Days.fromKey(settings.lastLogDay), now);
    if (hasBudget && progress > 1) return Mood.angry;
    if (hasBudget && progress >= 0.85) return Mood.worried;
    if (now.hour >= 23 || now.hour < 5) return Mood.sleepy;
    if (sinceLog >= 3) return Mood.sad;
    if (hasBudget && progress >= 0.65) return Mood.confused;
    if (streak >= 7) return Mood.love;
    if (streak >= 3) return Mood.excited;
    if (hasBudget && now.day >= 15 && progress < 0.4) return Mood.smart;
    if (sinceLog >= 1) return Mood.neutral;
    return Mood.happy;
  }

  String get greeting {
    final hour = DateTime.now().hour;
    final key = hour >= 23 || hour < 5 ? 'still_up' : hour < 12 ? 'good_morning' : hour < 17 ? 'good_afternoon' : 'good_evening';
    return tr(key);
  }

  String get moodLine => mood.line('$greeting ${me?.name ?? ''}'.trim(), Days.key(Days.today()));

  // ---- Festivals

  FestivalDay? get festival => FestivalCalendar.active(Days.today());
  FestivalDay? get upcomingFestival => FestivalCalendar.upcoming(Days.today());
  bool get festiveLive => settings.festiveMode && festival != null;
  bool get festivalClaimed => festival != null && settings.festivalsClaimed.contains(festival!.key);

  String get activeThemeId {
    final f = festival;
    if (f != null && settings.festiveMode && settings.festivalThemeSkipped != f.key) return f.festival.pack.themeId;
    return settings.themeId;
  }

  AvatarConfig get myLook {
    final look = me?.avatar ?? const AvatarConfig();
    return look.copyWith(mood: mood);
  }

  Future<void> claimFestival() async {
    final f = festival;
    final user = me;
    if (f == null) return;
    final pack = f.festival.pack;
    settings.unlocked.addAll(RewardCatalog.ofPack(pack).map((i) => i.id));
    if (settings.festivalsClaimed.add(f.key)) await _award(PointsRules.festivalGift, PointReasons.encode(PointReasons.festival, pack.name));
    if (user != null) {
      user.avatar = RewardCatalog.dressFor(pack, user.avatar);
      await _store.save(user);
    }
    await _persist();
  }

  Future<void> markFestivalSeen() async {
    final f = festival;
    if (f != null && settings.festivalsSeen.add(f.key)) await _persist();
  }

  // ---- Onboarding, members, session

  Future<void> completeOnboarding({required String name, required Gender gender, required String currency, required double budget}) async {
    final owner = Member(name: name.trim().capitalised, relation: 'me', isOwner: true, avatar: _randomLook(gender));
    await _store.save(owner);
    members = [owner];
    final nudge = Reminder(title: tr('preset_daily_nudge'), hour: 20, minute: 30, repeat: RepeatRule.daily);
    await _store.save(nudge);
    reminders = [nudge];
    settings
      ..onboarded = true
      ..activeMemberId = owner.id
      ..currencyCode = currency
      ..monthlyBudget = budget
      ..unlocked = RewardCatalog.defaults()
      ..lastBudgetCheckMonth = Days.monthKey(Days.today());
    locked = false;
    _applyGlobals();
    await _persist();
    await Notifier.requestPermission();
    await syncNotifications();
  }

  AvatarConfig _randomLook(Gender gender) {
    const male = ['hair_short', 'hair_buzz', 'hair_side_part', 'hair_curly'];
    const female = ['hair_long', 'hair_pixie', 'hair_curly', 'hair_short'];
    const outfits = ['outfit_tee', 'outfit_shirt', 'outfit_polo'];
    final hair = gender == Gender.male ? male : female;
    return AvatarConfig(
      skinTone: _random.nextInt(skinTones.length),
      hairId: hair[_random.nextInt(hair.length)],
      hairColor: _random.nextInt(2),
      outfitId: outfits[_random.nextInt(outfits.length)],
      gender: gender,
    );
  }

  Future<Member> addMember({required String name, required String relation, required Gender gender, required String upiId, required bool joinGroups, required bool resplit}) async {
    final m = Member(name: name.trim().capitalised, relation: relation, upiId: upiId.trim(), avatar: _randomLook(gender));
    await _store.save(m);
    members.add(m);
    if (joinGroups) {
      for (final g in groups) {
        g.memberIds.add(m.id);
        await _store.save(g);
        if (resplit) await _resplit(g);
      }
    }
    await _award(PointsRules.addMember, PointReasons.member);
    await _afterChange();
    return m;
  }

  Future<void> _resplit(Group g) async {
    for (final e in expenses.where((e) => e.groupId == g.id && e.splitType == SplitType.equal)) {
      e.shares = SplitCalculator.equalShares(e.amount, g.memberIds);
      await _store.save(e);
    }
  }

  Future<void> updateMember(Member m) async {
    await _store.save(m);
    await _afterChange();
  }

  Future<void> removeMember(Member m, {required bool resplit}) async {
    members.remove(m);
    await _store.remove(m);
    for (final g in groups.where((g) => g.memberIds.contains(m.id))) {
      g.memberIds.remove(m.id);
      await _store.save(g);
      if (resplit) await _resplit(g);
    }
    await _afterChange();
  }

  Future<void> setPin(Member m, String? pin) async {
    m.pinHash = pin == null ? '' : Pin.hash(pin);
    await _store.save(m);
    if (!members.any((x) => x.id == settings.activeMemberId && x.hasPin)) settings.appLock = false;
    if (!m.hasPin && settings.biometricMemberId == m.id) settings.biometricMemberId = 0;
    await _persist();
  }

  Future<void> setAppLock(bool on) async {
    settings.appLock = on;
    await _persist();
  }

  Future<void> setBiometric(Member? m) async {
    settings.biometricMemberId = m?.id ?? 0;
    await _persist();
  }

  Future<void> login(Member m) async {
    settings.activeMemberId = m.id;
    locked = false;
    await _persist();
  }

  Future<void> logout() async {
    locked = true;
    settings.activeMemberId = 0;
    await _persist();
  }

  // ---- Gamification

  Future<void> _award(int delta, String reason) async {
    final before = level.level;
    final entry = PointEntry(delta: delta, reason: reason);
    await _store.save(entry);
    ledger.add(entry);
    settings.points += delta;
    if (delta > 0) settings.lifetimePoints += delta;
    final after = level;
    if (after.level > before) {
      celebrations.add(Celebration(CelebrationKind.level,
          title: tr('toast_level', [after.level, after.title]), body: trPick('notif_level_bodies', [after.title]), sound: Channel.levels.sound));
      if (settings.rewardNotifs) Notifier.show(Channel.levels, _copy('level', 0, [after.level]), _copy('level', 1, [after.title]), route: 'rewards');
    }
  }

  BadgeSnapshot get _snapshot {
    final spends = expenses.where((e) => e.amount > 0).toList();
    final hours = spends.map((e) => DateTime.fromMillisecondsSinceEpoch(e.createdAt).hour).toList();
    final paid = settings.unlocked.map(RewardCatalog.find).whereType<RewardItem>().where((i) => !i.isFree && i.pack == null).toList();
    return BadgeSnapshot()
      ..expenses = spends.length
      ..distinctCategories = spends.map((e) => e.category).toSet().length
      ..paymentModes = spends.map((e) => e.mode).toSet().length
      ..maxExpense = spends.fold(0.0, (m, e) => max(m, e.amount))
      ..smallExpenses = spends.where((e) => e.amount < 100).length
      ..notedExpenses = spends.where((e) => e.note.trim().isNotEmpty).length
      ..earlyLogs = hours.where((h) => h < 9).length
      ..lateLogs = hours.where((h) => h >= 22).length
      ..voiceLogs = settings.voiceLogs
      ..streak = settings.streakDays
      ..groups = groups.length
      ..settlements = settlements.length
      ..membersBesidesYou = max(members.length - 1, 0)
      ..reminders = reminders.length
      ..customCategories = categories.where((c) => !c.builtIn).length
      ..paidUnlocks = paid.length
      ..outfitUnlocks = paid.where((i) => i.kind == RewardKind.outfit).length
      ..accessoryUnlocks = paid.where((i) => i.kind == RewardKind.accessory).length
      ..themeUnlocks = paid.where((i) => i.kind == RewardKind.theme).length
      ..monthsUnderBudget = settings.budgetMonthsWon.length
      ..level = level.level
      ..languageChanged = settings.languageChanged;
  }

  /// Worked out once per change: [notifyListeners] drops the cached list.
  List<BadgeStatus> get badgeStatuses {
    final cached = _badgeStatuses;
    if (cached != null) return cached;
    final s = _snapshot;
    return _badgeStatuses = [for (final b in BadgeCatalog.badges) BadgeStatus(b, settings.badges[b.id], BadgeCatalog.progress(b.id, s))];
  }

  List<BadgeStatus>? _badgeStatuses;

  @override
  void notifyListeners() {
    _badgeStatuses = null;
    super.notifyListeners();
  }

  Future<void> _checkBadges() async {
    var again = true;
    while (again) {
      again = false;
      _badgeStatuses = null;
      for (final status in badgeStatuses.where((s) => !s.earned && s.progress >= s.badge.target)) {
        final b = status.badge;
        settings.badges[b.id] = DateTime.now().millisecondsSinceEpoch;
        celebrations.add(Celebration(CelebrationKind.badge, badgeId: b.id, title: tr('toast_badge', [b.name]), body: trPick('notif_badge_bodies', [b.name, b.bonus]), sound: Channel.badges.sound));
        if (settings.rewardNotifs) Notifier.show(Channel.badges, _copy('badge', 0, [b.emoji]), _copy('badge', 1, [b.name, b.bonus]), route: 'badges');
        await _award(b.bonus, PointReasons.encode(PointReasons.badge, b.id));
        again = true;
      }
    }
  }

  Future<void> _afterChange() async {
    await _checkBadges();
    await _persist();
    _syncLater();
  }

  Timer? _syncSoon;

  void _syncLater() {
    _syncSoon?.cancel();
    _syncSoon = Timer(const Duration(seconds: 2), () {
      syncNotifications();
      _syncNative();
    });
  }

  /// Hands the Android widget and payment alert their text in the app's language, then asks the widget to redraw.
  Future<void> _syncNative() async {
    if (!Platform.isAndroid || !settings.onboarded) return;
    final today = Days.today();
    final safe = safeToday;
    try {
      await _store.saveForNative({
        'widget_title': tr('widget_month', [Fmt.month(today)]),
        'widget_amount': Fmt.money(spentIn(today)),
        'widget_note': safe == null ? tr('widget_today', [Fmt.money(max(net(onDay(today)), 0.0))]) : tr('widget_safe', [Fmt.money(max(safe, 0.0))]),
        'capture_alert_title': tr('capture_alert_title'),
        'capture_alert_body': tr('capture_alert_body'),
      });
      await const AndroidIntent(action: 'app.gharcha.WIDGET_REFRESH', package: 'app.gharcha', componentName: 'app.gharcha.SpendWidget').sendBroadcast();
    } on Exception {
      return;
    }
  }

  Future<bool> unlock(RewardItem item) async {
    if (isUnlocked(item.id)) return true;
    if (item.pack != null) {
      if (festival?.festival.pack != item.pack) return false;
      await claimFestival();
      return true;
    }
    if (settings.points < item.cost) return false;
    settings.unlocked.add(item.id);
    await _award(-item.cost, PointReasons.encode(PointReasons.unlock, item.id));
    await _afterChange();
    return true;
  }

  Future<void> applyTheme(String themeId) async {
    settings.themeId = themeId;
    final f = festival;
    settings.festivalThemeSkipped = f != null && f.festival.pack.themeId != themeId ? f.key : '';
    await _persist();
  }

  // ---- Expenses

  /// Saves [e]. Returns the points earned for a newly logged spend.
  Future<int> saveExpense(Expense e, {bool voice = false}) async {
    final isNew = e.id == 0;
    e.title = e.title.trim().capitalised;
    e.note = e.note.trim().capitalised;
    await _store.save(e);
    var earned = 0;
    if (isNew) {
      expenses.add(e);
      if (voice) settings.voiceLogs++;
      if (!e.isCredit) earned = await _rewardLog();
    }
    if (!e.isCredit) await _checkBudgets(e);
    await _afterChange();
    if (isNew && earned > 0) pointsToast.value = earned;
    if (isNew && festiveLive) festiveMoment.value++;
    return earned;
  }

  Future<int> _rewardLog() async {
    final today = Days.today();
    var earned = PointsRules.logExpense;
    if (!loggedToday) {
      settings.streakDays = streak + 1;
      settings.lastLogDay = Days.key(today);
      earned += PointsRules.firstLogOfDay + PointsRules.streakBonus(settings.streakDays);
      if (StreakMilestones.reached(settings.streakDays)) {
        final name = me?.name ?? '';
        celebrations.add(Celebration(CelebrationKind.streak,
            title: tr('celebrate_streak_title', [settings.streakDays]), body: trPick('celebrate_streak_lines', [name, settings.streakDays]), sound: Channel.streakWin.sound));
        if (settings.rewardNotifs) Notifier.show(Channel.streakWin, _copy('streak_win', 0, [settings.streakDays]), _copy('streak_win', 1), route: 'rewards');
      }
    }
    await _award(earned, PointReasons.logExpense);
    return earned;
  }

  Future<void> _checkBudgets(Expense e) async {
    if (!settings.budgetAlerts || e.day ~/ 100 != Days.monthKey(Days.today())) return;
    final month = inMonth(Days.today());
    Future<void> check(String scope, String label, double spent, double limit) async {
      if (limit <= 0) return;
      final ratio = spent / limit;
      final stage = ratio >= 1 ? 100 : ratio >= 0.8 ? 80 : 0;
      if (stage == 0 || !settings.budgetAlertsSent.add('${Days.monthKey(Days.today())}:$scope:$stage')) return;
      final args = [label, Fmt.money(spent), Fmt.money(limit)];
      if (stage == 100) {
        await Notifier.show(Channel.budgetOver, _copy('budget_over', 0), _copy('budget_over', 1, args), route: 'budgets');
      } else {
        await Notifier.show(Channel.budgetWarn, _copy('budget_warn', 0), _copy('budget_warn', 1, args), route: 'budgets');
      }
    }

    await check('all', tr('monthly_budget'), max(net(month), 0.0), settings.monthlyBudget);
    final limit = settings.categoryBudgets[e.category] ?? 0.0;
    await check(e.category, category(e.category).name, max(net(month.where((x) => x.category == e.category)), 0.0), limit);
  }

  Future<void> deleteExpense(Expense e) async {
    expenses.remove(e);
    await _store.remove(e);
    await _afterChange();
  }

  /// Logs the same expense again, dated today.
  Future<void> duplicateExpense(Expense e) =>
      saveExpense(Expense(title: e.title, amount: e.amount, category: e.category, mode: e.mode, day: Days.key(Days.today()), paidBy: e.paidBy, groupId: e.groupId, splitType: e.splitType, shares: Map.of(e.shares), note: e.note));

  /// Puts back an expense removed by [deleteExpense].
  Future<void> restoreExpense(Expense e) async {
    e.id = 0;
    await _store.save(e);
    expenses.add(e);
    await _afterChange();
  }

  // ---- Categories

  Future<void> saveCategory(Category c) async {
    if (c.id == 0) {
      c.sortOrder = categories.length;
      categories.add(c);
    }
    c.customName = c.customName.trim().capitalised;
    await _store.save(c);
    await _afterChange();
  }

  Future<void> deleteCategory(Category c) async {
    for (final e in expenses.where((e) => e.category == c.key)) {
      e.category = BuiltInCategories.other;
      await _store.save(e);
    }
    settings.categoryBudgets.remove(c.key);
    categories.remove(c);
    await _store.remove(c);
    await _afterChange();
  }

  // ---- Groups

  Future<void> saveGroup(Group g) async {
    final isNew = g.id == 0;
    g.name = g.name.trim().capitalised;
    await _store.save(g);
    if (isNew) {
      groups.add(g);
      await _award(PointsRules.createGroup, PointReasons.group);
    } else {
      await _resplit(g);
    }
    await _afterChange();
  }

  Future<void> deleteGroup(Group g) async {
    for (final e in expenses.where((e) => e.groupId == g.id)) {
      e
        ..groupId = null
        ..splitType = SplitType.none
        ..shares = {};
      await _store.save(e);
    }
    for (final s in settlements.where((s) => s.groupId == g.id).toList()) {
      settlements.remove(s);
      await _store.remove(s);
    }
    groups.remove(g);
    await _store.remove(g);
    await _afterChange();
  }

  List<Expense> groupExpenses(Group g) => expenses.where((e) => e.groupId == g.id).toList()..sort((a, b) => b.day.compareTo(a.day));

  List<MemberBalance> balances(Group g) {
    final nets = {for (final id in g.memberIds) id: 0.0};
    for (final e in groupExpenses(g)) {
      nets[e.paidBy] = (nets[e.paidBy] ?? 0.0) + e.amount;
      e.shares.forEach((id, share) => nets[id] = (nets[id] ?? 0.0) - share);
    }
    for (final s in settlements.where((s) => s.groupId == g.id)) {
      nets[s.from] = (nets[s.from] ?? 0.0) + s.amount;
      nets[s.to] = (nets[s.to] ?? 0.0) - s.amount;
    }
    return [for (final e in nets.entries) MemberBalance(e.key, memberName(e.key), e.value)];
  }

  /// What each other member owes the active member across every group's settle-up plan; negative when the active member owes them.
  Map<Member, double> get myDues {
    final id = settings.activeMemberId;
    final dues = <int, double>{};
    for (final g in groups) {
      for (final t in SplitCalculator.settlements(balances(g))) {
        if (t.toId == id) dues[t.fromId] = (dues[t.fromId] ?? 0) + t.amount;
        if (t.fromId == id) dues[t.toId] = (dues[t.toId] ?? 0) - t.amount;
      }
    }
    return {
      for (final d in dues.entries)
        if (member(d.key) != null && d.value.abs() >= 0.005) member(d.key)!: d.value,
    };
  }

  double get myGroupBalance {
    final id = settings.activeMemberId;
    return groups.fold(0.0, (sum, g) => sum + (balances(g).where((b) => b.memberId == id).firstOrNull?.net ?? 0.0));
  }

  Future<void> settle(Group g, Transfer t) async {
    final s = Settlement(groupId: g.id, from: t.fromId, to: t.toId, amount: t.amount);
    await _store.save(s);
    settlements.add(s);
    await _award(PointsRules.settleUp, PointReasons.settle);
    await _afterChange();
  }

  String groupSummary(Group g) {
    final lines = <String>[g.name, tr('share_total_spent', [Fmt.money(max(net(groupExpenses(g)), 0.0))]), ''];
    for (final b in balances(g)) {
      final status = b.net > 0.005
          ? tr('share_is_owed', [Fmt.money(b.net)])
          : b.net < -0.005
              ? tr('share_owes', [Fmt.money(-b.net)])
              : tr('share_is_settled');
      lines.add('${b.name} $status');
    }
    final plan = SplitCalculator.settlements(balances(g));
    if (plan.isNotEmpty) lines.add('');
    for (final t in plan) {
      lines.add('${t.fromName} → ${t.toName}: ${Fmt.money(t.amount)}');
    }
    return lines.join('\n');
  }

  // ---- Budgets

  Future<void> setMonthlyBudget(double value) async {
    settings.monthlyBudget = value;
    await _persist();
  }

  Future<void> setCardLook(String card, int look) async {
    settings.cardLooks[card] = look;
    await _persist();
  }

  Future<void> setTourSeen() async {
    settings.tourSeen = true;
    await _persist();
  }

  Future<void> toggleQuickAccess(String route) async {
    final list = settings.quickAccess;
    if (!list.remove(route) && list.length < Settings.quickAccessMax) list.add(route);
    await _persist();
  }

  Future<void> setMonthlyIncome(double value) async {
    settings.monthlyIncome = value;
    await _persist();
  }

  Future<void> setCategoryBudget(String key, double? value) async {
    if (value == null || value <= 0) {
      settings.categoryBudgets.remove(key);
    } else {
      settings.categoryBudgets[key] = value;
    }
    await _persist();
  }

  /// Plain-words forecast for the current month, or null without a budget.
  String? get forecast {
    final budget = settings.monthlyBudget;
    if (budget <= 0) return null;
    final today = Days.today();
    final spent = max(net(inMonth(today).where((e) => e.day <= Days.key(today))), 0.0);
    if (spent > budget) return tr('forecast_already_over', [Fmt.money((spent - budget).round())]);
    final daily = spent / today.day;
    final projected = daily * Days.inMonth(today);
    if (projected <= budget || daily <= 0) return tr('forecast_on_track', [Fmt.money((budget - projected).round())]);
    final crossing = today.add(Duration(days: ((budget - spent) / daily).ceil()));
    return tr('forecast_over', [Fmt.money((projected - budget).round()), Fmt.date(crossing)]);
  }

  // ---- Reminders

  Future<void> saveReminder(Reminder r) async {
    r.title = r.title.trim().capitalised;
    if (r.id == 0) reminders.add(r);
    await _store.save(r);
    await _afterChange();
  }

  Future<void> deleteReminder(Reminder r) async {
    reminders.remove(r);
    await _store.remove(r);
    await _afterChange();
  }

  List<MapEntry<Reminder, DateTime>> get upcomingReminders {
    final now = DateTime.now();
    return [
      for (final r in reminders.where((r) => r.enabled))
        if (r.nextAfter(now) != null) MapEntry(r, r.nextAfter(now)!),
    ]..sort((a, b) => a.value.compareTo(b.value));
  }

  // ---- Household money

  double khataDue(Shop s) => khata.where((k) => k.shopId == s.id).fold(0.0, (sum, k) => sum + (k.payment ? -k.amount : k.amount));
  double get totalKhataDue => shops.fold(0.0, (sum, s) => sum + max(khataDue(s), 0.0));

  Future<void> addShop(String name) async {
    final s = Shop(name: name.trim().capitalised);
    await _store.save(s);
    shops.add(s);
    notifyListeners();
  }

  Future<void> deleteShop(Shop s) async {
    for (final k in khata.where((k) => k.shopId == s.id).toList()) {
      khata.remove(k);
      await _store.remove(k);
    }
    shops.remove(s);
    await _store.remove(s);
    notifyListeners();
  }

  Future<void> addKhata(Shop s, double amount, {required bool payment, String note = '', PaymentMode mode = PaymentMode.cash}) async {
    final entry = KhataEntry(shopId: s.id, amount: amount, payment: payment, note: note.trim().capitalised, day: Days.key(Days.today()));
    await _store.save(entry);
    khata.add(entry);
    if (payment) {
      await saveExpense(Expense(title: tr('khata_payment_title', [s.name]), amount: amount, category: BuiltInCategories.groceries, mode: mode, day: entry.day, paidBy: settings.activeMemberId));
    } else {
      notifyListeners();
    }
  }

  Future<void> deleteKhata(KhataEntry k) async {
    khata.remove(k);
    await _store.remove(k);
    notifyListeners();
  }

  Future<void> saveService(HomeService s) async {
    if (s.id == 0) services.add(s);
    s.name = s.name.trim().capitalised;
    await _store.save(s);
    notifyListeners();
  }

  Future<void> deleteService(HomeService s) async {
    services.remove(s);
    await _store.remove(s);
    notifyListeners();
  }

  Future<void> payService(HomeService s, DateTime month) async {
    final key = Days.monthKey(month);
    if (s.paidMonths.containsKey(key)) return;
    final amount = s.billFullMonth(month);
    s.paidMonths[key] = amount;
    await _store.save(s);
    final due = amount - (s.advances[key] ?? 0);
    if (due > 0) await saveExpense(Expense(title: tr('service_payment_title', [s.name, Fmt.monthYear(month)]), amount: due, category: s.category, day: Days.key(Days.today()), paidBy: settings.activeMemberId));
    notifyListeners();
  }

  /// Records money handed over early against [month]'s bill; it is logged as an expense now and taken off the final payment.
  Future<void> payAdvance(HomeService s, DateTime month, double amount) async {
    final key = Days.monthKey(month);
    s.advances[key] = (s.advances[key] ?? 0) + amount;
    await _store.save(s);
    await saveExpense(Expense(title: tr('service_advance_title', [s.name]), amount: amount, category: s.category, day: Days.key(Days.today()), paidBy: settings.activeMemberId));
  }

  double get goldValue => gold.fold(0.0, (sum, g) => sum + g.valueAt(settings.goldRate));
  double get chitValue => chits.fold(0.0, (sum, c) => sum + c.savingsValue);

  Future<void> setGoldRate(double rate) async {
    settings.goldRate = rate;
    await _persist();
  }

  /// Saves a new item, or puts back one removed by [deleteGold].
  Future<void> saveGold(GoldItem g) async {
    g.id = 0;
    await _store.save(g);
    gold.add(g);
    notifyListeners();
  }

  Future<void> deleteGold(GoldItem g) async {
    gold.remove(g);
    await _store.remove(g);
    notifyListeners();
  }

  Future<void> saveChit(Chit c) async {
    if (c.id == 0) chits.add(c);
    await _store.save(c);
    notifyListeners();
  }

  Future<void> deleteChit(Chit c) async {
    chits.remove(c);
    await _store.remove(c);
    notifyListeners();
  }

  // ---- Preferences

  Future<void> setLanguage(String code) async {
    settings.language = code;
    if (code != 'en') settings.languageChanged = true;
    await L10n.load(code);
    if (settings.onboarded) {
      await _afterChange();
    } else {
      await _persist();
    }
  }

  Future<void> updateSettings(void Function(Settings s) change) async {
    change(settings);
    _applyGlobals();
    await _persist();
    await syncNotifications();
  }

  Future<void> eraseAll() async {
    await Notifier.cancelAll();
    await _store.wipe();
    celebrations.clear();
    await load();
    notifyListeners();
  }

  // ---- Payment capture (Android)

  static const _captureWindowMs = 10 * 60 * 1000;

  /// Turns the messages queued by the notification listener into pending captures, skipping anything that is not a
  /// completed payment or that repeats a capture or expense of the same amount from the last ten minutes.
  Future<void> syncCaptures() async {
    if (!captureBuild) return;
    captureOn = await _store.captureConnected();
    for (final raw in await _store.takeCaptured()) {
      final sender = (raw['sender'] as String? ?? '').trim();
      final parsed = PaymentParser.parse('$sender ${raw['text'] ?? ''}');
      if (parsed == null) continue;
      final at = raw['at'] as int? ?? DateTime.now().millisecondsSinceEpoch;
      final since = at - _captureWindowMs;
      if (captures.any((c) => c.amount == parsed.amount && c.at >= since) || expenses.any((e) => e.amount == parsed.amount && e.createdAt >= since)) continue;
      final capture = Capture(amount: parsed.amount, merchant: parsed.merchant, source: sender, at: at);
      await _store.save(capture);
      captures.add(capture);
    }
    notifyListeners();
  }

  Future<void> dismissCapture(Capture c) async {
    captures.remove(c);
    await _store.remove(c);
    notifyListeners();
  }

  // ---- Data

  Future<String> exportBackup() => _store.dump();

  /// Replaces all data with a backup file's. Returns false when the file is not a Gharcha backup.
  Future<bool> restoreBackup(String backup) async {
    if (!await _store.restore(backup)) return false;
    celebrations.clear();
    await load();
    notifyListeners();
    unawaited(syncNotifications());
    return true;
  }

  String exportCsv({DateTime? month}) {
    final list = (month == null ? [...expenses] : inMonth(month))..sort((a, b) => a.day.compareTo(b.day));
    return Csv.encode([
      Csv.header,
      for (final e in list)
        [Csv.isoDate(e.date), e.title, category(e.category).name, e.mode.name.toUpperCase(), e.amount.toString(), memberName(e.paidBy), e.groupId?.toString() ?? '', e.note],
    ]);
  }

  Future<ImportResult?> importCsv(String text) async {
    final rows = Csv.parse(text);
    if (rows.isEmpty) return null;
    final head = rows.first.map((c) => c.trim().toLowerCase()).toList();
    int col(String name) => head.indexOf(name);
    if (col('date') < 0 || col('title') < 0 || col('amount') < 0) return null;
    String cell(List<String> row, String name) => col(name) >= 0 && col(name) < row.length ? row[col(name)].trim() : '';
    String keyOf(Expense e) => '${e.day}|${e.title.toLowerCase()}|${e.amount.toStringAsFixed(2)}';
    final existing = expenses.map(keyOf).toSet();
    var added = 0, duplicates = 0, invalid = 0;
    for (final row in rows.skip(1)) {
      final date = Csv.parseDate(cell(row, 'date'));
      final amount = double.tryParse(cell(row, 'amount').replaceAll('−', '-').replaceAll(',', ''));
      final title = cell(row, 'title');
      if (date == null || amount == null || amount == 0 || title.isEmpty) {
        invalid++;
        continue;
      }
      final categoryName = cell(row, 'category').toLowerCase();
      final payer = cell(row, 'paid_by').toLowerCase();
      final e = Expense(
        title: title.capitalised,
        amount: amount,
        category: categories.where((c) => c.name.toLowerCase() == categoryName || c.key.toLowerCase() == categoryName).firstOrNull?.key ?? BuiltInCategories.other,
        mode: PaymentMode.values.where((m) => m.name == cell(row, 'payment_mode').toLowerCase()).firstOrNull ?? PaymentMode.cash,
        day: Days.key(date),
        paidBy: members.where((m) => m.name.toLowerCase() == payer).firstOrNull?.id ?? settings.activeMemberId,
        note: cell(row, 'note'),
      );
      if (!existing.add(keyOf(e))) {
        duplicates++;
        continue;
      }
      await _store.save(e);
      expenses.add(e);
      added++;
    }
    await _afterChange();
    return ImportResult(added, duplicates, invalid);
  }

  // ---- Daily housekeeping and notifications

  Future<void> _dailyChecks() async {
    final today = Days.today();
    final previous = Days.addMonths(today, -1);
    if (settings.lastBudgetCheckMonth < Days.monthKey(previous)) {
      final list = inMonth(previous);
      if (settings.monthlyBudget > 0 && list.any((e) => e.amount > 0) && net(list) <= settings.monthlyBudget && settings.budgetMonthsWon.add(Days.monthKey(previous))) {
        await _award(PointsRules.monthUnderBudget, PointReasons.encode(PointReasons.budget, Fmt.monthYear(previous)));
      }
      settings.lastBudgetCheckMonth = Days.monthKey(previous);
    }
    final now = DateTime.now();
    for (final r in reminders.where((r) => r.enabled && r.autoLog && r.isBill)) {
      for (var i = 31; i >= 0; i--) {
        final day = DateTime(today.year, today.month, today.day - i);
        final due = DateTime(day.year, day.month, day.day, r.hour, r.minute);
        if (Days.key(day) <= r.lastLoggedDay || !r.occursOn(day) || due.isAfter(now)) continue;
        r.lastLoggedDay = Days.key(day);
        await _store.save(r);
        final e = Expense(title: r.title, amount: r.amount!, category: r.category ?? BuiltInCategories.other, mode: PaymentMode.bank, day: Days.key(day), paidBy: members.where((m) => m.isOwner).firstOrNull?.id ?? settings.activeMemberId);
        await _store.save(e);
        expenses.add(e);
        Notifier.show(Channel.autolog, tr('notif_autolog_title', [r.title]), tr('notif_autolog_body', [Fmt.money(e.amount)]), route: 'expenses');
      }
    }
    final f = festival;
    if (f != null && settings.festiveMode && !settings.festivalsSeen.contains(f.key)) {
      celebrations.add(Celebration(CelebrationKind.festival,
          title: f.festival.title(me?.name ?? ''), body: f.festival.line, sound: f.festival.pack.sound, festival: f));
    }
    await _checkBadges();
    await _store.saveSettings(settings);
    await syncNotifications();
  }

  /// A notification's title ([part] 0) or body (1): a random roast from the pools when the tone is spicy, one plain line otherwise.
  String _copy(String kind, int part, [List<Object?> args = const []]) {
    final spicy = settings.tone == NotifTone.spicy;
    return part == 0
        ? (spicy ? trPick('notif_${kind}_titles', args) : tr('plain_${kind}_title', args))
        : (spicy ? trPick('notif_${kind}_bodies', args) : tr('plain_${kind}_body', args));
  }

  /// Reschedules every notification. Runs one pass at a time; a call made meanwhile queues one more pass.
  Future<void> syncNotifications() async {
    if (_syncing) {
      _syncAgain = true;
      return;
    }
    _syncing = true;
    try {
      do {
        _syncAgain = false;
        await _schedule();
      } while (_syncAgain);
    } catch (e) {
      debugPrint('Notification sync failed: $e');
    } finally {
      _syncing = false;
    }
  }

  bool _syncing = false;
  bool _syncAgain = false;

  Future<void> _schedule() async {
    await Notifier.cancelAll();
    if (!settings.onboarded) return;
    final now = DateTime.now();
    if (settings.reminderNotifs) {
      for (final r in reminders.where((r) => r.enabled)) {
        final next = r.nextAfter(now);
        if (next == null) continue;
        List<String> copy() => r.isBill
            ? [_copy('bill', 0, [r.title]), _copy('bill', 1, ['${r.title} · ${Fmt.money(r.amount!)}'])]
            : [_copy('nudge', 0), _copy('nudge', 1, [r.title])];
        final channel = r.isBill ? Channel.bills : Channel.nudges;
        final route = r.isBill ? 'reminders' : 'add';
        if (r.repeat == RepeatRule.daily) {
          for (var slot = 0; slot < 7; slot++) {
            final line = copy();
            final when = next.add(Duration(days: slot));
            await Notifier.schedule(NotificationIds.reminder(r.id, slot), channel, when, line[0], line[1], route: route, repeat: slot == 6 ? DateTimeComponents.time : null);
          }
        } else {
          final line = copy();
          final repeat = switch (r.repeat) {
            RepeatRule.weekly => DateTimeComponents.dayOfWeekAndTime,
            RepeatRule.monthly => DateTimeComponents.dayOfMonthAndTime,
            RepeatRule.yearly => DateTimeComponents.dateAndTime,
            _ => null,
          };
          await Notifier.schedule(NotificationIds.reminder(r.id, 0), channel, next, line[0], line[1], route: route, repeat: repeat);
          final early = next.subtract(const Duration(days: 3));
          if (r.isBill && early.isAfter(now)) {
            await Notifier.schedule(NotificationIds.reminder(r.id, NotificationIds.earlySlot), channel, early, tr('bill_early_title', [r.title]), tr('bill_early_body', [Fmt.money(r.amount!), Fmt.date(next, 'd MMM')]), route: route);
          }
        }
      }
      for (final p in papers) {
        final expiry = Days.fromKey(p.expiryDay);
        for (final (slot, daysBefore) in const [7, 0].indexed) {
          final when = DateTime(expiry.year, expiry.month, expiry.day - daysBefore, 9);
          if (when.isAfter(now)) await Notifier.schedule(NotificationIds.paper(p.id) * 2 + slot, Channel.bills, when, tr('paper_notice_title', [p.name]), tr(daysBefore == 0 ? 'paper_notice_today' : 'paper_notice_week', [Fmt.date(expiry, 'd MMM yyyy')]), route: 'reminders');
        }
      }
      for (final l in loans.where((l) => !l.settled && l.dueDay != null)) {
        final due = Days.fromKey(l.dueDay!);
        for (final (slot, daysAfter) in const [0, 3].indexed) {
          final body = l.amount > 0 ? (daysAfter == 0 ? 'loan_notice_get' : 'loan_notice_get_late') : (daysAfter == 0 ? 'loan_notice_pay' : 'loan_notice_pay_late');
          await Notifier.schedule(NotificationIds.loan(l.id) * 2 + slot, Channel.bills, DateTime(due.year, due.month, due.day + daysAfter, 10), tr('loan_notice_title', [l.person]), tr(body, [Fmt.money(l.amount.abs())]), route: 'loans');
        }
      }
      for (final c in chits.where((c) => !c.done)) {
        final due = c.nextDue;
        await Notifier.schedule(NotificationIds.chit(c.id), Channel.bills, DateTime(due.year, due.month, 1, 9, 15), tr('chit_notice_title', [c.name]), tr('chit_notice_body', [Fmt.money(c.monthlyAmount)]), route: 'savings');
      }
      final nextMonth = DateTime(now.year, now.month + 1, 1, 9);
      final unpaid = services.where((s) => !s.paidMonths.containsKey(Days.monthKey(now))).map((s) => s.name).join(', ');
      if (unpaid.isNotEmpty) {
        await Notifier.schedule(NotificationIds.services, Channel.bills, nextMonth, tr('service_notice_title', [Fmt.month(now)]), tr('service_notice_body', [unpaid]), route: 'services');
      }
      final days = streak;
      if (days >= 2 && settings.tone != NotifTone.quiet) {
        final tonight = DateTime(now.year, now.month, now.day, 21, 30);
        final when = loggedToday ? tonight.add(const Duration(days: 1)) : tonight;
        await Notifier.schedule(NotificationIds.streakRisk, Channel.streakRisk, when, _copy('streak_risk', 0, [days]), _copy('streak_risk', 1, [days]), route: 'add');
      }
      if (settings.tone != NotifTone.quiet) {
        final comeback = DateTime(now.year, now.month, now.day + 3, 19);
        await Notifier.schedule(NotificationIds.comeback, Channel.nudges, comeback, _copy('comeback', 0), _copy('comeback', 1, [me?.name ?? '']), route: 'add');
        final sunday = DateTime(now.year, now.month, now.day + (DateTime.sunday - now.weekday) % 7, 10);
        await Notifier.schedule(NotificationIds.weekly, Channel.nudges, sunday.isAfter(now) ? sunday : sunday.add(const Duration(days: 7)), _copy('weekly', 0), _copy('weekly', 1, [me?.name ?? '']),
            route: 'insights', repeat: DateTimeComponents.dayOfWeekAndTime);
        final open = goals.where((g) => g.left > 0);
        if (open.isNotEmpty) {
          final aside = open.fold(0.0, (sum, g) => sum + (g.monthly(nextMonth) ?? 0));
          await Notifier.schedule(NotificationIds.goals, Channel.nudges, nextMonth.add(const Duration(hours: 1)), tr('goal_notice_title'), aside > 0 ? tr('goal_notice_body', [Fmt.money(aside.roundToDouble())]) : tr('goal_notice_open'), route: 'goals');
        }
        if (inMonth(now).isNotEmpty) {
          await Notifier.schedule(NotificationIds.recap, Channel.nudges, nextMonth.add(const Duration(minutes: 30)), tr('recap_title', [Fmt.monthYear(now)]), tr('recap_sub'), route: 'home');
        }
        final owed = myDues.values.where((d) => d > 0).fold(0.0, (sum, d) => sum + d), owe = myDues.values.where((d) => d < 0).fold(0.0, (sum, d) => sum - d);
        final pending = [if (owed > 0) tr('digest_owed', [Fmt.money(owed)]), if (owe > 0) tr('digest_owe', [Fmt.money(owe)]), if (totalKhataDue > 0) tr('digest_khata', [Fmt.money(totalKhataDue)])];
        if (pending.isNotEmpty) {
          final saturday = DateTime(now.year, now.month, now.day + (DateTime.saturday - now.weekday) % 7, 10);
          await Notifier.schedule(NotificationIds.dues, Channel.nudges, saturday.isAfter(now) ? saturday : saturday.add(const Duration(days: 7)), tr('digest_title'), pending.join(' · '), route: 'home');
        }
      }
    }
    final greeting = FestivalCalendar.nextGreeting(now);
    if (settings.festiveMode && greeting != null) {
      final f = greeting.$1.festival;
      await Notifier.schedule(NotificationIds.festival, Channel.festival, greeting.$2, f.title(me?.name ?? ''), f.line, route: 'home', sound: f.pack.sound);
    }
  }
}

class AppScope extends InheritedNotifier<AppState> {
  const AppScope({super.key, required AppState state, required super.child}) : super(notifier: state);

  static AppState of(BuildContext context) => context.dependOnInheritedWidgetOfExactType<AppScope>()!.notifier!;
  static AppState read(BuildContext context) => context.getInheritedWidgetOfExactType<AppScope>()!.notifier!;
}
