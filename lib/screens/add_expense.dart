import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../core/app_state.dart';
import '../core/catalogs.dart';
import '../core/format.dart';
import '../core/l10n.dart';
import '../core/models.dart';
import '../core/parsers.dart';
import '../ui/glyphs.dart';
import '../ui/theme.dart';
import '../ui/widgets.dart';
import 'cards.dart';
import 'common.dart';
import 'export.dart';

class AddExpenseScreen extends StatefulWidget {
  const AddExpenseScreen({super.key, this.editing, this.startWithVoice = false, this.firstTime = false, this.groupId, this.draft, this.draftDay, this.onSaved});
  final Expense? editing;
  final bool startWithVoice;

  /// Opened straight after setup: greets the user and asks for their first entry.
  final bool firstTime;

  /// Values to start a new entry from (a captured payment, a shopping trip), with its date if it has one.
  final VoiceResult? draft;
  final DateTime? draftDay;

  /// Runs after the new entry is saved.
  final VoidCallback? onSaved;
  final int? groupId;

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> with SingleTickerProviderStateMixin {
  final _speech = SpeechToText();
  final _amountCtrl = TextEditingController();
  final _amountFocus = FocusNode();
  final _title = TextEditingController();
  final _note = TextEditingController();
  late final AnimationController _bump = AnimationController(vsync: this, duration: const Duration(milliseconds: 220));
  bool _credit = false;
  bool _listening = false;
  bool _voiceUsed = false;
  bool _noteFromVoice = false;
  bool _saved = false;
  bool _repeat = false;
  String _photo = '';
  int? _account;
  String _heard = '';
  String _category = BuiltInCategories.other;
  DateTime _day = Days.today();
  int _paidBy = 0;
  PaymentMode _mode = PaymentMode.upi;
  int? _groupId;
  SplitType _split = SplitType.equal;
  final Map<int, String> _custom = {};
  bool _ready = false;

  void _setAmountText(String v) {
    _amountCtrl.value = TextEditingValue(
      text: v,
      selection: TextSelection.collapsed(offset: v.length),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_ready) return;
    _ready = true;
    final app = AppScope.read(context);
    final e = widget.editing;
    _paidBy = app.settings.activeMemberId;
    _groupId = widget.groupId;
    if (e != null) {
      _setAmountText(Fmt.number(e.amount).replaceAll(',', ''));
      _credit = e.isCredit;
      _title.text = e.title;
      _note.text = e.note;
      _photo = e.photo;
      _account = e.accountId;
      _category = e.category;
      _day = e.date;
      _paidBy = e.paidBy;
      _mode = e.mode;
      _groupId = e.groupId;
      _split = e.splitType == SplitType.none ? SplitType.equal : e.splitType;
      e.shares.forEach((id, share) => _custom[id] = Fmt.number(_split == SplitType.percent && e.amount != 0 ? share / e.amount * 100 : share).replaceAll(',', ''));
    }
    final d = widget.draft;
    if (d != null) {
      if (d.amount != null) {
        _setAmountText(Fmt.number(d.amount!).replaceAll(',', ''));
      }
      _credit = d.credit;
      _title.text = d.title;
      _note.text = d.note ?? '';
      _category = app.categoryFor(d.title) ?? d.categoryKey ?? VoiceParser.parse(d.title, AppScope.read(context).customCategoryNames).categoryKey ?? _category;
      _mode = d.mode ?? _mode;
      final day = widget.draftDay;
      if (day != null) _day = Days.of(day.isAfter(DateTime.now()) ? DateTime.now() : day);
    }
    if (widget.startWithVoice) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _listen());
    } else if (e == null && d?.amount == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _amountFocus.requestFocus();
      });
    }
  }

  @override
  void dispose() {
    _speech.stop();
    _amountCtrl.dispose();
    _amountFocus.dispose();
    _title.dispose();
    _note.dispose();
    _bump.dispose();
    super.dispose();
  }

  double get _value => double.tryParse(_amountCtrl.text.trim()) ?? 0.0;

  Future<void> _listen() async {
    if (_listening) {
      await _speech.stop();
      setState(() => _listening = false);
      return;
    }
    FocusScope.of(context).unfocus();
    final available = await _speech.initialize(
      onError: (_) {
        if (mounted) setState(() => _listening = false);
      },
      onStatus: (status) {
        if (mounted && status != 'listening') setState(() => _listening = false);
      },
    );
    if (!mounted) return;
    if (!available) {
      toast(context, tr('voice_unavailable'));
      return;
    }
    setState(() {
      _listening = true;
      _heard = '';
    });
    await _speech.listen(
      localeId: const {'en': 'en_IN', 'hi': 'hi_IN', 'gu': 'gu_IN'}[L10n.lang],
      onResult: (result) {
        if (!mounted) return;
        setState(() => _heard = result.recognizedWords);
        if (result.finalResult) _applyVoice(result.recognizedWords);
      },
    );
  }

  void _applyVoice(String words) {
    if (words.trim().isEmpty) return;
    _voiceUsed = true;
    _fill(VoiceParser.parse(words, AppScope.read(context).customCategoryNames), words);
  }

  Future<void> _paste() async {
    final text = (await Clipboard.getData(Clipboard.kTextPlain))?.text?.trim() ?? '';
    if (!mounted) return;
    final parsed = text.isEmpty ? null : MessageParser.parse(text, AppScope.read(context).customCategoryNames) ?? VoiceParser.parse(text, AppScope.read(context).customCategoryNames);
    if (parsed?.amount == null) {
      toast(context, tr('paste_nothing'));
      return;
    }
    _fill(parsed!, text);
  }

  void _usePick(Expense p) {
    HapticFeedback.selectionClick();
    setState(() {
      _title.text = p.title;
      _setAmountText(Fmt.number(p.amount).replaceAll(',', ''));
      _category = p.category;
      _mode = p.mode;
      _account = p.accountId;
    });
    _bump.forward(from: 0).whenComplete(() => _bump.reverse());
  }

  void _fill(VoiceResult parsed, String words) {
    setState(() {
      _listening = false;
      _credit = parsed.credit;
      if (parsed.amount != null) _setAmountText(Fmt.number(parsed.amount!).replaceAll(',', ''));
      if (parsed.title.isNotEmpty) _title.text = parsed.title;
      _category = AppScope.read(context).categoryFor(parsed.title) ?? parsed.categoryKey ?? _category;
      if (parsed.mode != null) _mode = parsed.mode!;
      if (_note.text.isEmpty || _noteFromVoice) {
        _note.text = parsed.note ?? words.capitalised;
        _noteFromVoice = true;
      }
    });
    _bump.forward(from: 0).whenComplete(() => _bump.reverse());
  }

  Map<int, double>? _shares(Group? group) {
    if (group == null || _credit) return {};
    if (_split == SplitType.equal) return SplitCalculator.equalShares(_value, group.memberIds);
    final typed = {for (final id in group.memberIds) id: double.tryParse(_custom[id] ?? '') ?? 0.0};
    final total = typed.values.fold(0.0, (a, b) => a + b);
    return switch (_split) {
      SplitType.percent => (total - 100).abs() < 0.005 ? typed.map((id, v) => MapEntry(id, _value * v / 100)) : null,
      SplitType.weights => total > 0 ? typed.map((id, v) => MapEntry(id, _value * v / total)) : null,
      _ => (total - _value).abs() < 0.005 ? typed : null,
    };
  }

  double _typedTotal(Group group) => group.memberIds.fold(0.0, (a, id) => a + (double.tryParse(_custom[id] ?? '') ?? 0));

  Future<void> _save(Group? group) async {
    FocusScope.of(context).unfocus();
    final app = AppScope.read(context);
    final shares = _shares(group)!;
    final e = widget.editing ??
        Expense(title: '', amount: 0, category: _category, day: Days.key(_day), paidBy: _paidBy);
    e
      ..title = _title.text.trim().isEmpty ? app.category(_category).name : _title.text
      ..amount = _credit ? -_value : _value
      ..category = _category
      ..mode = _mode
      ..day = Days.key(_day)
      ..paidBy = _paidBy
      ..groupId = _credit ? null : group?.id
      ..splitType = group == null || _credit ? SplitType.none : _split
      ..shares = shares
      ..note = _note.text
      ..photo = _photo
      ..accountId = app.accounts.any((a) => a.id == _account) ? _account : null;
    HapticFeedback.heavyImpact();
    setState(() => _saved = true);
    await app.saveExpense(e, voice: _voiceUsed && widget.editing == null);
    widget.onSaved?.call();
    if (_repeat) await app.saveReminder(Reminder(title: e.title, hour: 9, minute: 0, dayOfMonth: _day.day, amount: _value, category: _category, autoLog: true, lastLoggedDay: e.day));
    await Future<void>.delayed(const Duration(milliseconds: 650));
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _delete() async {
    final app = AppScope.read(context);
    final e = widget.editing!;
    Navigator.of(context).pop();
    toast(context, tr('deleted_msg', [e.title]), onUndo: () => app.restoreExpense(e));
    await app.deleteExpense(e);
  }

  Future<void> _photoSheet() async {
    final name = await pickPhoto(context, title: tr('receipt_photo'), current: _photo);
    if (name != null && mounted) setState(() => _photo = name);
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(context: context, initialDate: _day, firstDate: DateTime(2015), lastDate: DateTime(Days.today().year + 2));
    if (picked != null) setState(() => _day = Days.of(picked));
  }

  Future<void> _pickGroup(AppState app) async {
    final picked = await showKSheet<int>(
      context,
      title: tr('split_with_group'),
      builder: (sheet) => Column(children: [
        if (app.groups.isEmpty) Padding(padding: const EdgeInsets.all(12), child: Text(tr('no_groups_hint'), style: sheet.tt.bodyMedium)),
        NavRow(icon: Icons.person_rounded, title: tr('not_shared'), onTap: () => Navigator.of(sheet).pop(0), trailing: _groupId == null ? Icon(Icons.check_circle_rounded, color: sheet.cs.primary) : const SizedBox()),
        for (final g in app.groups)
          NavRow(
            icon: Icons.groups_rounded,
            title: g.name,
            subtitle: g.memberIds.map(app.memberName).join(', '),
            onTap: () => Navigator.of(sheet).pop(g.id),
            trailing: _groupId == g.id ? Icon(Icons.check_circle_rounded, color: sheet.cs.primary) : const SizedBox(),
          ),
      ]),
    );
    if (picked != null) setState(() => _groupId = picked == 0 ? null : picked);
  }

  Future<void> _moreDetailsSheet(AppState app, bool editing) async {
    FocusScope.of(context).unfocus();
    final today = Days.today();
    final quickDays = {
      tr('yesterday'): DateTime(today.year, today.month, today.day - 1),
      tr('today'): today,
      tr('tomorrow'): DateTime(today.year, today.month, today.day + 1),
    };
    await showKSheet<void>(
      context,
      title: tr('more_details'),
      builder: (sheet) => StatefulBuilder(
        builder: (sheetCtx, setSheet) {
          void sync(VoidCallback fn) {
            setState(fn);
            setSheet(() {});
          }

          final cs = sheetCtx.cs;
          final group = app.groups.where((g) => g.id == _groupId).firstOrNull;
          final shares = _shares(group);

          return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            NavRow(
              icon: Icons.calendar_month_rounded,
              color: const Color(0xFF039BE5),
              title: tr('date'),
              subtitle: Fmt.relativeDay(_day),
              onTap: () async {
                await _pickDate();
                if (sheetCtx.mounted) setSheet(() {});
              },
            ),
            const SizedBox(height: 6),
            Row(children: [
              for (final q in quickDays.entries)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: Pressable(
                      onTap: () => sync(() => _day = q.value),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(color: _day == q.value ? cs.primary : cs.surfaceContainerHighest, borderRadius: BorderRadius.circular(14)),
                        child: FittedBox(child: Text(q.key, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _day == q.value ? Colors.white : cs.onSurface))),
                      ),
                    ),
                  ),
                ),
            ]),
            if (app.accounts.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(tr('account'), style: sheetCtx.tt.labelMedium),
              const SizedBox(height: 8),
              Wrap(spacing: 8, runSpacing: 8, children: [
                for (final a in app.accounts) KChip(a.name, selected: _account == a.id, onTap: () => sync(() => _account = _account == a.id ? null : a.id)),
              ]),
            ],
            if (!_credit) ...[
              const SizedBox(height: 14),
              NavRow(
                icon: Icons.groups_rounded,
                color: const Color(0xFF7C4DFF),
                title: tr('split_with_group'),
                subtitle: group == null ? tr('not_shared') : group.name,
                onTap: () async {
                  await _pickGroup(app);
                  if (sheetCtx.mounted) setSheet(() {});
                },
              ),
              if (group != null) ...[
                const SizedBox(height: 8),
                Wrap(spacing: 8, runSpacing: 8, children: [
                  for (final type in const [SplitType.equal, SplitType.custom, SplitType.percent, SplitType.weights])
                    KChip(tr('split_${type.name}'), selected: _split == type, onTap: () => sync(() {
                          _split = type;
                          _custom.clear();
                        })),
                ]),
                const SizedBox(height: 10),
                for (final id in group.memberIds)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(children: [
                      Expanded(child: Text(app.memberName(id), maxLines: 1, overflow: TextOverflow.ellipsis, style: sheetCtx.tt.titleSmall)),
                      if (_split == SplitType.equal || _split == SplitType.percent || _split == SplitType.weights)
                        Padding(padding: const EdgeInsets.only(right: 10), child: Text(shares == null ? '' : Fmt.money(shares[id] ?? 0), style: _split == SplitType.equal ? sheetCtx.tt.titleSmall : sheetCtx.tt.bodySmall)),
                      if (_split != SplitType.equal)
                        SizedBox(
                          width: 104,
                          child: TextFormField(
                            key: ValueKey('share${_split.name}$id'),
                            initialValue: _custom[id] ?? '',
                            textAlign: TextAlign.end,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
                            onChanged: (v) => sync(() => _custom[id] = v),
                            decoration: InputDecoration(isDense: true, prefixText: _split == SplitType.custom ? Fmt.symbol : null, suffixText: _split == SplitType.percent ? '%' : null, contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10)),
                          ),
                        ),
                    ]),
                  ),
                if (_split == SplitType.custom) _SharesStatus(_value - _typedTotal(group), Fmt.money),
                if (_split == SplitType.percent) _SharesStatus(100 - _typedTotal(group), (v) => '${Fmt.number(v)}%'),
                if (_split == SplitType.weights) Padding(padding: const EdgeInsets.only(top: 8), child: Text(tr('weights_hint'), style: sheetCtx.tt.bodySmall)),
              ],
            ],
            if (!editing && !_credit) ...[
              const SizedBox(height: 10),
              NavRow(
                icon: Icons.event_repeat_rounded,
                color: const Color(0xFF26A69A),
                title: tr('repeat_monthly'),
                subtitle: tr('repeat_monthly_sub', [_day.day]),
                trailing: KSwitch(value: _repeat, onChanged: (on) => sync(() => _repeat = on)),
              ),
            ],
            const SizedBox(height: 10),
            NavRow(
              icon: Icons.receipt_long_rounded,
              color: const Color(0xFF8D6E63),
              title: tr('receipt_photo'),
              subtitle: _photo.isEmpty ? tr('receipt_photo_add') : tr('receipt_photo_added'),
              onTap: () async {
                await _photoSheet();
                if (sheetCtx.mounted) setSheet(() {});
              },
              trailing: _photo.isEmpty ? null : ClipRRect(borderRadius: BorderRadius.circular(10), child: Image.file(File('${app.photosDir}/$_photo'), width: 44, height: 44, fit: BoxFit.cover)),
            ),
            const SizedBox(height: 14),
            KField(controller: _note, label: tr('note'), hint: tr('note_hint'), icon: Icons.sticky_note_2_rounded, lines: 2, onChanged: (_) => _noteFromVoice = false),
          ]);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final cs = context.cs;
    final group = app.groups.where((g) => g.id == _groupId).firstOrNull;
    final shares = _shares(group);
    final canSave = _value > 0 && shares != null && !_saved;
    final editing = widget.editing != null;
    final picks = app.quickPicks(_title.text);
    final accent = _credit ? good : cs.primary;
    final cat = app.category(_category);

    final moreSummary = [
      Fmt.relativeDay(_day),
      if (group != null) group.name,
      if (_account != null) app.accounts.where((a) => a.id == _account).firstOrNull?.name,
      if (_repeat) tr('repeat_monthly'),
      if (_photo.isNotEmpty) tr('receipt_photo'),
      if (_note.text.trim().isNotEmpty) tr('note'),
    ].whereType<String>().join(' · ');

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Backdrop(
        child: Stack(children: [
          SafeArea(
            child: Column(children: [
              // Familiar Gharcha top header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 4),
                child: Row(children: [
                  RoundIcon(Icons.close_rounded, onTap: () => Navigator.of(context).pop()),
                  const SizedBox(width: 12),
                  Expanded(child: Text(editing ? tr('edit_expense') : _credit ? tr('add_credit') : tr('add_transaction'), style: context.tt.headlineSmall)),
                  if (editing) ...[
                    RoundIcon(Icons.ios_share_rounded, onTap: () => shareCard(context, ReceiptCard(widget.editing!), file: 'gharcha-expense', text: '${widget.editing!.title} · ${Fmt.ledger(widget.editing!.amount)}')),
                    const SizedBox(width: 8),
                    RoundIcon(Icons.delete_outline_rounded, onTap: _delete),
                  ],
                ]),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                  physics: const BouncingScrollPhysics(),
                  children: [
                    if (widget.firstTime)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: KCard(
                          padding: const EdgeInsets.all(14),
                          child: Row(children: [
                            const Sticker('receipt', size: 48),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text(tr('first_log_title'), style: context.tt.titleMedium!.copyWith(fontWeight: FontWeight.w700)),
                                Text(tr('first_log_body', [PointsRules.logExpense + PointsRules.firstLogOfDay]), style: context.tt.bodySmall),
                              ]),
                            ),
                          ]),
                        ),
                      ),
                    // Speak & Paste compact row right above amount
                    Row(children: [
                      Expanded(
                        child: Tooltip(
                          message: tr('voice_title'),
                          child: Pressable(
                            onTap: _listen,
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 220),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              decoration: BoxDecoration(
                                color: _listening ? cs.primary : cs.primaryContainer,
                                borderRadius: BorderRadius.circular(18),
                              ),
                              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                                _MicPulse(active: _listening),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: Text(
                                    _listening ? (_heard.isNotEmpty ? _heard : tr('voice_prompt')) : tr('voice_short'),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: context.tt.labelLarge!.copyWith(color: _listening ? Colors.white : cs.onPrimaryContainer, fontWeight: FontWeight.w700),
                                  ),
                                ),
                              ]),
                            ),
                          ),
                        ),
                      ),
                      if (!editing) ...[
                        const SizedBox(width: 10),
                        Expanded(
                          child: Tooltip(
                            message: '${tr('paste_title')}: ${tr('paste_sub')}',
                            child: Pressable(
                              onTap: _paste,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                                decoration: BoxDecoration(
                                  color: cs.surface,
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(color: cs.outlineVariant),
                                ),
                                child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                                  Icon(Icons.content_paste_go_rounded, size: 19, color: cs.primary),
                                  const SizedBox(width: 8),
                                  Flexible(
                                    child: Text(
                                      tr('paste_short'),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: context.tt.labelLarge!.copyWith(fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                ]),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ]),
                    if (_listening)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(tr('voice_subtitle'), textAlign: TextAlign.center, style: context.tt.bodySmall),
                      ),
                    const SizedBox(height: 10),
                    Segmented<bool>(
                      options: {false: tr('kind_expense'), true: tr('kind_credit')},
                      value: _credit,
                      color: accent,
                      onChanged: (credit) => setState(() => _credit = credit),
                    ),
                    // Editable amount with native cursor (supports editing any digit)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Column(children: [
                        ScaleTransition(
                          scale: Tween(begin: 1.0, end: 1.08).animate(CurvedAnimation(parent: _bump, curve: Curves.easeOut, reverseCurve: Curves.easeIn)),
                          child: Row(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, children: [
                            Text(_credit ? '+${Fmt.symbol}' : Fmt.symbol, style: context.tt.displaySmall!.copyWith(fontSize: 36, color: accent.withValues(alpha: 0.78))),
                            const SizedBox(width: 6),
                            IntrinsicWidth(
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(minWidth: 52, maxWidth: 240),
                                child: TextField(
                                  controller: _amountCtrl,
                                  focusNode: _amountFocus,
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  textAlign: TextAlign.center,
                                  cursorColor: accent,
                                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d{0,9}(\.\d{0,2})?$'))],
                                  style: context.tt.displaySmall!.copyWith(fontSize: 54, color: accent, fontWeight: FontWeight.w700),
                                  decoration: InputDecoration(
                                    border: InputBorder.none,
                                    enabledBorder: InputBorder.none,
                                    focusedBorder: InputBorder.none,
                                    filled: false,
                                    isDense: true,
                                    contentPadding: EdgeInsets.zero,
                                    hintText: '0',
                                    hintStyle: context.tt.displaySmall!.copyWith(fontSize: 54, color: cs.onSurfaceVariant.withValues(alpha: 0.45)),
                                  ),
                                  onChanged: (_) => setState(() {}),
                                ),
                              ),
                            ),
                          ]),
                        ),
                        if (_credit) Padding(padding: const EdgeInsets.only(top: 4), child: Text(tr('credit_hint'), textAlign: TextAlign.center, style: context.tt.bodySmall)),
                      ]),
                    ),
                    // Main compact card: What for + top 3 picks + Category row + Payment mode + Paid by (wrapped)
                    KCard(
                      padding: const EdgeInsets.all(16),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        KField(controller: _title, label: tr('what_for'), hint: tr('what_for_hint'), onChanged: (_) => setState(() {})),
                        if (!editing && picks.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              for (final p in picks.take(3))
                                KChip('${p.title} · ${Fmt.money(p.amount)}', selected: false, icon: app.category(p.category).icon, color: app.category(p.category).tint, onTap: () => _usePick(p)),
                            ],
                          ),
                        ],
                        const SizedBox(height: 10),
                        NavRow(
                          icon: cat.icon,
                          color: cat.tint,
                          title: tr('category'),
                          subtitle: cat.name,
                          onTap: () async {
                            FocusScope.of(context).unfocus();
                            final picked = await pickCategory(context, selected: _category);
                            if (picked != null) setState(() => _category = picked);
                          },
                        ),
                        const SizedBox(height: 12),
                        Text(tr('payment_mode'), style: context.tt.labelMedium),
                        const SizedBox(height: 8),
                        Row(children: [
                          for (final m in PaymentMode.values)
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 3),
                                child: Pressable(
                                  scale: 0.92,
                                  onTap: () => setState(() => _mode = m),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    padding: const EdgeInsets.symmetric(vertical: 10),
                                    decoration: BoxDecoration(
                                      color: _mode == m ? m.color.withValues(alpha: context.isDark ? 0.3 : 0.14) : cs.surfaceContainerHighest,
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(color: _mode == m ? m.color : Colors.transparent, width: 2),
                                    ),
                                    child: Column(children: [
                                      Icon(m.icon, size: 20, color: _mode == m ? m.color : cs.onSurfaceVariant),
                                      const SizedBox(height: 3),
                                      Text(m.label, maxLines: 1, style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: _mode == m ? cs.onSurface : cs.onSurfaceVariant)),
                                    ]),
                                  ),
                                ),
                              ),
                            ),
                        ]),
                        const SizedBox(height: 14),
                        Text(tr('paid_by'), style: context.tt.labelMedium),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (final m in app.members)
                              MemberChip(m, selected: _paidBy == m.id, onTap: () => setState(() => _paidBy = m.id)),
                          ],
                        ),
                      ]),
                    ),
                    const SizedBox(height: 12),
                    // Secondary details tucked cleanly below
                    KCard(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      child: NavRow(
                        icon: Icons.tune_rounded,
                        color: cs.primary,
                        title: tr('more_details'),
                        subtitle: moreSummary,
                        onTap: () => _moreDetailsSheet(app, editing),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 6, 20, 12),
                child: KButton(
                  editing ? tr('save_changes') : _credit ? tr('save_credit') : tr('save_expense'),
                  icon: Icons.check_rounded,
                  onTap: canSave ? () => _save(group) : null,
                ),
              ),
            ]),
          ),
          if (_saved) Positioned.fill(child: _SavedBurst(colour: accent)),
        ]),
      ),
    );
  }
}

class _SharesStatus extends StatelessWidget {
  const _SharesStatus(this.left, this.format);
  final double left;
  final String Function(num value) format;

  @override
  Widget build(BuildContext context) {
    final ok = left.abs() < 0.005;
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Text(ok ? tr('shares_ok') : left > 0 ? tr('shares_left', [format(left)]) : tr('shares_over', [format(-left)]), style: context.tt.labelMedium!.copyWith(color: ok ? good : bad)),
    );
  }
}

class _MicPulse extends StatefulWidget {
  const _MicPulse({required this.active});
  final bool active;

  @override
  State<_MicPulse> createState() => _MicPulseState();
}

class _MicPulseState extends State<_MicPulse> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1100))..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    return SizedBox(
      width: 30,
      height: 30,
      child: AnimatedBuilder(
        animation: _c,
        builder: (_, child) => Stack(alignment: Alignment.center, children: [
          if (widget.active)
            for (final offset in [0.0, 0.5])
              Opacity(
                opacity: 1 - (_c.value + offset) % 1,
                child: Transform.scale(scale: 0.6 + 0.9 * ((_c.value + offset) % 1), child: Container(decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: 0.35)))),
              ),
          child!,
        ]),
        child: Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(shape: BoxShape.circle, color: widget.active ? Colors.white : cs.primary),
          child: Icon(widget.active ? Icons.graphic_eq_rounded : Icons.mic_rounded, color: widget.active ? cs.primary : Colors.white, size: 15),
        ),
      ),
    );
  }
}

/// The save moment: the screen floods with the accent colour and a tick springs in.
class _SavedBurst extends StatelessWidget {
  const _SavedBurst({required this.colour});
  final Color colour;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 620),
      builder: (_, v, __) => ColoredBox(
        color: colour.withValues(alpha: (v * 2.2).clamp(0.0, 0.96).toDouble()),
        child: Center(
          child: Transform.scale(
            scale: Curves.elasticOut.transform((v * 1.25).clamp(0.0, 1.0).toDouble()),
            child: Container(
              width: 112,
              height: 112,
              decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
              child: Icon(Icons.check_rounded, size: 72, color: colour),
            ),
          ),
        ),
      ),
    );
  }
}
