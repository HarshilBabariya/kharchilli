import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../core/app_state.dart';
import '../core/catalogs.dart';
import '../core/format.dart';
import '../core/l10n.dart';
import '../core/models.dart';
import '../core/parsers.dart';
import '../ui/theme.dart';
import '../ui/widgets.dart';
import 'common.dart';

class AddExpenseScreen extends StatefulWidget {
  const AddExpenseScreen({super.key, this.editing, this.startWithVoice = false, this.groupId});
  final Expense? editing;
  final bool startWithVoice;
  final int? groupId;

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> with SingleTickerProviderStateMixin {
  final _speech = SpeechToText();
  final _title = TextEditingController();
  final _note = TextEditingController();
  late final AnimationController _bump = AnimationController(vsync: this, duration: const Duration(milliseconds: 260));
  String _amount = '';
  bool _credit = false;
  bool _keypad = true;
  bool _listening = false;
  bool _voiceUsed = false;
  bool _noteFromVoice = false;
  bool _saved = false;
  String _heard = '';
  String _category = BuiltInCategories.other;
  DateTime _day = Days.today();
  int _paidBy = 0;
  PaymentMode _mode = PaymentMode.upi;
  int? _groupId;
  SplitType _split = SplitType.equal;
  final Map<int, String> _custom = {};
  bool _ready = false;

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
      _amount = Fmt.number(e.amount).replaceAll(',', '');
      _credit = e.isCredit;
      _keypad = false;
      _title.text = e.title;
      _note.text = e.note;
      _category = e.category;
      _day = e.date;
      _paidBy = e.paidBy;
      _mode = e.mode;
      _groupId = e.groupId;
      _split = e.splitType == SplitType.custom ? SplitType.custom : SplitType.equal;
      e.shares.forEach((id, share) => _custom[id] = Fmt.number(share).replaceAll(',', ''));
    }
    if (widget.startWithVoice) WidgetsBinding.instance.addPostFrameCallback((_) => _listen());
  }

  @override
  void dispose() {
    _speech.stop();
    _title.dispose();
    _note.dispose();
    _bump.dispose();
    super.dispose();
  }

  double get _value => double.tryParse(_amount) ?? 0.0;

  Future<void> _listen() async {
    if (_listening) {
      await _speech.stop();
      setState(() => _listening = false);
      return;
    }
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
    final app = AppScope.read(context);
    final parsed = VoiceParser.parse(words, {for (final c in app.categories.where((c) => !c.builtIn)) c.key: c.customName});
    setState(() {
      _listening = false;
      _voiceUsed = true;
      _credit = parsed.credit;
      if (parsed.amount != null) _amount = Fmt.number(parsed.amount!).replaceAll(',', '');
      if (parsed.title.isNotEmpty) _title.text = parsed.title;
      if (parsed.categoryKey != null) _category = parsed.categoryKey!;
      if (parsed.mode != null) _mode = parsed.mode!;
      if (_note.text.isEmpty || _noteFromVoice) {
        _note.text = parsed.note ?? words.capitalised;
        _noteFromVoice = true;
      }
      _keypad = parsed.amount == null;
    });
    _bump.forward(from: 0);
  }

  Map<int, double>? _shares(Group? group) {
    if (group == null || _credit) return {};
    if (_split == SplitType.equal) return SplitCalculator.equalShares(_value, group.memberIds);
    final shares = {for (final id in group.memberIds) id: double.tryParse(_custom[id] ?? '') ?? 0.0};
    final total = shares.values.fold(0.0, (a, b) => a + b);
    return (total - _value).abs() < 0.005 ? shares : null;
  }

  Future<void> _save(Group? group) async {
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
      ..note = _note.text;
    HapticFeedback.heavyImpact();
    setState(() => _saved = true);
    await app.saveExpense(e, voice: _voiceUsed && widget.editing == null);
    await Future<void>.delayed(const Duration(milliseconds: 650));
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _delete() async {
    final app = AppScope.read(context);
    final nav = Navigator.of(context);
    if (await confirm(context, title: tr('delete_expense_q'), body: tr('delete_expense_body'), action: tr('delete'))) {
      await app.deleteExpense(widget.editing!);
      nav.pop();
    }
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

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final cs = context.cs;
    final cat = app.category(_category);
    final group = app.groups.where((g) => g.id == _groupId).firstOrNull;
    final shares = _shares(group);
    final canSave = _value > 0 && shares != null && !_saved;
    final today = Days.today();
    final quickDays = {tr('yesterday'): DateTime(today.year, today.month, today.day - 1), tr('today'): today, tr('tomorrow'): DateTime(today.year, today.month, today.day + 1)};
    final editing = widget.editing != null;
    final accent = _credit ? good : cs.primary;

    return Scaffold(
      body: Backdrop(
        child: Stack(children: [
          SafeArea(
            child: Column(children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
                child: Row(children: [
                  RoundIcon(Icons.close_rounded, onTap: () => Navigator.of(context).pop()),
                  const SizedBox(width: 12),
                  Expanded(child: Text(editing ? tr('edit_expense') : _credit ? tr('add_credit') : tr('add_transaction'), style: context.tt.headlineSmall)),
                  if (editing) RoundIcon(Icons.delete_outline_rounded, onTap: _delete),
                ]),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
                  physics: const BouncingScrollPhysics(),
                  children: [
                    Entrance(
                      child: Pressable(
                        onTap: _listen,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 260),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(color: _listening ? cs.primary : cs.primaryContainer, borderRadius: BorderRadius.circular(22)),
                          child: Row(children: [
                            _MicPulse(active: _listening),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text(_listening ? tr('voice_prompt') : tr('voice_title'), style: context.tt.titleMedium!.copyWith(color: _listening ? Colors.white : cs.onPrimaryContainer, fontWeight: FontWeight.w700)),
                                Text(_listening && _heard.isNotEmpty ? _heard : tr('voice_subtitle'), maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12.5, color: _listening ? Colors.white70 : cs.onSurfaceVariant)),
                              ]),
                            ),
                          ]),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Entrance(
                      index: 1,
                      child: Segmented<bool>(options: {false: tr('kind_expense'), true: tr('kind_credit')}, value: _credit, color: accent, onChanged: (credit) => setState(() => _credit = credit)),
                    ),
                    Entrance(
                      index: 2,
                      child: Pressable(
                        scale: 0.98,
                        onTap: () {
                          FocusScope.of(context).unfocus();
                          setState(() => _keypad = true);
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          child: Column(children: [
                            ScaleTransition(
                              scale: Tween(begin: 1.0, end: 1.1).animate(CurvedAnimation(parent: _bump, curve: Curves.easeOut, reverseCurve: Curves.easeIn)),
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Row(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, children: [
                                  Text(_credit ? '+${Fmt.symbol}' : Fmt.symbol, style: context.tt.displaySmall!.copyWith(fontSize: 40, color: accent.withValues(alpha: 0.75))),
                                  const SizedBox(width: 6),
                                  Text(_amount.isEmpty ? '0' : _amount, style: context.tt.displaySmall!.copyWith(fontSize: 64, color: _amount.isEmpty ? cs.onSurfaceVariant.withValues(alpha: 0.5) : accent)),
                                ]),
                              ),
                            ),
                            if (_credit) Padding(padding: const EdgeInsets.only(top: 6), child: Text(tr('credit_hint'), textAlign: TextAlign.center, style: context.tt.bodySmall)),
                          ]),
                        ),
                      ),
                    ),
                    AnimatedSize(
                      duration: const Duration(milliseconds: 280),
                      curve: Curves.easeOutCubic,
                      child: _keypad
                          ? Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: AmountKeypad(
                                value: _amount,
                                onChanged: (v) {
                                  setState(() => _amount = v);
                                  _bump.forward(from: 0).whenComplete(() => _bump.reverse());
                                },
                              ),
                            )
                          : const SizedBox(width: double.infinity),
                    ),
                    Entrance(
                      index: 3,
                      child: KCard(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          KField(controller: _title, label: tr('what_for'), hint: tr('what_for_hint'), onTap: () => setState(() => _keypad = false)),
                          const SizedBox(height: 14),
                          NavRow(
                            icon: cat.icon,
                            color: cat.tint,
                            title: tr('category'),
                            subtitle: cat.name,
                            onTap: () async {
                              final picked = await pickCategory(context, selected: _category);
                              if (picked != null) setState(() => _category = picked);
                            },
                          ),
                          NavRow(icon: Icons.calendar_month_rounded, color: const Color(0xFF039BE5), title: tr('date'), subtitle: Fmt.relativeDay(_day), onTap: _pickDate),
                          const SizedBox(height: 6),
                          Row(children: [
                            for (final q in quickDays.entries)
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 3),
                                  child: Pressable(
                                    onTap: () => setState(() => _day = q.value),
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
                        ]),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Entrance(
                      index: 4,
                      child: KCard(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(tr('paid_by'), style: context.tt.labelMedium),
                          const SizedBox(height: 10),
                          Wrap(spacing: 8, runSpacing: 8, children: [for (final m in app.members) MemberChip(m, selected: _paidBy == m.id, onTap: () => setState(() => _paidBy = m.id))]),
                          const SizedBox(height: 18),
                          Text(tr('payment_mode'), style: context.tt.labelMedium),
                          const SizedBox(height: 10),
                          Row(children: [
                            for (final m in PaymentMode.values)
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 3),
                                  child: Pressable(
                                    scale: 0.9,
                                    onTap: () => setState(() => _mode = m),
                                    child: AnimatedContainer(
                                      duration: const Duration(milliseconds: 220),
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                      decoration: BoxDecoration(
                                        color: _mode == m ? m.color.withValues(alpha: context.isDark ? 0.3 : 0.14) : cs.surfaceContainerHighest,
                                        borderRadius: BorderRadius.circular(18),
                                        border: Border.all(color: _mode == m ? m.color : Colors.transparent, width: 2),
                                      ),
                                      child: Column(children: [
                                        Icon(m.icon, color: _mode == m ? m.color : cs.onSurfaceVariant),
                                        const SizedBox(height: 4),
                                        Text(m.label, maxLines: 1, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _mode == m ? cs.onSurface : cs.onSurfaceVariant)),
                                      ]),
                                    ),
                                  ),
                                ),
                              ),
                          ]),
                        ]),
                      ),
                    ),
                    if (!_credit) ...[
                      const SizedBox(height: 16),
                      Entrance(
                        index: 5,
                        child: KCard(
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            NavRow(icon: Icons.groups_rounded, color: const Color(0xFF7C4DFF), title: tr('split_with_group'), subtitle: group == null ? tr('not_shared') : group.name, onTap: () => _pickGroup(app)),
                            if (group != null) ...[
                              const SizedBox(height: 8),
                              Row(children: [
                                KChip(tr('split_equally'), selected: _split == SplitType.equal, onTap: () => setState(() => _split = SplitType.equal)),
                                const SizedBox(width: 8),
                                KChip(tr('split_custom'), selected: _split == SplitType.custom, onTap: () => setState(() => _split = SplitType.custom)),
                              ]),
                              const SizedBox(height: 10),
                              for (final id in group.memberIds)
                                Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 4),
                                  child: Row(children: [
                                    Expanded(child: Text(app.memberName(id), style: context.tt.titleSmall)),
                                    if (_split == SplitType.equal)
                                      Text(Fmt.money(SplitCalculator.equalShares(_value, group.memberIds)[id] ?? 0), style: context.tt.titleSmall)
                                    else
                                      SizedBox(
                                        width: 110,
                                        child: TextFormField(
                                          key: ValueKey('share$id'),
                                          initialValue: _custom[id] ?? '',
                                          textAlign: TextAlign.end,
                                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
                                          onTap: () => setState(() => _keypad = false),
                                          onChanged: (v) => setState(() => _custom[id] = v),
                                          decoration: InputDecoration(isDense: true, prefixText: Fmt.symbol, contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10)),
                                        ),
                                      ),
                                  ]),
                                ),
                              if (_split == SplitType.custom) _SharesStatus(_value - group.memberIds.fold(0.0, (a, id) => a + (double.tryParse(_custom[id] ?? '') ?? 0))),
                            ],
                          ]),
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    Entrance(
                      index: 6,
                      child: KField(controller: _note, label: tr('note'), hint: tr('note_hint'), icon: Icons.sticky_note_2_rounded, lines: 3, onTap: () => setState(() => _keypad = false), onChanged: (_) => _noteFromVoice = false),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 6, 20, 14),
                child: KButton(editing ? tr('save_changes') : _credit ? tr('save_credit') : tr('save_expense'), icon: Icons.check_rounded, onTap: canSave ? () => _save(group) : null),
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
  const _SharesStatus(this.left);
  final double left;

  @override
  Widget build(BuildContext context) {
    final ok = left.abs() < 0.005;
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Text(ok ? tr('shares_ok') : left > 0 ? tr('shares_left', [Fmt.money(left)]) : tr('shares_over', [Fmt.money(-left)]), style: context.tt.labelMedium!.copyWith(color: ok ? good : bad)),
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
      width: 48,
      height: 48,
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
          width: 40,
          height: 40,
          decoration: BoxDecoration(shape: BoxShape.circle, color: widget.active ? Colors.white : cs.primary),
          child: Icon(widget.active ? Icons.graphic_eq_rounded : Icons.mic_rounded, color: widget.active ? cs.primary : Colors.white, size: 22),
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
