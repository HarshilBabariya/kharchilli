import 'package:flutter/material.dart';

import '../core/app_state.dart';
import '../core/format.dart';
import '../core/l10n.dart';
import '../core/models.dart';
import '../ui/glyphs.dart';
import '../ui/theme.dart';
import '../ui/widgets.dart';
import 'common.dart';

class KhataScreen extends StatelessWidget {
  const KhataScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    return KPage(
      title: tr('khata'),
      bottom: KButton(tr('add_shop'), icon: Icons.add_business_rounded, onTap: () async {
        final name = await askText(context, tr('add_shop'), tr('shop_name'), tr('shop_name_hint'));
        if (name != null) await app.addShop(name);
      }),
      children: [
        KCard(
          gradient: context.heroGradient,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(tr('khata_total_due'), style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontWeight: FontWeight.w600)),
            CountUp(app.totalKhataDue, style: context.tt.displaySmall!.copyWith(color: Colors.white)),
            const SizedBox(height: 6),
            Text(tr('khata_explain'), style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 12.5)),
          ]),
        ),
        const SizedBox(height: 14),
        if (app.shops.isEmpty) EmptyState(art: 'shop', title: tr('khata_empty'), body: tr('khata_empty_body')),
        for (final shop in app.shops)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: KCard(
              onTap: () => _shop(context, shop),
              child: Row(children: [
                const Sticker('shop', size: 52),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(shop.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: context.tt.titleLarge),
                    Text(tr('khata_entries', [app.khata.where((k) => k.shopId == shop.id).length]), style: context.tt.bodySmall),
                  ]),
                ),
                Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Text(Fmt.money(app.khataDue(shop).abs()), style: context.tt.titleMedium!.copyWith(fontWeight: FontWeight.w700, color: app.khataDue(shop) > 0.005 ? bad : good)),
                  Text(app.khataDue(shop) > 0.005 ? tr('khata_due') : tr('khata_clear'), style: context.tt.labelSmall),
                ]),
              ]),
            ),
          ),
      ],
    );
  }

  void _shop(BuildContext context, Shop shop) {
    showKSheet<void>(
      context,
      title: shop.name,
      builder: (sheet) {
        final app = AppScope.of(sheet);
        final entries = app.khata.where((k) => k.shopId == shop.id).toList().reversed.toList();
        Future<void> add(bool payment) async {
          final amount = await askAmount(sheet, title: payment ? tr('khata_record_payment') : tr('khata_add_purchase'));
          if (amount == null || amount <= 0 || !sheet.mounted) return;
          final note = payment ? '' : await askText(sheet, tr('khata_bought'), tr('note'), tr('khata_note_hint')) ?? '';
          await app.addKhata(shop, amount, payment: payment, note: note);
        }

        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(tr('khata_balance', [Fmt.money(app.khataDue(shop))]), style: sheet.tt.headlineSmall),
          const SizedBox(height: 4),
          Text(tr('khata_payment_logged'), style: sheet.tt.bodySmall),
          const SizedBox(height: 14),
          Row(children: [
            Expanded(child: KButton(tr('khata_bought'), tonal: true, icon: Icons.add_shopping_cart_rounded, onTap: () => add(false))),
            const SizedBox(width: 10),
            Expanded(child: KButton(tr('khata_paid'), icon: Icons.payments_rounded, onTap: () => add(true))),
          ]),
          const SizedBox(height: 10),
          for (final k in entries)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 7),
              child: Row(children: [
                IconTile(k.payment ? Icons.south_west_rounded : Icons.north_east_rounded, color: k.payment ? good : bad, size: 38),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(k.payment ? tr('khata_paid') : (k.note.isEmpty ? tr('khata_bought') : k.note), maxLines: 1, overflow: TextOverflow.ellipsis, style: sheet.tt.titleSmall),
                    Text(Fmt.date(Days.fromKey(k.day), 'd MMM yyyy'), style: sheet.tt.bodySmall),
                  ]),
                ),
                Text('${k.payment ? '−' : '+'}${Fmt.money(k.amount)}', style: sheet.tt.titleSmall!.copyWith(color: k.payment ? good : bad)),
                if (!k.payment) IconButton(onPressed: () => app.deleteKhata(k), icon: const Icon(Icons.close_rounded, size: 18)),
              ]),
            ),
          const SizedBox(height: 8),
          KButton(tr('delete_shop'), tonal: true, danger: true, onTap: () async {
            final nav = Navigator.of(sheet);
            if (await confirm(sheet, title: tr('delete_shop_q', [shop.name]), body: tr('delete_shop_body'), action: tr('delete'))) {
              nav.pop();
              await app.deleteShop(shop);
            }
          }),
        ]);
      },
    );
  }
}

class ServicesScreen extends StatelessWidget {
  const ServicesScreen({super.key});

  static const _presets = <(String, String, ServiceBilling, String)>[
    ('svc_milk', 'milk', ServiceBilling.perUnit, BuiltInCategories.groceries),
    ('svc_newspaper', 'paper', ServiceBilling.perUnit, BuiltInCategories.other),
    ('svc_water_can', 'water', ServiceBilling.perUnit, BuiltInCategories.other),
    ('svc_maid', 'maid', ServiceBilling.monthly, BuiltInCategories.other),
    ('svc_cook', 'cook', ServiceBilling.monthly, BuiltInCategories.other),
    ('svc_driver', 'driver', ServiceBilling.monthly, BuiltInCategories.other),
  ];

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final month = Days.monthStart(Days.today());
    final total = app.services.fold(0.0, (sum, s) => sum + s.billSoFar(month));
    return KPage(
      title: tr('services'),
      bottom: KButton(tr('add_service'), icon: Icons.add_rounded, onTap: () => _add(context)),
      children: [
        KCard(
          gradient: context.heroGradient,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(Fmt.monthYear(month), style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontWeight: FontWeight.w600)),
            Text(tr('services_month_total', [Fmt.money(total)]), style: context.tt.headlineMedium!.copyWith(color: Colors.white)),
            const SizedBox(height: 6),
            Text(tr('services_explain'), style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 12.5)),
          ]),
        ),
        const SizedBox(height: 14),
        if (app.services.isEmpty) EmptyState(art: 'svc_milk', title: tr('services_empty'), body: tr('services_empty_body')),
        for (final s in app.services)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: KCard(
              onTap: () => open(context, ServiceDetailScreen(s)),
              child: Row(children: [
                serviceSticker(s.icon),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(s.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: context.tt.titleLarge),
                    Text(s.billing == ServiceBilling.perUnit ? tr('service_units', [Fmt.number(s.unitsUntil(month, Days.today())), Fmt.money(s.rate)]) : tr('service_leaves', [s.leavesIn(month)]), style: context.tt.bodySmall),
                  ]),
                ),
                Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Text(Fmt.money(s.paidMonths[Days.monthKey(month)] ?? s.billSoFar(month)), style: context.tt.titleMedium!.copyWith(fontWeight: FontWeight.w700)),
                  Text(s.paidMonths.containsKey(Days.monthKey(month)) ? tr('service_paid') : tr('service_so_far'), style: context.tt.labelSmall!.copyWith(color: s.paidMonths.containsKey(Days.monthKey(month)) ? good : null)),
                ]),
              ]),
            ),
          ),
      ],
    );
  }

  Future<void> _add(BuildContext context) async {
    final app = AppScope.read(context);
    final name = TextEditingController();
    final rate = TextEditingController();
    final qty = TextEditingController(text: '1');
    final deduction = TextEditingController();
    var icon = 'other';
    var billing = ServiceBilling.perUnit;
    var category = BuiltInCategories.other;
    await showKSheet<void>(
      context,
      title: tr('add_service'),
      pinned: true,
      builder: (sheet) => StatefulBuilder(
        builder: (_, setState) => KSheetForm(body: [
          SizedBox(
            height: 92,
            child: ListView(scrollDirection: Axis.horizontal, clipBehavior: Clip.none, children: [
              for (final p in _presets)
                Pressable(
                  scale: 0.9,
                  onTap: () => setState(() {
                    name.text = tr(p.$1);
                    icon = p.$2;
                    billing = p.$3;
                    category = p.$4;
                  }),
                  child: SizedBox(
                    width: 76,
                    child: Column(children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(borderRadius: BorderRadius.circular(22), border: Border.all(color: icon == p.$2 ? sheet.cs.primary : Colors.transparent, width: 2.5)),
                        child: serviceSticker(p.$2, size: 54),
                      ),
                      const SizedBox(height: 4),
                      Text(tr(p.$1), maxLines: 1, overflow: TextOverflow.ellipsis, style: sheet.tt.labelSmall!.copyWith(color: sheet.cs.onSurface)),
                    ]),
                  ),
                ),
            ]),
          ),
          const SizedBox(height: 12),
          KField(controller: name, label: tr('service_name'), hint: tr('service_name_hint'), onChanged: (_) => setState(() {})),
          const SizedBox(height: 10),
          Segmented<ServiceBilling>(options: {ServiceBilling.perUnit: tr('billing_per_unit'), ServiceBilling.monthly: tr('billing_monthly')}, value: billing, onChanged: (b) => setState(() => billing = b)),
          const SizedBox(height: 10),
          KField(controller: rate, label: billing == ServiceBilling.perUnit ? tr('rate_per_unit') : tr('monthly_salary'), number: true, onChanged: (_) => setState(() {})),
          const SizedBox(height: 10),
          if (billing == ServiceBilling.perUnit) KField(controller: qty, label: tr('units_per_day'), number: true) else KField(controller: deduction, label: tr('leave_deduction'), number: true),
          ], actions: [
          KButton(tr('save'), onTap: name.text.trim().isEmpty || (double.tryParse(rate.text) ?? 0) <= 0
              ? null
              : () async {
                  final nav = Navigator.of(sheet);
                  nav.pop();
                  await app.saveService(HomeService(
                    name: name.text,
                    icon: icon,
                    billing: billing,
                    rate: double.parse(rate.text),
                    defaultQty: billing == ServiceBilling.perUnit ? double.tryParse(qty.text) ?? 1.0 : 1.0,
                    leaveDeduction: double.tryParse(deduction.text) ?? 0.0,
                    category: category,
                    startDay: Days.key(Days.monthStart(Days.today())),
                  ));
                }),
        ]),
      ),
    );
  }
}

class ServiceDetailScreen extends StatefulWidget {
  const ServiceDetailScreen(this.service, {super.key});
  final HomeService service;

  @override
  State<ServiceDetailScreen> createState() => _ServiceDetailScreenState();
}

class _ServiceDetailScreenState extends State<ServiceDetailScreen> {
  DateTime _month = Days.monthStart(Days.today());
  DateTime? _picked;

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final cs = context.cs;
    final s = widget.service;
    final today = Days.today();
    final start = Days.monthStart(Days.fromKey(s.startDay));
    final perUnit = s.billing == ServiceBilling.perUnit;
    final paid = s.paidMonths[Days.monthKey(_month)];
    final soFar = s.billSoFar(_month), full = s.billFullMonth(_month);
    final advance = s.advances[Days.monthKey(_month)] ?? 0;
    final lead = _month.weekday - 1;

    Future<void> setQty(DateTime d, double qty) async {
      if (qty == s.defaultQty) {
        s.days.remove(Days.key(d));
      } else {
        s.days[Days.key(d)] = qty;
      }
      await app.saveService(s);
    }

    return KPage(
      title: s.name,
      actions: [
        RoundIcon(Icons.delete_outline_rounded, onTap: () async {
          final nav = Navigator.of(context);
          if (await confirm(context, title: tr('delete_service_q', [s.name]), body: tr('delete_service_body'), action: tr('delete'))) {
            nav.pop();
            await app.deleteService(s);
          }
        }),
      ],
      bottom: paid != null
          ? KButton(tr('service_paid_on', [Fmt.money(paid)]), tonal: true)
          : KButton(tr('service_mark_paid', [Fmt.money((full - advance).clamp(0, full).toDouble())]), icon: Icons.check_rounded, onTap: () => app.payService(s, _month)),
      children: [
        KCard(
          child: Column(children: [
            Row(children: [
              RoundIcon(Icons.chevron_left_rounded, onTap: () {
                if (_month.isAfter(start)) setState(() => _month = Days.addMonths(_month, -1));
              }),
              Expanded(child: Text(Fmt.monthYear(_month), textAlign: TextAlign.center, style: context.tt.titleLarge)),
              RoundIcon(Icons.chevron_right_rounded, onTap: () {
                if (Days.addMonths(_month, 1).isBefore(today)) setState(() => _month = Days.addMonths(_month, 1));
              }),
            ]),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: 7,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 4,
              crossAxisSpacing: 4,
              children: [
                for (var i = 0; i < lead + Days.inMonth(_month); i++)
                  if (i < lead)
                    const SizedBox()
                  else
                    Builder(builder: (_) {
                      final d = DateTime(_month.year, _month.month, i - lead + 1);
                      final future = d.isAfter(today);
                      final qty = s.qtyOn(d);
                      final changed = s.days.containsKey(Days.key(d));
                      final on = _picked == d;
                      return Pressable(
                        scale: 0.86,
                        onTap: future || paid != null
                            ? null
                            : () {
                                if (perUnit) {
                                  setState(() => _picked = on ? null : d);
                                } else {
                                  setQty(d, qty == 0 ? s.defaultQty : 0.0);
                                }
                              },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          decoration: BoxDecoration(
                            color: on ? cs.primary : (!perUnit && qty == 0 ? bad.withValues(alpha: 0.18) : changed ? cs.primaryContainer : cs.surfaceContainerHighest),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Opacity(
                            opacity: future ? 0.35 : 1,
                            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                              Text('${d.day}', style: TextStyle(fontSize: 11, color: on ? Colors.white70 : cs.onSurfaceVariant)),
                              if (perUnit) Text(Fmt.number(qty), style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: on ? Colors.white : cs.onSurface)) else Icon(qty == 0 ? Icons.close_rounded : Icons.check_rounded, size: 16, color: qty == 0 ? bad : good),
                            ]),
                          ),
                        ),
                      );
                    }),
              ],
            ),
            if (perUnit && _picked != null && paid == null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  RoundIcon(Icons.remove_rounded, onTap: () => setQty(_picked!, (s.qtyOn(_picked!) - 0.5).clamp(0.0, 99.0).toDouble())),
                  Padding(padding: const EdgeInsets.symmetric(horizontal: 22), child: Text(Fmt.number(s.qtyOn(_picked!)), style: context.tt.headlineMedium)),
                  RoundIcon(Icons.add_rounded, filled: true, onTap: () => setQty(_picked!, s.qtyOn(_picked!) + 0.5)),
                ]),
              ),
            const SizedBox(height: 10),
            Text(perUnit ? tr('service_tap_hint_units') : tr('service_tap_hint_leave'), textAlign: TextAlign.center, style: context.tt.bodySmall),
          ]),
        ),
        const SizedBox(height: 14),
        KCard(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(
              perUnit
                  ? tr('service_bill_units', [Fmt.number(s.rate <= 0 ? 0.0 : soFar / s.rate), Fmt.money(s.rate), Fmt.money(soFar)])
                  : tr('service_bill_monthly', [Fmt.money(s.rate), s.leavesIn(_month), Fmt.money(s.leaveDeduction), Fmt.money(soFar)]),
              style: context.tt.titleMedium,
            ),
            if (perUnit && (full - soFar).abs() > 0.005) Padding(padding: const EdgeInsets.only(top: 6), child: Text(tr('service_full_month', [Fmt.money(full)]), style: context.tt.bodySmall)),
            if (advance > 0) Padding(padding: const EdgeInsets.only(top: 6), child: Text(tr('advance_given', [Fmt.money(advance)]), style: context.tt.bodySmall!.copyWith(color: good, fontWeight: FontWeight.w600))),
            if (paid == null) ...[
              const SizedBox(height: 12),
              KButton(tr('give_advance'), tonal: true, icon: Icons.payments_rounded, onTap: () async {
                final amount = await askAmount(context, title: tr('give_advance'));
                if (amount != null && amount > 0) await app.payAdvance(s, _month, amount);
              }),
            ],
          ]),
        ),
      ],
    );
  }
}

class SavingsScreen extends StatelessWidget {
  const SavingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final rate = app.settings.goldRate;
    return KPage(
      title: tr('savings'),
      children: [
        KCard(
          gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFFFFB627), Color(0xFFE08A00), Color(0xFF9A5B00)]),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(tr('savings_total'), style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontWeight: FontWeight.w600)),
            CountUp(app.goldValue + app.chitValue, style: context.tt.displaySmall!.copyWith(color: Colors.white)),
            Text(tr('savings_split', [Fmt.money(app.goldValue), Fmt.money(app.chitValue)]), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
          ]),
        ),
        const SizedBox(height: 14),
        KCard(
          onTap: () async {
            final v = await askAmount(context, title: tr('gold_rate_field'), initial: rate);
            if (v != null) await app.setGoldRate(v);
          },
          child: Row(children: [
            const IconTile(Icons.show_chart_rounded, color: Color(0xFFFFB300)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(tr('gold_rate_label'), style: context.tt.labelSmall),
                Text(rate > 0 ? tr('gold_rate_value', [Fmt.money(rate)]) : tr('gold_rate_missing'), style: context.tt.titleMedium),
                Text(tr('gold_rate_hint'), style: context.tt.bodySmall),
              ]),
            ),
          ]),
        ),
        SectionTitle(tr('gold'), action: tr('add_gold'), onAction: () => _addGold(context)),
        for (final g in app.gold)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: KCard(
                padding: const EdgeInsets.fromLTRB(14, 14, 6, 14),
                child: Row(children: [
                  const Sticker('gold', size: 48),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(g.label, maxLines: 1, overflow: TextOverflow.ellipsis, style: context.tt.titleMedium),
                      Text(
                        tr('gold_line', [Fmt.number(g.grams), g.karat, Fmt.money(g.pricePaid), g.pricePaid <= 0 || rate <= 0 ? '' : '${g.valueAt(rate) >= g.pricePaid ? '▲' : '▼'} ${((g.valueAt(rate) - g.pricePaid).abs() / g.pricePaid * 100).round()}%']),
                        maxLines: 2,
                        style: context.tt.bodySmall,
                      ),
                    ]),
                  ),
                  Text(Fmt.money(g.valueAt(rate)), style: context.tt.titleMedium!.copyWith(fontWeight: FontWeight.w700)),
                  IconButton(
                    icon: Icon(Icons.delete_outline_rounded, color: context.cs.onSurfaceVariant),
                    onPressed: () {
                      toast(context, tr('deleted_msg', [g.label]), onUndo: () => app.saveGold(g));
                      app.deleteGold(g);
                    },
                  ),
                ]),
            ),
          ),
        SectionTitle(tr('chits'), action: tr('add_chit'), onAction: () => _addChit(context)),
        if (app.chits.isEmpty) Text(tr('chits_empty'), style: context.tt.bodySmall),
        for (final c in app.chits)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: KCard(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Expanded(child: Text(c.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: context.tt.titleLarge)),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      icon: Icon(Icons.delete_outline_rounded, color: context.cs.onSurfaceVariant),
                      onPressed: () {
                        toast(context, tr('deleted_msg', [c.name]), onUndo: () {
                          c.id = 0;
                          app.saveChit(c);
                        });
                        app.deleteChit(c);
                      },
                    ),
                  ]),
                  Text(tr('chit_line', [Fmt.money(c.monthlyAmount), c.paidMonths, c.months]), style: context.tt.bodySmall),
                  const SizedBox(height: 10),
                  KProgress(c.paidMonths / c.months, color: const Color(0xFFFFB300)),
                  const SizedBox(height: 8),
                  Text(c.prizeAmount != null ? tr('chit_prized', [Fmt.money(c.prizeAmount!)]) : c.done ? tr('chit_done') : tr('chit_next_due', [Fmt.monthYear(c.nextDue)]), style: context.tt.labelMedium),
                  const SizedBox(height: 10),
                  Row(children: [
                    if (!c.done)
                      Expanded(
                        child: KButton(tr('chit_pay'), tonal: true, onTap: () {
                          c.paidMonths++;
                          app.saveChit(c);
                        }),
                      ),
                    if (!c.done && c.prizeAmount == null) const SizedBox(width: 10),
                    if (c.prizeAmount == null)
                      Expanded(
                        child: KButton(tr('chit_prize'), onTap: () async {
                          final v = await askAmount(context, title: tr('chit_prize_amount'));
                          if (v != null && v > 0) {
                            c.prizeAmount = v;
                            await app.saveChit(c);
                          }
                        }),
                      ),
                  ]),
                ]),
            ),
          ),
      ],
    );
  }

  Future<void> _addGold(BuildContext context) async {
    final app = AppScope.read(context);
    final label = TextEditingController(), grams = TextEditingController(), paid = TextEditingController();
    var karat = 22;
    await showKSheet<void>(
      context,
      title: tr('add_gold'),
      builder: (sheet) => StatefulBuilder(
        builder: (_, setState) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          KField(controller: label, label: tr('gold_label'), hint: tr('gold_label_hint'), onChanged: (_) => setState(() {})),
          const SizedBox(height: 10),
          KField(controller: grams, label: tr('gold_grams'), number: true, onChanged: (_) => setState(() {})),
          const SizedBox(height: 10),
          Row(children: [for (final k in [24, 22, 18]) Padding(padding: const EdgeInsets.only(right: 8), child: KChip('${k}K', selected: karat == k, onTap: () => setState(() => karat = k)))]),
          const SizedBox(height: 10),
          KField(controller: paid, label: tr('gold_price_paid'), number: true),
          const SizedBox(height: 14),
          KButton(tr('save'), onTap: label.text.trim().isEmpty || (double.tryParse(grams.text) ?? 0) <= 0
              ? null
              : () async {
                  final nav = Navigator.of(sheet);
                  nav.pop();
                  await app.saveGold(GoldItem(label: label.text.trim().capitalised, grams: double.parse(grams.text), karat: karat, pricePaid: double.tryParse(paid.text) ?? 0.0));
                }),
        ]),
      ),
    );
  }

  Future<void> _addChit(BuildContext context) async {
    final app = AppScope.read(context);
    final name = TextEditingController(), monthly = TextEditingController(), months = TextEditingController(text: '20');
    await showKSheet<void>(
      context,
      title: tr('add_chit'),
      builder: (sheet) => StatefulBuilder(
        builder: (_, setState) => Column(children: [
          KField(controller: name, label: tr('chit_name'), hint: tr('chit_name_hint'), onChanged: (_) => setState(() {})),
          const SizedBox(height: 10),
          KField(controller: monthly, label: tr('chit_monthly'), number: true, onChanged: (_) => setState(() {})),
          const SizedBox(height: 10),
          KField(controller: months, label: tr('chit_months'), number: true, onChanged: (_) => setState(() {})),
          const SizedBox(height: 6),
          Text('${tr('chit_start')} · ${Fmt.monthYear(Days.today())}', style: sheet.tt.bodySmall),
          const SizedBox(height: 14),
          KButton(tr('save'), onTap: name.text.trim().isEmpty || (double.tryParse(monthly.text) ?? 0) <= 0 || (int.tryParse(months.text) ?? 0) <= 0
              ? null
              : () async {
                  final nav = Navigator.of(sheet);
                  nav.pop();
                  await app.saveChit(Chit(name: name.text.trim().capitalised, monthlyAmount: double.parse(monthly.text), months: int.parse(months.text), startMonth: Days.monthKey(Days.today())));
                }),
        ]),
      ),
    );
  }
}
