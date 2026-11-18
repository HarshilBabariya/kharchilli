import 'dart:math';

import 'package:flutter/material.dart';

import '../core/app_state.dart';
import '../core/catalogs.dart';
import '../core/format.dart';
import '../core/l10n.dart';
import '../core/models.dart';
import '../ui/avatar.dart';
import '../ui/glyphs.dart';
import '../ui/theme.dart';
import '../ui/widgets.dart';

/// The frame every shared image uses: brand gradient, the mark and name on top, the tagline at the bottom.
class ShareCard extends StatelessWidget {
  const ShareCard({super.key, required this.label, required this.child});
  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1080 / 1350,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(gradient: context.heroGradient, borderRadius: BorderRadius.circular(28)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(children: [
            ClipRRect(borderRadius: BorderRadius.circular(9), child: Image.asset('assets/brand/icon.png', width: 30, height: 30)),
            const SizedBox(width: 8),
            const Text('Gharcha', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700, fontSize: 17, color: Colors.white)),
            const Spacer(),
            Pill(label, onDark: true),
          ]),
          const SizedBox(height: 14),
          Expanded(child: child),
          const SizedBox(height: 12),
          Text(tr('tagline'), textAlign: TextAlign.center, style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 11.5, fontWeight: FontWeight.w600)),
        ]),
      ),
    );
  }
}

/// The white panel most cards put their details on.
class _Panel extends StatelessWidget {
  const _Panel({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(22), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.18), blurRadius: 24, offset: const Offset(0, 10))]),
      child: DefaultTextStyle.merge(style: const TextStyle(color: Color(0xFF1D1517)), child: child),
    );
  }
}

const _ink = Color(0xFF1D1517);
const _muted = Color(0xFF6E6064);

/// "A owes B" for one payment of a group's settle-up plan.
class ReminderCard extends StatelessWidget {
  const ReminderCard(this.group, this.transfer, {super.key});
  final Group group;
  final Transfer transfer;

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final from = app.member(transfer.fromId), to = app.member(transfer.toId);
    return ShareCard(
      label: tr('settle_up'),
      child: _Panel(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            if (from != null) AvatarView(from.avatar.copyWith(mood: Mood.worried), size: 78),
            const Padding(padding: EdgeInsets.symmetric(horizontal: 10), child: Icon(Icons.arrow_forward_rounded, color: _muted, size: 26)),
            if (to != null) AvatarView(to.avatar.copyWith(mood: Mood.happy), size: 78),
          ]),
          const SizedBox(height: 16),
          Text(tr('card_owes', [transfer.fromName, transfer.toName]), textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w500, fontSize: 16, color: _muted)),
          const SizedBox(height: 4),
          FittedBox(fit: BoxFit.scaleDown, child: Text(Fmt.money(transfer.amount), style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700, fontSize: 46, color: _ink))),
          const SizedBox(height: 12),
          Row(mainAxisSize: MainAxisSize.min, children: [
            groupSticker(group.icon, size: 30),
            const SizedBox(width: 8),
            Flexible(child: Text(group.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: _ink))),
          ]),
          if ((to?.upiId ?? '').isNotEmpty) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(color: const Color(0xFFF4EEF0), borderRadius: BorderRadius.circular(12)),
              child: Text('UPI · ${to!.upiId}', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: _ink)),
            ),
          ],
        ]),
      ),
    );
  }
}

/// A group's total and where every member stands.
class GroupCard extends StatelessWidget {
  const GroupCard(this.group, {super.key});
  final Group group;

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final balances = app.balances(group);
    return ShareCard(
      label: tr('balances'),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          groupSticker(group.icon, size: 44),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(group.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700, fontSize: 19, color: Colors.white)),
              Text('${tr('total_shared')} · ${Fmt.money(max(AppState.net(app.groupExpenses(group)), 0.0))}', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 12.5, fontWeight: FontWeight.w600)),
            ]),
          ),
        ]),
        const SizedBox(height: 14),
        Expanded(
          child: _Panel(
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              for (final b in balances.take(6))
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 5),
                  child: Row(children: [
                    if (app.member(b.memberId) != null) AvatarView(app.member(b.memberId)!.avatar, size: 32, ring: false),
                    const SizedBox(width: 10),
                    Expanded(child: Text(b.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: _ink))),
                    Text(
                      b.net.abs() < 0.005 ? tr('settled') : b.net > 0 ? tr('gets_amount', [Fmt.money(b.net)]) : tr('owes_amount', [Fmt.money(-b.net)]),
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: b.net.abs() < 0.005 ? _muted : b.net > 0 ? good : bad),
                    ),
                  ]),
                ),
            ]),
          ),
        ),
      ]),
    );
  }
}

/// One expense as a receipt.
class ReceiptCard extends StatelessWidget {
  const ReceiptCard(this.expense, {super.key});
  final Expense expense;

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final cat = app.category(expense.category);
    Widget line(String label, String value) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 5),
          child: Row(children: [
            Text(label, style: const TextStyle(color: _muted, fontSize: 12.5, fontWeight: FontWeight.w600)),
            const SizedBox(width: 12),
            Expanded(child: Text(value, textAlign: TextAlign.end, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: _ink, fontSize: 13.5, fontWeight: FontWeight.w700))),
          ]),
        );
    return ShareCard(
      label: expense.isCredit ? tr('kind_credit') : tr('kind_expense'),
      child: _Panel(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          IconTile(cat.icon, color: cat.tint, size: 56),
          const SizedBox(height: 12),
          Text(expense.title, textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700, fontSize: 18, color: _ink)),
          FittedBox(fit: BoxFit.scaleDown, child: Text(Fmt.ledger(expense.amount), style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700, fontSize: 42, color: expense.isCredit ? good : _ink))),
          const SizedBox(height: 8),
          const Divider(color: Color(0x22000000)),
          line(tr('date'), Fmt.date(expense.date, 'd MMM yyyy')),
          line(tr('category'), cat.name),
          line(tr('paid_by'), app.memberName(expense.paidBy)),
          line(tr('payment_mode'), expense.mode.label),
          if (expense.note.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 8), child: Text(expense.note, textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: _muted, fontSize: 12.5))),
        ]),
      ),
    );
  }
}

/// A badge that was earned, to show off.
class BadgeCard extends StatelessWidget {
  const BadgeCard(this.badge, {super.key});
  final BadgeDef badge;

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    return ShareCard(
      label: tr('toast_streak', [app.streak]),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Medal(badge.id, size: 150),
        const SizedBox(height: 14),
        Text(tr('card_badge', [app.me?.name ?? '']), textAlign: TextAlign.center, style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 14, fontWeight: FontWeight.w600)),
        const SizedBox(height: 2),
        Text(badge.name, textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700, fontSize: 26, color: Colors.white, height: 1.15)),
        const SizedBox(height: 8),
        Text(badge.description, textAlign: TextAlign.center, maxLines: 3, overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 13.5, height: 1.35)),
      ]),
    );
  }
}
